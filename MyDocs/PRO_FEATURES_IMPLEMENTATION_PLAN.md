# PRO Features Implementation Plan
## Custom Fork Development Roadmap

**Created:** December 31, 2025
**Version:** 1.0
**Target:** Eigenfocus Custom Fork with PRO Features
**Selected Features:**
- ✅ Views as Projections (Dynamic Grouping)
- ✅ Grid View (Spreadsheet-style)
- ✅ Custom Issue Statuses & Types
- ✅ Multi-user Authentication (Email/Password)
- ✅ Full Permission System

---

## 🎯 Implementation Strategy

### Dependency Order

PRO features have dependencies that dictate implementation order:

```
1. Multi-user Authentication (Foundation)
   ↓
2. Permission System (Authorization)
   ↓
3. Custom Issue Statuses & Types (Data Model)
   ↓
4. Views as Projections (Visualization)
   ↓
5. Grid View (Advanced UI)
```

**Rationale:** Authentication must come first since all other features assume multiple users. Permissions are needed before users can interact. Status/Types enhance the data model that projections and grid view will use.

---

## Phase 1: Multi-user Authentication System
**Duration:** 1-2 weeks
**Complexity:** High (Breaking Changes to Existing Code)
**Priority:** Critical (Foundation)

### Overview

Transform the single-user FREE edition into a multi-user system with proper authentication.

### Goals

1. Add user authentication with email/password
2. Update existing models to track user ownership
3. Add user registration and login flows
4. Migrate existing single-user data to multi-user structure
5. Maintain backward compatibility during migration

---

### Step 1.1: Install and Configure Devise
**Duration:** 1 day

#### Install Devise Gem

```ruby
# Gemfile
gem 'devise', '~> 4.9'
```

```bash
bundle install
rails generate devise:install
rails generate devise User
```

#### Configure Devise

```ruby
# config/initializers/devise.rb
Devise.setup do |config|
  config.mailer_sender = ENV.fetch('MAILER_SENDER', 'noreply@eigenfocus.local')
  config.authentication_keys = [:email]
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 12
  config.reconfirmable = false # Disable email reconfirmation for simplicity
  config.expire_all_remember_me_on_sign_out = true
  config.password_length = 8..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.timeout_in = 30.minutes
  config.sign_out_via = :delete
end
```

---

### Step 1.2: Enhance User Model
**Duration:** 1 day

#### Migration: Add Devise Fields

```ruby
# db/migrate/XXXXXX_add_devise_to_users.rb
class AddDeviseToUsers < ActiveRecord::Migration[8.1]
  def change
    # Devise Database Authenticatable
    add_column :users, :email, :string, null: false, default: ""
    add_column :users, :encrypted_password, :string, null: false, default: ""

    # Devise Recoverable
    add_column :users, :reset_password_token, :string
    add_column :users, :reset_password_sent_at, :datetime

    # Devise Rememberable
    add_column :users, :remember_created_at, :datetime

    # Devise Trackable (optional but useful)
    add_column :users, :sign_in_count, :integer, default: 0, null: false
    add_column :users, :current_sign_in_at, :datetime
    add_column :users, :last_sign_in_at, :datetime
    add_column :users, :current_sign_in_ip, :string
    add_column :users, :last_sign_in_ip, :string

    # Additional fields
    add_column :users, :name, :string
    add_column :users, :avatar_url, :string
    add_column :users, :role, :string, default: 'member', null: false

    # Indexes
    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
  end
end
```

#### Data Migration: Migrate Existing User

```ruby
# db/migrate/XXXXXX_migrate_existing_user_data.rb
class MigrateExistingUserData < ActiveRecord::Migration[8.1]
  def up
    # Get the existing single user
    user = User.first

    if user && user.email.blank?
      # Prompt to set email via environment variable or use default
      email = ENV.fetch('ADMIN_EMAIL', 'admin@eigenfocus.local')
      password = ENV.fetch('ADMIN_PASSWORD', SecureRandom.hex(16))

      user.update!(
        email: email,
        password: password,
        password_confirmation: password,
        name: 'Admin User',
        role: 'admin'
      )

      # Log credentials to console for first-time setup
      puts "=" * 80
      puts "ADMIN USER CREATED:"
      puts "Email: #{email}"
      puts "Password: #{password}"
      puts "IMPORTANT: Change this password after first login!"
      puts "=" * 80
    end
  end

  def down
    # No rollback needed
  end
end
```

#### Update User Model

```ruby
# app/models/user.rb
class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  # Enums
  enum role: {
    member: 'member',
    admin: 'admin'
  }

  # Associations (existing + new)
  has_many :time_entries, dependent: :destroy
  has_one :preferences, class_name: 'UserPreference', dependent: :destroy

  # NEW: Multi-user associations
  has_many :project_memberships, dependent: :destroy
  has_many :projects, through: :project_memberships
  has_many :owned_projects, class_name: 'Project', foreign_key: :owner_id
  has_many :created_issues, class_name: 'Issue', foreign_key: :creator_id
  has_many :assigned_issues, class_name: 'Issue', foreign_key: :assigned_user_id
  has_many :comments, class_name: 'Issue::Comment', foreign_key: :author_id

  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :role, presence: true

  # Callbacks
  after_create :create_default_preferences

  # Instance methods
  def admin?
    role == 'admin'
  end

  def display_name
    name.presence || email.split('@').first
  end

  def initials
    name.split.map(&:first).join.upcase[0..1] if name.present?
  end

  private

  def create_default_preferences
    create_preferences! unless preferences
  end
end
```

---

### Step 1.3: Add Project Ownership & Memberships
**Duration:** 1 day

#### Migration: Add Owner and Memberships

```ruby
# db/migrate/XXXXXX_add_project_ownership.rb
class AddProjectOwnership < ActiveRecord::Migration[8.1]
  def change
    # Add owner to projects
    add_reference :projects, :owner, foreign_key: { to_table: :users }

    # Create project memberships table
    create_table :project_memberships do |t|
      t.references :project, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false, default: 'viewer'
      # Roles: owner, editor, viewer

      t.timestamps
    end

    # Unique constraint: one membership per user per project
    add_index :project_memberships, [:project_id, :user_id], unique: true
  end
end

# db/migrate/XXXXXX_migrate_existing_projects.rb
class MigrateExistingProjects < ActiveRecord::Migration[8.1]
  def up
    # Set existing user as owner of all projects
    user = User.first

    if user
      Project.update_all(owner_id: user.id)

      # Create memberships for owner
      Project.find_each do |project|
        ProjectMembership.create!(
          project: project,
          user: user,
          role: 'owner'
        )
      end
    end
  end

  def down
    ProjectMembership.delete_all
    Project.update_all(owner_id: nil)
  end
end
```

#### Create ProjectMembership Model

```ruby
# app/models/project_membership.rb
class ProjectMembership < ApplicationRecord
  belongs_to :project
  belongs_to :user

  # Roles
  enum role: {
    owner: 'owner',     # Full control
    editor: 'editor',   # Can edit, cannot manage members
    viewer: 'viewer'    # Read-only
  }

  # Validations
  validates :user_id, uniqueness: { scope: :project_id }
  validates :role, presence: true

  # Scopes
  scope :owners, -> { where(role: 'owner') }
  scope :editors, -> { where(role: 'editor') }
  scope :viewers, -> { where(role: 'viewer') }

  # Instance methods
  def can_edit?
    owner? || editor?
  end

  def can_manage_members?
    owner?
  end
end
```

#### Update Project Model

