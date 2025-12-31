# Eigenfocus Reverse Engineering Analysis
## Complete Documentation Package

**Analysis Date:** December 31, 2025
**Application Version:** 1.4.1 FREE
**Documentation Version:** 1.0

---

## 📚 Document Index

This documentation package contains a comprehensive reverse engineering analysis of the Eigenfocus FREE edition codebase.

### Documents in This Package

1. **[00-README.md](00-README.md)** *(This file)*
   Quick reference guide and documentation index

2. **[01-Executive-Summary.md](01-Executive-Summary.md)**
   High-level overview, technology stack, architecture summary, business model analysis

3. **[02-Frontend-Architecture-And-Capabilities.md](02-Frontend-Architecture-And-Capabilities.md)**
   React components, Stimulus controllers, real-time system, asset pipeline, UI capabilities

4. **[03-Backend-Architecture-And-API.md](03-Backend-Architecture-And-API.md)**
   Database schema, models, controllers, services, background jobs, API endpoints

5. **[04-Free-vs-Pro-Version-Differences.md](04-Free-vs-Pro-Version-Differences.md)**
   Feature comparison matrix, upgrade analysis, use case recommendations

---

## 🎯 Quick Reference

### What is Eigenfocus?

**Eigenfocus** is a self-hosted project management and time tracking web application built with Ruby on Rails 8. It offers:

- **FREE Edition:** Fully functional single-user project management (this codebase)
- **PRO Edition:** Commercial multi-user version with team collaboration features

### Technology Stack (FREE Edition)

**Backend:**
- Ruby 3.4.7
- Rails 8.1.1
- SQLite3 (3 separate databases)
- Puma web server
- Solid Queue (background jobs)
- Solid Cable (WebSocket)

**Frontend:**
- React 18.3.1 (islands architecture)
- Stimulus.js (31 controllers)
- Tailwind CSS 4.4
- Turbo Rails (Hotwire)
- Shakapacker 8.4

**Infrastructure:**
- Docker containerized
- ActiveStorage (file uploads)
- ActionCable (real-time updates)

---

## 📊 Core Features Summary

### FREE Edition Features

✅ **Project Management**
- Unlimited projects with 5 built-in templates
- Archive/restore functionality
- Kanban boards with drag-and-drop

✅ **Issue Tracking**
- Unlimited issues with markdown descriptions
- File attachments, labels, due dates, comments
- Archive and finish states

✅ **Time Tracking**
- Project and issue-level time tracking
- Start/stop timers
- Time reports with CSV export

✅ **Focus Space**
- Pomodoro timer (4 presets + custom)
- Ambient sounds player
- Animated background

✅ **User Experience**
- Light/Dark themes
- English & Portuguese localization
- Responsive design
- Guided tours

### FREE Edition Limitations

❌ **Single-user only** (no multi-user collaboration)
❌ **No user authentication** (automatic single-user session)
❌ **No advanced views** (grid view, projections)
❌ **No custom statuses/types** (only archive/finish)
❌ **No SSO integration**
❌ **No API access**

---

## 🏗️ Architecture Overview

### Hybrid Frontend Architecture

```
Server-Rendered Views (ERB)
    ↓
Turbo Drive (SPA navigation)
    ↓
┌───────────────────┬────────────────────┐
│   React Islands   │ Stimulus Controllers│
│  (Complex UI)     │  (Simple interactions)│
├───────────────────┼────────────────────┤
│ - FocusApp        │ - Modal            │
│ - MarkdownEditor  │ - Sortable         │
│ - IssueLabels     │ - Dropzone         │
└───────────────────┴────────────────────┘
    ↓
ActionCable (Real-time updates)
```

### Database Architecture

**Three SQLite Databases:**
1. **Primary** - Application data (users, projects, issues, time entries)
2. **Cable** - ActionCable subscriptions
3. **Queue** - Solid Queue background jobs

### Key Design Patterns

