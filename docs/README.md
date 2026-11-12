# 📚 CVS Activity Tracker — Engineering Documentation

Welcome to the technical documentation for **CVS Activity Tracker**, built with C++17, Qt 6, QML, and Neon Serverless PostgreSQL.

## 📑 Documentation Index

1. [**01-architecture-and-analogies.md**](01-architecture-and-analogies.md)
   - High-level architecture (The Restaurant Analogy)
   - The JavaScript/React to C++/Qt dictionary
   - Why C++17 and Qt 6 were selected
   - Data flow walkthrough

2. [**02-code-walkthrough.md**](02-code-walkthrough.md)
   - Detailed file-by-file inspection
   - Structs, references, and memory safety
   - `QAbstractListModel` virtualized data binding
   - `Q_OBJECT`, `Q_PROPERTY`, and `Q_INVOKABLE`
   - QML layouts and modern design tokens

3. [**03-how-to-explain-in-interview.md**](03-how-to-explain-in-interview.md)
   - 60-second elevator pitch
   - Top interview questions and sharp answers
   - Live demonstration checklist

4. [**04-engineering-troubleshooting-log.md**](04-engineering-troubleshooting-log.md)
   - Debugging real-world Qt 6 issues
   - Resource prefixes and `QTP0001`
   - Windows Subsystems (GUI vs Console)
   - IntelliSense and `compile_commands.json`
   - QML delegate required property role resolution in Qt 6 (`(Untitled Activity)` fix)
   - Multi-Platform CI/CD workflow engineering (Python 3.15 alpha override, MSVC `win64_msvc2022_64`, macOS Carbon `AGL` linker workaround, CTest DLL path injection)
   - Material Design mobile floating label overlay resolution on desktop containers
   - Duplicate signal declaration on aliased properties (`[duplicated-name]`)
   - QML directory namespace scope collisions (`import "." as Components`)
   - Qt 6 QML delegate role binding failures (`status`, `priority`, `extensionCount`) in dual views
   - Mouse event hijacking in Kanban Drag & Drop vs action button clicks
   - Cross-view QML signal parity resolution (`addRequested`)

5. [**05-industry-best-practices-roadmap.md**](05-industry-best-practices-roadmap.md)
   - Commercial desktop standards matrix
   - Status tracking across Branding, Dual-View Workflow, Window State, Live Filtering, Enterprise Security, Data Portability, System Tray, and Packaging
   - Interactive Kanban Board (Todo, In Progress, Completed) with bidirectional drag & drop
   - Modern shadcn/ui design tokens and P0-P3 concise priority system

6. [**06-v2-architecture-auth-and-neon-db.md**](06-v2-architecture-auth-and-neon-db.md)
   - Complete multi-screen architecture with `StackView`
   - Authentication engine (`LoginView`, `SignUpView`, `ForgotPasswordView`, `AuthService`, SHA-256 hashing, session tokens, Quick Demo mode)
   - Neon Serverless PostgreSQL cloud integration (`users` and `activities` multi-user schema, async background worker thread, hybrid offline JSON fallback)
   - Interactive Live Focus Timer (Pomodoro countdown, progress ring, category glow, completion celebration)
   - Productivity Power Toolbar (Multi-criteria sorting, `🧹 Clear Done`, `📋 Export Daily Standup Summary` to clipboard)
   - Analytics & Productivity Forecast ("Finish by 5:45 PM" dynamic engine, Focus Streak tracking)