```ruby
# app/models/project.rb
class Project < ApplicationRecord
  # Associations
  belongs_to :owner, class_name: 'User', optional: true # optional during migration
  has_many :project_memberships, dependent: :destroy
  has_many :members, through: :project_memberships, source: :user

  # ... existing associations ...

  # Callbacks
  after_create :create_owner_membership, if: :owner_id?

  # Scopes
  scope :accessible_by, ->(user) {
    joins(:project_memberships)
      .where(project_memberships: { user_id: user.id })
  }

  # Instance methods
  def user_membership(user)
    project_memberships.find_by(user: user)
  end

  def user_role(user)
    user_membership(user)&.role
  end

  def accessible_by?(user)
    return true if owner_id == user.id
    members.include?(user)
  end

  def editable_by?(user)
    return true if owner_id == user.id
    user_membership(user)&.can_edit?
  end

  private

  def create_owner_membership
    project_memberships.create!(
      user: owner,
      role: 'owner'
    ) unless project_memberships.exists?(user: owner)
  end
end
```

---

### Step 1.4: Add Issue Assignment & Ownership
**Duration:** 1 day

#### Migration: Add Creator and Assignee

```ruby
# db/migrate/XXXXXX_add_issue_user_tracking.rb
class AddIssueUserTracking < ActiveRecord::Migration[8.1]
  def change
    add_reference :issues, :creator, foreign_key: { to_table: :users }
    add_reference :issues, :assigned_user, foreign_key: { to_table: :users }

    add_index :issues, :creator_id
    add_index :issues, :assigned_user_id
  end
end

# db/migrate/XXXXXX_migrate_existing_issues.rb
class MigrateExistingIssues < ActiveRecord::Migration[8.1]
  def up
    user = User.first

    if user
      # Set existing user as creator for all issues
      Issue.update_all(creator_id: user.id)
    end
  end

  def down
    Issue.update_all(creator_id: nil, assigned_user_id: nil)
  end
end
```

#### Update Issue Model

```ruby
# app/models/issue.rb
class Issue < ApplicationRecord
  # Associations
  belongs_to :project
  belongs_to :creator, class_name: 'User', optional: true
  belongs_to :assigned_user, class_name: 'User', optional: true

  # ... existing associations ...

  # Scopes
  scope :assigned_to, ->(user) { where(assigned_user: user) }
  scope :created_by, ->(user) { where(creator: user) }
  scope :unassigned, -> { where(assigned_user_id: nil) }

  # Validations
  validates :title, presence: true
  validates :creator, presence: true, on: :create

  # Ransack
  def self.ransackable_attributes(auth_object = nil)
    super + ["assigned_user_id", "creator_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    super + ["assigned_user", "creator"]
  end

  # Instance methods
  def assigned?
    assigned_user.present?
  end

  def assign_to(user)
    update(assigned_user: user)
  end

  def unassign
    update(assigned_user: nil)
  end
end
```

---

### Step 1.5: Update Application Controller
**Duration:** 0.5 day

#### Add Authentication Requirements

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  # IMPORTANT: Replace the old current_user method
  before_action :authenticate_user!
  before_action :set_locale
  before_action :set_timezone

  # Helper methods
  helper_method :current_user # Provided by Devise

  # Remove old current_user method:
  # def current_user
  #   @current_user ||= User.first_or_create
  # end

  # Keep existing locale/timezone methods

  private

  def set_locale
    if user_signed_in?
      I18n.locale = current_user.locale || I18n.default_locale
    else
      I18n.locale = I18n.default_locale
    end
  end

  def set_timezone
    if user_signed_in? && current_user.timezone.present?
      Time.zone = current_user.timezone
    end
  end

  # Optional: Skip authentication for public pages
  # def skip_authentication
  #   skip_before_action :authenticate_user!
  # end
end
```

---

### Step 1.6: Create Authentication Views
**Duration:** 1 day

#### Generate Devise Views

```bash
rails generate devise:views
```

#### Customize Login Page

```erb
<%# app/views/devise/sessions/new.html.erb %>
<div class="min-h-screen flex items-center justify-center bg-base-200">
  <div class="card w-96 bg-base-100 shadow-xl">
    <div class="card-body">
      <h2 class="card-title text-center text-2xl mb-4">
        <%= image_tag "logo.png", alt: "Eigenfocus", class: "h-8 mx-auto mb-2" %>
        Sign in to Eigenfocus
      </h2>

      <%= form_for(resource, as: resource_name, url: session_path(resource_name), html: { class: "space-y-4" }) do |f| %>
        <div class="form-control">
          <%= f.label :email, class: "label" %>
          <%= f.email_field :email, autofocus: true, autocomplete: "email", class: "input input-bordered w-full" %>
        </div>

        <div class="form-control">
          <%= f.label :password, class: "label" %>
          <%= f.password_field :password, autocomplete: "current-password", class: "input input-bordered w-full" %>
        </div>

        <% if devise_mapping.rememberable? %>
          <div class="form-control">
            <label class="label cursor-pointer justify-start">
              <%= f.check_box :remember_me, class: "checkbox checkbox-primary" %>
              <span class="label-text ml-2">Remember me</span>
            </label>
          </div>
        <% end %>

        <div class="form-control mt-6">
          <%= f.submit "Sign in", class: "btn btn-primary w-full" %>
        </div>
      <% end %>

      <div class="divider">OR</div>

      <div class="text-center space-y-2">
        <%= link_to "Sign up", new_registration_path(resource_name), class: "link link-primary" %>
        <br>
        <%= link_to "Forgot password?", new_password_path(resource_name), class: "link link-secondary" %>
      </div>
    </div>
  </div>
</div>
```

#### Customize Registration Page

```erb
<%# app/views/devise/registrations/new.html.erb %>
<div class="min-h-screen flex items-center justify-center bg-base-200">
  <div class="card w-96 bg-base-100 shadow-xl">
    <div class="card-body">
      <h2 class="card-title text-center text-2xl mb-4">Create Account</h2>

      <%= form_for(resource, as: resource_name, url: registration_path(resource_name), html: { class: "space-y-4" }) do |f| %>
        <%= render "devise/shared/error_messages", resource: resource %>

        <div class="form-control">
          <%= f.label :name, class: "label" %>
          <%= f.text_field :name, autofocus: true, class: "input input-bordered w-full", placeholder: "Your Name" %>
        </div>

        <div class="form-control">
          <%= f.label :email, class: "label" %>
          <%= f.email_field :email, autocomplete: "email", class: "input input-bordered w-full" %>
        </div>

        <div class="form-control">
          <%= f.label :password, class: "label" %>
          <%= f.password_field :password, autocomplete: "new-password", class: "input input-bordered w-full" %>
          <% if @minimum_password_length %>
            <label class="label">
              <span class="label-text-alt">Minimum <%= @minimum_password_length %> characters</span>
            </label>
          <% end %>
        </div>

        <div class="form-control">
          <%= f.label :password_confirmation, class: "label" %>
          <%= f.password_field :password_confirmation, autocomplete: "new-password", class: "input input-bordered w-full" %>
        </div>

        <div class="form-control mt-6">
          <%= f.submit "Sign up", class: "btn btn-primary w-full" %>
        </div>
      <% end %>

      <div class="divider">OR</div>

      <div class="text-center">
        <%= link_to "Sign in", new_session_path(resource_name), class: "link link-primary" %>
      </div>
    </div>
  </div>
</div>
```

---

### Step 1.7: Update Routes
**Duration:** 0.5 day

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Devise routes
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions'
  }

  # Authenticated routes only
  authenticate :user do
    root to: 'dashboard#show'

    # ... existing routes ...

    # User management routes
    namespace :settings do
      resource :profile, only: [:edit, :update]
      resources :team_members, only: [:index, :create, :destroy]
    end
  end

  # Public landing page (optional)
  # root to: 'pages#home'
end
```

---

### Step 1.8: Update Navigation & Layout
**Duration:** 1 day

#### Add User Menu to Header