- **MVC Architecture** - Rails convention-over-configuration
- **Service Objects** - Business logic extraction (template applier, example creator)
- **ViewComponents** - Reusable UI components
- **Turbo Streams** - Real-time partial page updates
- **ActiveRecord Callbacks** - Model lifecycle hooks
- **Scopes** - Reusable query patterns

---

## 📁 Codebase Structure

```
eigenfocus/
├── app/
│   ├── assets/              # CSS, images
│   ├── channels/            # ActionCable channels (2 files)
│   ├── components/          # ViewComponents
│   ├── controllers/         # Rails controllers (20 files)
│   ├── helpers/             # View helpers
│   ├── javascript/          # Stimulus controllers (31 files)
│   ├── jobs/                # Background jobs (4 files)
│   ├── models/              # ActiveRecord models (15 files)
│   ├── services/            # Business logic services
│   └── views/               # ERB templates
├── config/
│   ├── locales/             # i18n translations (en, pt-BR)
│   ├── project_templates/   # 5 YAML templates
│   └── routes.rb            # URL routing
├── db/
│   ├── migrate/             # Database migrations (20+ files)
│   └── schema.rb            # Database schema
├── frontend/
│   ├── components/          # React components (FocusApp, etc.)
│   ├── packs/               # Webpack entry points
│   └── shared/              # Shared utilities
├── spec/                    # RSpec tests
├── Dockerfile               # Production Docker image
└── docker-compose.yml       # Docker Compose config
```

---

## 🗃️ Database Schema Quick Reference

### Core Tables

**users** (1 row in FREE edition)
- `id`, `locale`, `timezone`, `favorite_theme_key`

**projects**
- `id`, `name`, `archived_at`, `time_tracking_enabled`
- Relations: has_many issues, visualizations, time_entries, issue_labels

**issues**
- `id`, `title`, `description`, `project_id`, `archived_at`, `finished_at`, `due_date`
- Relations: belongs_to project, has_many comments, labels, time_entries, files

**visualizations** (Kanban boards)
- `id`, `type`, `project_id`, `favorite_issue_labels`
- Relations: belongs_to project, has_many groupings

**groupings** (Kanban columns)
- `id`, `title`, `visualization_id`, `position`, `hidden`
- Relations: belongs_to visualization, has_many issues (through allocations)

**time_entries**
- `id`, `project_id`, `user_id`, `issue_id`, `total_logged_time_in_minutes`, `started_at`, `reference_date`
- `started_at IS NOT NULL` = running timer

**issue_labels**
- `id`, `title`, `project_id`, `hex_color`

**issue_comments**
- `id`, `content`, `issue_id`, `author_id`

---

## 🌐 API Endpoints Quick Reference

### Projects
```
GET    /projects
POST   /projects
PUT    /projects/:id/archive
PUT    /projects/:id/unarchive
```

### Issues
```
GET    /p/:project_id/issues
POST   /p/:project_id/issues
PATCH  /issues/:id/update_description
PUT    /issues/:id/archive
PUT    /issues/:id/finish
```

### Time Entries
```
GET    /time_entries
POST   /time_entries
PUT    /time_entries/:id/start
PUT    /time_entries/:id/stop
```

### Visualizations (Kanban)
```
GET    /v/:id                    # Show board
GET    /v/:id/i/:issue_id        # Show board with issue detail
PATCH  /v/:id                    # Update favorite labels
```

### Reports
```
GET    /reports/total_time       # Time report (HTML)
GET    /reports/total_time.csv   # Time report (CSV)
```

*Note: All endpoints return HTML/Turbo Stream responses (no JSON API)*

---

## 🔄 Real-time System

### ActionCable Channels

**Visualizations::AllocationsChannel**
- Broadcasts: Issue movement, position changes
- Subscription: Per visualization

**Visualizations::GroupingsChannel**
- Broadcasts: Column created/renamed/deleted/reordered
- Subscription: Per visualization

