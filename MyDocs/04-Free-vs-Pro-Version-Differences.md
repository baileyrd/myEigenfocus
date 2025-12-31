# Eigenfocus: FREE vs PRO Edition
## Comprehensive Feature Comparison and Analysis

**Document Version:** 1.0
**Last Updated:** December 31, 2025
**FREE Version Analyzed:** 1.4.1

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Feature Comparison Matrix](#feature-comparison-matrix)
3. [FREE Edition Capabilities](#free-edition-capabilities)
4. [PRO Edition Exclusive Features](#pro-edition-exclusive-features)
5. [Technical Architecture Differences](#technical-architecture-differences)
6. [Business Model Analysis](#business-model-analysis)
7. [Upgrade Path](#upgrade-path)
8. [Use Case Recommendations](#use-case-recommendations)

---

## Executive Summary

### Version Overview

**FREE Edition (1.4.1)**
- **Target User:** Individual developers, freelancers, solo entrepreneurs
- **User Limit:** Single user only
- **Cost:** Free (self-hosted)
- **License:** Source-available, proprietary
- **Authentication:** None (automatic single-user session)
- **Deployment:** Self-hosted via Docker

**PRO Edition**
- **Target User:** Teams (2-100+ users)
- **User Limit:** Multiple users with permissions
- **Cost:** Pay-once model (not subscription)
- **License:** Commercial, closed-source
- **Authentication:** Full SSO support (Google, Microsoft, GitHub, OIDC)
- **Deployment:** Self-hosted or Cloud SaaS

### Key Differentiators

**FREE Edition Philosophy:**
- Fully functional single-user project management
- No artificial limitations or time restrictions
- Genuine value as standalone product
- Marketing tool for PRO edition

**PRO Edition Philosophy:**
- Team collaboration and advanced workflows
- Enterprise-grade authentication
- Advanced visualization and customization
- Support and updates included

---

## Feature Comparison Matrix

### Project Management

| Feature | FREE Edition | PRO Edition |
|---------|-------------|-------------|
| **Projects** | ✅ Unlimited | ✅ Unlimited |
| **Project Templates** | ✅ 5 built-in templates | ✅ 5 built-in + custom templates |
| **Archive/Restore Projects** | ✅ Yes | ✅ Yes |
| **Project Permissions** | ❌ No (single user) | ✅ Per-project user permissions |
| **Project Sharing** | ❌ No | ✅ Invite users to projects |

---

### Issue Management

| Feature | FREE Edition | PRO Edition |
|---------|-------------|-------------|
| **Issues per Project** | ✅ Unlimited | ✅ Unlimited |
| **Markdown Descriptions** | ✅ Milkdown editor | ✅ Milkdown editor |
| **File Attachments** | ✅ Unlimited | ✅ Unlimited |
| **Labels** | ✅ Unlimited custom labels | ✅ Unlimited custom labels |
| **Due Dates** | ✅ Yes | ✅ Yes |
| **Comments** | ✅ Yes | ✅ Yes + @mentions |
| **Issue Assignees** | ❌ No (only one user) | ✅ Assign to team members |
| **Custom Statuses** | ❌ No (archive/finish only) | ✅ Custom status workflows |
| **Custom Issue Types** | ❌ No | ✅ Bug, Feature, Task, etc. |
| **Issue Dependencies** | ❌ No | ❓ Unknown (not documented) |
| **Issue Templates** | ❌ No | ❓ Unknown (not documented) |

---

### Views & Visualizations

| Feature | FREE Edition | PRO Edition |
|---------|-------------|-------------|
| **Table/List View** | ✅ Yes | ✅ Yes |
| **Kanban Board** | ✅ Yes (single board per project) | ✅ Yes (multiple boards) |
| **Board Customization** | ✅ Custom columns, drag-and-drop | ✅ Advanced customization |
| **Hidden Columns** | ✅ Yes | ✅ Yes |
| **Favorite Labels Filter** | ✅ Yes | ✅ Yes |
| **Views as Projections** | ❌ No | ✅ **Dynamic grouping by:**<br>- Label<br>- Assignee<br>- Status<br>- Custom fields |
| **Multiple Views** | ❌ No (one board per project) | ✅ Multiple saved views per project |
| **Grid View** | ❌ No | ✅ **Spreadsheet-style grid:**<br>- Customizable rows<br>- Customizable columns<br>- Group by any field |
| **Calendar View** | ❌ No | ❓ Unknown (not documented) |
| **Gantt Chart** | ❌ No | ❓ Unknown (not documented) |

---

### Time Tracking

| Feature | FREE Edition | PRO Edition |
|---------|-------------|-------------|
| **Time Entries** | ✅ Unlimited | ✅ Unlimited |
| **Project-level Tracking** | ✅ Yes | ✅ Yes |
| **Issue-level Tracking** | ✅ Yes | ✅ Yes |
| **Start/Stop Timers** | ✅ Yes (running time entries) | ✅ Yes |
| **Multiple Running Timers** | ✅ Yes | ✅ Yes |
| **Time Reports** | ✅ Basic (by project, date range) | ✅ Advanced (by user, label, custom fields) |
| **CSV Export** | ✅ Yes | ✅ Yes |
| **Time Estimation** | ❌ No | ❓ Unknown (not documented) |
| **Time Budgets** | ❌ No | ❓ Unknown (not documented) |
| **Billable Hours** | ❌ No | ❓ Unknown (not documented) |

---

### Focus & Productivity

| Feature | FREE Edition | PRO Edition |
|---------|-------------|-------------|
| **Focus Space** | ✅ Yes | ✅ Yes |
| **Pomodoro Timer** | ✅ Yes (customizable presets) | ✅ Yes |
| **Ambient Sounds** | ✅ Yes (multiple sounds) | ✅ Yes |
| **Animated Background** | ✅ Yes | ✅ Yes |
| **Timer Presets** | ✅ 4 presets + custom | ✅ 4 presets + custom |

---

### User Management & Authentication

| Feature | FREE Edition | PRO Edition |
|---------|-------------|-------------|
| **User Accounts** | ❌ **Single user only** | ✅ **Multiple users** |
| **User Roles** | ❌ No | ✅ Admin, Member, Viewer, etc. |
| **Per-Project Permissions** | ❌ No | ✅ Owner, Editor, Viewer per project |
| **Email/Password Login** | ❌ No login system | ✅ Yes |
| **SSO - Google** | ❌ No | ✅ Yes |
| **SSO - Microsoft** | ❌ No | ✅ Yes |
| **SSO - GitHub** | ❌ No | ✅ Yes |
| **Custom OIDC Providers** | ❌ No | ✅ Authentik, Okta, Auth0, etc. |
| **Two-Factor Authentication** | ❌ No | ❓ Unknown (not documented) |
| **API Tokens** | ❌ No | ❓ Unknown (not documented) |

---

### Collaboration Features

| Feature | FREE Edition | PRO Edition |
|---------|-------------|-------------|
| **Real-time Updates** | ✅ Yes (Turbo Streams) | ✅ Yes (Turbo Streams + presence) |
| **Comments** | ✅ Yes | ✅ Yes |
| **@Mentions** | ❌ No (no other users) | ✅ Tag team members |
| **Issue Assignments** | ❌ No | ✅ Assign to users |
| **Activity Feed** | ❌ No | ❓ Unknown (not documented) |
| **Notifications** | ✅ System announcements only | ✅ User activity notifications |
| **Email Notifications** | ❌ No | ❓ Unknown (not documented) |
| **Webhooks** | ❌ No | ❓ Unknown (not documented) |

---

### Customization & Configuration

| Feature | FREE Edition | PRO Edition |
|---------|-------------|-------------|
| **Themes** | ✅ Light + Dark | ✅ Light + Dark |
| **Localization** | ✅ English, Portuguese | ✅ English, Portuguese + more |
| **Custom Fields** | ❌ No | ✅ Yes (custom issue fields) |
| **Custom Workflows** | ❌ No | ✅ Custom status workflows |
| **Custom Issue Types** | ❌ No | ✅ Bug, Feature, Task, custom types |
| **API Access** | ❌ No public API | ❓ Unknown (likely yes) |

---

### Reporting & Analytics

| Feature | FREE Edition | PRO Edition |
|---------|-------------|-------------|
| **Time Reports** | ✅ Basic time reports | ✅ Advanced time reports |
| **CSV Export** | ✅ Time entries only | ✅ All data types |
| **Charts & Graphs** | ❌ No | ❓ Unknown (not documented) |
| **Burndown Charts** | ❌ No | ❓ Unknown (not documented) |
| **Velocity Tracking** | ❌ No | ❓ Unknown (not documented) |
| **Custom Reports** | ❌ No | ❓ Unknown (not documented) |

---

### Technical & Deployment

| Feature | FREE Edition | PRO Edition |
|---------|-------------|-------------|
| **Self-Hosted** | ✅ Docker only | ✅ Docker + manual install |
| **Cloud Hosted** | ❌ No | ✅ SaaS option available |
| **Database** | ✅ SQLite only | ❓ SQLite + PostgreSQL (likely) |
| **Backups** | ⚠️ Manual (volume copy) | ✅ Automated (likely) |
| **Updates** | ⚠️ Manual (Docker pull) | ✅ Auto-updates (cloud) |
| **Support** | ❌ Community/GitHub issues | ✅ Email support |
| **SLA** | ❌ No | ✅ Yes (cloud version) |

---

## FREE Edition Capabilities

### Complete Feature Set

The FREE edition is **fully functional** for single-user scenarios:

#### ✅ Included Features

**Project Management:**
- Unlimited projects
- Project templates (5 built-in)
- Archive/restore functionality
- Project-level time tracking toggle

**Issue Tracking:**
- Unlimited issues per project
- Rich markdown descriptions
- File attachments (unlimited size/count)
- Custom labels with colors
- Due dates
- Archive and finish states (separate)
- Comments

**Kanban Board:**
- Drag-and-drop issues
- Drag-and-drop column reordering
- Custom columns (groupings)
- Hidden columns
- Favorite labels for quick filtering
- Real-time updates (if multiple browser tabs open)

**Time Tracking:**
- Unlimited time entries
- Project and issue-level tracking
- Start/stop timers
- Multiple running timers simultaneously
- Time reports with filtering
- CSV export

**Focus Features:**
- Full Focus Space
- Pomodoro timer with 4 presets
- Custom timer intervals
- Ambient sounds (multiple tracks)
- Visual animated background
- Timer completion notifications

**User Experience:**
- Light and Dark themes
- English and Portuguese localization
- Responsive design (desktop, tablet, mobile)
- Guided tours for onboarding
- Keyboard shortcuts

**Data Management:**
- Full data ownership (self-hosted)
- SQLite database (portable)
- No external dependencies
- No cloud sync (isolated instance)

### ❌ Limitations (vs PRO)

**Single-User Only:**
- No user authentication system
- No multi-user collaboration
- No user assignment
- No @mentions
- No activity notifications

**Limited Visualizations:**
- One Kanban board per project
- No views as projections (dynamic grouping)
- No grid view
- No custom views

**No Advanced Customization:**
- No custom statuses (only archive/finish)
- No custom issue types
- No custom fields
- No workflow customization

**No Enterprise Features:**
- No SSO integration
- No API access
- No webhooks
- No advanced reporting

---

## PRO Edition Exclusive Features

### Based on README and Code Analysis

**Note:** PRO edition is closed-source. Features are based on documentation and marketing materials.

### 🌟 Major PRO Features

#### 1. Multi-User Support
**The Core PRO Differentiator**

- **Multiple User Accounts:** 2-100+ users per instance
- **Per-Project Permissions:**
  - Owner (full control)
  - Editor (can edit)
  - Viewer (read-only)
- **User Profiles:** Individual settings, avatars, preferences
- **User Activity Tracking:** Who did what, when

**Technical Implementation (Inferred):**
- Full authentication system (email/password)
- Session management
- Authorization layer (CanCanCan or Pundit likely)
- User-scoped queries throughout codebase

---

#### 2. Views as Projections
**Dynamic Issue Grouping**

Instead of static Kanban boards, PRO allows **dynamic grouping**:

**Group Issues By:**
- **Label:** All issues with "Bug" label in one column, "Feature" in another
- **Assignee:** Column per team member showing their assigned issues
- **Status:** Custom status columns (To Do, In Progress, Review, Done)
- **Custom Fields:** Any custom field can become a grouping dimension

**Benefits:**
- Multiple perspectives on same data
- No need to manually move issues
- Auto-updates when issue attributes change
- Switch between views instantly

**Example Use Cases:**
- **Sprint Planning View:** Group by status
- **Team Workload View:** Group by assignee
- **Bug Triage View:** Group by severity label
- **Client View:** Group by client label

**Technical Implementation (Inferred):**
```ruby
# PRO-only code (not in FREE)
class Visualization
  # FREE: type = "board" (static)
  # PRO: type = "projection" (dynamic)

  def grouping_field
    # :label, :assignee, :status, :custom_field_id
  end

  def groupings
    # Dynamically generated based on grouping_field
    # e.g., if grouping by assignee:
    #   - Column for each user assigned to project
    #   - Auto-create column when new user assigned
  end
end
```

---

#### 3. Grid View
**Spreadsheet-Style Issue Management**

**Features:**
- Rows = Issues
- Columns = Customizable fields (title, assignee, status, labels, due date, custom fields)
- Inline editing (click to edit any cell)
- Bulk operations (select multiple, bulk edit)
- Sorting by any column
- Filtering

**Benefits:**
- Power users prefer spreadsheet interface
- Bulk editing efficiency
- Data entry speed
- Export to CSV/Excel

**Technical Implementation (Inferred):**
- React DataGrid component (e.g., AG-Grid, React Table)
- Optimistic UI updates
- Batch API updates

---

#### 4. Custom Issue Statuses & Types

**Custom Statuses:**
- Define workflow states: "To Do → In Progress → Code Review → QA → Done"
- Status transitions (state machine)
- Status colors and icons
- Per-project or global

**Custom Issue Types:**
- Bug (red, bug icon)
- Feature (blue, star icon)
- Task (green, checkmark icon)
- Epic (purple, folder icon)
- Custom types...

**Benefits:**
- Match existing workflows
- Clear visual distinction
- Better reporting
- Workflow enforcement

**Technical Implementation (Inferred):**
```ruby
# PRO-only tables
create_table :issue_statuses do |t|
  t.string :name
  t.string :color
  t.integer :position
  t.references :project
end

create_table :issue_types do |t|
  t.string :name
  t.string :icon
  t.string :color
  t.references :project
end

# Issues table gains:
# - issue_status_id
# - issue_type_id
```

---

#### 5. SSO Authentication

**Supported Providers:**
- **Google Workspace:** OAuth 2.0
- **Microsoft Azure AD:** OAuth 2.0
- **GitHub:** OAuth 2.0
- **Custom OIDC:** Authentik, Okta, Auth0, Keycloak, etc.

**Benefits:**
- No password management
- Centralized user provisioning
- Enterprise security compliance
- Faster onboarding

**Technical Implementation (Inferred):**
- OmniAuth gem integration
- Devise + OmniAuth
- SAML support (possibly)

---

### 🔍 Inferred PRO Features

Based on codebase analysis and common patterns:

**Likely PRO Features (Not Explicitly Documented):**

1. **Issue Dependencies:** Link issues (blocks, blocked by)
2. **Issue Templates:** Pre-fill new issues
3. **Advanced Search:** Full-text search, saved filters
4. **Dashboards:** Customizable project dashboards
5. **Charts & Graphs:** Burndown, velocity, pie charts
6. **Email Notifications:** Issue updates, assignments, mentions
7. **Webhooks:** Integrate with Slack, Discord, etc.
8. **API Access:** RESTful API for integrations
9. **Custom Fields:** Add arbitrary fields to issues
10. **Time Budgets:** Project/issue time estimates
11. **Recurring Issues:** Automated issue creation
12. **Archive Search:** Search archived issues

---

## Technical Architecture Differences

### Database Schema Differences

**FREE Edition:**
```sql
-- Users table: Simple, single user expected
CREATE TABLE users (
  id, locale, timezone, favorite_theme_key
)

-- No user_id foreign keys on most tables
-- No permission tables
-- No authentication tables
```

**PRO Edition (Inferred):**
```sql
-- Users table: Full authentication
CREATE TABLE users (
  id, email, encrypted_password, ...
  -- Devise fields
)

-- User foreign keys everywhere
CREATE TABLE issues (
  ...
  assigned_user_id INTEGER REFERENCES users(id)
  created_by_user_id INTEGER REFERENCES users(id)
)

-- Permission tables
CREATE TABLE project_memberships (
  project_id, user_id, role
)

-- Custom fields tables
CREATE TABLE custom_fields (...)
CREATE TABLE custom_field_values (...)

-- Status and type tables
CREATE TABLE issue_statuses (...)
CREATE TABLE issue_types (...)
```

---

### Code Architecture Differences

**FREE Edition:**
- Simple, straightforward Rails app
- Minimal authorization (none really)
- Single database (SQLite)
- Limited customization points

**PRO Edition (Inferred):**
- Authorization layer (Pundit/CanCanCan)
- User scoping throughout
- Multi-database support (PostgreSQL)
- Plugin/extension system for custom fields
- Dynamic query building for projections
- Complex permissions logic

---

### Frontend Differences

**FREE Edition:**
- Simple board view
- Limited configuration options
- No advanced filtering UI

**PRO Edition (Inferred):**
- Grid view (React DataGrid)
- Projection configuration UI
- Advanced filter builders
- User assignment dropdowns
- Mention autocomplete
- Presence indicators ("User X is viewing this")

---

## Business Model Analysis

### Pricing Strategy

**FREE Edition:**
- **Cost:** $0 forever
- **Deployment:** Self-hosted only
- **Support:** Community (GitHub issues)
- **Updates:** Manual (Docker pull)

**PRO Edition - Self-Hosted:**
- **Cost:** Pay-once (one-time purchase)
  - Likely: $199-$999 depending on user count
  - Lifetime license for version X.x
  - Major version upgrades may require repurchase
- **Deployment:** Self-hosted (Docker or manual)
- **Support:** Email support included
- **Updates:** Free minor updates, paid major upgrades (likely)

**PRO Edition - Cloud:**
- **Cost:** Subscription or pay-once (unclear)
  - Likely: $10-25/user/month OR pay-once
- **Deployment:** Managed SaaS (eigenfocus.com)
- **Support:** Priority email support
- **Updates:** Automatic
- **SLA:** Uptime guarantee

---

### Competitive Positioning

**FREE Edition Competitors:**
- Trello (free tier)
- GitHub Projects (free)
- Notion (free tier)
- Taiga (open-source)

**FREE Edition Advantages:**
- Fully self-hosted (data ownership)
- No feature limitations (for single user)
- Focus features (Pomodoro, ambient sounds)
- No cloud lock-in

**PRO Edition Competitors:**
- Jira ($7.50-$14/user/month)
- Linear ($8/user/month)
- Asana ($10.99/user/month)
- ClickUp ($5-$19/user/month)

**PRO Edition Advantages:**
- Pay-once pricing (vs subscription fatigue)
- Self-hosted option (data privacy)
- Focus on simplicity (vs feature bloat)
- Fast performance (Rails + SQLite or PostgreSQL)

---

### Target Markets

**FREE Edition:**
- Solo developers and freelancers
- Students and hobbyists
- Personal project management
- Side projects and open-source maintainers
- Users evaluating for PRO upgrade

**PRO Edition - Self-Hosted:**
- Small agencies (5-20 people)
- Startups with privacy concerns
- Teams in regulated industries (HIPAA, GDPR)
- Companies with strict data policies
- Dev teams at larger companies

**PRO Edition - Cloud:**
- Small teams wanting simplicity (2-10 people)
- Non-technical teams
- Fast setup without IT involvement
- Teams without DevOps resources

---

## Upgrade Path

### Migration from FREE to PRO

**Self-Hosted PRO:**

**Option 1: Export/Import (Likely)**
1. Export data from FREE (CSV or database dump)
2. Install PRO edition
3. Import data into PRO
4. Configure users and permissions
5. Train team on new features

**Option 2: In-Place Upgrade (Ideal but Unlikely)**
1. Purchase PRO license
2. Stop FREE container
3. Start PRO container with same database volume
4. License activation
5. Database migration adds PRO tables
6. Configure users and permissions

**Challenges:**
- Database schema compatibility (FREE SQLite → PRO PostgreSQL?)
- User mapping (single FREE user → multiple PRO users)
- Data migration scripts not provided
- Manual process, documentation unclear

**Cloud PRO:**
- Likely manual export from FREE → import to cloud
- Or start fresh in cloud

---

### Decision Framework

**When to Use FREE:**
- ✅ Solo developer or freelancer
- ✅ Personal productivity tool
- ✅ No team collaboration needed
- ✅ Self-hosting capable
- ✅ Budget-conscious
- ✅ Data privacy critical (keep everything local)

**When to Upgrade to PRO:**
- ✅ Team of 2+ people
- ✅ Need user assignment and collaboration
- ✅ Complex workflows (custom statuses/types)
- ✅ Multiple project views needed
- ✅ SSO integration required
- ✅ Want advanced reporting
- ✅ Need vendor support

---

## Use Case Recommendations

### FREE Edition Use Cases

**1. Solo Freelancer**
- Manage multiple client projects
- Track billable hours
- Organize tasks with Kanban
- Use Focus Space for deep work
- Export time reports for invoicing

**2. Side Project Developer**
- Track personal project tasks
- Time investment tracking
- Simple bug tracking
- Feature planning

**3. Student**
- Coursework management
- Assignment tracking
- Study time tracking with Pomodoro
- Free tier forever

**4. Open-Source Maintainer**
- Issue triage (though GitHub Issues likely better)
- Personal roadmap planning
- Time tracking for contributions

---

### PRO Edition Use Cases

**1. Startup Development Team (5-10 people)**
- Sprint planning with custom statuses
- Issue assignment to developers
- Multiple board views (by assignee, by sprint, by priority)
- Time tracking per developer
- SSO with Google Workspace

**2. Design Agency (3-15 people)**
- Client projects with team collaboration
- Design issue types (mockup, revision, feedback)
- Client-facing vs internal views
- Time tracking for billing
- File attachments for designs

**3. Customer Support Team**
- Ticket tracking (custom issue types: bug, feature request, question)
- Assignment to support agents
- Status workflow (new → assigned → in progress → resolved)
- SLA tracking (due dates)
- Grid view for rapid triage

**4. Remote Software Team**
- Distributed team collaboration
- Real-time updates across timezones
- SSO for security
- Multiple project views for different roles
- Advanced reporting for stakeholders

**5. Regulated Industry (Healthcare, Finance)**
- Self-hosted for HIPAA/GDPR compliance
- Audit trail (who changed what)
- Custom fields for compliance tracking
- No cloud data exposure

---

## Conclusion

### FREE vs PRO Summary

**FREE Edition is ideal for:**
- Single users who need full-featured project management
- Users who value data ownership and self-hosting
- Budget-conscious individuals
- Users evaluating Eigenfocus before team adoption

**PRO Edition is necessary for:**
- Any team (2+ people)
- Organizations requiring user permissions
- Teams needing advanced visualizations
- Enterprises requiring SSO
- Users wanting vendor support

---

### Value Proposition

**FREE Edition Value:**
- **$0/year forever** vs competitors' $60-200/year for individual plans
- Full features, not a limited trial
- No artificial restrictions (unlimited projects, issues, time tracking)
- Data ownership and privacy

**PRO Edition Value:**
- **Pay-once** vs $500-1000+/year for team subscriptions
- Self-hosted option (competitors charge more for this)
- Simpler than enterprise tools (Jira complexity)
- Faster than bloated alternatives

---

### Recommendation

**For Individual Users:**
Eigenfocus FREE is an excellent choice, offering more features than most free tiers while maintaining complete data ownership.

**For Teams:**
Eigenfocus PRO provides strong value against subscription-based competitors, especially for teams seeking simplicity and pay-once pricing.

**Migration Path:**
Start with FREE for personal use. If your needs grow to require team collaboration, the PRO edition offers a clear upgrade path with familiar interface and workflows.

The FREE edition is not a crippled trial—it's a fully functional product that genuinely serves single-user needs while providing a low-risk evaluation path for potential PRO customers.
