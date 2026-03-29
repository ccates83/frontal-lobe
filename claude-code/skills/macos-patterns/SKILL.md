---
name: macos-patterns
description: "macOS architecture patterns, AppKit integration, SwiftUI-on-Mac patterns, sandboxing, entitlements, notarization, distribution, and menu bar app guides. Reference material for swift-architect, swift-builder, and swift-reviewer agents when making architecture and implementation decisions for macOS projects."
---

# macOS Patterns — Architecture & Implementation Reference

Quick-reference guide for macOS development patterns. Used by the macOS planner ecosystem to make informed architecture and implementation decisions.

## When to Apply

Reference these patterns when:
- Designing new macOS features or apps
- Choosing between AppKit and SwiftUI for a component
- Implementing multi-window, menu bar, or toolbar UIs
- Configuring sandboxing, entitlements, or hardened runtime
- Distributing macOS apps (notarization, DMG, pkg, App Store)
- Reviewing macOS code for platform-specific issues

---

## 1. SwiftUI macOS Scene Architecture

### Multi-Window App

```swift
@main
struct MyMacApp: App {
    var body: some Scene {
        // Main document/content windows (multiple instances)
        WindowGroup("Documents", id: "document", for: Document.ID.self) { $documentId in
            DocumentView(documentId: documentId)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Document") { /* ... */ }
                    .keyboardShortcut("n", modifiers: .command)
            }
            FileCommands()
            EditCommands()
        }
        .defaultSize(width: 800, height: 600)

        // Single unique window (e.g., Activity Monitor-style)
        Window("Activity", id: "activity") {
            ActivityView()
        }
        .keyboardShortcut("0", modifiers: [.command, .shift])
        .defaultSize(width: 500, height: 400)

        // Preferences
        Settings {
            SettingsView()
        }

        // Menu bar utility
        MenuBarExtra("Status", systemImage: "circle.fill") {
            StatusMenuView()
        }
        .menuBarExtraStyle(.window) // Use .menu for simple dropdown
    }
}
```

### Settings with TabView

```swift
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }

            AppearanceSettingsView()
                .tabItem { Label("Appearance", systemImage: "paintbrush") }

            AdvancedSettingsView()
                .tabItem { Label("Advanced", systemImage: "gearshape.2") }
        }
        .frame(width: 450)
        .fixedSize()
    }
}
```

### Window Management

```swift
struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(\.openSettings) private var openSettings  // macOS 14+

    var body: some View {
        Button("Open Activity") {
            openWindow(id: "activity")
        }
        Button("Open Settings") {
            openSettings()
        }
    }
}
```

---

## 2. Menu Bar Apps

### SwiftUI MenuBarExtra (macOS 13+)

```swift
@main
struct MenuBarApp: App {
    // No main window — menu bar only
    var body: some Scene {
        MenuBarExtra("My Utility", systemImage: "cpu") {
            MenuBarContentView()
        }
        .menuBarExtraStyle(.window) // Rich popover content

        Settings {
            SettingsView()
        }
    }
}

struct MenuBarContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("System Status")
                .font(.headline)
            Divider()
            StatusRow(label: "CPU", value: "42%")
            StatusRow(label: "Memory", value: "8.2 GB")
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding()
        .frame(width: 250)
    }
}
```

### AppKit NSStatusItem (for broader compatibility or advanced behavior)

```swift
class StatusBarController {
    private var statusItem: NSStatusItem

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "cpu", accessibilityDescription: "Status")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        // For a menu-based approach:
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Dashboard", action: #selector(showDashboard), keyEquivalent: "d"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.shared.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    deinit {
        NSStatusBar.system.removeStatusItem(statusItem)
    }
}
```

---

## 3. AppKit Integration Patterns

### NSHostingView / NSHostingController (Embedding SwiftUI in AppKit)

```swift
// In an NSWindowController or NSViewController:
let swiftUIView = MySwiftUIView(viewModel: viewModel)
let hostingController = NSHostingController(rootView: swiftUIView)

// As a subview
let hostingView = NSHostingView(rootView: swiftUIView)
containerView.addSubview(hostingView)
hostingView.translatesAutoresizingMaskIntoConstraints = false
NSLayoutConstraint.activate([
    hostingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
    hostingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
    hostingView.topAnchor.constraint(equalTo: containerView.topAnchor),
    hostingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
])
```

