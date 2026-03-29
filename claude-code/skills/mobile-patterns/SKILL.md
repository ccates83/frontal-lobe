---
name: mobile-patterns
description: "Cross-platform mobile development patterns for React Native, Expo, and Flutter. Covers navigation, state management, performance optimization, platform-specific code, and testing strategies. Reference material for mobile-planner and its sub-agents."
---

# Mobile Patterns — React Native, Expo & Flutter Reference

Quick-reference guide for cross-platform mobile development. Used by the mobile planner ecosystem.

## When to Apply

Reference these patterns when:
- Designing cross-platform mobile architecture
- Implementing React Native, Expo, or Flutter features
- Optimizing mobile performance
- Handling platform-specific behavior
- Writing mobile tests

---

## 1. Navigation Patterns

### Expo Router (File-Based)
```
app/
├── _layout.tsx           # Root layout
├── index.tsx             # / (home)
├── (auth)/
│   ├── _layout.tsx       # Auth layout (no tabs)
│   ├── login.tsx         # /login
│   └── register.tsx      # /register
├── (tabs)/
│   ├── _layout.tsx       # Tab layout
│   ├── index.tsx         # / (home tab)
│   ├── search.tsx        # /search
│   └── profile.tsx       # /profile
├── post/
│   └── [id].tsx          # /post/:id
└── +not-found.tsx        # 404
```

### Type-Safe Navigation (React Navigation)
```tsx
type RootStackParamList = {
  Home: undefined
  Profile: { userId: string }
  Settings: undefined
}

// Usage with type safety
navigation.navigate('Profile', { userId: '123' })
```

### Flutter GoRouter
```dart
final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isLoggedIn = ref.read(authProvider).isLoggedIn;
    if (!isLoggedIn && !state.matchedLocation.startsWith('/auth')) {
      return '/auth/login';
    }
    return null;
  },
  routes: [
    ShellRoute(
      builder: (context, state, child) => ScaffoldWithNavBar(child: child),
      routes: [
        GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
        GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
      ],
    ),
  ],
);
```

---

## 2. State Management Patterns

### React Native: Zustand + TanStack Query
```tsx
// Global app state (Zustand)
const useAuthStore = create<AuthState>((set) => ({
  user: null,
  token: null,
  setAuth: (user, token) => set({ user, token }),
  logout: () => set({ user: null, token: null }),
}))

// Server state (TanStack Query)
function useUser(id: string) {
  return useQuery({
    queryKey: ['user', id],
    queryFn: () => api.getUser(id),
    staleTime: 5 * 60 * 1000,
  })
}
```

### Flutter: Riverpod
```dart
// Simple state
final counterProvider = StateProvider<int>((ref) => 0);

// Async data
final userProvider = FutureProvider.autoDispose.family<User, String>((ref, id) async {
  final api = ref.watch(apiClientProvider);
  return api.getUser(id);
});

// State notifier for complex state
final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState.empty();

  void addItem(Product product) {
    state = state.copyWith(items: [...state.items, CartItem(product: product)]);
  }
}
```

---

## 3. Performance Patterns

### List Optimization (React Native)
```tsx
// Use FlashList for large lists
import { FlashList } from '@shopify/flash-list'

<FlashList
  data={items}
  renderItem={({ item }) => <ItemCard item={item} />}
  estimatedItemSize={80}
  keyExtractor={(item) => item.id}
/>

// Memoize list items
const ItemCard = React.memo(({ item }: { item: Item }) => (
  <View style={styles.card}>
    <Text>{item.title}</Text>
  </View>
))
```

### Image Optimization
```tsx
// React Native: expo-image (preferred over Image)
import { Image } from 'expo-image'

<Image
  source={{ uri: imageUrl }}
  style={{ width: 200, height: 200 }}
  contentFit="cover"
  placeholder={blurhash}
  transition={200}
/>
```

### Flutter: const Constructors
```dart
// Good: const prevents unnecessary rebuilds
class MyWidget extends StatelessWidget {
  const MyWidget({super.key}); // const constructor

  @override
  Widget build(BuildContext context) {
    return const Padding(  // const here too
      padding: EdgeInsets.all(16),
      child: Text('Hello'),
    );
  }
}
```

---

## 4. Platform-Specific Patterns

### Conditional Code (React Native)
```tsx
import { Platform } from 'react-native'

// Inline
const styles = StyleSheet.create({
  shadow: Platform.select({
    ios: { shadowColor: '#000', shadowOpacity: 0.1, shadowRadius: 4 },
    android: { elevation: 4 },
  }),
})

// File-based: Component.ios.tsx / Component.android.tsx
```

### Conditional Code (Flutter)
```dart
import 'dart:io' show Platform;

Widget build(BuildContext context) {
  if (Platform.isIOS) {
    return const CupertinoButton(child: Text('iOS'));
  }
  return ElevatedButton(onPressed: () {}, child: const Text('Android'));
}

// Or use .adaptive constructors
Switch.adaptive(value: isOn, onChanged: toggle)
```

---

## 5. Offline-First Patterns

### Cache Strategy
```
1. Show cached data immediately (stale)
2. Fetch fresh data in background
3. Update UI when fresh data arrives
4. Queue writes when offline
5. Sync queued writes when online
```

### Network Status Handling
```tsx
import NetInfo from '@react-native-community/netinfo'

function useNetworkStatus() {
  const [isConnected, setIsConnected] = useState(true)

  useEffect(() => {
    const unsubscribe = NetInfo.addEventListener(state => {
      setIsConnected(state.isConnected ?? false)
    })
    return unsubscribe
  }, [])

  return isConnected
}
```

---

## 6. Testing Patterns

### Component Test (React Native Testing Library)
```tsx
import { render, screen } from '@testing-library/react-native'
import userEvent from '@testing-library/user-event'

it('submits the form with valid data', async () => {
  const onSubmit = jest.fn()
  const user = userEvent.setup()
  render(<LoginForm onSubmit={onSubmit} />)

  await user.type(screen.getByLabelText('Email'), 'test@test.com')
  await user.type(screen.getByLabelText('Password'), 'password')
  await user.press(screen.getByRole('button', { name: 'Sign In' }))

  expect(onSubmit).toHaveBeenCalledWith({ email: 'test@test.com', password: 'password' })
})
```

### Widget Test (Flutter)
```dart
testWidgets('counter increments', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: CounterScreen()));

  expect(find.text('0'), findsOneWidget);
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();
  expect(find.text('1'), findsOneWidget);
});
```
