---
name: ios-patterns
description: "iOS architecture patterns, Swift concurrency reference, SwiftUI patterns, and Apple framework integration guides. Reference material for swift-architect, swift-builder, and swift-reviewer agents when making architecture and implementation decisions for iOS projects."
compatibility: opencode
---
# iOS Patterns — Architecture & Implementation Reference

Quick-reference guide for iOS development patterns. Used by the iOS orchestrator ecosystem to make informed architecture and implementation decisions.

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
