# React to Flutter Conversion Notes

## Conversion Completed: June 3, 2026

This document contains detailed notes about the conversion process from React to Flutter.

## Architecture Comparison

### React App
- **Framework**: React 18.3.1 + Vite
- **Routing**: React Router v7
- **Styling**: Tailwind CSS v4
- **UI Components**: Radix UI + shadcn/ui
- **State**: React hooks (useState, useNavigate)

### Flutter App
- **Framework**: Flutter 3.0+
- **Routing**: GoRouter v14
- **Styling**: Native Flutter widgets with custom styling
- **UI Components**: Material Design widgets + custom widgets
- **State**: StatefulWidget with setState

## Component Mapping

### Navigation
| React | Flutter |
|-------|---------|
| `<Nav links={...} />` | `AppNav(links: [...])` |
| `useNavigate()` | `context.go()` |
| `<Link to="...">` | `GestureDetector(onTap: () => context.go())` |

### Form Controls
| React | Flutter |
|-------|---------|
| `<input type="text" />` | `AppTextField()` |
| `<button onClick={...}>` | `AppButton(onPressed: ...)` |
| `<select>` | `DropdownButton` |
| `<textarea>` | `TextField(maxLines: null)` |

### Layout
| React | Flutter |
|-------|---------|
| `<div className="...">` | `Container(decoration: ...)` |
| Flexbox (grid, flex) | `Row`, `Column`, `Flex` |
| `className="gap-2"` | `SizedBox(width/height: ...)` between children |
| `max-w-md mx-auto` | `constraints: BoxConstraints(maxWidth: ...)` |

## Style Conversions

### Tailwind to Flutter

```dart
// Tailwind: bg-white border border-[#b4b2a9] rounded-[10px] p-3.5
Container(
  padding: EdgeInsets.all(14),  // 3.5 * 4 = 14
  decoration: BoxDecoration(
    color: Colors.white,
    border: Border.all(color: Color(0xFFB4B2A9)),
    borderRadius: BorderRadius.circular(10),
  ),
)

// Tailwind: text-[13px] font-semibold text-[#1a1a18]
TextStyle(
  fontSize: 13,
  fontWeight: FontWeight.w600,
  color: Color(0xFF1A1A18),
)
```

### Spacing Scale
- Tailwind `px` → Flutter `logical pixels`
- `p-1` (4px) → `padding: 4`
- `p-2` (8px) → `padding: 8`
- `p-3.5` (14px) → `padding: 14`
- `gap-2` → `SizedBox(width: 8)` or `SizedBox(height: 8)`

## State Management Patterns

### Simple Local State
```dart
// React
const [radius, setRadius] = useState(10);

// Flutter
class _PageState extends State<Page> {
  int radius = 10;
  
  void updateRadius(int value) {
    setState(() => radius = value);
  }
}
```

### Navigation State
```dart
// React
const navigate = useNavigate();
navigate('/dashboard');

// Flutter
context.go('/dashboard');
```

## File Organization

### React Structure
```
src/app/
├── App.tsx
├── routes.tsx
├── pages/
│   ├── Login.tsx
│   └── ...
└── components/
    ├── Nav.tsx
    └── ui/
```

### Flutter Structure
```
lib/
├── main.dart
├── routes/
│   └── app_router.dart
├── pages/
│   ├── login_page.dart
│   └── ...
└── widgets/
    ├── app_nav.dart
    └── ...
```

## Notable Differences

### 1. Event Handling
- React: `onClick`, `onChange`
- Flutter: `onTap`, `onPressed`, `onChanged`

### 2. Conditional Rendering
```dart
// React
{isVisible && <div>Content</div>}

// Flutter
if (isVisible) 
  Container(child: Text('Content'))
```

### 3. List Rendering
```dart
// React
{items.map(item => <div key={item.id}>{item.name}</div>)}

// Flutter
...items.map((item) => Container(
  key: ValueKey(item.id),
  child: Text(item.name),
))
```

### 4. Async/Await
Both React and Flutter use similar async patterns:
```dart
// Both
async () {
  final result = await fetchData();
}
```

## Not Yet Implemented

The following features from the React app need backend implementation:

1. **Authentication**: Currently no real auth, just navigation
2. **API Integration**: No backend calls
3. **Form Validation**: Basic forms without validation
4. **Search Logic**: Mock data only
5. **State Persistence**: No local storage
6. **Error Handling**: Minimal error states
7. **Loading States**: No loading indicators
8. **Responsive Design**: Optimized for mobile, needs tablet/desktop work

## Performance Considerations

### Flutter Advantages
- Native compilation (faster than React web)
- No virtual DOM reconciliation
- 60fps+ animations out of the box
- Smaller app size for mobile

### React Advantages
- Hot reload during development
- Larger ecosystem of packages
- Easier web deployment
- More developers familiar with it

## Testing Strategy

### Unit Tests
Test individual widgets and business logic:
```dart
testWidgets('Login button navigates', (tester) async {
  await tester.pumpWidget(LoginPage());
  await tester.tap(find.byType(AppButton));
  // Assert navigation occurred
});
```

### Integration Tests
Test full user flows across multiple screens.

### Widget Tests
Test UI components in isolation.

## Build Sizes

Estimated production build sizes:
- **Android APK**: ~15-20 MB
- **iOS IPA**: ~20-30 MB
- **Web**: ~2-3 MB (compressed)

React web bundle: ~500 KB (compressed)

## Migration Checklist

- [x] Project structure setup
- [x] Routing configuration
- [x] All 15 pages converted
- [x] Reusable widgets created
- [x] Styling matched to original
- [ ] Backend integration
- [ ] State management (Provider/Riverpod)
- [ ] Form validation
- [ ] Error handling
- [ ] Loading states
- [ ] Unit tests
- [ ] Integration tests
- [ ] Responsive layouts
- [ ] Accessibility
- [ ] Performance optimization

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [GoRouter Package](https://pub.dev/packages/go_router)
- [Material Design](https://m3.material.io/)
- [Flutter for React Developers](https://docs.flutter.dev/get-started/flutter-for/react-devs)
