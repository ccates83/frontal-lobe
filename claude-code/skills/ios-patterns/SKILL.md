---
name: ios-patterns
description: "iOS architecture patterns, Swift concurrency reference, SwiftUI patterns, and Apple framework integration guides. Reference material for swift-architect, swift-builder, and swift-reviewer agents when making architecture and implementation decisions for iOS projects."
---

# iOS Patterns — Architecture & Implementation Reference

Quick-reference guide for iOS development patterns. Used by the iOS planner ecosystem to make informed architecture and implementation decisions.

## When to Apply

Reference these patterns when:
- Designing new iOS features or modules
- Choosing between architectural approaches
- Implementing Swift concurrency correctly
- Integrating Apple frameworks
- Reviewing code for pattern violations

---

## 1. Architecture Patterns

### MVVM with SwiftUI (Recommended for SwiftUI projects)

```swift
// Model
struct User: Codable, Identifiable {
    let id: UUID
    var name: String
    var email: String
}

// ViewModel (using Observation framework)
@Observable
final class UserListViewModel {
    var users: [User] = []
    var isLoading = false
    var error: Error?

    private let repository: UserRepository

    init(repository: UserRepository) {
        self.repository = repository
    }

    func loadUsers() async {
        isLoading = true
        defer { isLoading = false }
        do {
            users = try await repository.fetchAll()
        } catch {
            self.error = error
        }
    }
}

// View
struct UserListView: View {
    @State private var viewModel: UserListViewModel

    init(repository: UserRepository) {
        _viewModel = State(initialValue: UserListViewModel(repository: repository))
    }

    var body: some View {
        List(viewModel.users) { user in
            UserRow(user: user)
        }
        .overlay { if viewModel.isLoading { ProgressView() } }
        .task { await viewModel.loadUsers() }
    }
}
```

### MV (Model-View) Pattern (Simpler SwiftUI apps)

For simpler apps, skip the ViewModel layer. Use SwiftData `@Query` directly in views and `@Environment(\.modelContext)` for mutations.

```swift
struct ItemListView: View {
    @Query(sort: \Item.date, order: .reverse) private var items: [Item]
    @Environment(\.modelContext) private var context

    var body: some View {
        List(items) { item in
            ItemRow(item: item)
        }
    }

    private func addItem() {
        let item = Item(name: "New")
        context.insert(item)
    }
}
```

### Coordinator Pattern (Navigation-heavy apps)

```swift
@Observable
final class AppCoordinator {
    var path = NavigationPath()

    enum Destination: Hashable {
        case detail(Item.ID)
        case settings
        case profile(User.ID)
    }

    func navigate(to destination: Destination) {
        path.append(destination)
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
```

### File Structure Conventions

- Group behavior by capability in separate extension files: `Type+Capability.swift` (e.g., `ViewModel+ScrollState.swift`, `Feature+Filter.swift`)
- One main concern per extension file
- Use a hyphen for MARK section headers: `// MARK: - Security`, `// MARK: Private Methods`
- Group private implementation in a `private extension` on the same type
- When a type is only used in one context, define it inside that type's extension or namespace (nested types)
- Match the project's existing file and type naming conventions (prefixes, module boundaries, etc.)

---

## 2. Swift Concurrency Patterns

### Actor for Shared Mutable State

```swift
actor CacheManager {
    private var cache: [String: Data] = [:]

    func get(_ key: String) -> Data? {
        cache[key]
    }

    func set(_ key: String, data: Data) {
        cache[key] = data
    }
}
```

### Structured Concurrency

```swift
// Parallel independent work
async let profile = fetchProfile(id: userId)
async let posts = fetchPosts(userId: userId)
async let friends = fetchFriends(userId: userId)
let (p, ps, f) = try await (profile, posts, friends)

// Dynamic parallel work
try await withThrowingTaskGroup(of: Image.self) { group in
    for url in imageURLs {
        group.addTask { try await downloadImage(url) }
    }
    for try await image in group {
        images.append(image)
    }
}
```

### Async Stream for Continuous Updates

```swift
func locationUpdates() -> AsyncStream<CLLocation> {
    AsyncStream { continuation in
        let delegate = LocationDelegate(continuation: continuation)
        continuation.onTermination = { _ in delegate.stop() }
        delegate.start()
    }
}
```

### MainActor Isolation

```swift
// Entire class on MainActor
@MainActor
@Observable
final class SettingsViewModel {
    var theme: Theme = .system

    // Background work must be explicitly nonisolated or use Task
    nonisolated func exportData() async throws -> Data {
        // Runs off MainActor
        try await DataExporter.export()
    }
}
```

---

## 3. SwiftUI Patterns

### Environment-Based Dependency Injection

