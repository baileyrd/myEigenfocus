# Frontend Architecture and Capabilities
## Detailed Reverse Engineering Analysis

**Document Version:** 1.0
**Last Updated:** December 31, 2025

---

## Table of Contents
1. [Frontend Architecture Overview](#frontend-architecture-overview)
2. [React Component System](#react-component-system)
3. [Stimulus Controller System](#stimulus-controller-system)
4. [Real-time Communication](#real-time-communication)
5. [Asset Pipeline](#asset-pipeline)
6. [User Interface Capabilities](#user-interface-capabilities)
7. [State Management](#state-management)
8. [Third-Party Libraries](#third-party-libraries)

---

## Frontend Architecture Overview

### Hybrid Architecture Pattern

Eigenfocus uses a **hybrid server-rendered + JavaScript islands architecture**:

```
┌─────────────────────────────────────────────────┐
│           Rails Server-Rendered Views           │
│                  (ERB Templates)                │
└────────────┬────────────────────────────────────┘
             │
             ├──> Turbo Drive (SPA-like navigation)
             │
             ├──> Turbo Frames (partial updates)
             │
             ├──> Turbo Streams (real-time updates)
             │
             ├──> React Islands (complex components)
             │    └─> FocusApp
             │    └─> MarkdownEditor
             │    └─> IssueLabels
             │
             └──> Stimulus Controllers (simple interactions)
                  └─> 31 controllers for modals, dropdowns, etc.
```

### Technology Stack Details

**Core Frameworks:**
- **React 18.3.1** - Component-based UI for complex interactions
- **Stimulus.js** - Rails default JavaScript framework for HTML-centric interactions
- **Turbo Rails** - Hotwire framework for SPA-like behavior without writing JavaScript
- **ViewComponent 4.1.1** - Server-side component system

**CSS Framework:**
- **Tailwind CSS 4.4** - Utility-first CSS framework
- **DaisyUI** - Tailwind component library (implied by class names)
- **Custom CSS** - Animations, themes, and specific component styles

**Build Tools:**
- **Shakapacker 8.4** - Webpack integration for Rails
- **Webpack 5** - Module bundler
- **Babel** - JavaScript transpilation
- **PostCSS** - CSS processing

---

## React Component System

### Component Architecture

React components are mounted into server-rendered DOM using a custom mounting system:

**Location:** `frontend/shared/dispatcher-hooks.js`

The system uses a `MutationObserver` to detect when React component markers appear in the DOM (via Turbo Frame updates) and automatically mounts the corresponding React components.

### Core React Components

#### 1. FocusApp Component
**File:** `frontend/components/FocusApp.js`

**Purpose:** Primary focus workspace with Pomodoro timer and ambient sounds

**Features:**
- Toggle button with sliding animation
- State indicators (sound playing, timer running, timer finished)
- Animated background when active
- Persistent state across navigation

**State Management:**
```javascript
- isFocusSpaceShowing: boolean (show/hide focus space)
- hasSoundPlaying: boolean (audio playback state)
- pomodoroState: enum (STOPPED, RUNNING, PAUSED, FINISHED)
```

**Sub-components:**
- `FocusSpace` - Main workspace container
- `AnimatedBackground` - Visual background effects
- `PomodoroTimer` - Timer functionality
- `AmbientSoundsPlayer` - Audio player system

**User Experience Details:**
- Floating button in corner with slide-out animation
- Visual indicators: bouncing dot (timer finished), pulsing icon (sound playing), hourglass (timer running)
- Smooth transitions between states
- Keyboard shortcut support (implied)

#### 2. PomodoroTimer Component System
**Location:** `frontend/components/FocusApp/PomodoroTimer/`

**Components:**
- `PomodoroTimer.js` - Main timer logic and state
- `TimerDisplay.js` - Visual countdown display
- `TimerControls.js` - Start, pause, reset buttons
- `TimerPresets.js` - Quick-start timer configurations
- `TimersSettingsModal.js` - Custom timer configuration

**Timer Presets** (`time_presets.js`):
```javascript
- Deep Work: 90 minutes work
- Classic Pomodoro: 25 minutes work, 5 minutes break
- Short Sprint: 15 minutes work, 3 minutes break
- Extended Focus: 50 minutes work, 10 minutes break
```

**Timer States:**
```javascript
POMODORO_STATE = {
  STOPPED: 'stopped',
  RUNNING: 'running',
  PAUSED: 'paused',
  FINISHED: 'finished'
}
```

**Custom Hooks:**
- `useAlarms.js` - Audio alarm system for timer completion

**Features:**
- Configurable work/break intervals
- Browser notification on completion
- Audio alarm (customizable sound)
- Pause/resume functionality
- Auto-start next phase option
- Visual progress indicator

#### 3. AmbientSoundsPlayer Component
**Location:** `frontend/components/FocusApp/AmbientSoundsPlayer/`

**Components:**
- `AmbientSoundsPlayer.js` - Main player logic
- `PlayList.js` - Sound selection list
- `PlayListItem.js` - Individual sound item
- `ControlBar.js` - Player controls (play/pause, volume)
- `PlayStopButton.js` - Toggle playback button
- `SoundWaveIcon.js` - Animated visual indicator

**Available Sounds** (`sounds.js`):
The system includes multiple ambient sounds for concentration:
- Nature sounds (rain, ocean waves, forest)
- White noise variations
- Cafe ambiance
- Focus music tracks

**Features:**
- Loop playback
- Volume control with persistence
- Visual playback indicator
- Smooth audio transitions
- Multiple simultaneous sounds (mixer capability)

#### 4. MarkdownEditor Component
**File:** `frontend/components/MarkdownEditor.js`

**Purpose:** Rich markdown editing for issue descriptions

**Library:** Milkdown (extensible markdown editor framework)

**Configuration Files:**
- `configure/menu.js` - Toolbar configuration
- `configure/image-block.js` - Image upload and display
- `configure/link-tooltip.js` - Link editing tooltip
- `configure/table-block.js` - Table editing support

**Features:**
- Live preview
- Image upload via drag-and-drop
- Link insertion with preview
- Table creation and editing
- Syntax highlighting for code blocks
- Keyboard shortcuts (Markdown shortcuts)
- Undo/redo functionality

**Markdown Support:**
- Headers (H1-H6)
- Bold, italic, strikethrough
- Lists (ordered, unordered, task lists)
- Code blocks with language detection
- Tables
- Links and images
- Blockquotes
- Horizontal rules

#### 5. IssueLabels Component System
**File:** `frontend/components/IssueLabels.js`

**Purpose:** Label management for issues

**Sub-components:**
- `IssueLabels/Badge.js` - Label display badge
- `IssueLabels/Dropdown.js` - Label selection dropdown
- `IssueLabels/Form.js` - Create/edit label form

**Features:**
- Color picker for label customization
- Real-time label creation
- Dropdown multi-select
- Inline editing
- Label search/filter

**Integration:**
- Communicates with Rails backend via Turbo Streams
- Updates issue cards in real-time
- Synchronizes across multiple views (board, table)

#### 6. IssueDetail/Description Component
**File:** `frontend/components/IssueDetail/Description.js`

**Purpose:** Issue description display and editing

**Features:**
- Inline editing toggle
- Markdown rendering
- Edit/save/cancel controls
- Auto-save on blur
- Real-time preview

---

## Stimulus Controller System

### Controller Architecture

Stimulus follows a **HTML-first approach** where controllers are attached to DOM elements via `data-controller` attributes.

**Location:** `app/javascript/controllers/`

**Total Controllers:** 31 controllers (20 found in search)

### Key Stimulus Controllers

#### 1. Sortable Controller
**File:** `app/javascript/controllers/sortable_controller.js`

**Purpose:** Drag-and-drop functionality for Kanban boards and lists

**Library:** SortableJS

**Features:**
- Drag-and-drop issue cards between columns
- Drag-and-drop column reordering
- Visual drag feedback
- Server persistence via AJAX
- Animation during drag operations

**Use Cases:**
- Kanban board issue positioning
- Column reordering
- Priority sorting in lists

#### 2. Modal Controller
**File:** `app/javascript/controllers/modal_controller.js`

**Purpose:** Modal dialog management

**Features:**
- Open/close animations
- Backdrop click to close
- ESC key to close
- Focus trap (accessibility)
- Multiple modals support
- Custom modal sizes

**Use Cases:**
- Issue creation forms
- Confirmation dialogs
- Settings panels
- Upgrade prompts

#### 3. Dropzone Controller
**File:** `app/javascript/controllers/dropzone_controller.js`

**Purpose:** File upload via drag-and-drop

**Library:** Dropzone.js

**Features:**
- Drag-and-drop file upload
- Multiple file support
- Upload progress indication
- File type validation
- Image preview
- Upload queue management

**Use Cases:**
- Issue file attachments
- Avatar uploads
- Bulk file uploads

#### 4. Markdown Controller
**File:** `app/javascript/controllers/markdown_controller.js`

**Purpose:** Markdown rendering and preview

**Library:** Marked.js

**Features:**
- Live markdown to HTML conversion
- Syntax highlighting
- Safe HTML rendering (XSS prevention)
- Custom link handling

#### 5. Form Controller
**File:** `app/javascript/controllers/form_controller.js`

**Purpose:** Enhanced form functionality

**Features:**
- Auto-submit on change
- Form validation
- Loading states
- Error display
- Dirty tracking (unsaved changes warning)

#### 6. Select2 Controller
**File:** `app/javascript/controllers/select2_controller.js`

**Purpose:** Enhanced select dropdowns

**Library:** Select2

**Features:**
- Search/filter options
- Multi-select
- Tag creation
- Remote data loading
- Custom rendering

**Use Cases:**
- Project selection
- Label selection
- User assignment (PRO)

#### 7. Theme Switcher Controller
**File:** `app/javascript/controllers/theme_switcher_controller.js`

**Purpose:** Light/dark theme toggling

**Features:**
- Theme persistence (localStorage)
- Smooth theme transitions
- System preference detection
- Multiple theme options

**Available Themes:**
- Light (default)
- Dark
- System (follows OS preference)

#### 8. Sidebar Controller
**File:** `app/javascript/controllers/sidebar_controller.js`

**Purpose:** Collapsible sidebar navigation

**Features:**
- Toggle open/close
- Responsive behavior
- State persistence
- Mobile overlay mode

#### 9. Grouping Column Controller
**File:** `app/javascript/controllers/grouping_column_controller.js`

**Purpose:** Kanban column (grouping) management

**Features:**
- Column collapse/expand
- Column hiding
- Issue count display
- Drag-and-drop integration

#### 10. Issue Detail Controller
**File:** `app/javascript/controllers/issue_detail_controller.js`

**Purpose:** Issue detail panel management

**Features:**
- Slide-in/out animations
- Keyboard shortcuts (close on ESC)
- URL state synchronization
- Auto-load on route change

#### 11. Issue Preview Controller
**File:** `app/javascript/controllers/issue_preview_controller.js`

**Purpose:** Quick issue preview on hover/click

**Features:**
- Tooltip-style preview
- Lazy loading
- Position calculation
- Click outside to close

#### 12. Clock Timer Controller
**File:** `app/javascript/controllers/clock_timer_controller.js`

**Purpose:** Running time entry display

**Features:**
- Real-time clock updates
- Format time display (HH:MM:SS)
- Start/stop integration
- Visual running indicator

#### 13. Color Input Controller
**File:** `app/javascript/controllers/color_input_controller.js`

**Purpose:** Color picker for labels

**Library:** Coloris

**Features:**
- Visual color picker
- Hex color input
- Preset colors
- Custom color creation

#### 14. Dependent Fields Controller
**File:** `app/javascript/controllers/dependent_fields_controller.js`

**Purpose:** Dynamic form field dependencies

**Features:**
- Show/hide fields based on selection
- Load dependent options via AJAX
- Cascading selects

**Use Cases:**
- Project → Issues dropdown
- Issue → Labels dropdown

#### 15. Closable Dropdown Controller
**File:** `app/javascript/controllers/closable_dropdown_controller.js`

**Purpose:** Dropdown menu management

**Features:**
- Click outside to close
- ESC key to close
- Position calculation
- Nested dropdowns support

#### 16. Copy Controller
**File:** `app/javascript/controllers/copy_controller.js`

**Purpose:** Copy text to clipboard

**Library:** Clipboard.js

**Features:**
- One-click copy
- Success feedback
- Fallback for older browsers

#### 17. Resizable Input Controller
**File:** `app/javascript/controllers/resizable_input_controller.js`

**Purpose:** Auto-growing textarea

**Features:**
- Expand on input
- Min/max height constraints
- Smooth transitions

#### 18. Animation Controller
**File:** `app/javascript/controllers/animation_controller.js`

**Purpose:** CSS animation triggers

**Features:**
- Scroll-based animations
- Entrance animations
- Intersection observer integration

#### 19. Alert Message Controller
**File:** `app/javascript/controllers/alert_message_controller.js`

**Purpose:** Flash message/notification display

**Features:**
- Auto-dismiss after timeout
- Manual dismiss
- Slide-in animations
- Multiple message types (success, error, info, warning)

#### 20. Upgrade to Pro Button Controller
**File:** `app/javascript/controllers/upgrade_to_pro_button_controller.js`

**Purpose:** Upgrade button with attention animation

**Features:**
- Shine animation every 4 days (localStorage tracking)
- Click tracking
- Modal trigger

---

## Real-time Communication

### Turbo Streams

**Purpose:** Server-initiated partial page updates

**Use Cases:**
1. **Issue Updates:** When an issue is updated, all viewers see the change immediately
2. **Time Entry Updates:** Running time entries update header in real-time
3. **Label Changes:** Label edits reflect immediately on all issue cards
4. **Board Updates:** Column changes broadcast to all viewers

**Broadcast Targets:**
- Issue cards on Kanban board
- Issue table rows
- Header time entry indicator
- Notification badges
- Sidebar project list

### ActionCable Channels

**WebSocket Channels for Live Updates:**

#### 1. Visualizations::AllocationsChannel
**Purpose:** Real-time issue movement on Kanban boards

**Events:**
- Issue moved between columns
- Issue position changed within column
- Issue created/deleted

**Subscription:**
```ruby
stream_for visualization
```

#### 2. Visualizations::GroupingsChannel
**Purpose:** Real-time column/grouping updates

**Events:**
- Column created/deleted
- Column renamed
- Column hidden/shown
- Column reordered

**Subscription:**
```ruby
stream_for visualization
```

### Real-time Update Flow

```
User Action (drag issue)
    ↓
Stimulus Controller (sortable)
    ↓
AJAX POST to server
    ↓
Rails Controller updates DB
    ↓
after_commit callback
    ↓
Turbo Stream broadcast
    ↓
ActionCable delivers to all subscribers
    ↓
Browser receives Turbo Stream
    ↓
DOM updated automatically (morphing)
    ↓
All viewers see change instantly
```

---

## Asset Pipeline

### Webpack Configuration

**Location:** `config/shakapacker.yml`

**Entry Points:**
- `frontend/packs/application.js` - Main application bundle

**Asset Organization:**
```
frontend/
  ├── components/          # React components
  │   ├── FocusApp.js
  │   ├── MarkdownEditor.js
  │   └── IssueLabels.js
  ├── packs/               # Webpack entry points
  │   └── application.js
  └── shared/              # Shared utilities
      └── dispatcher-hooks.js
```

### Build Process

**Development:**
1. `bin/dev` command runs:
   - Rails server (Puma)
   - CSS build (Tailwind watch mode)
   - JavaScript build (Webpack watch mode)

**Production:**
1. Assets precompiled during Docker build
2. Fingerprinted for caching
3. Served via Puma with static file middleware

### CSS Pipeline

**Tailwind CSS Build:**
- Source: `app/assets/stylesheets/application.tailwind.css`
- Build: Tailwind CLI (standalone binary)
- Output: `app/assets/builds/application.css`

**Custom CSS:**
- Animations for Focus Space
- Theme variables
- Component-specific styles
- Responsive utilities

---

## User Interface Capabilities

### Navigation System

**Primary Navigation:**
- Sidebar with project list
- Header with:
  - Project switcher
  - Time entry indicator
  - Focus Space toggle
  - Theme switcher
  - Notifications bell
  - User menu

**Turbo Drive Navigation:**
- Instant page transitions (no full reload)
- Progress bar during navigation
- Back/forward button support
- URL state management

### Responsive Design

**Breakpoints (Tailwind defaults):**
- sm: 640px
- md: 768px
- lg: 1024px
- xl: 1280px
- 2xl: 1536px

**Mobile Optimizations:**
- Collapsible sidebar
- Touch-friendly drag-and-drop
- Responsive tables → card view
- Bottom navigation for key actions
- Swipe gestures (where applicable)

### Theme System

**Implementation:**
- CSS variables for colors
- `data-theme` attribute on root element
- localStorage persistence
- System preference detection

**Theme Switching:**
```javascript
// Stimulus theme_switcher_controller.js
1. User clicks theme button
2. localStorage.setItem('theme', selectedTheme)
3. document.documentElement.setAttribute('data-theme', selectedTheme)
4. CSS variables update instantly
```

### Accessibility Features

**ARIA Support:**
- Proper landmark regions
- Form labels and descriptions
- Button roles and states
- Modal focus management
- Keyboard navigation

**Keyboard Shortcuts:**
- ESC to close modals/dropdowns
- Tab navigation
- Enter to submit forms
- Arrow keys for list navigation (implied)

---

## State Management

### Client-Side State

**React Component State:**
- Local state with `useState` hooks
- No global state management (Redux, etc.)
- Props drilling for parent-child communication

**LocalStorage Usage:**
1. Theme preference
2. Sidebar collapse state
3. Upgrade button shine timestamp
4. Time format preference

**SessionStorage Usage:**
- Minimal usage (implied)
- Possibly for tour progress

### Server-Side State

**Primary State Storage:**
- Database (SQLite)
- ActiveRecord models
- No client-side caching layer

**State Synchronization:**
- Turbo Streams for automatic sync
- ActionCable for real-time updates
- Optimistic UI updates (minimal)

---

## Third-Party Libraries

### JavaScript Libraries

**UI Components:**
- `select2` - Enhanced select dropdowns
- `sortablejs` - Drag-and-drop
- `dropzone` - File uploads
- `flatpickr` - Date picker
- `driver.js` - Guided tours
- `@melloware/coloris` - Color picker

**Utilities:**
- `marked` - Markdown parsing
- `clipboard.js` - Copy to clipboard
- `moment.js` - Date/time manipulation
- `fuse.js` - Fuzzy search
- `just-extend` - Object merging

**Icons:**
- `@tabler/icons-react` - React icon components
- `@fortawesome/fontawesome-free` - Font Awesome icons

**Rails/Hotwire:**
- `@hotwired/turbo-rails` - Turbo Drive/Frames/Streams
- `@hotwired/stimulus` - Stimulus framework
- `@rails/request.js` - AJAX request library
- `@rolemodel/turbo-confirm` - Confirmation dialogs

**React Ecosystem:**
- `react` - React library
- `react-dom` - React DOM rendering
- `@milkdown/core` - Markdown editor

### CSS Libraries

- **Tailwind CSS 4.4** - Utility-first CSS
- **DaisyUI** - Tailwind component library (implied by class patterns)

---

## Performance Optimizations

### Code Splitting

**Webpack Entry Points:**
- Main application bundle
- React components lazy-loaded (implied)
- Vendor libraries in separate chunk

### Asset Optimization

**Images:**
- Lazy loading with `loading="lazy"`
- Responsive images with `srcset`
- WebP format support (implied)

**Fonts:**
- System font stack as fallback
- Icon fonts preloaded

**JavaScript:**
- Minification in production
- Tree shaking for unused code
- Gzip compression

**CSS:**
- PurgeCSS via Tailwind (unused utilities removed)
- Minification in production

### Rendering Optimizations

**Server-Rendered Content:**
- Fast initial page load
- SEO-friendly HTML
- Progressive enhancement

**React Optimizations:**
- React.memo for expensive components (implied)
- useMemo/useCallback hooks (implied)
- Virtual DOM diffing

**Turbo Optimizations:**
- Partial page replacement (Turbo Frames)
- Morphing for minimal DOM changes
- Cached page snapshots

---

## Developer Experience

### Development Tools

**Development Server:**
```bash
bin/dev  # Runs all processes via Procfile.dev
```

**Hot Module Replacement:**
- Webpack HMR for JavaScript
- Tailwind watch mode for CSS
- Live reload on changes

**Debugging:**
- Browser DevTools support
- React DevTools extension compatible
- Stimulus debug mode (implied)

### Testing Frontend

**JavaScript Testing:**
- Jest test runner
- Happy DOM for DOM simulation
- React Testing Library (implied)

**Test Location:**
`frontend/components/*.test.js`

**Example:**
`frontend/components/HelloWorld.test.js`

---

## Conclusion

The Eigenfocus frontend demonstrates a modern, pragmatic approach to web application development:

1. **Server-rendered baseline** for fast initial loads and SEO
2. **React islands** for complex interactions requiring stateful components
3. **Stimulus controllers** for simpler DOM interactions
4. **Turbo** for SPA-like navigation without heavy JavaScript
5. **Real-time updates** via ActionCable for collaborative features

This hybrid architecture provides:
- Fast performance
- Progressive enhancement
- Maintainable codebase
- Excellent user experience
- Accessibility compliance

The frontend is production-ready with comprehensive features, thoughtful UX, and modern best practices throughout.
