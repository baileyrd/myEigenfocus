# Phase 1: Multi-user Authentication Setup Guide

This guide walks you through implementing Phase 1 of the PRO features: Multi-user Authentication.

## ✅ Files Created

The following files have been created for you:

### Database Migrations
- `db/migrate/20250101000001_add_devise_to_users.rb`
- `db/migrate/20250101000002_migrate_existing_user_data.rb`
- `db/migrate/20250101000003_add_project_ownership.rb`
- `db/migrate/20250101000004_migrate_existing_projects.rb`
- `db/migrate/20250101000005_add_issue_user_tracking.rb`
- `db/migrate/20250101000006_migrate_existing_issues.rb`

### Configuration
- `config/initializers/devise.rb`

### Dependencies Added
- Updated `Gemfile` with Devise and Pundit gems

---

## 📋 Steps to Complete

### Step 1: Install Dependencies

In your development environment (Docker/WSL/local Ruby), run:

```bash
bundle install
```

This will install:
- `devise` (~> 4.9) - Authentication
- `pundit` (~> 2.3) - Authorization (for Phase 2)

---

### Step 2: Generate Devise Files

Run the Devise generators:

```bash
# Generate Devise views
rails generate devise:views

# This will create view files in app/views/devise/
```

---

### Step 3: Update User Model

Edit `app/models/user.rb` and replace it with:

```ruby
# frozen_string_literal: true

class User < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable

  # Enums
  enum role: {
    member: "member",
    admin: "admin"
  }

  # Associations (existing)
  has_many :time_entries, dependent: :destroy
  has_one :preferences, class_name: "UserPreference", dependent: :destroy

  # NEW: Multi-user associations
  has_many :project_memberships, dependent: :destroy
  has_many :projects, through: :project_memberships
  has_many :owned_projects, class_name: "Project", foreign_key: :owner_id
  has_many :created_issues, class_name: "Issue", foreign_key: :creator_id
  has_many :assigned_issues, class_name: "Issue", foreign_key: :assigned_user_id
  has_many :comments, class_name: "Issue::Comment", foreign_key: :author_id

  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :role, presence: true

  # Callbacks
  after_create :create_default_preferences

  # Instance methods
  def admin?
    role == "admin"
  end

  def display_name
    name.presence || email.split("@").first
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

### Step 4: Create ProjectMembership Model

Create `app/models/project_membership.rb`:

```ruby
# frozen_string_literal: true

class ProjectMembership < ApplicationRecord
  belongs_to :project
  belongs_to :user

  # Roles
  enum role: {
    owner: "owner",     # Full control
    editor: "editor",   # Can edit, cannot manage members
    viewer: "viewer"    # Read-only
  }

  # Validations
  validates :user_id, uniqueness: { scope: :project_id }
  validates :role, presence: true

  # Scopes
  scope :owners, -> { where(role: "owner") }
  scope :editors, -> { where(role: "editor") }
  scope :viewers, -> { where(role: "viewer") }

  # Instance methods
  def can_edit?
    owner? || editor?
  end

  def can_manage_members?
    owner?
  end
end
```

---

### Step 5: Update Project Model

Edit `app/models/project.rb` and add the following:

```ruby
# Add to associations section:
belongs_to :owner, class_name: "User", optional: true
has_many :project_memberships, dependent: :destroy
has_many :members, through: :project_memberships, source: :user

# Add to callbacks section:
after_create :create_owner_membership, if: :owner_id?

# Add to scopes section:
scope :accessible_by, ->(user) {
  joins(:project_memberships)
    .where(project_memberships: { user_id: user.id })
}

# Add these instance methods:
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
    role: "owner"
  ) unless project_memberships.exists?(user: owner)
end
```

---

### Step 6: Update Issue Model

Edit `app/models/issue.rb` and add:

```ruby
# Add to associations section:
belongs_to :creator, class_name: "User", optional: true
belongs_to :assigned_user, class_name: "User", optional: true