```erb
<%# app/views/layouts/_header.html.erb %>
<header class="navbar bg-base-100 shadow-lg">
  <div class="flex-1">
    <%= link_to root_path, class: "btn btn-ghost normal-case text-xl" do %>
      Eigenfocus
    <% end %>
  </div>

  <div class="flex-none gap-2">
    <%# Running time entries indicator - existing %>
    <%= render 'shared/running_time_entries' %>

    <%# Theme switcher - existing %>
    <%= render 'shared/theme_switcher' %>

    <%# NEW: User menu %>
    <div class="dropdown dropdown-end">
      <label tabindex="0" class="btn btn-ghost btn-circle avatar placeholder">
        <div class="bg-neutral-focus text-neutral-content rounded-full w-10">
          <span class="text-xl"><%= current_user.initials || "?" %></span>
        </div>
      </label>
      <ul tabindex="0" class="menu menu-compact dropdown-content mt-3 p-2 shadow bg-base-100 rounded-box w-52">
        <li class="menu-title">
          <span><%= current_user.display_name %></span>
          <span class="text-xs opacity-50"><%= current_user.email %></span>
        </li>
        <li><%= link_to "Profile Settings", edit_settings_profile_path %></li>
        <li><%= link_to "Sign Out", destroy_user_session_path, method: :delete, class: "text-error" %></li>
      </ul>
    </div>
  </div>
</header>
```

---

### Step 1.9: Testing
**Duration:** 1 day

#### RSpec Tests

```ruby
# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:email).case_insensitive }
  end

  describe 'associations' do
    it { should have_many(:project_memberships).dependent(:destroy) }
    it { should have_many(:projects).through(:project_memberships) }
    it { should have_many(:owned_projects).class_name('Project') }
    it { should have_many(:created_issues).class_name('Issue') }
  end

  describe '#admin?' do
    it 'returns true for admin users' do
      user = create(:user, role: 'admin')
      expect(user.admin?).to be true
    end

    it 'returns false for member users' do
      user = create(:user, role: 'member')
      expect(user.admin?).to be false
    end
  end
end

# spec/models/project_membership_spec.rb
require 'rails_helper'

RSpec.describe ProjectMembership, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:role) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:project_id) }
  end

  describe 'associations' do
    it { should belong_to(:project) }
    it { should belong_to(:user) }
  end

  describe '#can_edit?' do
    it 'returns true for owners' do
      membership = create(:project_membership, role: 'owner')
      expect(membership.can_edit?).to be true
    end

    it 'returns true for editors' do
      membership = create(:project_membership, role: 'editor')
      expect(membership.can_edit?).to be true
    end

    it 'returns false for viewers' do
      membership = create(:project_membership, role: 'viewer')
      expect(membership.can_edit?).to be false
    end
  end
end
```

#### Factory Bot Factories

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:name) { |n| "User #{n}" }
    password { "password123" }
    password_confirmation { "password123" }
    role { "member" }

    trait :admin do
      role { "admin" }
    end
  end
end

# spec/factories/project_memberships.rb
FactoryBot.define do
  factory :project_membership do
    project
    user
    role { "viewer" }

    trait :owner do
      role { "owner" }
    end

    trait :editor do
      role { "editor" }
    end
  end
end
```

---

## Phase 2: Authorization & Permission System
**Duration:** 1 week
**Complexity:** High
**Priority:** Critical

### Overview

Implement role-based access control using Pundit gem for clean, policy-based authorization.

---

### Step 2.1: Install Pundit
**Duration:** 0.5 day

```ruby
# Gemfile
gem 'pundit', '~> 2.3'
```

```bash
bundle install
rails generate pundit:install
```

#### Configure ApplicationController

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Pundit::Authorization

  before_action :authenticate_user!

  # Pundit error handling
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end
end
```

---

### Step 2.2: Create Policies
**Duration:** 2 days

#### ApplicationPolicy (Base)

```ruby
# app/policies/application_policy.rb
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end
end
```

#### ProjectPolicy

```ruby
# app/policies/project_policy.rb
class ProjectPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      # Users can see projects they're members of
      scope.accessible_by(user)
    end
  end

  def index?
    true # All logged-in users can see project list
  end

  def show?
    user_can_access?
  end

  def create?
    true # All users can create projects
  end

  def update?
    user_can_edit?
  end

  def destroy?
    user_is_owner?
  end

  def archive?
    user_can_edit?
  end

  def unarchive?
    user_can_edit?
  end

  def manage_members?
    user_is_owner?
  end

  private

  def user_can_access?
    record.accessible_by?(user)
  end

  def user_can_edit?
    record.editable_by?(user)
  end

  def user_is_owner?
    record.owner_id == user.id
  end
end
```

#### IssuePolicy

```ruby
# app/policies/issue_policy.rb
class IssuePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      # Users see issues in projects they can access
      scope.joins(:project)
        .merge(Project.accessible_by(user))
    end
  end

  def show?
    project_accessible?
  end

  def create?
    project_editable?
  end

  def update?
    project_editable?
  end

  def destroy?
    project_editable?
  end

  def archive?
    project_editable?
  end

  def finish?
    project_editable?
  end

  def assign?
    project_editable?
  end

  private

  def project_accessible?
    record.project.accessible_by?(user)
  end

  def project_editable?
    record.project.editable_by?(user)
  end
end
```

#### TimeEntryPolicy

```ruby
# app/policies/time_entry_policy.rb
class TimeEntryPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      # Users see their own time entries
      # Plus time entries in projects they can access
      scope.where(user: user)
        .or(scope.joins(:project).merge(Project.accessible_by(user)))
    end
  end

  def show?
    own_entry? || project_accessible?
  end

  def create?
    true # Users can create their own time entries
  end

  def update?
    own_entry?
  end

  def destroy?
    own_entry?
  end

  def start?
    own_entry?
  end

  def stop?
    own_entry?
  end

  private

  def own_entry?
    record.user_id == user.id
  end

  def project_accessible?
    record.project&.accessible_by?(user)
  end
end
```

---

### Step 2.3: Update Controllers with Authorization
**Duration:** 2 days

#### ProjectsController

```ruby
# app/controllers/projects_controller.rb
class ProjectsController < ApplicationController
  before_action :set_project, only: [:show, :edit, :update, :destroy, :archive, :unarchive]

  def index
    @projects = policy_scope(Project).active.order(created_at: :desc)
  end

  def show
    authorize @project
    redirect_to @project.default_visualization
  end

  def new
    @project = Project.new
    authorize @project
  end

  def create
    @project = Project.new(project_params)
    @project.owner = current_user
    authorize @project

    if @project.save
      redirect_to @project, notice: 'Project created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @project
  end

  def update
    authorize @project

    if @project.update(project_params)
      redirect_to @project, notice: 'Project updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @project
    @project.destroy
    redirect_to projects_path, notice: 'Project deleted.'
  end

  def archive
    authorize @project
    @project.archive!
    redirect_to projects_path, notice: 'Project archived.'
  end

  def unarchive
    authorize @project
    @project.unarchive!
    redirect_to @project, notice: 'Project restored.'
  end

  private

  def set_project
    @project = Project.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :time_tracking_enabled, :use_template)
  end
end
```

#### IssuesController (Similar Pattern)

```ruby
# app/controllers/issues_controller.rb
class IssuesController < ApplicationController
  before_action :set_issue
  before_action :authorize_issue

  # ... actions ...

  private

  def authorize_issue
    authorize @issue
  end
end
```

---

### Step 2.4: Update Views with Authorization Checks
**Duration:** 1 day

#### Helper Methods

```ruby
# app/helpers/application_helper.rb
module ApplicationHelper
  def policy(record)
    Pundit.policy(current_user, record)
  end

  def can?(action, record)
    policy(record).public_send("#{action}?")
  rescue Pundit::NotDefinedError
    false
  end
end
```

#### Conditional Rendering in Views

```erb
<%# app/views/projects/show.html.erb %>
<div class="project-actions">
  <% if can?(:edit, @project) %>
    <%= link_to "Edit Project", edit_project_path(@project), class: "btn btn-primary" %>
  <% end %>

  <% if can?(:destroy, @project) %>
    <%= button_to "Delete Project", project_path(@project),
        method: :delete,
        class: "btn btn-error",
        data: { confirm: "Are you sure?" } %>
  <% end %>

  <% if can?(:manage_members, @project) %>
    <%= link_to "Manage Team", project_members_path(@project), class: "btn btn-secondary" %>
  <% end %>
</div>
```

