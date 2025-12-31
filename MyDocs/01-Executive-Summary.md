# Eigenfocus - Reverse Engineering Analysis
## Executive Summary

**Document Version:** 1.0
**Analysis Date:** December 31, 2025
**Application Version:** 1.4.1 FREE
**Analyzed By:** Reverse Engineering Analysis

---

## Project Overview

**Eigenfocus** is a self-hosted project management and time tracking web application built with a modern Ruby on Rails stack. The application follows a dual-version business model with a FREE edition (analyzed here) and a commercial PRO edition.

### Key Characteristics

- **Product Type:** Project Management & Time Tracking SaaS
- **Deployment Model:** Self-hosted via Docker
- **Business Model:** Freemium (FREE self-hosted + paid PRO upgrade)
- **License:** Source-available, proprietary (not open source)
- **Target Users:** Individual developers, small teams, freelancers
- **Current Version:** 1.4.1 (FREE edition)

### Technology Stack Summary

**Backend:**
- Ruby 3.4.7
- Rails 8.1.1 (latest framework features)
- SQLite3 2.1+ (multi-database setup)
- Puma web server
- Solid Queue (background jobs)
- Solid Cable (WebSocket connections)

**Frontend:**
- React 18.3.1 (islands architecture)
- Stimulus.js (primary JavaScript framework)
- Tailwind CSS 4.4
- Turbo Rails (SPA-like navigation)
- Shakapacker 8.4 (asset bundling)

**Infrastructure:**
- Docker containerized
- SQLite3 with volume persistence
- ActionCable for real-time updates
- ActiveStorage for file management

---

## Application Architecture

### Architectural Pattern
Eigenfocus employs a **hybrid server-rendered + React islands architecture**:

1. **Server-rendered baseline:** Rails views with ERB templates provide the core HTML structure
2. **React islands:** Complex interactive components (Focus Space, Markdown editor, label management) are React components mounted into the server-rendered DOM
3. **Stimulus controllers:** Handle simpler interactions (31 controllers for dropdowns, modals, drag-and-drop, etc.)
4. **Turbo Streams:** Enable real-time partial page updates without full page reloads
5. **ActionCable:** WebSocket channels for live collaborative features

This architecture optimizes for:
- Fast initial page loads (server-rendered)
- Rich interactivity where needed (React)
- Real-time updates (Turbo + ActionCable)
- Minimal JavaScript footprint for simple interactions (Stimulus)

### Database Architecture

The application uses **three separate SQLite databases**:
1. **Primary database** (`db/production.sqlite3`) - Core application data
2. **Cable database** (`db/production_cable.sqlite3`) - ActionCable subscriptions
3. **Queue database** (`db/production_queue.sqlite3`) - Solid Queue background jobs

This separation follows Rails 8 best practices for multi-database architectures.

---

## Core Features (FREE Edition)

### 1. Project Management
- Unlimited projects with templates (5 built-in templates)
- Project archival before deletion (safety mechanism)
- Project templates: Basic Kanban, Bug Tracking, Software Development, Customer Support, CRM

### 2. Issue Management
- Issues with markdown descriptions
- File attachments via ActiveStorage
- Custom labels with color coding
- Due dates and comments
- Archive and finish states (separate concepts)
- Forced archival before deletion (prevents accidental data loss)

### 3. Kanban Boards
- Visual drag-and-drop interface
- Customizable columns (groupings)
- Issue positioning within columns
- Collapsible/hidden columns
- Favorite labels for filtering
- Real-time updates via ActionCable

### 4. Time Tracking
- Project-level and issue-level time tracking
- Start/stop timers (running time entries)
- Time reports with CSV export
- Filtering by project and date range
- Real-time header updates for running timers

### 5. Focus Space
- **Pomodoro Timer:** Customizable work/break intervals with presets
- **Ambient Sounds Player:** Multiple ambient sounds for concentration
- **Animated Background:** Visual focus environment
- Integrated timer controls with state management
- Persistent state across sessions

### 6. User Experience
- Light and Dark themes with persistence
- Guided tours (app-tours library)
- Internationalization (English, Portuguese)
- Responsive design (Tailwind CSS)
- Markdown editor (Milkdown-based)

---

## PRO Edition Differences

Based on code analysis and README documentation, the PRO edition includes:

### PRO-Only Features (Not in FREE codebase)

1. **Multi-User Support**
   - Multiple user accounts
   - Per-project permission control
   - User authentication system

2. **Advanced Views**
   - Views as projections (dynamic grouping)
   - Group by: label, assignee, status
   - Multiple views per project
   - Grid view with customizable columns/rows

3. **Custom Fields**
   - Custom issue statuses
   - Custom issue types
   - Flexible field configuration

4. **Authentication**
   - SSO login (Google, Microsoft, GitHub)
   - Custom OIDC providers (Authentik, Okta)
   - Enterprise authentication support

### FREE Edition Limitations

The FREE edition is explicitly **single-user**:
- Only one user account in the database
- No authentication/login system (automatic single-user session)
- No user management interface
- No permission controls
- Single visualization type (board/Kanban only)
- No custom statuses or types

### Upgrade Mechanism

The FREE edition includes:
- **Upgrade modal** (`app/views/layouts/_upgrade_modal.html.erb`)
- **Upgrade button controller** with "shine animation" every 4 days
- Links to commercial PRO edition website
- No in-app purchase flow (external sales process)

---

## Target Use Cases