### NSApplicationDelegateAdaptor (AppKit Lifecycle in SwiftUI)

```swift
@main
struct MyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // AppKit lifecycle hook
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true  // Quit when all windows closed
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        // Handle URL scheme
    }
}
```

### NSWindow Customization

```swift
// Access NSWindow from SwiftUI (when needed)
struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { callback(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

// Usage in SwiftUI:
ContentView()
    .background(WindowAccessor { window in
        window?.titlebarAppearsTransparent = true
        window?.styleMask.insert(.fullSizeContentView)
    })
```

### Custom NSMenu

```swift
class MenuManager {
    func setupMainMenu() {
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About MyApp", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Preferences...", action: #selector(showPreferences), keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit MyApp", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        NSApplication.shared.mainMenu = mainMenu
    }
}
```

---

## 4. Sandboxing & Security

### Entitlements File Example

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Enable App Sandbox -->
    <key>com.apple.security.app-sandbox</key>
    <true/>

    <!-- File access -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.files.bookmarks.app-scope</key>
    <true/>

    <!-- Network -->
    <key>com.apple.security.network.client</key>
    <true/>

    <!-- Hardware -->
    <key>com.apple.security.device.camera</key>
    <true/>
</dict>
</plist>
```

### Security-Scoped Bookmarks (Persisting File Access)

```swift
actor BookmarkManager {
    private let bookmarkKey = "savedBookmarks"

    func saveBookmark(for url: URL) throws {
        let bookmarkData = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        // Store bookmarkData in UserDefaults or a file
        var bookmarks = loadBookmarks()
        bookmarks[url.path] = bookmarkData
        UserDefaults.standard.set(bookmarks, forKey: bookmarkKey)
    }

    func resolveBookmark(for path: String) throws -> URL? {
        guard let bookmarks = UserDefaults.standard.dictionary(forKey: bookmarkKey),
              let data = bookmarks[path] as? Data else { return nil }

        var isStale = false
        let url = try URL(resolvingBookmarkData: data,
                          options: .withSecurityScope,
                          relativeTo: nil,
                          bookmarkDataIsStale: &isStale)

        if isStale {
            try saveBookmark(for: url)  // Refresh
        }

        guard url.startAccessingSecurityScopedResource() else {
            throw BookmarkError.accessDenied
        }
        // IMPORTANT: caller must call url.stopAccessingSecurityScopedResource() when done

        return url
    }

    private func loadBookmarks() -> [String: Data] {
        UserDefaults.standard.dictionary(forKey: bookmarkKey) as? [String: Data] ?? [:]
    }
}
```

### File Access with NSOpenPanel (Sandboxed)

```swift
func openFile() async -> URL? {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    panel.allowedContentTypes = [.plainText, .json]

    let response = await panel.begin()
    guard response == .OK, let url = panel.url else { return nil }

    // The URL is security-scoped while the app is running
    // Save a bookmark if you need access after relaunch
    return url
}
```

---

## 5. Distribution Patterns

### Notarization Workflow

```bash
# 1. Archive
xcodebuild -project MyApp.xcodeproj -scheme MyApp \
  -destination 'generic/platform=macOS' \
  -archivePath build/MyApp.xcarchive archive

# 2. Export with Developer ID signing
xcodebuild -exportArchive \
  -archivePath build/MyApp.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist

# 3. Create DMG
hdiutil create -volname "MyApp" \
  -srcfolder build/export/MyApp.app \
  -ov -format UDZO build/MyApp.dmg

# 4. Notarize
xcrun notarytool submit build/MyApp.dmg \
  --keychain-profile "notarization-profile" --wait

# 5. Staple
xcrun stapler staple build/MyApp.dmg

# 6. Verify
spctl --assess --type open --context context:primary-signature build/MyApp.dmg
```

### ExportOptions.plist (Developer ID)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>YOURTEAMID</string>
    <key>signingStyle</key>
    <string>automatic</string>
</dict>
</plist>
```