---

### Step 2.5: Testing Policies
**Duration:** 1 day

```ruby
# spec/policies/project_policy_spec.rb
require 'rails_helper'

RSpec.describe ProjectPolicy do
  subject { described_class }

  let(:owner) { create(:user) }
  let(:editor) { create(:user) }
  let(:viewer) { create(:user) }
  let(:outsider) { create(:user) }
  let(:project) { create(:project, owner: owner) }

  before do
    create(:project_membership, project: project, user: editor, role: 'editor')
    create(:project_membership, project: project, user: viewer, role: 'viewer')
  end

  permissions :show? do
    it "grants access to owner" do
      expect(subject).to permit(owner, project)
    end

    it "grants access to editor" do
      expect(subject).to permit(editor, project)
    end

    it "grants access to viewer" do
      expect(subject).to permit(viewer, project)
    end

    it "denies access to outsider" do
      expect(subject).not_to permit(outsider, project)
    end
  end

  permissions :update? do
    it "grants access to owner" do
      expect(subject).to permit(owner, project)
    end

    it "grants access to editor" do
      expect(subject).to permit(editor, project)
    end

    it "denies access to viewer" do
      expect(subject).not_to permit(viewer, project)
    end
  end

  permissions :destroy? do
    it "grants access to owner only" do
      expect(subject).to permit(owner, project)
      expect(subject).not_to permit(editor, project)
      expect(subject).not_to permit(viewer, project)
    end
  end
end
```

---

## Phase 3: Custom Issue Statuses & Types
**Duration:** 1 week
**Complexity:** Medium
**Priority:** High

### Overview

Add customizable issue statuses and types to replace the simple archive/finish states.

---

### Step 3.1: Database Schema
**Duration:** 1 day

```ruby
# db/migrate/XXXXXX_create_issue_statuses.rb
class CreateIssueStatuses < ActiveRecord::Migration[8.1]
  def change
    create_table :issue_statuses do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.string :color, default: '#6B7280' # gray-500
      t.string :icon # optional tabler icon name
      t.integer :position, null: false
      t.boolean :is_default, default: false
      t.boolean :is_closed_status, default: false # Marks issues as "done"

      t.timestamps
    end

    add_index :issue_statuses, [:project_id, :position], unique: true
    add_index :issue_statuses, [:project_id, :is_default]
  end
end

# db/migrate/XXXXXX_create_issue_types.rb
class CreateIssueTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :issue_types do |t|
      t.references :project, null: true, foreign_key: true
      # null project_id = global/system type
      t.string :name, null: false
      t.string :color, default: '#6B7280'
      t.string :icon # tabler icon name
      t.integer :position, null: false
      t.boolean :is_default, default: false

      t.timestamps
    end

    add_index :issue_types, :position
  end
end

# db/migrate/XXXXXX_add_status_and_type_to_issues.rb
class AddStatusAndTypeToIssues < ActiveRecord::Migration[8.1]
  def change
    add_reference :issues, :issue_status, foreign_key: true
    add_reference :issues, :issue_type, foreign_key: true
  end
end
```

---

### Step 3.2: Create Models
**Duration:** 1 day

#### IssueStatus Model

```ruby
# app/models/issue_status.rb
class IssueStatus < ApplicationRecord
  belongs_to :project
  has_many :issues, dependent: :nullify

  # Ordering
  acts_as_list scope: :project

  # Validations
  validates :name, presence: true
  validates :color, presence: true, format: { with: /\A#[0-9A-F]{6}\z/i }
  validates :position, presence: true, uniqueness: { scope: :project_id }

  # Scopes
  scope :ordered, -> { order(position: :asc) }
  scope :defaults, -> { where(is_default: true) }
  scope :closed_statuses, -> { where(is_closed_status: true) }

  # Callbacks
  before_validation :set_default_position, on: :create
  after_create :set_as_default_if_first

  # Class methods
  def self.create_defaults_for_project(project)
    statuses = [
      { name: 'To Do', color: '#6B7280', icon: 'circle', position: 1, is_default: true },
      { name: 'In Progress', color: '#3B82F6', icon: 'progress', position: 2 },
      { name: 'Done', color: '#10B981', icon: 'circle-check', position: 3, is_closed_status: true }
    ]

    statuses.each do |attrs|
      project.issue_statuses.create!(attrs)
    end
  end

  private

  def set_default_position
    self.position ||= (project.issue_statuses.maximum(:position) || 0) + 1
  end

  def set_as_default_if_first
    if project.issue_statuses.count == 1
      update_column(:is_default, true)
    end
  end
end
```

#### IssueType Model

```ruby
# app/models/issue_type.rb
class IssueType < ApplicationRecord
  belongs_to :project, optional: true
  has_many :issues, dependent: :nullify

  # Ordering
  acts_as_list scope: :project_id

  # Validations
  validates :name, presence: true
  validates :color, presence: true, format: { with: /\A#[0-9A-F]{6}\z/i }

  # Scopes
  scope :ordered, -> { order(position: :asc) }
  scope :global, -> { where(project_id: nil) }
  scope :for_project, ->(project) { where(project: [project, nil]).ordered }

  # Class methods
  def self.create_global_defaults
    types = [
      { name: 'Task', color: '#6B7280', icon: 'checklist', position: 1, is_default: true },
      { name: 'Bug', color: '#EF4444', icon: 'bug', position: 2 },
      { name: 'Feature', color: '#8B5CF6', icon: 'sparkles', position: 3 },
      { name: 'Enhancement', color: '#3B82F6', icon: 'bulb', position: 4 }
    ]

    types.each do |attrs|
      IssueType.create!(attrs)
    end
  end

  def global?
    project_id.nil?
  end
end
```

---

### Step 3.3: Update Issue Model
**Duration:** 1 day

```ruby
# app/models/issue.rb
class Issue < ApplicationRecord
  # Associations
  belongs_to :project
  belongs_to :issue_status, optional: true
  belongs_to :issue_type, optional: true
  belongs_to :creator, class_name: 'User', optional: true
  belongs_to :assigned_user, class_name: 'User', optional: true

  # ... existing associations ...

  # Callbacks
  before_validation :set_default_status, on: :create
  before_validation :set_default_type, on: :create

  # Scopes
  scope :with_status, ->(status_id) { where(issue_status_id: status_id) }
  scope :with_type, ->(type_id) { where(issue_type_id: type_id) }
  scope :closed, -> { joins(:issue_status).where(issue_statuses: { is_closed_status: true }) }
  scope :open, -> { joins(:issue_status).where(issue_statuses: { is_closed_status: false }) }

  # Instance methods
  def closed?
    issue_status&.is_closed_status?
  end

  def open?
    !closed?
  end

  def status_name
    issue_status&.name || 'No Status'
  end

  def type_name
    issue_type&.name || 'No Type'
  end

  private

  def set_default_status
    return if issue_status.present?
    self.issue_status = project.issue_statuses.defaults.first || project.issue_statuses.first
  end

  def set_default_type
    return if issue_type.present?
    self.issue_type = IssueType.global.where(is_default: true).first || IssueType.global.first
  end
end
```

---

### Step 3.4: Update Project Model
**Duration:** 0.5 day

```ruby
# app/models/project.rb
class Project < ApplicationRecord
  # Associations
  has_many :issue_statuses, dependent: :destroy

  # ... existing associations ...

  # Callbacks
  after_create :create_default_statuses

  private

  def create_default_statuses
    IssueStatus.create_defaults_for_project(self)
  end
end
```

---

### Step 3.5: Create Controllers
**Duration:** 2 days

#### IssueStatusesController