### Turbo Streams

Automatic broadcasts on model updates:
- Issue updates → broadcast to Kanban board
- Time entry changes → broadcast to header
- Label changes → broadcast to issue cards

---

## 🎨 Frontend Components

### React Components

1. **FocusApp** - Main focus workspace
   - PomodoroTimer - Timer with presets
   - AmbientSoundsPlayer - Audio player
   - AnimatedBackground - Visual effects
   - FocusSpace - Container component

2. **MarkdownEditor** - Milkdown-based editor
   - Image uploads
   - Link tooltips
   - Table editing
   - Syntax highlighting

3. **IssueLabels** - Label management
   - Color picker
   - Dropdown multi-select
   - Inline creation

### Stimulus Controllers (31 total)

**Key Controllers:**
- `sortable_controller.js` - Drag-and-drop
- `modal_controller.js` - Modal dialogs
- `dropzone_controller.js` - File uploads
- `markdown_controller.js` - Markdown rendering
- `theme_switcher_controller.js` - Theme toggle
- `clock_timer_controller.js` - Running time display
- `upgrade_to_pro_button_controller.js` - Upgrade prompts

---

## 🔐 Security Notes

### Authentication & Authorization

**FREE Edition:**
- ❌ No authentication system
- ❌ No authorization layer
- ⚠️ Single-user assumption (security by obscurity)
- ✅ Optional HTTP Basic Auth (via env vars)

**Security Features:**
- ✅ CSRF protection (Rails default)
- ✅ XSS prevention (ERB auto-escaping)
- ✅ SQL injection prevention (ActiveRecord)
- ✅ HTTPS enforcement (configurable)
- ✅ Security headers (X-Frame-Options, etc.)

**Deployment Security:**
- Use `HTTP_AUTH_USER` / `HTTP_AUTH_PASSWORD` for network-level protection
- Enable `FORCE_SSL=true` for HTTPS
- Deploy behind reverse proxy (Nginx, Caddy) for SSL termination

---

## 🚀 Deployment

### Docker Deployment

**Quick Start:**
```bash
docker run \
    --restart unless-stopped \
    -v ./app-data:/eigenfocus-app/app-data \
    -p 3001:3000 \
    -e DEFAULT_HOST_URL=http://localhost:3001 \
    -d \
    eigenfocus/eigenfocus:1.4.1-free
```

**Environment Variables:**
- `DEFAULT_HOST_URL` - Application URL (required)
- `FORCE_SSL` - Enforce HTTPS (default: false)
- `ASSUME_SSL_REVERSE_PROXY` - SSL termination at proxy (default: false)
- `HTTP_AUTH_USER` - Basic auth username (optional)
- `HTTP_AUTH_PASSWORD` - Basic auth password (optional)

**Data Persistence:**
- All data in `./app-data/` directory
- Contains 3 SQLite databases + uploaded files
- Backup strategy: Copy `app-data` directory

---

## 📈 Business Model

### FREE Edition
- **Cost:** $0 forever
- **Users:** Single user only
- **Support:** Community (GitHub issues)
- **Updates:** Manual (Docker pull)

### PRO Edition
- **Cost:** Pay-once (estimated $199-$999)
- **Users:** Multiple with permissions
- **Features:** SSO, grid view, projections, custom fields
- **Support:** Email support
- **Deployment:** Self-hosted or Cloud SaaS

### Upgrade Decision
- Use FREE for: Solo developers, freelancers, personal projects
- Upgrade to PRO for: Teams (2+ people), advanced workflows, SSO

---

## 🎯 Key Findings

### Strengths

1. **Modern Architecture:** Rails 8, React 18, Tailwind 4 (latest versions)
2. **Clean Code:** Well-organized, conventional Rails patterns
3. **Real-time Features:** Effective use of Turbo + ActionCable
4. **Genuine FREE Tier:** No artificial limitations for single users
5. **Focus Features:** Unique Pomodoro + ambient sounds integration
6. **Production Ready:** Comprehensive tests, Docker deployment, documentation

