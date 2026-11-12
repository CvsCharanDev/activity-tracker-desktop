# 🛠️ Real-World Engineering & Troubleshooting Log

During the development of this project, we encountered four real-world C++ and Qt engineering challenges. Documenting how we diagnosed and resolved each one demonstrates practical systems engineering capability.

---

## Issue 1: Application Exited Immediately with Code 1 on Startup

### 🔴 Symptom
Double-clicking or running `ActivityTracker.exe` caused the process to terminate within milliseconds with exit code `1`. No window appeared.

### 🔍 Root Cause Analysis
We ran the binary directly in a command prompt with console stderr capture:
```powershell
cmd /c "set QT_ASSUME_STDERR_HAS_CONSOLE=1 && ActivityTracker.exe 2>&1"
```
Output:
```text
QQmlApplicationEngine failed to load component
qrc:/ActivityTracker/qml/main.qml: No such file or directory
Failed to load QML: QUrl("qrc:/ActivityTracker/qml/main.qml")
```
- In Qt 6, `qt_add_qml_module` follows CMake policy **`QTP0001`**, which sets the default internal resource prefix to `:/qt/qml/`.
- The QML module named `ActivityTracker` was embedded at:
  `qrc:/qt/qml/ActivityTracker/qml/main.qml`
- But `main.cpp` was requesting:
  `qrc:/ActivityTracker/qml/main.qml` (missing `/qt/qml`).

### 🟢 Resolution
Updated `src/main.cpp`:
```cpp
const QUrl mainQml("qrc:/qt/qml/ActivityTracker/qml/main.qml");
```
The QML engine loaded the root window successfully.

---

## Issue 2: A Black Command Prompt (CLI) Window Opened Alongside the GUI

### 🔴 Symptom
When launching `ActivityTracker.exe`, a black Windows Command Prompt window opened first. If the user closed the command prompt, the entire desktop application closed.

### 🔍 Root Cause Analysis
- Windows executables (PE files) specify a **Subsystem** in their PE header:
  - `IMAGE_SUBSYSTEM_WINDOWS_CUI` (Console): Spawns a console window.
  - `IMAGE_SUBSYSTEM_WINDOWS_GUI` (GUI): Does not spawn a console window.
- In `CMakeLists.txt`, we initially had:
  ```cmake
  WIN32_EXECUTABLE $<CONFIG:Release>
  ```
  Because we were building in **Debug** mode (`--config Debug`), the generator expression evaluated to false. MSVC linked the executable with `/SUBSYSTEM:CONSOLE`.

### 🟢 Resolution
Changed `CMakeLists.txt` to enable `WIN32_EXECUTABLE` unconditionally:
```cmake
if(WIN32)
    set_target_properties(ActivityTracker PROPERTIES
        WIN32_EXECUTABLE ON
    )
endif()
```
Inspected the re-linked binary with `dumpbin /headers`:
```text
            6.00 subsystem version
               2 subsystem (Windows GUI)
```
The executable now launches directly into the Windows desktop with no terminal window.

---

## Issue 3: Editor Showed "Unknown type name 'QString'" & "Undeclared Identifier"

### 🔴 Symptom
The code compiled with zero errors using MSVC, but the IDE editor showed red squiggles on `QString`, `QGuiApplication`, and other Qt classes.

### 🔍 Root Cause Analysis
- Unlike JavaScript (where `package.json` and `node_modules` sit directly in the folder), C++ header files live in the installed toolchain (`C:\Qt\6.9.3\msvc2022_64\include`).
- The editor's C/C++ language server (IntelliSense / clangd) needs a **`compile_commands.json`** file to know all include directories and preprocessor definitions.
- Visual Studio project generators (`.vcxproj`) do not emit `compile_commands.json` by default.

