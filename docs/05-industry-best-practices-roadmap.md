# 🚀 Desktop Industry Best Practices & Learning Roadmap

This document outlines the professional standards expected of commercial, production-grade desktop applications (such as Bloomberg Terminal, TradingView Desktop, Slack, VS Code), compared against our current progress in **CVS Activity Tracker**.

We will follow this roadmap to implement features **one by one on a daily basis**, tracking both learning and implementation progress.

---

## 📊 Feature & Best Practice Matrix

| Category | Industry Best Practice | Status in Project | Learning Goal / Qt Concept |
|---|---|---|---|
| **1. Branding & Design** | shadcn/ui inspired primitives, custom icons, dark/light theme | ✅ *Completed* | `QIcon`, vector SVGs, `MultiEffect` dynamic tinting |
| **2. Dual-View Workflow** | High-density List View & 3-stage interactive Kanban Board | ✅ *Completed* | Reactive `QAbstractListModel`, bidirectional Drag & Drop |
| **3. Window State** | Remembers window size, dock position, timeframe, and view mode | ✅ *Completed* | `QSettings` / `appSettings` persistent workstation state |
| **4. Live Filtering** | Multi-dimensional instant search, category, priority (P0-P3), and status | ✅ *Completed* | Reactive client-side filtering with live reactive count recalculations |
| **5. Keyboard Productivity** | Global shortcuts (`Ctrl+N`, `Ctrl+F`, `Ctrl+1` list, `Ctrl+2` board, `Ctrl+B`, `Ctrl+T`) | ✅ *Completed* | QML `Shortcut`, `Action`, keyboard navigation |
| **6. Enterprise Security** | Session management, remote session revocation, same-device dedup | ✅ *Completed* | `AuthService`, `UserSession`, crypto hashing |
| **7. Data Portability** | JSON persistence + Neon Serverless PostgreSQL cloud sync | ✅ *Completed* | `JsonStore`, REST/HTTP cloud synchronization |
| **8. Startup UX** | Native Splash Screen during boot with loading progress | ⏳ *Next Up* | `QSplashScreen`, asynchronous QML component loading |
| **9. System Tray** | Minimize to tray, background execution, and right-click context menu | ⏳ *Pending* | `QSystemTrayIcon`, `QMenu`, desktop lifecycle management |
| **10. Diagnostics** | Rotating log files in `%LOCALAPPDATA%\logs` for bug reports | ⏳ *Pending* | `qInstallMessageHandler`, custom logging patterns |
| **11. Packaging** | One-click Windows installer with Desktop & Start Menu shortcuts | 🔄 *CI Active* | Inno Setup / CPack, automated GitHub Actions release bundling |

---

## 🗓️ Step-by-Step Daily Implementation Plan

```
┌────────────────────────────────────────────────────────────────────────┐
│                        PHASE 1: BRANDING & STARTUP                     │
├────────────────────────────────┬───────────────────────────────────────┤
│ Milestone 1.1: Visual Identity │ • App Name: "CVS Activity Tracker"    │
│                                │ • Custom branded SVG & PNG Logo       │
│                                │ • Window icon & Taskbar badge         │
├────────────────────────────────┼───────────────────────────────────────┤
│ Milestone 1.2: Splash Screen   │ • Native QSplashScreen on launch      │
│                                │ • Shows loading progress & logo       │
│                                │ • Smooth fade-out to main window      │
└────────────────────────────────┴───────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                       PHASE 2: DESKTOP POLISH & UX                     │
├────────────────────────────────┬───────────────────────────────────────┤
│ Milestone 2.1: Window State    │ • Remembers x, y, width, height       │
│                                │ • Restores maximized state            │
│                                │ • Uses QSettings (%APPDATA% registry) │
├────────────────────────────────┼───────────────────────────────────────┤
│ Milestone 2.2: Live Filter/Sort│ • QSortFilterProxyModel implementation │
│                                │ • Search bar for instant filtering    │
│                                │ • Category tabs: All, Work, Learn, etc│
├────────────────────────────────┼───────────────────────────────────────┤
│ Milestone 2.3: Shortcuts       │ • Ctrl+N: Focus Add Activity input    │
│                                │ • Ctrl+F: Focus Search input          │
│                                │ • Esc: Clear input / filter           │
└────────────────────────────────┴───────────────────────────────────────┘
                                   │
                                   ▼
┌────────────────────────────────────────────────────────────────────────┐
│                  PHASE 3: ENTERPRISE & DATA MANAGEMENT                 │
├────────────────────────────────┬───────────────────────────────────────┤
│ Milestone 3.1: System Tray     │ • Minimize to Tray on close           │
│                                │ • Tray notifications when goals met   │
│                                │ • Right-click menu (Show, Add, Exit)  │
├────────────────────────────────┼───────────────────────────────────────┤
│ Milestone 3.2: Export / Import │ • Native QFileDialog for saving CSV   │
│                                │ • Export timesheet for manager review │
│                                │ • Backup & Restore JSON files         │
├────────────────────────────────┼───────────────────────────────────────┤
│ Milestone 3.3: Production Logs │ • qInstallMessageHandler              │
│                                │ • Logs errors to rotating text file   │
└────────────────────────────────┴───────────────────────────────────────┘
```

---

## 🎯 Detail of Key Best Practices

### 1. Application Branding & Window Icons
- **What it is:** Professional software never shows a generic blank window icon on the Windows taskbar or in the titlebar.
- **Why it matters:** Establishes credibility, recognizable identity, and a polished appearance.
- **Qt mechanism:** 
  - `app.setWindowIcon(QIcon(":/qt/qml/ActivityTracker/resources/icons/app_icon.svg"));`
  - Windows `.rc` resource file for embedding the `.ico` icon into the `.exe` file in File Explorer.

### 2. Native Splash Screen (`QSplashScreen`)
- **What it is:** A lightweight branded image displayed while the application initializes databases, loads plugins, or prepares QML caches.
- **Why it matters:** On cold boot, users see immediate visual feedback within 50ms rather than waiting in silence.
- **Qt mechanism:** `QSplashScreen splash(pixmap); splash.show(); ... splash.finish(&mainWindow);`

### 3. Window Geometry & State Persistence (`QSettings`)
- **What it is:** If the user moves the window to a secondary monitor or resizes it to 1200x800, it should reopen in that exact location next time.
- **Why it matters:** Standard expectation for all professional desktop software.
- **Qt mechanism:**
  - On Close: `settings.setValue("geometry", saveGeometry());`
  - On Open: `restoreGeometry(settings.value("geometry").toByteArray());`

### 4. `QSortFilterProxyModel` (C++ Filtering & Sorting)
- **What it is:** A specialized Qt model that wraps your raw `ActivityListModel` to provide sorting (by date, duration, name) and filtering (by category or search text) **without altering the underlying data**.
- **Why it matters:** Super-fast $O(1)$ updates without rebuilding arrays or re-reading disk.

### 5. System Tray & Background Running (`QSystemTrayIcon`)
- **What it is:** An icon in the bottom-right Windows notification area. Clicking `X` minimizes the app to the tray instead of terminating it, keeping your active time tracking alive.

---

*We will proceed with Milestone 1.1 immediately: Renaming the application to **CVS Activity Tracker**, adding the application logo to the header and window icon, and verifying the updated build.*