### Store Notarization Credentials

```bash
xcrun notarytool store-credentials "notarization-profile" \
  --apple-id "developer@example.com" \
  --team-id "YOURTEAMID" \
  --password "app-specific-password"
```

---

## 6. Multi-Platform Code Patterns

### Platform Conditional Compilation

```swift
#if os(macOS)
import AppKit
typealias PlatformColor = NSColor
typealias PlatformImage = NSImage
#elseif os(iOS)
import UIKit
typealias PlatformColor = UIColor
typealias PlatformImage = UIImage
#endif

// SwiftUI views that differ by platform
struct AdaptiveView: View {
    var body: some View {
        #if os(macOS)
        NavigationSplitView {
            Sidebar()
        } detail: {
            DetailView()
        }
        .frame(minWidth: 600, minHeight: 400)
        #else
        NavigationStack {
            MainList()
        }
        #endif
    }
}
```

### Shared ViewModel, Platform-Specific Views

```swift
// Shared (in a cross-platform SPM package)
@Observable
final class DocumentViewModel {
    var content: String = ""
    var isModified: Bool = false

    func save() async throws { /* ... */ }
    func load(from url: URL) async throws { /* ... */ }
}

// macOS-specific view
#if os(macOS)
struct DocumentView: View {
    @State private var viewModel = DocumentViewModel()

    var body: some View {
        TextEditor(text: $viewModel.content)
            .toolbar {
                ToolbarItem { Button("Save") { Task { try? await viewModel.save() } } }
            }
            .navigationTitle(viewModel.isModified ? "Document *" : "Document")
    }
}
#endif
```

---

## 7. macOS-Specific Testing

### Testing Window Lifecycle

```swift
@Test("document window opens with correct title")
func documentWindowTitle() async {
    let viewModel = DocumentViewModel()
    viewModel.content = "Hello"
    viewModel.isModified = true

    // Test the state, not the window itself
    #expect(viewModel.isModified == true)
}
```

### Testing Sandbox File Access

```swift
@Test("bookmark manager saves and resolves bookmarks")
func bookmarkRoundTrip() async throws {
    let manager = BookmarkManager()
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.txt")
    FileManager.default.createFile(atPath: tempURL.path, contents: Data("test".utf8))
    defer { try? FileManager.default.removeItem(at: tempURL) }

    try await manager.saveBookmark(for: tempURL)
    let resolved = try await manager.resolveBookmark(for: tempURL.path)
    #expect(resolved != nil)
    resolved?.stopAccessingSecurityScopedResource()
}
```

---

## 8. macOS Performance Checklist

- [ ] No blocking calls on MainActor (same as iOS)
- [ ] Multi-window state is independent per window (no accidental shared mutation)
- [ ] Large file operations use background actors
- [ ] Images downsampled for display (NSImage representations)
- [ ] Menu bar apps use minimal resources when idle
- [ ] Animations use Core Animation / SwiftUI, not manual frame updates
- [ ] File system access respects sandbox boundaries
- [ ] Security-scoped resources are released promptly (`stopAccessingSecurityScopedResource`)
- [ ] Network requests are cancellable
- [ ] Memory usage reasonable for long-running desktop app (no unbounded growth)

---

## 9. Common macOS Frameworks

### ServiceManagement (Login Items)
```swift
import ServiceManagement

// Register as login item (macOS 13+)
try SMAppService.mainApp.register()

// Unregister
try SMAppService.mainApp.unregister()

// Check status
let status = SMAppService.mainApp.status  // .enabled, .notRegistered, .requiresApproval
```

### UserNotifications (macOS)
```swift
import UserNotifications

func requestNotificationPermission() async throws -> Bool {
    try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
}

func sendNotification(title: String, body: String) {
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default

    let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
    UNUserNotificationCenter.current().add(request)
}
```

### FileProvider (File Provider Extension)
- Used for cloud storage integrations in Finder
- Requires `NSFileProviderExtension` and entitlements
- Complex: involves domain management, enumeration, and materialization

### SystemExtensions
- Network extensions, endpoint security, driver extensions
- Require special entitlements from Apple
- Must be distributed outside the App Store (or with special approval)