# Add to scopes section:
scope :assigned_to, ->(user) { where(assigned_user: user) }
scope :created_by, ->(user) { where(creator: user) }
scope :unassigned, -> { where(assigned_user_id: nil) }

# Update validations:
validates :creator, presence: true, on: :create

# Add to ransackable_attributes:
def self.ransackable_attributes(auth_object = nil)
  super + ["assigned_user_id", "creator_id"]
end

def self.ransackable_associations(auth_object = nil)
  super + ["assigned_user", "creator"]
end

# Add these instance methods:
def assigned?
  assigned_user.present?
end

def assign_to(user)
  update(assigned_user: user)
end

def unassign
  update(assigned_user: nil)
end
```

---

### Step 7: Update ApplicationController

Edit `app/controllers/application_controller.rb`:

```ruby
class ApplicationController < ActionController::Base
  # IMPORTANT: Add authentication
  before_action :authenticate_user!
  before_action :set_locale
  before_action :set_timezone

  # Remove the old current_user method if it exists:
  # def current_user
  #   @current_user ||= User.first_or_create
  # end

  # current_user is now provided by Devise

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
end
```

---

### Step 8: Update Routes

Edit `config/routes.rb` and add at the top:

```ruby
Rails.application.routes.draw do
  # Devise routes
  devise_for :users

  # Authenticated routes only
  authenticate :user do
    # Your existing routes go here
    root to: "projects#index" # or whatever your root is

    # ... rest of your routes ...
  end
end
```

---

### Step 9: Run Migrations

Set environment variables for the admin user (optional):

```bash
export ADMIN_EMAIL="your-email@example.com"
export ADMIN_PASSWORD="YourSecurePassword123"
```

Then run migrations:

```bash
rails db:migrate
```

This will:
1. Add Devise fields to users table
2. Migrate your existing user to have email/password
3. Add project ownership
4. Create project memberships
5. Add issue creator/assignee tracking
6. Migrate existing data

---

### Step 10: Update ProjectsController

Edit `app/controllers/projects_controller.rb`:

```ruby
# Add to create action:
def create
  @project = Project.new(project_params)
  @project.owner = current_user  # ADD THIS LINE

  if @project.save
    redirect_to @project, notice: "Project created successfully."
  else
    render :new, status: :unprocessable_entity
  end
end
```

---

### Step 11: Update IssuesController

Find where issues are created and add:

```ruby
# In create action:
def create
  @issue = @project.issues.build(issue_params)
  @issue.creator = current_user  # ADD THIS LINE

  if @issue.save
    # ...
  end
end
```

---

### Step 12: Create Custom Devise Controllers (Optional)

If you want to customize registration:

```bash
rails generate devise:controllers users
```

Then update routes:

```ruby
devise_for :users, controllers: {
  registrations: "users/registrations",
  sessions: "users/sessions"
}
```

---

### Step 13: Customize Devise Views

The views were generated in Step 2. You can now customize them.

Key files to customize:
- `app/views/devise/sessions/new.html.erb` - Login page
- `app/views/devise/registrations/new.html.erb` - Sign up page
- `app/views/devise/registrations/edit.html.erb` - Edit profile
- `app/views/devise/passwords/new.html.erb` - Forgot password

See the PRO_FEATURES_IMPLEMENTATION_PLAN.md for example customized views with Tailwind CSS.

---

### Step 14: Update Navigation/Header

Add user menu to your header/navigation. Example:

```erb
<%# app/views/layouts/_header.html.erb or similar %>
<div class="user-menu">
  <% if user_signed_in? %>
    <div class="dropdown">
      <button class="avatar-button">
        <%= current_user.initials || "?" %>
      </button>
      <div class="dropdown-menu">
        <span><%= current_user.display_name %></span>
        <span class="email"><%= current_user.email %></span>
        <%= link_to "Profile Settings", edit_user_registration_path %>
        <%= button_to "Sign Out", destroy_user_session_path, method: :delete %>
      </div>
    </div>
  <% else %>
    <%= link_to "Sign In", new_user_session_path %>
    <%= link_to "Sign Up", new_user_registration_path %>
  <% end %>
