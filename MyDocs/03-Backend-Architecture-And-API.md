# Backend Architecture and API Analysis
## Detailed Reverse Engineering Analysis

**Document Version:** 1.0
**Last Updated:** December 31, 2025

---

## Table of Contents
1. [Backend Architecture Overview](#backend-architecture-overview)
2. [Database Schema](#database-schema)
3. [Model Layer](#model-layer)
4. [Controller Layer](#controller-layer)
5. [Service Layer](#service-layer)
6. [Background Jobs](#background-jobs)
7. [API Endpoints](#api-endpoints)
8. [Real-time System](#real-time-system)
9. [File Storage](#file-storage)
10. [Security & Authentication](#security--authentication)

---

## Backend Architecture Overview

### Rails 8.1.1 Framework

Eigenfocus leverages the latest Rails 8 features:

**Modern Rails 8 Features:**
- **Solid Queue** - Database-backed background job processing (replaces Redis-based Sidekiq/Resque)
- **Solid Cable** - Database-backed ActionCable (replaces Redis for WebSocket pub/sub)
- **Kamal Deployment** - Built-in zero-downtime deployment (not used here, Docker instead)
- **SQLite 3 for Production** - Officially supported for production workloads

**Architecture Pattern:**
```
┌─────────────────────────────────────────────┐
│              Puma Web Server                │
│         (Multi-threaded, Clustered)         │
└────────────┬────────────────────────────────┘
             │
    ┌────────┴────────┐
    │                 │
┌───▼────┐      ┌────▼─────┐
│  HTTP  │      │ActionCable│
│Request │      │WebSockets │
└───┬────┘      └────┬──────┘
    │                │
┌───▼────────────────▼──────┐
│    Rails Router           │
└───┬───────────────────────┘
    │
┌───▼───────────────────────┐
│    Controllers            │
│  (Business Logic Entry)   │
└───┬───────────────────────┘
    │
┌───▼───────────────────────┐
│    Models (ActiveRecord)  │
│    Services (Business)    │
│    Jobs (Background)      │
└───┬───────────────────────┘
    │
┌───▼───────────────────────┐
│   Database Layer          │
│  - Primary DB (SQLite)    │
│  - Cable DB (SQLite)      │
│  - Queue DB (SQLite)      │
└───────────────────────────┘
```

### Directory Structure

```
app/
├── channels/              # ActionCable WebSocket channels
│   └── visualizations/
│       ├── allocations_channel.rb
│       └── groupings_channel.rb
├── controllers/           # HTTP request handlers
│   ├── application_controller.rb
│   ├── projects_controller.rb
│   ├── issues_controller.rb
│   ├── time_entries_controller.rb
│   ├── reports_controller.rb
│   ├── visualizations_controller.rb
│   └── ...
├── models/                # Data models (ActiveRecord)
│   ├── project.rb
│   ├── issue.rb
│   ├── time_entry.rb
│   ├── user.rb
│   └── ...
├── services/              # Business logic services
│   ├── example_project_creator.rb
│   └── project/templatable/
│       ├── template.rb
│       └── template_applier.rb
├── jobs/                  # Background jobs
│   ├── new_version_check_job.rb
│   ├── eigenfocus_notifications_fetcher_job.rb
│   └── submit_survey_response_job.rb
├── views/                 # ERB templates
├── components/            # ViewComponents
└── helpers/               # View helpers
```

---

## Database Schema

### Multi-Database Architecture

**Three Separate SQLite Databases:**

1. **Primary Database** (`db/production.sqlite3`)
   - Application data
   - Users, projects, issues, time entries
   - Schema: `db/schema.rb`

2. **Cable Database** (`db/production_cable.sqlite3`)
   - ActionCable subscriptions and state
   - Schema: `db/cable_schema.rb`

3. **Queue Database** (`db/production_queue.sqlite3`)
   - Solid Queue job processing
   - Schema: `db/queue_schema.rb`

### Primary Database Schema

#### Core Tables

**1. users**
```sql
CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  locale VARCHAR(5),              -- User language preference
  timezone VARCHAR,               -- User timezone
  favorite_theme_key VARCHAR,     -- Theme preference
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
)
```

**Fields:**
- `locale` - Language code (en, pt-BR)
- `timezone` - IANA timezone string
- `favorite_theme_key` - Theme selection

**Relations:**
- `has_many :time_entries`
- `has_one :preferences` (user_preferences table)

---

**2. user_preferences**
```sql
CREATE TABLE user_preferences (
  id INTEGER PRIMARY KEY,
  user_id INTEGER NOT NULL,
  time_entry_time_format VARCHAR DEFAULT 'minutes' NOT NULL,
  favorite_theme_key VARCHAR,
  FOREIGN KEY (user_id) REFERENCES users(id)
)
```

**Fields:**
- `time_entry_time_format` - Display format: "minutes" or "hours:minutes"
- `favorite_theme_key` - Duplicated from users table (normalization issue)

---

**3. projects**
```sql
CREATE TABLE projects (
  id INTEGER PRIMARY KEY,
  name VARCHAR,
  archived_at DATETIME,           -- NULL = active, SET = archived
  time_tracking_enabled BOOLEAN DEFAULT TRUE NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
)
```

**Business Rules:**
- Must be archived before deletion (via `before_destroy :ensure_is_archived`)
- `time_tracking_enabled` toggles time entry creation for project

**Relations:**
- `has_many :visualizations`
- `has_many :time_entries`
- `has_many :issues`
- `has_many :issue_labels`

**Scopes:**
- `scope :active` - Where `archived_at IS NULL`

---

**4. issues**
```sql
CREATE TABLE issues (
  id INTEGER PRIMARY KEY,
  title VARCHAR,
  description VARCHAR,            -- Markdown text
  project_id INTEGER,
  archived_at DATETIME,           -- Archived state
  finished_at DATETIME,           -- Finished state (separate from archived)
  due_date DATE,
  comments_count INTEGER DEFAULT 0 NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id)
)
```

**Key Concepts:**
- **Archived vs Finished:** Two separate states
  - `archived_at` - Hidden from view, can be restored
  - `finished_at` - Marked as complete, still visible
- **Must archive before delete** - Safety mechanism
- **Comments counter cache** - Denormalized for performance

**Relations:**
- `belongs_to :project`
- `has_many :time_entries`
- `has_many :grouping_issue_allocations` (position on Kanban board)
- `has_many :groupings, through: :grouping_issue_allocations`
- `has_many :comments` (Issue::Comment model)
- `has_many :label_links` (IssueLabelLink join table)
- `has_many :labels, through: :label_links`
- `has_many_attached :files` (ActiveStorage)

**Scopes:**
- `scope :active` - Not archived
- `scope :archived` - Archived
- `scope :finished` - Finished
- `scope :by_archiving_status(status)` - Filter by status
- `scope :by_label_titles(*titles)` - Filter by label names

**Ransack Support (Search/Filter):**
- Searchable: `title`, `due_date`, `created_at`, `updated_at`
- Associations: `labels`, `groupings`
- Scopes: `by_label_titles`, `by_archiving_status`

---

**5. issue_labels**
```sql
CREATE TABLE issue_labels (
  id INTEGER PRIMARY KEY,
  title VARCHAR NOT NULL,
  project_id INTEGER,
  hex_color VARCHAR,              -- #RRGGBB format
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id)
)
```

**Relations:**
- `belongs_to :project`
- `has_many :label_links`
- `has_many :issues, through: :label_links`

**Indexes:**
- `index_issue_labels_on_title`
- `index_issue_labels_on_project_id`

---

**6. issue_label_links** (Join Table)
```sql
CREATE TABLE issue_label_links (
  id INTEGER PRIMARY KEY,
  issue_id INTEGER NOT NULL,
  issue_label_id INTEGER NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  UNIQUE INDEX (issue_id, issue_label_id)
)
```

**Many-to-Many Relationship:**
- Issues ↔ IssueLabels

---

**7. issue_comments**
```sql
CREATE TABLE issue_comments (
  id INTEGER PRIMARY KEY,
  content TEXT,
  issue_id INTEGER NOT NULL,
  author_id INTEGER NOT NULL,     -- User who wrote comment
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (issue_id) REFERENCES issues(id),
  FOREIGN KEY (author_id) REFERENCES users(id)
)
```

**Model:** `Issue::Comment`

**Relations:**
- `belongs_to :issue, counter_cache: :comments_count`
- `belongs_to :author, class_name: 'User'`

---

**8. visualizations**
```sql
CREATE TABLE visualizations (
  id INTEGER PRIMARY KEY,
  type VARCHAR DEFAULT 'board',   -- Visualization type
  project_id INTEGER NOT NULL,
  favorite_issue_labels JSON DEFAULT '[]' NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id)
)
```

**Business Logic:**
- Each project has one default visualization (auto-created)
- `type = 'board'` - Currently only Kanban board view in FREE edition
- `favorite_issue_labels` - JSON array of label IDs for quick filtering

**Relations:**
- `belongs_to :project`
- `has_many :groupings` (Kanban columns)

---

**9. groupings**
```sql
CREATE TABLE groupings (
  id INTEGER PRIMARY KEY,
  title VARCHAR,
  visualization_id INTEGER NOT NULL,
  position INTEGER NOT NULL,      -- Display order
  hidden BOOLEAN DEFAULT FALSE NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  UNIQUE INDEX (visualization_id, position),
  FOREIGN KEY (visualization_id) REFERENCES visualizations(id)
)
```

**Business Logic:**
- Kanban board columns
- Positioned using `acts_as_list` or similar (unique position per visualization)
- Can be hidden without deletion

**Relations:**
- `belongs_to :visualization`
- `has_many :grouping_issue_allocations`
- `has_many :issues, through: :grouping_issue_allocations`

---

**10. grouping_issue_allocations** (Join Table with Position)
```sql
CREATE TABLE grouping_issue_allocations (
  id INTEGER PRIMARY KEY,
  position INTEGER NOT NULL,      -- Position within grouping
  issue_id INTEGER NOT NULL,
  grouping_id INTEGER NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  UNIQUE INDEX (grouping_id, position),
  FOREIGN KEY (grouping_id) REFERENCES groupings(id),
  FOREIGN KEY (issue_id) REFERENCES issues(id)
)
```

**Business Logic:**
- Places issues in specific columns at specific positions
- Unique position per grouping (drag-and-drop ordering)

---

**11. time_entries**
```sql
CREATE TABLE time_entries (
  id INTEGER PRIMARY KEY,
  project_id INTEGER,
  user_id INTEGER,
  issue_id INTEGER,               -- NULL = project-level time
  description VARCHAR DEFAULT '',
  total_logged_time_in_minutes INTEGER DEFAULT 0 NOT NULL,
  started_at DATETIME,            -- NULL = stopped, SET = running
  reference_date DATE,            -- Date for time entry
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL,
  FOREIGN KEY (project_id) REFERENCES projects(id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (issue_id) REFERENCES issues(id)
)
```

**Time Tracking Logic:**
- **Running Entry:** `started_at IS NOT NULL`
- **Stopped Entry:** `started_at IS NULL`

**Methods:**
- `start!` - Sets `started_at` to current time
- `stop!` - Calculates elapsed time, adds to `total_logged_time_in_minutes`, clears `started_at`
- `total_time` - Returns total including currently running time

**Relations:**
- `belongs_to :user`
- `belongs_to :project`
- `belongs_to :issue, optional: true`

**Scopes:**
- `scope :by_date(date)` - Filter by reference_date
- `scope :running` - Where `started_at IS NOT NULL`
- `scope :by_issue_labels_title(*titles)` - Filter by issue labels

**Validations:**
- `reference_date` required
- `total_logged_time_in_minutes` >= 0

---

**12. notifications**
```sql
CREATE TABLE notifications (
  id INTEGER PRIMARY KEY,
  title VARCHAR NOT NULL,
  content TEXT,
  announcement_modes JSON DEFAULT '[]' NOT NULL,
  external_link BOOLEAN DEFAULT FALSE,
  external_id VARCHAR,
  read_at DATETIME,
  published_at DATETIME,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
)
```

**Purpose:** System announcements and updates from Eigenfocus team

**Fields:**
- `external_id` - ID from external notification service
- `read_at` - NULL = unread, SET = read
- `published_at` - When notification becomes visible

---

**13. app_metadata** (Singleton Table)
```sql
CREATE TABLE app_metadata (
  id INTEGER PRIMARY KEY,
  token VARCHAR,
  last_released_version VARCHAR,
  last_released_version_checked_at DATETIME,
  last_used_at DATETIME,
  onboarding_survey_response JSON DEFAULT '{}',
  survey_token VARCHAR
)
```

**Purpose:** Application-level metadata (only one row)

**Fields:**
- `token` - Unique instance identifier
- `last_released_version` - Latest version from update check
- `onboarding_survey_response` - Survey answers
- `survey_token` - Anonymous survey submission token

---

**14. active_storage_* Tables**

Rails ActiveStorage for file uploads:

```sql
-- File metadata
CREATE TABLE active_storage_blobs (
  id INTEGER PRIMARY KEY,
  key VARCHAR NOT NULL UNIQUE,
  filename VARCHAR NOT NULL,
  content_type VARCHAR,
  metadata TEXT,
  service_name VARCHAR NOT NULL,
  byte_size BIGINT NOT NULL,
  checksum VARCHAR,
  created_at DATETIME NOT NULL
)

-- Polymorphic attachments
CREATE TABLE active_storage_attachments (
  id INTEGER PRIMARY KEY,
  name VARCHAR NOT NULL,
  record_type VARCHAR NOT NULL,
  record_id BIGINT NOT NULL,
  blob_id BIGINT NOT NULL,
  created_at DATETIME NOT NULL,
  UNIQUE INDEX (record_type, record_id, name, blob_id)
)

-- Image variants
CREATE TABLE active_storage_variant_records (
  id INTEGER PRIMARY KEY,
  blob_id BIGINT NOT NULL,
  variation_digest VARCHAR NOT NULL,
  UNIQUE INDEX (blob_id, variation_digest)
)
```

**Usage:**
- Issue file attachments: `Issue.files` (has_many_attached)
- Avatar uploads (if implemented)

---

### Database Indexes

**Performance Indexes:**
- `index_issues_on_archived_at` - Fast archived/active filtering
- `index_issues_on_project_id` - Issue lookups by project
- `index_time_entries_on_project_id` - Time report queries
- `index_time_entries_on_user_id` - User time entry queries
- `index_grouping_issue_allocations_on_grouping_id_and_position` - Kanban board rendering
- `index_issue_label_links_on_issue_id_and_issue_label_id` - Label filtering

---

## Model Layer

### ActiveRecord Models

#### Project Model
**File:** `app/models/project.rb`

```ruby
class Project < ApplicationRecord
  # Virtual attribute for template selection
  attribute :use_template, :string

  # Relations
  has_many :visualizations, dependent: :destroy
  has_many :time_entries, dependent: :destroy
  has_many :issues, dependent: :destroy
  has_many :issue_labels, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :use_template,
    inclusion: { in: Template::AVAILABLE_TEMPLATES },
    on: :create,
    if: -> { use_template.present? }

  # Safety: Must archive before destroy
  before_destroy :ensure_is_archived

  # Scopes
  scope :active, -> { where(archived_at: nil) }

  # Auto-apply template on creation
  after_create :apply_template, if: -> { use_template.present? }

  # Business logic
  def default_visualization
    visualizations.first_or_create
  end

  def archived?
    archived_at.present?
  end

  def archive!
    self.archived_at = Time.current
    save!
  end

  def unarchive!
    self.archived_at = nil
    save!
  end
end
```

**Template System:**
- `use_template` - Virtual attribute for project creation
- Available templates stored in `config/project_templates/`
- Applied via `Project::Templatable::TemplateApplier` service

---

#### Issue Model
**File:** `app/models/issue.rb`

```ruby
class Issue < ApplicationRecord
  ARCHIVING_STATUS_LIST = [:all, :active, :archived, :finished]

  # Relations
  belongs_to :project
  has_many_attached :files
  has_many :time_entries, dependent: :nullify
  has_many :grouping_issue_allocations, dependent: :destroy
  has_many :groupings, through: :grouping_issue_allocations
  has_many :comments,
    class_name: "Issue::Comment",
    dependent: :destroy,
    counter_cache: :comments_count
  has_many :label_links,
    class_name: "IssueLabelLink",
    dependent: :destroy
  has_many :labels,
    through: :label_links,
    source: :issue_label

  # Validations
  validates :title, presence: true

  # Safety: Must archive before destroy
  before_destroy :ensure_is_archived, unless: -> { destroyed_by_association }

  # Scopes
  scope :archived, ->(archived = true) {
    archived ? where.not(archived_at: nil) : where(archived_at: nil)
  }
  scope :active, -> { archived(false) }
  scope :finished, ->(finished = true) {
    finished ? where.not(finished_at: nil) : where(finished_at: nil)
  }
  scope :by_archiving_status, ->(status) {
    case status
    when "all" then all
    when "active" then active
    when "archived" then archived(true)
    when "finished" then finished(true)
    end
  }

  # Complex label filtering scope
  scope :by_label_titles, ->(*label_titles) do
    label_titles.flatten!
    from(
      joins(:labels)
        .where("LOWER(issue_labels.title) IN (?)", label_titles.map(&:downcase))
        .group("issues.id")
        .having("COUNT(DISTINCT issue_labels.id) = ?", label_titles.size),
      :issues
    )
  end

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    ["title", "due_date", "created_at", "updated_at"]
  end

  def self.ransackable_scopes(auth_object = nil)
    ["by_label_titles", "by_archiving_status"]
  end

  # Real-time updates
  after_update_commit -> {
    broadcast_replace_later_to(
      project.default_visualization,
      partial: "visualizations/card",
      locals: { issue: self, visualization: project.default_visualization }
    )
  }

  # SEO-friendly URLs
  def to_param
    if persisted?
      [id, title.parameterize].join("-")
    end
  end

  # Label management
  def labels_list=(labels_input)
    @labels_list = parse_label_input(labels_input)
  end

  def labels_list
    @labels_list || labels.map(&:title)
  end

  before_commit :apply_labels_list, unless: -> { @labels_list.blank? }

  def apply_labels_list
    self.labels = @labels_list.map do |title|
      project.issue_labels.with_title(title).first ||
        project.issue_labels.create(title: title)
    end
  end
end
```

**Key Features:**
- Dual archiving states (archived + finished)
- Safety mechanism prevents accidental deletion
- Real-time broadcasts on update
- Label auto-creation on assignment
- SEO-friendly URLs (slug-based)

---

#### TimeEntry Model
**File:** `app/models/time_entry.rb`

```ruby
class TimeEntry < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :project
  belongs_to :issue, optional: true

  # Scopes
  scope :by_date, ->(date) { where(reference_date: date) }
  scope :running, -> { where.not(started_at: nil) }

  # Validations
  validates :reference_date, presence: true
  validates :total_logged_time_in_minutes,
    presence: true,
    numericality: { greater_than_or_equal_to: 0 }

  # Real-time broadcasts
  broadcasts_to ->(time_entry) { "time_entries" },
    inserts_by: :prepend,
    target: "time-entries-tbody"

  after_commit :broadcast_header_update

  # Timer controls
  def start!
    fail "You can only start stopped time entries" if started_at.present?
    self.started_at = DateTime.current
    save!
  end

  def stop!
    fail "You can only stop running time entries" if started_at.nil?
    self.total_logged_time_in_minutes ||= 0
    self.total_logged_time_in_minutes =
      ((Time.current - started_at) / 60.0) + total_logged_time_in_minutes
    self.started_at = nil
    save!
  end

  def total_time
    return total_logged_time_in_minutes unless running?
    total_logged_time_in_minutes + (Time.current - started_at.to_datetime)/60.0
  end

  def running?
    started_at.present?
  end

  private

  def broadcast_header_update
    broadcast_replace_to(
      "layout_updates",
      target: "header_running_time_entries",
      renderable: Header::RunningTimeEntriesComponent.new(
        count: user.running_time_entries.count
      )
    )
  end
end
```

**Timer Logic:**
- `start!` - Begin timer (set `started_at`)
- `stop!` - Stop timer (calculate elapsed, clear `started_at`)
- `total_time` - Running total including active timer
- Real-time header updates when timer state changes

---

#### Visualization Model
**File:** `app/models/visualization.rb`

```ruby
class Visualization < ApplicationRecord
  # Disable STI (using 'type' as regular column)
  self.inheritance_column = "_type"

  VALID_TYPES = ["board"]

  # Associations
  belongs_to :project
  has_many :groupings, -> { order(position: :asc) }, dependent: :destroy

  # Validations
  validates :type, inclusion: { in: VALID_TYPES }

  # Broadcasts
  after_update_commit :broadcast_favorite_issue_labels,
    if: -> { saved_change_to_favorite_issue_labels? }

  def broadcast_favorite_issue_labels
    broadcast_replace_later_to(
      self,
      targets: "[data-visualization-favorite-labels-list='#{id}']".html_safe,
      partial: "visualizations/favorite_labels_dropdown_list",
      locals: { visualization: self }
    )
  end
end
```

**Note:** `inheritance_column = "_type"` disables Rails STI to use `type` as regular column

---

## Controller Layer

### Controller Architecture

**Base Controller:**
`app/controllers/application_controller.rb`

```ruby
class ApplicationController < ActionController::Base
  # CSRF protection (enabled by default)
  # Session management
  # Flash messages
  # Localization
  # Timezone handling
end
```

### Key Controllers

#### ProjectsController
**File:** `app/controllers/projects_controller.rb`

**Routes:**
```ruby
resources :projects do
  member do
    put :archive
    put :unarchive
  end
end
```

**Actions:**
- `index` - List all projects
- `new` - New project form
- `create` - Create project (with optional template)
- `show` - Redirects to default visualization
- `edit` - Edit project form
- `update` - Update project
- `destroy` - Delete project (only if archived)
- `archive` - Archive project
- `unarchive` - Restore archived project

---

#### IssuesController
**File:** `app/controllers/issues_controller.rb`

**Routes:**
```ruby
resources :issues, only: [:destroy] do
  member do
    patch :update_description
    patch :pick_grouping
    put :archive
    put :unarchive
    put :finish
    put :unfinish
  end
end
```

**Actions:**
- `destroy` - Delete issue (only if archived)
- `update_description` - Update markdown description
- `pick_grouping` - Assign issue to Kanban column
- `archive` - Archive issue
- `unarchive` - Restore issue
- `finish` - Mark as finished
- `unfinish` - Mark as not finished

**Nested Resources:**
```ruby
scope module: "issues" do
  resource :file, only: [:destroy] do
    post :attach, on: :collection
  end
  resources :comments, only: [:create, :edit, :update, :destroy]
end
```

---

#### TimeEntriesController
**File:** `app/controllers/time_entries_controller.rb`

**Routes:**
```ruby
resources :time_entries do
  get :form_projects_dependent_fields, on: :collection
  member do
    put :start
    put :stop
  end
end
```

**Actions:**
- `index` - List time entries with filtering
- `new` - New time entry form
- `create` - Create time entry
- `edit` - Edit time entry form
- `update` - Update time entry
- `destroy` - Delete time entry
- `start` - Start timer
- `stop` - Stop timer
- `form_projects_dependent_fields` - AJAX endpoint for dependent dropdowns

---

#### VisualizationsController
**File:** `app/controllers/visualizations_controller.rb`

**Routes:**
```ruby
get "v/:id/i/:issue_id",
  as: :show_visualization_issue,
  controller: :visualizations,
  action: :show

resources :visualizations, path: "v", only: [:show, :update]
```

**Actions:**
- `show` - Display Kanban board (with optional issue detail)
- `update` - Update visualization settings (favorite labels)

**Nested Controllers:**
```ruby
scope module: :visualizations do
  resources :groupings, only: [:new, :create, :edit, :update, :destroy] do
    member do
      get :move_all_issues
      post :move_all_issues_to
      post :archive_all_issues
    end
    collection do
      post :move
    end
  end

  resources :issues, path: "i", only: [:create, :update, :destroy]

  resources :allocations, only: [] do
    post :move, on: :collection
  end
end
```

---

#### Visualizations::GroupingsController
**File:** `app/controllers/visualizations/groupings_controller.rb`

**Actions:**
- `new` - New grouping form
- `create` - Create grouping (column)
- `edit` - Edit grouping form
- `update` - Update grouping
- `destroy` - Delete grouping
- `move` - Reorder groupings (drag-and-drop)
- `move_all_issues` - Display confirmation for moving all issues
- `move_all_issues_to` - Move all issues to another grouping
- `archive_all_issues` - Archive all issues in grouping

---

#### Visualizations::AllocationsController
**File:** `app/controllers/visualizations/allocations_controller.rb`

**Actions:**
- `move` - Move issue between groupings or reposition within grouping

**Logic:**
```ruby
def move
  # Update grouping_issue_allocation
  # Recalculate positions
  # Broadcast via Turbo Stream
end
```

---

#### ReportsController
**File:** `app/controllers/reports_controller.rb`

**Routes:**
```ruby
resource :reports, only: [] do
  get :total_time
end
```

**Actions:**
- `total_time` - Time report with filtering and CSV export

**CSV Export:**
```ruby
respond_to do |format|
  format.html
  format.csv do
    send_data generate_csv,
      filename: "time-report-#{Date.today}.csv"
  end
end
```

---

#### ProfilesController
**File:** `app/controllers/profiles_controller.rb`

**Routes:**
```ruby
resource :profile, only: [:edit, :update] do
  patch :update_preferences
end
```

**Actions:**
- `edit` - User settings form
- `update` - Update user settings
- `update_preferences` - Update user preferences (time format, theme)

---

### Response Formats

**Turbo Stream Responses:**
```ruby
# Example from IssuesController
def archive
  @issue.archive!
  respond_to do |format|
    format.turbo_stream
  end
end
```

**Turbo Stream Template:**
```erb
<%# app/views/issues/archive.turbo_stream.erb %>
<%= turbo_stream.replace dom_id(@issue) do %>
  <%= render @issue %>
<% end %>

<%= turbo_stream.update "flash" do %>
  <%= render "shared/flash", message: "Issue archived" %>
<% end %>
```

---

## Service Layer

### Business Logic Services

#### ExampleProjectCreator
**File:** `app/services/example_project_creator.rb`

**Purpose:** Create demo project with sample data

**Usage:**
```ruby
ExampleProjectCreator.new(user).create
```

**Creates:**
- Sample project
- Sample issues
- Sample labels
- Sample groupings (Kanban columns)

---

#### Project::Templatable::TemplateApplier
**File:** `app/services/project/templatable/template_applier.rb`

**Purpose:** Apply project templates on creation

**Usage:**
```ruby
template = Project::Templatable::Template.find("basic_kanban")
Project::Templatable::TemplateApplier.new(project, template).apply
```

**Template System:**
- Templates defined in `config/project_templates/`
- YAML configuration files
- Creates groupings, labels, sample issues

**Template Structure:**
```yaml
# config/project_templates/basic_kanban.yml
groupings:
  - title: "To Do"
  - title: "In Progress"
  - title: "Done"

labels:
  - title: "Bug"
    hex_color: "#FF0000"
  - title: "Feature"
    hex_color: "#00FF00"
```

---

#### Project::Templatable::Template
**File:** `app/services/project/templatable/template.rb`

**Available Templates:**
```ruby
AVAILABLE_TEMPLATES = [
  "basic_kanban",
  "bug_tracking",
  "software_development",
  "customer_support",
  "crm"
]
```

**Methods:**
- `Template.find(name)` - Load template by name
- `Template.all` - List all templates
- Template validation logic

---

## Background Jobs

### Solid Queue Jobs

**Queue Configuration:**
- Database-backed (no Redis required)
- Multiple queues: `default`, `low_priority`
- Async execution

### Job Classes

#### NewVersionCheckJob
**Purpose:** Check for application updates

**Schedule:** Periodic (cron-style)

**Logic:**
```ruby
def perform
  # Fetch latest version from eigenfocus.com API
  # Compare with current version
  # Update app_metadata table
  # Create notification if new version available
end
```

---

#### EigenfocusNotificationsFetcherJob
**Purpose:** Fetch announcements from Eigenfocus team

**Schedule:** Periodic

**Logic:**
```ruby
def perform
  # API call to eigenfocus.com
  # Fetch notifications for this instance
  # Create notification records
  # Mark as published
end
```

---

#### SubmitSurveyResponseJob
**Purpose:** Submit onboarding survey anonymously

**Trigger:** After user completes onboarding survey

**Logic:**
```ruby
def perform(survey_response, survey_token)
  # POST to eigenfocus.com analytics API
  # Submit anonymous survey data
  # Log success/failure
end
```

---

## API Endpoints

### RESTful API Structure

**Note:** Eigenfocus FREE does not expose a public REST API. All endpoints are HTML/Turbo Stream responses for the web UI.

### Endpoint Summary

#### Projects
```
GET    /projects                 # List projects
GET    /projects/new             # New project form
POST   /projects                 # Create project
GET    /projects/:id/edit        # Edit project form
PATCH  /projects/:id             # Update project
DELETE /projects/:id             # Delete project
PUT    /projects/:id/archive     # Archive project
PUT    /projects/:id/unarchive   # Unarchive project
```

#### Issues (via Projects)
```
GET    /p/:project_id/issues                # List issues
GET    /p/:project_id/issues/new            # New issue form
POST   /p/:project_id/issues                # Create issue
PATCH  /p/:project_id/issues/:id            # Update issue
DELETE /p/:project_id/issues/:id            # Delete issue
POST   /p/:project_id/issues/:id/add_label  # Add label
DELETE /p/:project_id/issues/:id/remove_label # Remove label
```

#### Issues (Global)
```
DELETE /issues/:id                     # Delete issue
PATCH  /issues/:id/update_description  # Update description
PATCH  /issues/:id/pick_grouping       # Assign to column
PUT    /issues/:id/archive             # Archive
PUT    /issues/:id/unarchive           # Unarchive
PUT    /issues/:id/finish              # Mark finished
PUT    /issues/:id/unfinish            # Mark not finished
```

#### Issue Files
```
POST   /issues/:issue_id/file/attach  # Attach file
DELETE /issues/:issue_id/file         # Delete file
```

#### Issue Comments
```
POST   /issues/:issue_id/comments         # Create comment
GET    /issues/:issue_id/comments/:id/edit # Edit form
PATCH  /issues/:issue_id/comments/:id     # Update comment
DELETE /issues/:issue_id/comments/:id     # Delete comment
```

#### Visualizations (Kanban Boards)
```
GET    /v/:id                      # Show board
GET    /v/:id/i/:issue_id          # Show board with issue detail
PATCH  /v/:id                      # Update settings
```

#### Groupings (Kanban Columns)
```
GET    /v/:visualization_id/groupings/new           # New column form
POST   /v/:visualization_id/groupings               # Create column
GET    /v/:visualization_id/groupings/:id/edit     # Edit column form
PATCH  /v/:visualization_id/groupings/:id          # Update column
DELETE /v/:visualization_id/groupings/:id          # Delete column
POST   /v/:visualization_id/groupings/move         # Reorder columns
GET    /v/:visualization_id/groupings/:id/move_all_issues    # Confirm move all
POST   /v/:visualization_id/groupings/:id/move_all_issues_to # Execute move all
POST   /v/:visualization_id/groupings/:id/archive_all_issues # Archive all
```

#### Allocations (Issue Positioning)
```
POST   /v/:visualization_id/allocations/move  # Move issue
```

#### Time Entries
```
GET    /time_entries                              # List entries
GET    /time_entries/new                          # New entry form
POST   /time_entries                              # Create entry
GET    /time_entries/:id/edit                     # Edit entry form
PATCH  /time_entries/:id                          # Update entry
DELETE /time_entries/:id                          # Delete entry
PUT    /time_entries/:id/start                    # Start timer
PUT    /time_entries/:id/stop                     # Stop timer
GET    /time_entries/form_projects_dependent_fields # AJAX dependent fields
```

#### Reports
```
GET    /reports/total_time        # Time report (HTML)
GET    /reports/total_time.csv    # Time report (CSV)
```

#### Profile
```
GET    /profile/edit              # Settings form
PATCH  /profile                   # Update settings
PATCH  /profile/update_preferences # Update preferences
```

#### Notifications
```
POST   /notifications/:id/mark_as_read  # Mark notification read
POST   /notifications/mark_all_as_read  # Mark all read
```

#### Issue Labels
```
GET    /p/:project_id/issue_labels                # List labels
GET    /p/:project_id/issue_labels/new            # New label form
POST   /p/:project_id/issue_labels                # Create label
GET    /p/:project_id/issue_labels/:id/edit       # Edit label form
PATCH  /p/:project_id/issue_labels/:id            # Update label
DELETE /p/:project_id/issue_labels/:id            # Delete label
GET    /p/:project_id/issue_labels/:id/destroy_confirmation # Confirm delete
```

---

## Real-time System

### ActionCable Channels

#### Visualizations::AllocationsChannel
**File:** `app/channels/visualizations/allocations_channel.rb`

**Purpose:** Real-time issue movement on Kanban boards

**Subscription:**
```ruby
# Client subscribes
consumer.subscriptions.create(
  { channel: "Visualizations::AllocationsChannel", visualization_id: 123 }
)

# Server streams
stream_for @visualization
```

**Broadcasts:**
- Issue moved between groupings
- Issue position changed
- Issue created/deleted

---

#### Visualizations::GroupingsChannel
**File:** `app/channels/visualizations/groupings_channel.rb`

**Purpose:** Real-time grouping (column) updates

**Subscription:**
```ruby
stream_for @visualization
```

**Broadcasts:**
- Grouping created/deleted
- Grouping renamed
- Grouping hidden/shown
- Grouping reordered

---

### Turbo Stream Broadcasts

**Automatic Broadcasts:**
```ruby
# Issue model
after_update_commit -> {
  broadcast_replace_later_to(
    project.default_visualization,
    partial: "visualizations/card",
    locals: { issue: self, visualization: project.default_visualization }
  )
}

# TimeEntry model
broadcasts_to ->(time_entry) { "time_entries" },
  inserts_by: :prepend,
  target: "time-entries-tbody"
```

**Manual Broadcasts:**
```ruby
# From controller
@issue.broadcast_replace_to(
  @project.default_visualization,
  target: dom_id(@issue)
)
```

---

## File Storage

### ActiveStorage Configuration

**Storage Service:** Local disk

**Configuration:**
```yaml
# config/storage.yml
local:
  service: Disk
  root: <%= Rails.root.join("storage") %>
```

**Upload Location:**
```
storage/
  ├── [blob_key_prefix]/[blob_key]  # Actual files
  └── ...
```

**Database Storage:**
- Metadata in `active_storage_blobs`
- Attachments in `active_storage_attachments`
- Variants in `active_storage_variant_records`

**File Processing:**
- Direct uploads (no background processing)
- No image resizing (raw storage)
- Virus scanning: Not implemented

---

## Security & Authentication

### Authentication (FREE Edition)

**No Authentication System:**
- Single-user assumption
- Auto-login on first visit
- User record auto-created

**Session Management:**
```ruby
# ApplicationController
def current_user
  @current_user ||= User.first_or_create
end
```

---

### Authorization

**No Authorization System:**
- All actions allowed for single user
- No permission checks
- No role-based access control

---

### Security Features

**CSRF Protection:**
- Rails default CSRF tokens
- All forms include `authenticity_token`

**SQL Injection Prevention:**
- ActiveRecord parameterized queries
- No raw SQL execution

**XSS Prevention:**
- ERB auto-escaping
- `html_safe` used sparingly
- Sanitized markdown rendering

**File Upload Security:**
- ActiveStorage validation
- Content-type checking
- File size limits (configurable)

**HTTP Security Headers:**
```ruby
# config/application.rb
config.action_dispatch.default_headers = {
  'X-Frame-Options' => 'SAMEORIGIN',
  'X-XSS-Protection' => '1; mode=block',
  'X-Content-Type-Options' => 'nosniff'
}
```

**Optional HTTP Basic Auth:**
```ruby
# Configured via environment variables
before_action :http_authenticate if ENV['HTTP_AUTH_USER'].present?

def http_authenticate
  authenticate_or_request_with_http_basic do |user, password|
    user == ENV['HTTP_AUTH_USER'] && password == ENV['HTTP_AUTH_PASSWORD']
  end
end
```

---

## Conclusion

The Eigenfocus backend demonstrates:

1. **Modern Rails Architecture:** Leverages Rails 8 features (Solid Queue, Solid Cable)
2. **Clean Separation:** Controllers, models, services, jobs well-organized
3. **Real-time Capabilities:** Turbo Streams + ActionCable for live updates
4. **Safety Mechanisms:** Archive-before-delete, validations, transactions
5. **Performance:** Proper indexing, scopes, eager loading
6. **Maintainability:** Conventional Rails patterns, readable code

The backend is production-ready and demonstrates contemporary Rails best practices throughout.