### Limitations

1. **Single-user Only:** Not collaborative (by design)
2. **SQLite Only:** May limit scalability for PRO edition
3. **No Public API:** Limited integration possibilities
4. **Manual Migration:** FREE → PRO upgrade path unclear

### Technical Debt

1. **JavaScript Build Complexity:** Webpack + Shakapacker + React + Stimulus
2. **Tight Coupling:** Some controllers have multiple responsibilities
3. **Limited Extensibility:** No plugin system for custom features

---

## 📖 How to Use This Documentation

### For Developers
1. Start with **Executive Summary** for overview
2. Read **Backend Architecture** for database and API details
3. Study **Frontend Architecture** for UI implementation
4. Reference specific sections as needed during development

### For Business Analysts
1. Read **Executive Summary** for business context
2. Focus on **Free vs Pro Differences** for feature comparison
3. Review use cases and recommendations

### For Security Auditors
1. Check security sections in **Backend Architecture**
2. Review authentication/authorization details
3. Examine deployment configuration options

### For Users Evaluating Eigenfocus
1. Start with **Free vs Pro Differences**
2. Review feature lists and use cases
3. Assess upgrade decision framework

---

## 🔍 Additional Resources

### Official Resources
- **Website:** https://eigenfocus.com
- **GitHub:** https://github.com/Eigenfocus/eigenfocus
- **Docker Hub:** eigenfocus/eigenfocus
- **PRO Demo:** https://pro-demo.eigenfocus.com

### Documentation Files
- `README.md` - Official project README
- `docs/README.md` - Development setup guide
- `LICENSE` - Source-available license terms

### Internal Documentation
- `config/routes.rb` - Complete route definitions
- `db/schema.rb` - Full database schema
- `spec/` - RSpec tests (usage examples)

---

## 📝 Analysis Methodology

This reverse engineering analysis was conducted through:

1. **Static Code Analysis:** Reading all Ruby, JavaScript, ERB files
2. **Database Schema Analysis:** Understanding data model from migrations and schema
3. **Dependency Analysis:** Examining Gemfile and package.json
4. **Configuration Analysis:** Reviewing config files, Docker setup
5. **Documentation Review:** README, comments, inline documentation
6. **Pattern Recognition:** Identifying architectural patterns and conventions
7. **Comparative Analysis:** Inferring PRO features from FREE codebase gaps

**No Dynamic Analysis Performed:**
- Application was not run or debugged
- No runtime behavior observed
- Analysis based purely on source code examination

---

## ⚖️ Legal Notice

This documentation is an independent reverse engineering analysis of the Eigenfocus FREE edition source code for educational and evaluation purposes.

**Important:**
- Eigenfocus is **source-available, not open source**
- PRO edition is **commercial, closed-source**
- Code may not be redistributed or modified without permission
- See LICENSE file in repository for terms
- PRO feature descriptions are based on public documentation and inference

**Disclaimer:**
This analysis is provided "as is" without warranty. PRO edition features are inferred and may be inaccurate. Always consult official Eigenfocus documentation for authoritative information.

---

## 🏁 Conclusion

Eigenfocus FREE is a well-architected, production-ready Rails 8 application that demonstrates:

- ✅ Modern web development best practices
- ✅ Clean, maintainable codebase
- ✅ Thoughtful user experience design
- ✅ Effective hybrid frontend architecture
- ✅ Strategic product positioning

**For single users:** FREE edition provides genuine value as a standalone product

**For teams:** PRO edition offers clear upgrade path with compelling features

The codebase quality, architectural decisions, and feature completeness make Eigenfocus a strong example of contemporary Rails application development.

---

**End of Documentation Package**

*Generated: December 31, 2025*
*Analysis Version: 1.0*
*Eigenfocus Version: 1.4.1 FREE*