</div>
```

---

### Step 15: Test Authentication

1. Start your Rails server
2. Navigate to your app - you should be redirected to login
3. Sign up with a new account
4. Test login/logout
5. Test password reset
6. Verify existing data is accessible

---

## 🧪 Testing

### Create RSpec Tests

Create `spec/models/user_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:name) }
  end

  describe "associations" do
    it { should have_many(:project_memberships).dependent(:destroy) }
    it { should have_many(:projects).through(:project_memberships) }
    it { should have_many(:owned_projects).class_name("Project") }
  end

  describe "#admin?" do
    it "returns true for admin users" do
      user = create(:user, role: "admin")
      expect(user.admin?).to be true
    end

    it "returns false for member users" do
      user = create(:user, role: "member")
      expect(user.admin?).to be false
    end
  end
end
```

Create `spec/models/project_membership_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe ProjectMembership, type: :model do
  describe "validations" do
    it { should validate_presence_of(:role) }
  end

  describe "associations" do
    it { should belong_to(:project) }
    it { should belong_to(:user) }
  end

  describe "#can_edit?" do
    it "returns true for owners" do
      membership = create(:project_membership, role: "owner")
      expect(membership.can_edit?).to be true
    end

    it "returns true for editors" do
      membership = create(:project_membership, role: "editor")
      expect(membership.can_edit?).to be true
    end

    it "returns false for viewers" do
      membership = create(:project_membership, role: "viewer")
      expect(membership.can_edit?).to be false
    end
  end
end
```

### Update Factory Bot Factories

Create `spec/factories/users.rb`:

```ruby
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
```

Create `spec/factories/project_memberships.rb`:

```ruby
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

## ⚠️ Important Notes

### Environment Variables

Before running migrations, optionally set:

```bash
ADMIN_EMAIL=your-email@example.com
ADMIN_PASSWORD=YourSecurePassword123
```

If you don't set these, a random password will be generated and displayed in the console.

### Data Migration

The migrations will:
1. Add email/password to your existing single user
2. Make that user an admin
3. Assign all existing projects to that user as owner
4. Assign all existing issues to that user as creator

### Breaking Changes

After implementing Phase 1:
- Users will be required to log in
- No more automatic single-user assumption
- All controllers now check authentication

### Rollback Plan

If you need to rollback:

```bash
rails db:rollback STEP=6
```

This will undo all 6 migrations.

---

## ✅ Verification Checklist

After completing all steps, verify:

- [ ] Bundle install completed successfully
- [ ] All migrations ran without errors
- [ ] Admin user created with email/password
- [ ] Can log in with admin credentials
- [ ] Can log out
- [ ] Existing projects are accessible
- [ ] Existing issues are accessible
- [ ] Can create new projects (assigned to current user as owner)
- [ ] Can create new issues (creator set to current user)
- [ ] Password reset works
- [ ] User menu shows in header
- [ ] Tests pass (`bundle exec rspec`)

---

## 🚀 Next Steps

After Phase 1 is complete and tested:

1. **Phase 2: Authorization & Permissions**
   - Install Pundit
   - Create policies
   - Add permission checks

2. **Phase 3: Custom Issue Statuses & Types**
   - Create status/type models
   - Build management UI

3. **Phase 4: Views as Projections**
   - Dynamic grouping

4. **Phase 5: Grid View**
   - Spreadsheet interface

---

## 📞 Troubleshooting

### Issue: Bundle install fails
**Solution:** Make sure you're in the correct directory and Ruby is installed

### Issue: Migration fails
**Solution:** Check that no users exist without an ID, or manually set email before migrating

### Issue: Can't log in after migration
**Solution:** Check the console output for the generated password, or reset via:
```bash
rails console
user = User.first
user.update(password: "newpassword", password_confirmation: "newpassword")
```

### Issue: Existing features broken
**Solution:** Make sure all controllers that reference `current_user` still work with Devise's version

---

**Phase 1 Complete!** 🎉

Once all steps are complete and tested, you're ready to move to Phase 2: Authorization & Permissions.