```swift
// Define the key
struct NetworkClientKey: EnvironmentKey {
    static let defaultValue: NetworkClient = URLSessionNetworkClient()
}

extension EnvironmentValues {
    var networkClient: NetworkClient {
        get { self[NetworkClientKey.self] }
        set { self[NetworkClientKey.self] = newValue }
    }
}

// Inject
ContentView()
    .environment(\.networkClient, MockNetworkClient())

// Consume
struct DataView: View {
    @Environment(\.networkClient) private var networkClient
}
```

### View Composition

```swift
// Extract subviews when body exceeds ~30 lines
struct ProfileView: View {
    let user: User

    var body: some View {
        ScrollView {
            headerSection
            statsSection
            actionsSection
        }
    }

    private var headerSection: some View {
        VStack { /* ... */ }
    }

    private var statsSection: some View {
        HStack { /* ... */ }
    }

    private var actionsSection: some View {
        VStack { /* ... */ }
    }
}
```

### Adaptive Layout

```swift
ViewThatFits(in: .horizontal) {
    HStack { content }  // Try horizontal first
    VStack { content }  // Fall back to vertical
}
```

---

## 4. Persistence Patterns

### SwiftData

```swift
@Model
final class Trip {
    var name: String
    var destination: String
    var startDate: Date
    var endDate: Date
    @Relationship(deleteRule: .cascade) var activities: [Activity]

    init(name: String, destination: String, startDate: Date, endDate: Date) {
        self.name = name
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
        self.activities = []
    }
}
```

### UserDefaults + App Group (Extension Communication)

```swift
enum SharedDefaults {
    static let suiteName = "group.com.company.app"
    static let shared = UserDefaults(suiteName: suiteName)!

    static var currentGoal: Double {
        get { shared.double(forKey: "currentGoal") }
        set {
            shared.set(newValue, forKey: "currentGoal")
            shared.synchronize()  // Required for cross-process
        }
    }
}
```

---

## 5. Networking Pattern

```swift
protocol APIClient: Sendable {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

struct URLSessionAPIClient: APIClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let (data, response) = try await session.data(for: endpoint.urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode, data)
        }
        return try decoder.decode(T.self, from: data)
    }
}
```

### Domain Error Mapping

Map low-level or network errors to domain errors inside the layer that owns the call. Present a simple, user-friendly message (or localization key) in the UI.

```swift
// Domain error enum
enum ProfileError: Error, LocalizedError {
    case notFound
    case networkUnavailable
    case serverError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .notFound: String(localized: "profile.error.notFound")
        case .networkUnavailable: String(localized: "profile.error.offline")
        case .serverError: String(localized: "profile.error.server")
        }
    }
}

// Map at the repository layer
struct ProfileRepository {
    private let api: APIClient

    /// Fetches the user profile.
    /// - Throws: `ProfileError` for all failure cases.
    func fetchProfile(id: String) async throws(ProfileError) -> User {
        do {
            return try await api.request(.profile(id))
        } catch let error as APIError {
            switch error {
            case .httpError(404, _): throw .notFound
            case .httpError(let code, _): throw .serverError(statusCode: code)
            default: throw .networkUnavailable
            }
        } catch {
            throw .networkUnavailable
        }
    }
}
```

Document thrown errors in doc comments (`/// - Throws:`) so callers know the contract.

---

## 6. Testing Patterns

### Protocol-Based Mocking

```swift
protocol LocationProviding: Sendable {
    func currentLocation() async throws -> CLLocation
}

struct MockLocationProvider: LocationProviding {
    let location: CLLocation
    func currentLocation() async throws -> CLLocation { location }
}
```

### Testing Async Code (Swift Testing)

```swift
@Test("fetches user profile", .timeLimit(.seconds(5)))
func fetchProfile() async throws {
    let mock = MockAPIClient(response: .success(User.sample))
    let viewModel = ProfileViewModel(api: mock)

    await viewModel.load()

    #expect(viewModel.user?.name == "Test User")
    #expect(viewModel.isLoading == false)
}
```

---

## 7. Common Apple Framework Integration

### HealthKit
- Request authorization before reading/writing
- Use `HKHealthStore.isHealthDataAvailable()` to check device capability
- Background delivery for passive data collection
- Handle authorization denial gracefully

### CoreLocation
- Request `whenInUse` first, upgrade to `always` only if needed
- Handle all authorization states including `.denied` and `.restricted`
- Use `CLMonitor` (iOS 17+) for modern region monitoring

### Notifications
- Request authorization early but not on first launch
- Handle provisional authorization for quiet notifications
- Register notification categories and actions
- Use `UNUserNotificationCenter.current().delegate` for foreground handling

### FamilyControls / Screen Time
- Requires special entitlement from Apple
- `authorizationStatus` has known bugs (.notDetermined on denial)
- Shield extensions: 5-6 MB memory limit, PNG icons only
- Use App Groups + UserDefaults for extension communication
- Darwin Notifications for cross-process signaling