### FREE Edition Use Cases
1. **Solo Developer Projects:** Personal task tracking and time management
2. **Freelancers:** Client project management with time tracking
3. **Small Side Projects:** Hobby projects and personal productivity
4. **Learning/Education:** Students managing coursework
5. **Individual Focus Work:** Pomodoro technique practitioners

### PRO Edition Use Cases
1. **Small Teams:** 2-10 person development teams
2. **Agencies:** Client project management with team collaboration
3. **Startups:** Growing teams needing more structure
4. **Consultancies:** Multi-client work with team members
5. **Enterprise Departments:** Teams within larger organizations

---

## Security Considerations

### Authentication & Authorization
- **FREE:** No authentication system (single-user assumption)
- **Deployment Security:** Optional HTTP Basic Auth via environment variables
- **Network Security:** HTTPS enforcement via `FORCE_SSL` environment variable
- **Reverse Proxy Support:** `ASSUME_SSL_REVERSE_PROXY` for SSL termination scenarios

### Data Security
- **File Uploads:** Managed via ActiveStorage with blob storage
- **Input Sanitization:** Rails default XSS protection
- **SQL Injection:** ActiveRecord ORM prevents SQL injection
- **CSRF Protection:** Rails built-in CSRF tokens

### Deployment Security
- **Docker Isolation:** Containerized deployment
- **Volume Persistence:** SQLite databases in mounted volumes
- **No Default Credentials:** User creates account on first use

---

## Business Model Analysis

### Revenue Strategy
1. **FREE Edition:** Fully functional single-user version to drive adoption
2. **PRO Upgrade:** Pay-once model (not subscription) for team features
3. **Self-Hosted PRO:** One-time purchase for self-hosted deployments
4. **Cloud PRO:** Likely SaaS offering (mentioned in README)

### Market Positioning
- **Competitors:** Jira, Linear, Asana, Trello, ClickUp
- **Differentiation:**
  - Self-hosted option (privacy/control)
  - Pay-once pricing (vs. subscription fatigue)
  - Focus features (Pomodoro, ambient sounds)
  - Simplicity (vs. enterprise complexity)

### Growth Strategy
- **Viral Growth:** "Spread the word" messaging in README
- **Upgrade Prompts:** Periodic shine animation on upgrade button
- **Feature Gating:** Clear differentiation between FREE and PRO
- **Demo Availability:** Live PRO demo for evaluation

---

## Technical Debt & Architecture Decisions

### Strengths
1. **Modern Rails 8:** Leverages latest framework features (Solid Queue, Solid Cable)
2. **Clean Separation:** Controllers, models, services, components well-organized
3. **Real-time Updates:** Effective use of Turbo Streams and ActionCable
4. **Test Coverage:** Extensive RSpec tests (features, models, services, controllers)
5. **Component Architecture:** ViewComponent for reusable UI elements

### Potential Technical Debt
1. **SQLite Scalability:** May limit PRO edition growth without PostgreSQL option
2. **Single Visualization Type:** FREE edition locked to board view
3. **JavaScript Build Complexity:** Webpack + Shakapacker + React + Stimulus = complex asset pipeline
4. **Tight Coupling:** Some controllers are large with multiple responsibilities
5. **Migration Path:** No clear upgrade path from FREE to PRO self-hosted

### Architectural Trade-offs
1. **SQLite vs PostgreSQL:** Simplicity vs. scalability
2. **React Islands vs Full SPA:** Initial load speed vs. client-side state complexity
3. **Self-hosted vs Cloud:** User control vs. managed service revenue
4. **Monolith vs Microservices:** Development speed vs. scaling flexibility

---

## Deployment & Operations

### Docker Deployment
- **Base Image:** Ruby 3.4.7 with Node.js for asset compilation
- **Multi-stage Build:** Separate stages for dependencies, assets, and runtime
- **Volume Mounts:** `./app-data:/eigenfocus-app/app-data` for persistence
- **Port Mapping:** Internal 3000 → External 3001 (configurable)

### Environment Variables
- `DEFAULT_HOST_URL` - Application URL for email links and redirects
- `FORCE_SSL` - Enforce HTTPS (default: false)
- `ASSUME_SSL_REVERSE_PROXY` - Handle SSL termination at proxy (default: false)
- `HTTP_AUTH_USER` / `HTTP_AUTH_PASSWORD` - Optional basic auth

### Operational Considerations
- **Backup Strategy:** SQLite databases in `app-data` directory
- **Updates:** Pull new Docker image and restart container
- **Monitoring:** No built-in APM or logging (Docker logs only)
- **Scaling:** Single container, not horizontally scalable

---

## Conclusion

Eigenfocus FREE is a well-architected, modern Rails application that provides genuine value as a single-user project management tool. The codebase demonstrates:

- **High Code Quality:** Clean separation of concerns, extensive tests, modern patterns
- **Thoughtful UX:** Focus features, themes, guided tours, real-time updates
- **Strategic Product Design:** Clear upgrade path to PRO while FREE remains fully functional
- **Production Ready:** Containerized, documented, with deployment best practices

The FREE edition serves as both a standalone product and an effective marketing tool for the commercial PRO edition. The codebase is production-ready, maintainable, and demonstrates contemporary Rails best practices.

**Recommended Next Steps for Users:**
1. Evaluate FREE edition for single-user needs
2. Consider PRO edition for team collaboration
3. Review security requirements for deployment context
4. Plan backup strategy for SQLite databases
5. Test upgrade path if team features needed