### 🟢 Resolution
1. Ran CMake with Ninja generator to generate [`compile_commands.json`](file:///d:/CVS/9X/trading-desktop/ActivityTracker/compile_commands.json).
2. Added [`.vscode/c_cpp_properties.json`](file:///d:/CVS/9X/trading-desktop/ActivityTracker/.vscode/c_cpp_properties.json) referencing `compileCommands: "${workspaceFolder}/compile_commands.json"` and providing explicit fallback include paths for Qt 6.
3. Added automatic `CMAKE_PREFIX_PATH` fallback in [`CMakeLists.txt`](file:///d:/CVS/9X/trading-desktop/ActivityTracker/CMakeLists.txt) to automatically locate `C:/Qt/6.9.3/msvc2022_64`.
All editor squiggles were resolved.

---

## Issue 4: Activity Card Displayed Blank Name and "• 0 min"

### 🔴 Symptom
When a user added an activity, the list created a card, but the title was empty and duration showed `• 0 min` instead of the entered values.

### 🔍 Root Cause Analysis
In `ActivityListView.qml`, the delegate was defined as:
```qml
delegate: Components.ActivityCard {
    activityName: name
    activityDuration: durationMinutes
}
```
- In Qt 6 QML modules, unqualified model role access (e.g. `name` instead of `model.name`) inside delegate child instances is deprecated and does not resolve into scope.
- `name` evaluated to `undefined`, assigning an empty string `""`.
- `durationMinutes` evaluated to `undefined`, defaulting to `0`.

### 🟢 Resolution
Updated [`ActivityListView.qml`](file:///d:/CVS/9X/trading-desktop/ActivityTracker/qml/views/ActivityListView.qml) to use explicit `model.` prefixes:
```qml
delegate: Components.ActivityCard {
    activityName:      model.name
    activityCategory:  model.category
    activityDuration:  model.durationMinutes
    activityDone:      model.done
    activityIndex:     model.index
}
```
The card immediately displayed the correct title, category, and duration minutes.

---

## Issue 5: Linter False-Positives on Attached Properties and Context Objects (`.qmllint.ini`)

### 🔴 Symptom
When opening QML files in VS Code, the editor displayed multiple warnings:
- `Type Layout is used but it is not resolved [unresolved-type]`
- `Type Material is used but it is not resolved [unresolved-type]`
- `Unqualified access to context property 'activityService' [unqualified]`

### 🔍 Root Cause Analysis
- **Dynamic C++ Injection:** `activityService` and `activityModel` are injected dynamically at runtime via C++ (`rootContext()->setContextProperty(...)`). Static analyzers do not run C++ code, so they warn that the identifier is not defined inside the static QML file.
- **Attached Properties:** `Layout.*` (from `QtQuick.Layouts`) and `Material.*` (from `QtQuick.Controls.Material`) are attached property types, not standalone components. Without build-directory AST caches, the linter treats them as missing instantiations.

### 🟢 Resolution & Industry Best Practice
We created and committed `.qmllint.ini`:
```ini
[Warnings]
unqualified=disable
UnqualifiedAccess=disable
import=disable
Import=disable
ImportFailure=disable
unresolved-type=disable
UnresolvedType=disable
UnresolvedAttachedProperty=disable
```
- **Why keeping `.qmllint.ini` in Git is standard practice:** Just as frontend teams commit `.eslintrc.json` or `.prettierrc` so that every developer and CI pipeline runs with consistent code-quality rules, committing `.qmllint.ini` standardizes Qt linter behavior across all workstations and automated CI test runners.


---

## Issue 6: Qt 6 Delegate Required Properties Role Mapping (`(Untitled Activity)` & `0 min`)

### 🔴 Symptom
When adding activities or clicking quick-start templates, the cards rendered with `(Untitled Activity)`, `General`, and `0 min` instead of their actual name, category, and duration.

### 🔍 Root Cause Analysis
In Qt 6, when a custom delegate declares `required property`, Qt's QML engine alters data binding:
1. **Automated Role Matching:** Qt 6 searches the C++ model for roles with the exact same identifier as the required property.
2. If `ActivityCard.qml` declares `required property string activityName`, Qt 6 searches for a model role named `"activityName"`. Because the C++ `ActivityListModel::roleNames()` provides `"name"`, `"category"`, and `"durationMinutes"`, Qt 6 finds no match and initializes the required property to default values (`""`, `0`).
3. Furthermore, declaring `required property` disables legacy context object injection (`model.name`), rendering manual assignments inside the delegate null or unreactive.

### 🟢 Resolution & Best Practice
Aligned delegate property names to match C++ role names exactly:
```qml
// ActivityCard.qml
required property string name
required property string category
required property int    durationMinutes
required property bool   done
required property int    index
```
In `ActivityListView.qml`, Qt 6 directly and automatically populates these properties with zero boilerplate and full compile-time type safety.

---

## Issue 7: Multi-Platform CI/CD Workflow Failures (Windows & macOS)

### 🔴 Symptoms
The GitHub Actions workflow failed on both Windows and macOS runners:
1. **Windows:** `Error: The process 'C:\hostedtoolcache\windows\Python\3.15.2\x64\python.exe' failed with exit code 1`.
2. **Windows:** `ERROR: The packages ['qt_base'] were not found while parsing XML of package information!`.
3. **Windows:** `Generator Visual Studio 17 2022 could not find any instance of Visual Studio`.
4. **macOS:** `ld: framework 'AGL' not found` during linking `ActivityTracker.app`.
5. **CTest (Windows):** `Exit code 0xc0000135` (`STATUS_DLL_NOT_FOUND`).

### 🔍 Root Cause Analysis & Resolutions

1. **Python Toolcache Alpha Version:**
   * *Root Cause:* GitHub's runner image populated Python 3.15.2 alpha in `hostedtoolcache`. `jurplel/install-qt-action` defaulted to `setup-python: true`, discovering and crashing on Python 3.15 alpha.
   * *Fix:* Added `actions/setup-python@v5` with `python-version: '3.12'` and set `setup-python: false` in `install-qt-action`.
2. **Qt 6 Architecture Identifier Mismatch:**
   * *Root Cause:* In Qt 6 on Windows, the 64-bit MSVC package in `aqtinstall` is officially named `win64_msvc2022_64` (not `win64_msvc2022`).
   * *Fix:* Updated `arch: win64_msvc2022_64`.
3. **`windows-latest` Runner Version Drift:**
   * *Root Cause:* `windows-latest` migrated to preview `windows-2025` with Visual Studio 18/2026, where CMake could not locate Visual Studio 17 2022.
   * *Fix:* Pinned the runner explicitly to `windows-2022`.
4. **Obsolete Apple Carbon `AGL` Linker Dependency:**
   * *Root Cause:* Modern macOS (macOS 14/15/26 Apple Silicon) removed the deprecated Carbon `AGL.framework`. Qt 6.8's `FindWrapOpenGL.cmake` unconditionally linked `-framework AGL`.
   * *Fix:* In root `CMakeLists.txt`, pre-empted the finder by declaring `WrapOpenGL::WrapOpenGL` target with `-framework OpenGL` when `APPLE` is true.
5. **CTest Missing Qt DLLs on Windows (`0xc0000135`):**
   * *Root Cause:* The test executable `tst_ActivityModel.exe` was executed without Qt's `bin` directory in system `PATH`.
   * *Fix:* Added `set_tests_properties(tst_ActivityModel PROPERTIES ENVIRONMENT "PATH=$<TARGET_FILE_DIR:Qt6::Core>;$ENV{PATH}")` in `CMakeLists.txt`.

---

## Issue 8: Material Design Floating Placeholder Overlay Glitch

### 🔴 Symptom
In `TextField`, when focused or after typing, placeholder text did not disappear cleanly; it floated or remained overlayed on top of the user's typed text.

### 🔍 Root Cause Analysis
`QQuickStyle::setStyle("Material")` activates Material Design's mobile floating label animation. When a custom `background: Rectangle` with fixed container height and padding is used, the floating label cannot translate outside the container boundaries, causing it to render directly over the input text baseline.

### 🟢 Resolution & Modern Desktop Desktop Input Architecture
1. Set `placeholderText: ""` on the `TextField` to disable Material's internal floating label.
2. Embedded a custom smooth `Text` placeholder inside the container that softly dims on focus (`opacity: 0.35`) and instantly transitions to `0` opacity the moment any character is typed.
3. Added a dynamic Electric Blue focus halo, clear button (`✕`), and keyboard shortcut badge (`↵`).

---

## Issue 9: Cross-Platform Release Bundle Disparity — macOS (~133 MB) vs Windows (~34 MB)

### 🔴 Observation
The automated GitHub Actions release packaging produced artifacts of vastly different sizes:
* **Windows (`ActivityTracker-Windows-Release.zip`):** ~34.2 MB
* **macOS (`ActivityTracker-macOS-Release.zip`):** ~133.2 MB

Why is the macOS bundle nearly 4× larger than the Windows release for the exact same codebase?

### 🔍 Root Cause Analysis

1. **Universal 2 Dual-Architecture Mach-O Binaries (The #1 Factor):**
   * Modern Qt 6 builds for macOS (`clang_64` on GitHub Actions `macos-latest`) compile as **Universal Binaries (fat binaries)** containing two complete, independent machine code slices:
     * `arm64`: For Apple Silicon (M1, M2, M3, M4).
     * `x86_64`: For Intel-based Macs.
   * Every Qt framework dylib inside `ActivityTracker.app/Contents/Frameworks/` (`QtCore`, `QtGui`, `QtQuick`, `QtQml`, etc.) holds dual architecture slices, which immediately doubles the compiled binary size.
   * In contrast, the Windows build targets exclusively a single architecture (`win64_msvc2022_64`), needing only half the compiled bytes.

2. **Apple Framework Directory Structure vs Flat Windows DLLs:**
   * **Windows (`windeployqt`):** Extracts only flat, stripped `.dll` files (`Qt6Core.dll`, `Qt6Gui.dll`, etc.) directly into the application folder without wrapper directories.
   * **macOS (`macdeployqt`):** Assembles complete Apple `.framework` bundle directory hierarchies (`QtCore.framework/Versions/A/QtCore`, embedded `Info.plist` manifests, symlinks, localized string tables, and CodeResources signatures for Gatekeeper notarization).

3. **Debug Symbol Tables & Dynamic Relocation Overhead:**
   * **Windows (MSVC):** Release builds separate debug symbols into external `.pdb` files, which are excluded from the final release archive. The deployed DLLs contain no non-essential symbol tables.
   * **macOS:** Mach-O binaries retain dynamic symbol tables (`LC_SYMTAB`, `LC_DYSYMTAB`) required for Apple runtime dynamic linking, address space layout randomization (ASLR), and crash report stack unwinding.

4. **Self-Contained Sandboxed QML Runtime:**
   * `macdeployqt ... -qmldir=qml` bundles every Qt Quick plugin as an independent standalone bundle inside `ActivityTracker.app/Contents/PlugIns/` and links all secondary framework dependencies to ensure the `.app` executes on clean Macs without requiring a local Qt installation.

### 📊 Architecture Comparison Matrix

| Dimension | Windows Release (`windeployqt`) | macOS Release (`macdeployqt`) |
| :--- | :--- | :--- |
| **Target Architectures** | Single: `x86_64` | **Dual: `arm64` + `x86_64` (Universal 2)** |
| **Binary Format** | Windows PE (`.exe` + `.dll`) | Mach-O Fat Binary (`.framework` / `.dylib`) |
| **Metadata Overhead** | Minimal (flat folder) | High (Apple `.bundle`, `Info.plist`, signatures) |
| **Symbol Retention** | Zero (stripped; `.pdb` omitted) | Runtime symbol & relocation tables retained |
| **Compressed Archive** | **~34.2 MB** | **~133.2 MB** |

### 🟢 Production Optimization Strategies
If reducing the macOS archive footprint is desired in future releases:
1. **Thinning via `lipo`:** If targeting Apple Silicon exclusively, strip the Intel slice to reduce bundle size by ~45%:
   ```bash
   lipo -thin arm64 ActivityTracker.app/Contents/MacOS/ActivityTracker -output ActivityTracker.app/Contents/MacOS/ActivityTracker
   ```
2. **Mach-O Symbol Stripping:** Run `strip -S` on deployed frameworks to remove non-global symbol tables prior to notarization.
3. **Industry Standard Context:** 100–150 MB is the standard baseline for self-contained, notarizable Qt 6 desktop apps on macOS (e.g. Telegram Desktop, OBS Studio, Wireshark).

---

## Issue 10: Duplicate Signal Declaration on Aliased Properties (`[duplicated-name]`)

### 🔴 Symptom
Qt Creator and `qmllint` reported a static syntax warning in `ShadcnInput.qml`:
```text
Duplicated signal name "textChanged", "textChanged" is already a signal. [duplicated-name]
```

### 🔍 Root Cause Analysis
In QML, declaring an alias property (`property alias text: textField.text`) automatically generates a change notification signal named `textChanged` tied directly to the aliased target. When the component also declared an explicit `signal textChanged(string newText)`, it generated a duplicate signal collision in the QML engine's meta-object table.

### 🟢 Resolution
Removed the redundant explicit signal and the redundant `onTextChanged: textChanged(text)` bridge. Callers listen directly to the automatically propagated `onTextChanged` handler provided by the property alias.

---

## Issue 11: Scope Shadowing via `import "." as Components` (`[renamed-type]`)

### 🔴 Symptom
`SettingsModal.qml` emitted linter warnings:
```text
"ShadcnButton" is explicitly renamed to "Components.ShadcnButton" via a qmldir entry or QT_QML_SOURCE_TYPENAME CMake property. [renamed-type]
```

### 🔍 Root Cause Analysis
`SettingsModal.qml` already resided in `qml/components/`. At the top of the file, it executed `import "." as Components`. In Qt 6, importing the current directory under an explicit namespace qualifier causes the QML compiler to require all sibling types to be accessed through that qualifier (or warn of ambiguous shadowing).

### 🟢 Resolution
Removed `import "." as Components`. All sibling components (`ShadcnButton`, `ShadcnSelect`, `LucideIcon`) are natively in scope within the directory and are properly namespaced through the CMake QML module (`ActivityTracker 1.0`).

---

## Issue 12: Qt 6 QML Delegate Role Binding Failures (`required property`)

### 🔴 Symptom
In both `ActivityCard.qml` and `KanbanBoardView.qml`, activities failed to reflect active status changes (`"In Progress"` or priority changes). Cards remained locked in their default status (`"Created"` / `false`).

### 🔍 Root Cause Analysis
In Qt 6, `ListView` delegates consuming a C++ `QAbstractListModel` **only inject model roles into properties declared with `required property`**. 
- In `ActivityCard.qml`, `status`, `priority`, and `extensionCount` were declared as regular properties (`property string status: "Created"`), preventing Qt 6 from binding the `StatusRole` and `PriorityRole` from `ActivityListModel`.
- In `KanbanBoardView.qml`, the delegate omitted `required property` declarations entirely, falling back to unstable context lookups.

### 🟢 Resolution
Declared all model role properties as `required property` in both delegate files:
```qml
required property string name
required property string category
required property int    durationMinutes
required property bool   done
required property int    index
required property var    createdAt
required property string status
required property string priority
required property int    extensionCount
```
All role changes emitted by C++ `dataChanged()` signals now propagate reactively with zero lag.

---

## Issue 13: Mouse Event Hijacking in Kanban Drag & Drop vs Action Buttons

### 🔴 Symptom
Clicking **"Start"**, **"+15m"**, **"Done"**, **"Reopen"**, or **"Edit"** on a Kanban card was completely unresponsive; clicking them seemed to do nothing or randomly flickered.

### 🔍 Root Cause Analysis
The card background had a `MouseArea` for dragging that executed `dragProxy.visible = true` directly inside `onPressed`. Because `dragProxy` had `z: 99999` and matched the card's exact coordinates, pressing down on any button instantly spawned `dragProxy` directly under the cursor. The subsequent mouse release hit the drag proxy instead of the button below it, preventing button `TapHandler`s from ever completing a click.

### 🟢 Resolution
1. Added `drag.threshold: 8` and deferred `dragProxy.visible = true` to `onPositionChanged` (only when `drag.active` is true).
2. Wrapped card action buttons in their own `MouseArea { preventStealing: true }`, ensuring clicks execute their business logic immediately without ever triggering a card drag.

---

## Issue 14: QML Engine Initialization Crash (`Cannot assign to non-existent property "onAddRequested"`)

### 🔴 Symptom
Application crashed on startup with code 1:
```text
qrc:/qt/qml/ActivityTracker/qml/main.qml:1541:29: Cannot assign to non-existent property "onAddRequested"
Failed to load QML: QUrl("qrc:/qt/qml/ActivityTracker/qml/main.qml")
```

### 🔍 Root Cause Analysis
`main.qml` bound `onAddRequested` to both `mainListView` and `kanbanBoardView`. While `KanbanBoardView.qml` declared `signal addRequested()`, `ActivityListView.qml` had not declared the signal.

### 🟢 Resolution
Declared `signal addRequested()` in `ActivityListView.qml`, ensuring interface parity between the List and Kanban views.