```ruby
# app/controllers/issue_statuses_controller.rb
class IssueStatusesController < ApplicationController
  before_action :set_project
  before_action :set_issue_status, only: [:edit, :update, :destroy, :move]
  before_action :authorize_project

  def index
    @issue_statuses = @project.issue_statuses.ordered
  end

  def new
    @issue_status = @project.issue_statuses.build
  end

  def create
    @issue_status = @project.issue_statuses.build(issue_status_params)

    if @issue_status.save
      redirect_to project_issue_statuses_path(@project), notice: 'Status created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @issue_status.update(issue_status_params)
      redirect_to project_issue_statuses_path(@project), notice: 'Status updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @issue_status.issues.any?
      redirect_to project_issue_statuses_path(@project),
                  alert: 'Cannot delete status with issues. Reassign them first.'
    else
      @issue_status.destroy
      redirect_to project_issue_statuses_path(@project), notice: 'Status deleted.'
    end
  end

  def move
    @issue_status.insert_at(params[:position].to_i)
    head :ok
  end

  private

  def set_project
    @project = Project.find(params[:project_id])
  end

  def set_issue_status
    @issue_status = @project.issue_statuses.find(params[:id])
  end

  def authorize_project
    authorize @project, :update?
  end

  def issue_status_params
    params.require(:issue_status).permit(:name, :color, :icon, :is_default, :is_closed_status)
  end
end
```

#### IssueTypesController (Admin Only)

```ruby
# app/controllers/admin/issue_types_controller.rb
class Admin::IssueTypesController < ApplicationController
  before_action :require_admin
  before_action :set_issue_type, only: [:edit, :update, :destroy]

  def index
    @issue_types = IssueType.global.ordered
  end

  def new
    @issue_type = IssueType.new
  end

  def create
    @issue_type = IssueType.new(issue_type_params)

    if @issue_type.save
      redirect_to admin_issue_types_path, notice: 'Type created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @issue_type.update(issue_type_params)
      redirect_to admin_issue_types_path, notice: 'Type updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @issue_type.destroy
    redirect_to admin_issue_types_path, notice: 'Type deleted.'
  end

  private

  def set_issue_type
    @issue_type = IssueType.find(params[:id])
  end

  def require_admin
    redirect_to root_path, alert: 'Admin access required.' unless current_user.admin?
  end

  def issue_type_params
    params.require(:issue_type).permit(:name, :color, :icon, :is_default)
  end
end
```

---

### Step 3.6: Create Views
**Duration:** 1 day

#### Status Management UI

```erb
<%# app/views/issue_statuses/index.html.erb %>
<div class="container mx-auto px-4 py-8">
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-3xl font-bold">Issue Statuses</h1>
    <%= link_to "New Status", new_project_issue_status_path(@project), class: "btn btn-primary" %>
  </div>

  <div class="grid gap-4" data-controller="sortable" data-sortable-url-value="<%= move_project_issue_status_path(@project, ':id') %>">
    <% @issue_statuses.each do |status| %>
      <div class="card bg-base-100 shadow" data-sortable-id="<%= status.id %>">
        <div class="card-body flex-row justify-between items-center">
          <div class="flex items-center gap-4">
            <div class="cursor-move">
              <%= icon('grip-vertical') %>
            </div>
            <div class="badge badge-lg" style="background-color: <%= status.color %>;">
              <%= icon(status.icon) if status.icon %>
              <%= status.name %>
            </div>
            <% if status.is_default %>
              <span class="badge badge-sm">Default</span>
            <% end %>
            <% if status.is_closed_status %>
              <span class="badge badge-sm badge-success">Closed Status</span>
            <% end %>
            <span class="text-sm opacity-50"><%= status.issues.count %> issues</span>
          </div>

          <div class="flex gap-2">
            <%= link_to "Edit", edit_project_issue_status_path(@project, status), class: "btn btn-sm btn-ghost" %>
            <%= button_to "Delete", project_issue_status_path(@project, status),
                method: :delete,
                class: "btn btn-sm btn-ghost btn-error",
                data: { confirm: "Are you sure?" } %>
          </div>
        </div>
      </div>
    <% end %>
  </div>
</div>
```

#### Issue Card with Status/Type

```erb
<%# app/views/visualizations/_issue_card.html.erb %>
<div class="issue-card card bg-base-100 shadow-sm hover:shadow-md transition" data-issue-id="<%= issue.id %>">
  <div class="card-body p-4">
    <div class="flex items-start justify-between gap-2">
      <div class="flex-1">
        <%# Issue Type Badge %>
        <% if issue.issue_type %>
          <span class="badge badge-sm" style="background-color: <%= issue.issue_type.color %>;">
            <%= icon(issue.issue_type.icon) if issue.issue_type.icon %>
            <%= issue.issue_type.name %>
          </span>
        <% end %>

        <%# Issue Title %>
        <h3 class="font-semibold mt-1">
          <%= link_to issue.title, visualization_issue_path(visualization, issue), class: "hover:underline" %>
        </h3>

        <%# Issue Status %>
        <% if issue.issue_status %>
          <span class="badge badge-sm mt-2" style="background-color: <%= issue.issue_status.color %>;">
            <%= icon(issue.issue_status.icon) if issue.issue_status.icon %>
            <%= issue.issue_status.name %>
          </span>
        <% end %>

        <%# Labels %>
        <div class="flex flex-wrap gap-1 mt-2">
          <% issue.labels.each do |label| %>
            <span class="badge badge-xs" style="background-color: <%= label.hex_color %>;">
              <%= label.title %>
            </span>
          <% end %>
        </div>

        <%# Assignee %>
        <% if issue.assigned_user %>
          <div class="flex items-center gap-2 mt-2 text-sm opacity-70">
            <div class="avatar placeholder">
              <div class="bg-neutral-focus text-neutral-content rounded-full w-6 text-xs">
                <%= issue.assigned_user.initials %>
              </div>
            </div>
            <%= issue.assigned_user.display_name %>
          </div>
        <% end %>
      </div>
    </div>
  </div>
</div>
```

---

## Phase 4: Views as Projections (Dynamic Grouping)
**Duration:** 2 weeks
**Complexity:** High
**Priority:** High

### Overview

Implement dynamic grouping where issues are automatically organized by field values (status, assignee, label, type).

---

### Step 4.1: Database Schema
**Duration:** 1 day

```ruby
# db/migrate/XXXXXX_add_projection_fields_to_visualizations.rb
class AddProjectionFieldsToVisualizations < ActiveRecord::Migration[8.1]
  def change
    add_column :visualizations, :grouping_field, :string
    # Values: 'manual', 'status', 'assignee', 'label', 'type', 'priority'

    add_column :visualizations, :grouping_label_id, :integer
    # If grouping_field = 'label', which label to group by

    add_index :visualizations, :grouping_field
  end
end
```

---

### Step 4.2: Update Visualization Model
**Duration:** 2 days