---

## 8. Performance Checklist

- [ ] No blocking calls on MainActor
- [ ] Images downsampled to display size
- [ ] Lists use lazy loading (LazyVStack, LazyHGrid)
- [ ] Heavy computation on background actor/thread
- [ ] No retain cycles in closures (check with Memory Graph Debugger)
- [ ] Extensions stay under memory limits
- [ ] Network requests are cancellable and cancelled on disappear
- [ ] Animations use transform/opacity, not layout changes

---

## 9. Documentation Style

### Public API
- Add `///` doc comments for all public types, properties, and methods
- For non-trivial behavior use multiple lines; explain side effects or when something runs (e.g., "automatically when the property is set via its `didSet`")

### Parameters / Returns / Note
- Use `- Parameter name:`, `- Returns:`, `- Note: ...` where they clarify contract or usage

```swift
/// Fetches the user profile from the remote service.
///
/// - Parameter id: The unique identifier for the user.
/// - Returns: The populated `UserProfile`, or throws if the network is unreachable.
/// - Note: Automatically retries once on timeout before throwing.
func fetchProfile(id: String) async throws -> UserProfile
```

### Inline Comments
- Use for non-obvious logic; explain *why* or workarounds
- If code is temporary or a workaround, say so

### TODOs
- Use ticket/ID + condition so work is traceable:
  `// TODO: (TICKET-123) Remove once feature X is shipped.`

---

## 10. Accessibility

- Add `accessibilityLabel` (and `accessibilityHint` when helpful) for interactive elements and meaningful images; avoid redundant labels
- Support Dynamic Type: use semantic text styles (`.body`, `.headline`) or scale with the environment; avoid fixed font sizes for body text
- Respect `accessibilityReduceMotion` — disable or simplify non-essential animations when it is enabled
- Use `accessibilityIdentifier` for UI tests; keep identifiers stable and consistent with the project's naming convention

```swift
// Dynamic Type support
Text("Welcome")
    .font(.headline)  // ✅ Scales with system settings

Text("Welcome")
    .font(.system(size: 18))  // ❌ Fixed size, won't scale

// Reduce motion
@Environment(\.accessibilityReduceMotion) private var reduceMotion

withAnimation(reduceMotion ? nil : .spring()) {
    showContent = true
}

// Test identifiers
Button("Submit") { submit() }
    .accessibilityIdentifier("submitButton")
```

---

## 11. Localization

- Do not hardcode user-facing strings in Swift; use the project's localization mechanism (e.g., `String(localized:)`, `NSLocalizedString`, or a generated `L10n`/enum API)
- Keep keys or enum cases consistent with the project's existing naming
- Use placeholder comments or parameterized strings for dynamic text; avoid string concatenation for sentences

```swift
// ✅ Correct
Text(String(localized: "welcome.greeting \(userName)"))

// ❌ Avoid — breaks localization for RTL and grammatically different languages
Text("Hello, " + userName + "! You have " + "\(count)" + " items.")
```

---

## 12. Logging & Diagnostics

- Use the project's logging API (e.g., `os.Logger`, `OSLog`) instead of `print` for diagnostics
- Log at an appropriate level (`debug` for development, `error` for failures, `info` for significant events)
- Prefer structured or clearly formatted messages so logs are searchable and actionable
- Never log PII (emails, user IDs, tokens) or secrets

```swift
import os

extension Logger {
    static let networking = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Networking")
}

// ✅ Structured logging with levels
Logger.networking.debug("Request started: \(endpoint, privacy: .public)")
Logger.networking.error("Request failed: \(error.localizedDescription, privacy: .public)")

// ❌ Avoid
print("request started")  // Not filterable, ships in production
Logger.networking.info("User email: \(user.email)")  // PII leak
```

---

## 13. Privacy & Security

- Do not commit secrets, API keys, or tokens; use the project's config (e.g., xcconfig files, environment variables, keychain) and never log them
- Store credentials and sensitive data in the Keychain (or project-approved secure storage); do not use `UserDefaults` or plists for secrets
- Do not log PII (e.g., emails, IDs, tokens); redact or omit in log messages and analytics
- Use `privacy: .private` in OSLog for any potentially sensitive values

```swift
// ✅ Secrets via xcconfig / build settings
let apiKey = Bundle.main.infoDictionary?["API_KEY"] as? String

// ✅ Keychain for credentials
try KeychainManager.save(token, forKey: "authToken")

// ❌ Never store secrets in UserDefaults
UserDefaults.standard.set(authToken, forKey: "token")

// ✅ Redact sensitive values in logs
Logger.auth.debug("Token refreshed for user: \(userId, privacy: .private)")
```