```ruby
# app/models/visualization.rb
class Visualization < ApplicationRecord
  self.inheritance_column = "_type"

  VALID_TYPES = ["board"]
  GROUPING_FIELDS = %w[manual status assignee label type priority]

  belongs_to :project
  belongs_to :grouping_label, class_name: 'IssueLabel', optional: true
  has_many :groupings, -> { order(position: :asc) }, dependent: :destroy

  validates :type, inclusion: { in: VALID_TYPES }
  validates :grouping_field, inclusion: { in: GROUPING_FIELDS }, allow_nil: true

  # Default to manual grouping (existing behavior)
  after_initialize :set_default_grouping_field, if: :new_record?

  # Dynamic grouping methods
  def manual_grouping?
    grouping_field.blank? || grouping_field == 'manual'
  end

  def projection?
    !manual_grouping?
  end

  def dynamic_groupings
    return groupings if manual_grouping?

    case grouping_field
    when 'status'
      group_by_status
    when 'assignee'
      group_by_assignee
    when 'label'
      group_by_label
    when 'type'
      group_by_type
    when 'priority'
      group_by_priority
    else
      groupings
    end
  end

  def issues_for_grouping(grouping_value)
    base_scope = project.issues.active

    case grouping_field
    when 'status'
      base_scope.where(issue_status_id: grouping_value)
    when 'assignee'
      if grouping_value == 'unassigned'
        base_scope.unassigned
      else
        base_scope.where(assigned_user_id: grouping_value)
      end
    when 'label'
      base_scope.joins(:labels).where(issue_labels: { id: grouping_value })
    when 'type'
      base_scope.where(issue_type_id: grouping_value)
    when 'priority'
      base_scope.where(priority: grouping_value)
    else
      # Manual grouping - return issues in this grouping
      grouping_value.is_a?(Grouping) ? grouping_value.issues : Issue.none
    end
  end

  private

  def set_default_grouping_field
    self.grouping_field ||= 'manual'
  end

  def group_by_status
    project.issue_statuses.ordered.map do |status|
      DynamicGrouping.new(
        id: "status_#{status.id}",
        title: status.name,
        color: status.color,
        icon: status.icon,
        value: status.id,
        issue_count: project.issues.active.where(issue_status: status).count
      )
    end
  end

  def group_by_assignee
    assigned_users = project.members.joins(:assigned_issues)
      .where(issues: { project_id: project.id, archived_at: nil })
      .distinct
      .order(:name)

    groups = assigned_users.map do |user|
      DynamicGrouping.new(
        id: "assignee_#{user.id}",
        title: user.display_name,
        avatar: user.initials,
        value: user.id,
        issue_count: project.issues.active.where(assigned_user: user).count
      )
    end

    # Add "Unassigned" group
    unassigned_count = project.issues.active.unassigned.count
    if unassigned_count > 0
      groups << DynamicGrouping.new(
        id: "assignee_unassigned",
        title: "Unassigned",
        icon: "user-x",
        value: "unassigned",
        issue_count: unassigned_count
      )
    end

    groups
  end

  def group_by_label
    return [] unless grouping_label_id

    project.issue_labels.order(:title).map do |label|
      DynamicGrouping.new(
        id: "label_#{label.id}",
        title: label.title,
        color: label.hex_color,
        value: label.id,
        issue_count: project.issues.active.joins(:labels).where(issue_labels: { id: label.id }).count
      )
    end
  end

  def group_by_type
    IssueType.for_project(project).map do |type|
      DynamicGrouping.new(
        id: "type_#{type.id}",
        title: type.name,
        color: type.color,
        icon: type.icon,
        value: type.id,
        issue_count: project.issues.active.where(issue_type: type).count
      )
    end
  end

  def group_by_priority
    Issue.priorities.keys.map do |priority_key|
      DynamicGrouping.new(
        id: "priority_#{priority_key}",
        title: priority_key.titleize,
        value: priority_key,
        issue_count: project.issues.active.where(priority: priority_key).count
      )
    end
  end
end

# app/models/dynamic_grouping.rb
# PORO (Plain Old Ruby Object) for dynamic groupings
class DynamicGrouping
  attr_reader :id, :title, :color, :icon, :avatar, :value, :issue_count

  def initialize(attributes = {})
    @id = attributes[:id]
    @title = attributes[:title]
    @color = attributes[:color]
    @icon = attributes[:icon]
    @avatar = attributes[:avatar]
    @value = attributes[:value]
    @issue_count = attributes[:issue_count] || 0
  end

  def persisted?
    false
  end

  def dynamic?
    true
  end
end
```

---

### Step 4.3: Update VisualizationsController
**Duration:** 1 day

```ruby
# app/controllers/visualizations_controller.rb
class VisualizationsController < ApplicationController
  before_action :set_visualization
  before_action :authorize_visualization

  def show
    @groupings = @visualization.dynamic_groupings
    @issue_detail = @visualization.project.issues.find(params[:issue_id]) if params[:issue_id]
  end

  def update
    if @visualization.update(visualization_params)
      redirect_to @visualization, notice: 'View updated.'
    else
      render :show, status: :unprocessable_entity
    end
  end

  def update_grouping_field
    if @visualization.update(grouping_field: params[:grouping_field])
      redirect_to @visualization, notice: 'Grouping changed.'
    else
      redirect_to @visualization, alert: 'Failed to update grouping.'
    end
  end

  private

  def set_visualization
    @visualization = Visualization.find(params[:id])
  end

  def authorize_visualization
    authorize @visualization.project, :show?
  end

  def visualization_params
    params.require(:visualization).permit(:grouping_field, :grouping_label_id, :favorite_issue_labels)
  end
end
```

---

### Step 4.4: Create Grouping Selector UI
**Duration:** 2 days

```erb
<%# app/views/visualizations/_grouping_selector.html.erb %>
<div class="dropdown dropdown-end">
  <label tabindex="0" class="btn btn-sm btn-outline gap-2">
    <%= icon('layout-board') %>
    Group by: <strong><%= @visualization.grouping_field&.titleize || 'Columns' %></strong>
    <%= icon('chevron-down') %>
  </label>

  <ul tabindex="0" class="dropdown-content menu p-2 shadow bg-base-100 rounded-box w-52">
    <li class="menu-title"><span>Group Issues By</span></li>

    <%= link_to visualization_update_grouping_field_path(@visualization, grouping_field: 'manual'),
        method: :patch,
        class: "#{@visualization.grouping_field == 'manual' ? 'active' : ''}" do %>
      <%= icon('columns') %> Manual Columns
    <% end %>

    <%= link_to visualization_update_grouping_field_path(@visualization, grouping_field: 'status'),
        method: :patch,
        class: "#{@visualization.grouping_field == 'status' ? 'active' : ''}" do %>
      <%= icon('circle-dot') %> Status
    <% end %>

    <%= link_to visualization_update_grouping_field_path(@visualization, grouping_field: 'assignee'),
        method: :patch,
        class: "#{@visualization.grouping_field == 'assignee' ? 'active' : ''}" do %>
      <%= icon('user') %> Assignee
    <% end %>

    <%= link_to visualization_update_grouping_field_path(@visualization, grouping_field: 'type'),
        method: :patch,
        class: "#{@visualization.grouping_field == 'type' ? 'active' : ''}" do %>
      <%= icon('tag') %> Type
    <% end %>

    <%= link_to visualization_update_grouping_field_path(@visualization, grouping_field: 'priority'),
        method: :patch,
        class: "#{@visualization.grouping_field == 'priority' ? 'active' : ''}" do %>
      <%= icon('flag') %> Priority
    <% end %>
  </ul>
</div>
```

---

### Step 4.5: Update Board View
**Duration:** 2 days

```erb
<%# app/views/visualizations/show.html.erb %>
<div class="visualization-board" data-controller="board" data-board-projection="<%= @visualization.projection? %>">
  <div class="board-header flex justify-between items-center mb-4">
    <h1 class="text-2xl font-bold"><%= @visualization.project.name %></h1>

    <div class="flex gap-2">
      <%= render 'grouping_selector', visualization: @visualization %>

      <% unless @visualization.projection? %>
        <%= link_to "Add Column", new_visualization_grouping_path(@visualization), class: "btn btn-sm btn-primary" %>
      <% end %>
    </div>
  </div>

  <div class="board-columns flex gap-4 overflow-x-auto pb-4">
    <% @groupings.each do |grouping| %>
      <div class="board-column flex-shrink-0 w-80"
           data-grouping-id="<%= grouping.id %>"
           data-grouping-value="<%= grouping.value %>">

        <%# Column Header %>
        <div class="column-header card bg-base-200 mb-2">
          <div class="card-body p-3 flex-row justify-between items-center">
            <div class="flex items-center gap-2">
              <% if grouping.color %>
                <div class="w-3 h-3 rounded-full" style="background-color: <%= grouping.color %>;"></div>
              <% elsif grouping.avatar %>
                <div class="avatar placeholder">
                  <div class="bg-neutral-focus text-neutral-content rounded-full w-6 text-xs">
                    <%= grouping.avatar %>
                  </div>
                </div>
              <% elsif grouping.icon %>
                <%= icon(grouping.icon) %>
              <% end %>

              <span class="font-semibold"><%= grouping.title %></span>
              <span class="badge badge-sm"><%= grouping.issue_count %></span>
            </div>

            <% unless @visualization.projection? %>
              <div class="dropdown dropdown-end">
                <label tabindex="0" class="btn btn-ghost btn-xs">
                  <%= icon('dots-vertical') %>
                </label>
                <ul tabindex="0" class="dropdown-content menu p-2 shadow bg-base-100 rounded-box w-52">
                  <li><%= link_to "Edit Column", edit_visualization_grouping_path(@visualization, grouping) %></li>
                  <li><%= link_to "Delete Column", visualization_grouping_path(@visualization, grouping), method: :delete, class: "text-error" %></li>
                </ul>
              </div>
            <% end %>
          </div>
        </div>

        <%# Issues %>
        <div class="column-issues space-y-2 min-h-[200px]"
             data-controller="sortable"
             data-sortable-disabled="<%= @visualization.projection? %>"
             data-sortable-group="<%= grouping.value %>">

          <% @visualization.issues_for_grouping(grouping.value).each do |issue| %>
            <%= render 'visualizations/issue_card', issue: issue, visualization: @visualization %>
          <% end %>
        </div>
      </div>
    <% end %>
  </div>
</div>
```

---

### Step 4.6: Handle Drag-and-Drop with Projections
**Duration:** 1 day

When grouping by projection, dragging an issue should update the underlying field:

```javascript
// frontend/components/Board/ProjectionHandler.js
export class ProjectionHandler {
  constructor(visualization) {
    this.visualization = visualization;
  }

  handleIssueMoved(issue, toGrouping) {
    const groupingField = this.visualization.groupingField;

    switch (groupingField) {
      case 'status':
        return this.updateIssueStatus(issue, toGrouping.value);
      case 'assignee':
        return this.updateIssueAssignee(issue, toGrouping.value);
      case 'type':
        return this.updateIssueType(issue, toGrouping.value);
      case 'priority':
        return this.updateIssuePriority(issue, toGrouping.value);
      default:
        // Manual grouping - use existing allocation logic
        return this.updateIssueAllocation(issue, toGrouping);
    }
  }

  async updateIssueStatus(issue, statusId) {
    const response = await fetch(`/issues/${issue.id}/update_status`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.csrfToken()
      },
      body: JSON.stringify({ issue_status_id: statusId })
    });

    return response.ok;
  }

  async updateIssueAssignee(issue, assigneeId) {
    const response = await fetch(`/issues/${issue.id}/update_assignee`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.csrfToken()
      },
      body: JSON.stringify({ assigned_user_id: assigneeId === 'unassigned' ? null : assigneeId })
    });

    return response.ok;
  }

  // ... similar methods for type and priority ...
}
```

---

## Phase 5: Grid View (Spreadsheet-style)
**Duration:** 2 weeks
**Complexity:** High
**Priority:** Medium-High

### Overview

Implement a spreadsheet-style grid view for bulk editing and data entry.

---

### Step 5.1: Choose Grid Library
**Duration:** 0.5 day

**Recommended:** AG-Grid Community (free, open-source)

```bash
npm install ag-grid-react ag-grid-community
```

**Alternative:** TanStack Table (formerly React Table) - more lightweight

---

### Step 5.2: Create Grid View React Component
**Duration:** 3 days

```jsx
// frontend/components/GridView/GridView.jsx
import React, { useState, useCallback, useMemo } from 'react';
import { AgGridReact } from 'ag-grid-react';
import 'ag-grid-community/styles/ag-grid.css';
import 'ag-grid-community/styles/ag-theme-alpine.css';

export default function GridView({ projectId, initialIssues, statuses, types, members }) {
  const [issues, setIssues] = useState(initialIssues);

  // Column definitions
  const columnDefs = useMemo(() => [
    {
      field: 'id',
      headerName: 'ID',
      width: 80,
      pinned: 'left',
      cellRenderer: params => `#${params.value}`
    },
    {
      field: 'title',
      headerName: 'Title',
      width: 300,
      editable: true,
      pinned: 'left'
    },
    {
      field: 'issue_type_id',
      headerName: 'Type',
      width: 120,
      editable: true,
      cellEditor: 'agSelectCellEditor',
      cellEditorParams: {
        values: types.map(t => t.id)
      },
      valueFormatter: params => {
        const type = types.find(t => t.id === params.value);
        return type ? type.name : '';
      },
      cellRenderer: params => {
        const type = types.find(t => t.id === params.value);
        if (!type) return '';

        return `<span class="badge" style="background-color: ${type.color};">
          ${type.name}
        </span>`;
      }
    },
    {
      field: 'issue_status_id',
      headerName: 'Status',
      width: 140,
      editable: true,
      cellEditor: 'agSelectCellEditor',
      cellEditorParams: {
        values: statuses.map(s => s.id)
      },
      valueFormatter: params => {
        const status = statuses.find(s => s.id === params.value);
        return status ? status.name : '';
      },
      cellRenderer: params => {
        const status = statuses.find(s => s.id === params.value);
        if (!status) return '';

        return `<span class="badge" style="background-color: ${status.color};">
          ${status.name}
        </span>`;
      }
    },
    {
      field: 'assigned_user_id',
      headerName: 'Assignee',
      width: 150,
      editable: true,
      cellEditor: 'agSelectCellEditor',
      cellEditorParams: {
        values: [null, ...members.map(m => m.id)]
      },
      valueFormatter: params => {
        if (!params.value) return 'Unassigned';
        const member = members.find(m => m.id === params.value);
        return member ? member.name : '';
      },
      cellRenderer: params => {
        if (!params.value) return '<span class="text-gray-400">Unassigned</span>';
        const member = members.find(m => m.id === params.value);
        if (!member) return '';

        return `<div class="flex items-center gap-2">
          <div class="avatar placeholder">
            <div class="bg-neutral-focus text-neutral-content rounded-full w-6 text-xs">
              ${member.initials}
            </div>
          </div>
          ${member.name}
        </div>`;
      }
    },
    {
      field: 'priority',
      headerName: 'Priority',
      width: 120,
      editable: true,
      cellEditor: 'agSelectCellEditor',
      cellEditorParams: {
        values: ['none', 'low', 'medium', 'high', 'critical']
      },
      valueFormatter: params => params.value ? params.value.charAt(0).toUpperCase() + params.value.slice(1) : 'None'
    },
    {
      field: 'due_date',
      headerName: 'Due Date',
      width: 140,
      editable: true,
      cellEditor: 'agDateCellEditor',
      valueFormatter: params => params.value ? new Date(params.value).toLocaleDateString() : ''
    },
    {
      field: 'created_at',
      headerName: 'Created',
      width: 140,
      valueFormatter: params => new Date(params.value).toLocaleDateString()
    }
  ], [statuses, types, members]);

  // Handle cell value changes
  const onCellValueChanged = useCallback(async (params) => {
    const issue = params.data;
    const field = params.column.getColId();
    const newValue = params.newValue;

    try {
      const response = await fetch(`/issues/${issue.id}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({
          issue: {
            [field]: newValue
          }
        })
      });

      if (!response.ok) {
        throw new Error('Failed to update issue');
      }

      // Optionally show success notification
      console.log('Issue updated successfully');
    } catch (error) {
      console.error('Error updating issue:', error);
      // Revert change
      params.node.setDataValue(field, params.oldValue);
      alert('Failed to update issue');
    }
  }, []);

  // Default column configuration
  const defaultColDef = useMemo(() => ({
    sortable: true,
    filter: true,
    resizable: true
  }), []);

  return (
    <div className="grid-view h-full">
      <div className="ag-theme-alpine h-[calc(100vh-200px)]">
        <AgGridReact
          rowData={issues}
          columnDefs={columnDefs}
          defaultColDef={defaultColDef}
          onCellValueChanged={onCellValueChanged}
          rowSelection="multiple"
          animateRows={true}
          pagination={true}
          paginationPageSize={50}
        />
      </div>
    </div>
  );
}
```

---

### Step 5.3: Create Grid View Route
**Duration:** 0.5 day

```ruby
# config/routes.rb
resources :visualizations do
  member do
    get :grid # Grid view
  end
end
```

```ruby
# app/controllers/visualizations_controller.rb
def grid
  authorize @visualization.project, :show?

  @issues = policy_scope(@visualization.project.issues.active)
    .includes(:issue_status, :issue_type, :assigned_user, :labels)

  @statuses = @visualization.project.issue_statuses.ordered
  @types = IssueType.for_project(@visualization.project)
  @members = @visualization.project.members
end
```

---

### Step 5.4: Create Grid View Template
**Duration:** 1 day

```erb
<%# app/views/visualizations/grid.html.erb %>
<div class="container-fluid px-4 py-6">
  <div class="flex justify-between items-center mb-4">
    <h1 class="text-2xl font-bold"><%= @visualization.project.name %> - Grid View</h1>

    <div class="flex gap-2">
      <%= link_to "Board View", @visualization, class: "btn btn-sm btn-outline" %>
      <%= link_to "New Issue", new_project_issue_path(@visualization.project), class: "btn btn-sm btn-primary" %>
    </div>
  </div>

  <%= react_component('GridView', {
    projectId: @visualization.project.id,
    initialIssues: @issues.as_json(include: [:issue_status, :issue_type, :assigned_user]),
    statuses: @statuses.as_json,
    types: @types.as_json,
    members: @members.as_json(methods: [:initials])
  }) %>
</div>
```

---

### Step 5.5: Add Bulk Operations
**Duration:** 2 days

```jsx
// frontend/components/GridView/BulkActions.jsx
import React from 'react';

export default function BulkActions({ selectedRows, onBulkUpdate, statuses, types, members }) {
  const [action, setAction] = React.useState('');
  const [value, setValue] = React.useState('');

  const handleApply = () => {
    if (!action || !value) return;

    onBulkUpdate(selectedRows, action, value);
  };

  return (
    <div className="bulk-actions flex items-center gap-4 p-4 bg-base-200 rounded">
      <span className="font-semibold">{selectedRows.length} selected</span>

      <select
        className="select select-sm select-bordered"
        value={action}
        onChange={e => setAction(e.target.value)}
      >
        <option value="">Choose action...</option>
        <option value="status">Change Status</option>
        <option value="assignee">Change Assignee</option>
        <option value="type">Change Type</option>
        <option value="priority">Change Priority</option>
        <option value="archive">Archive</option>
        <option value="delete">Delete</option>
      </select>

      {action === 'status' && (
        <select
          className="select select-sm select-bordered"
          value={value}
          onChange={e => setValue(e.target.value)}
        >
          <option value="">Select status...</option>
          {statuses.map(s => (
            <option key={s.id} value={s.id}>{s.name}</option>
          ))}
        </select>
      )}

      {action === 'assignee' && (
        <select
          className="select select-sm select-bordered"
          value={value}
          onChange={e => setValue(e.target.value)}
        >
          <option value="">Select assignee...</option>
          <option value="null">Unassign</option>
          {members.map(m => (
            <option key={m.id} value={m.id}>{m.name}</option>
          ))}
        </select>
      )}

      <button
        className="btn btn-sm btn-primary"
        onClick={handleApply}
        disabled={!action || (!value && action !== 'archive' && action !== 'delete')}
      >
        Apply
      </button>
    </div>
  );
}
```

---

## Implementation Timeline Summary

### Total Estimated Duration: 6-7 weeks

| Phase | Duration | Dependencies | Key Deliverables |
|-------|----------|--------------|------------------|
| **Phase 1: Multi-user Authentication** | 1-2 weeks | None | User login, registration, project ownership, issue assignment |
| **Phase 2: Authorization & Permissions** | 1 week | Phase 1 | Pundit policies, role-based access, permission checks in UI |
| **Phase 3: Custom Statuses & Types** | 1 week | Phase 1 | Issue statuses, issue types, status workflows |
| **Phase 4: Views as Projections** | 2 weeks | Phase 1, 3 | Dynamic grouping by status/assignee/type/label |
| **Phase 5: Grid View** | 2 weeks | Phase 1, 3 | Spreadsheet interface, inline editing, bulk operations |

---

## Testing Strategy

### Phase 1: Authentication Testing
- User registration and login flows
- Session management
- Password reset
- Project ownership assignment
- Issue creator/assignee tracking

### Phase 2: Authorization Testing
- Policy specs for each resource
- Controller authorization checks
- UI permission hiding
- Unauthorized access attempts

### Phase 3: Status/Type Testing
- Default status/type creation
- Status workflow transitions
- Type assignment
- Migration of existing data

### Phase 4: Projection Testing
- Dynamic grouping generation
- Issue filtering by grouping field
- Drag-and-drop field updates
- Real-time updates

### Phase 5: Grid View Testing
- Grid rendering performance
- Inline editing
- Bulk operations
- Data validation

---

## Deployment Checklist

### Pre-Deployment
- [ ] Run full test suite (RSpec + Jest)
- [ ] Database backup
- [ ] Review all migrations
- [ ] Test migration rollback
- [ ] Check for N+1 queries
- [ ] Run Rubocop and ESLint
- [ ] Security scan (Brakeman)

### Deployment Steps
1. Pull latest code
2. Install dependencies (`bundle install`, `npm install`)
3. Run migrations (`rails db:migrate`)
4. Seed default data if needed
5. Precompile assets (`rails assets:precompile`)
6. Restart application server
7. Verify background jobs running

### Post-Deployment
- [ ] Smoke test: Login
- [ ] Smoke test: Create project
- [ ] Smoke test: Create issue
- [ ] Smoke test: Board view
- [ ] Smoke test: Grid view
- [ ] Check logs for errors
- [ ] Monitor performance
- [ ] Verify real-time features

---

## Risk Mitigation

### Breaking Changes
**Risk:** Multi-user changes break existing single-user functionality

**Mitigation:**
- Create comprehensive migration scripts
- Test with production data copy
- Provide rollback plan
- Feature flags for gradual rollout

### Performance Issues
**Risk:** Complex queries slow down projections and grid view

**Mitigation:**
- Add database indexes
- Use eager loading
- Implement caching
- Pagination
- Background job processing

### Data Loss
**Risk:** Migrations fail or corrupt data

**Mitigation:**
- Automated backups before deployment
- Test migrations on production copy
- Reversible migrations
- Manual verification steps

---

## Future Enhancements

### Post-Implementation Ideas
1. **Multiple Visualizations per Project** - Save different board/grid views
2. **Custom Fields** - Add arbitrary fields to issues
3. **Advanced Filters in Grid View** - Complex filter builder
4. **Export Grid to Excel** - Download grid data
5. **Mobile App** - Native mobile support
6. **Real-time Collaboration** - See who's viewing/editing
7. **Activity Feed** - Timeline of all changes
8. **Email Notifications** - Notify on assignments/mentions
9. **Webhooks** - Integrate with external tools
10. **API** - RESTful API for integrations

---

## Conclusion

This plan provides a comprehensive roadmap for transforming Eigenfocus FREE into a multi-user project management system with PRO features. The phased approach ensures that each component builds on the previous foundation, minimizing risk and allowing for iterative testing and refinement.

### Key Success Factors
1. **Thorough Testing** - Test each phase before moving to next
2. **Data Migration** - Carefully migrate existing single-user data
3. **Performance** - Monitor and optimize query performance
4. **User Experience** - Maintain smooth, intuitive interface
5. **Security** - Proper authentication and authorization

### Next Steps
1. Review and approve this plan
2. Set up development environment
3. Create feature branch
4. Begin Phase 1: Multi-user Authentication
5. Test thoroughly at each phase
6. Deploy incrementally

**Good luck with your custom fork! 🚀**

---

**Document Version:** 1.0
**Created:** December 31, 2025
**Author:** Implementation Planning Team
**Status:** Ready for Development
