# Pharmacy Network - Flutter App

A Flutter app for pharmacies to share drug inventory, search for medications, and manage requests.

## Features

### Owner Features
- **Authentication**: Login and registration for pharmacy owners
- **Dashboard**: View active queries, requests, and statistics
- **Drug Search**: Search for medications across nearby pharmacies
- **Request Management**: Accept or decline incoming share requests
- **Transaction History**: Track all completed transactions

### Admin Features
- **Admin Dashboard**: System overview and health monitoring
- **Pharmacy Management**: Approve/reject new pharmacy registrations
- **Transaction Monitoring**: View all system transactions
- **Reports**: Generate performance and activity reports
- **Audit Logs**: Track all system actions

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── routes/
│   └── app_router.dart         # GoRouter configuration
├── pages/                       # All page screens
│   ├── login_page.dart
│   ├── register_page.dart
│   ├── owner_dashboard_page.dart
│   ├── drug_query_page.dart
│   ├── search_results_page.dart
│   ├── receive_alert_page.dart
│   ├── accept_share_page.dart
│   ├── view_response_page.dart
│   ├── transaction_history_page.dart
│   ├── admin_dashboard_page.dart
│   ├── manage_pharmacies_page.dart
│   ├── approve_onboarding_page.dart
│   ├── monitor_transactions_page.dart
│   ├── reports_page.dart
│   └── audit_logs_page.dart
└── widgets/                     # Reusable widgets
    ├── app_nav.dart            # Navigation bar
    ├── app_text_field.dart     # Custom text input
    └── app_button.dart         # Custom button
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code with Flutter extensions
- iOS Simulator (for macOS) or Android Emulator

### Installation

1. **Clone or navigate to the project**
   ```bash
   cd flutter_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   
   For iOS:
   ```bash
   flutter run -d ios
   ```
   
   For Android:
   ```bash
   flutter run -d android
   ```
   
   For Web:
   ```bash
   flutter run -d chrome
   ```

### Connect to local backend

Run Flutter with backend URL using Dart define:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:4000
```

Backend health endpoint expected by `HealthApiService`:

- `GET /api/health`

## Key Dependencies

- **go_router**: Navigation and routing (^14.0.0)
- **provider**: State management (^6.1.0)
- **google_fonts**: Custom fonts (^6.1.0)

## Color Palette

The app uses the following color scheme:

- **Background**: `#F5F5F2`
- **Primary Green**: `#1D9E75`
- **Dark Green**: `#04342C`
- **Medium Green**: `#0F6E56`
- **Light Green**: `#E1F5EE`
- **Border**: `#B4B2A9`
- **Text Primary**: `#1A1A18`
- **Text Secondary**: `#5F5E5A`
- **Input Background**: `#F1EFEA`

## Navigation Routes

| Route | Page | Description |
|-------|------|-------------|
| `/` | LoginPage | Default landing page |
| `/register` | RegisterPage | New pharmacy registration |
| `/dashboard` | OwnerDashboardPage | Pharmacy owner dashboard |
| `/search` | DrugQueryPage | Search for medications |
| `/search/results` | SearchResultsPage | View search results |
| `/requests` | ReceiveAlertPage | Incoming share requests |
| `/requests/accepted` | AcceptSharePage | Confirmation page |
| `/search/response` | ViewResponsePage | Request status |
| `/history` | TransactionHistoryPage | Transaction log |
| `/admin` | AdminDashboardPage | Admin overview |
| `/admin/pharmacies` | ManagePharmaciesPage | Pharmacy management |
| `/admin/pharmacies/approve/:id` | ApproveOnboardingPage | Approve pharmacy |
| `/admin/transactions` | MonitorTransactionsPage | Transaction monitoring |
| `/admin/reports` | ReportsPage | System reports |
| `/admin/logs` | AuditLogsPage | Audit log viewer |

## Testing

Run tests with:
```bash
flutter test
```

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## Next Steps

1. **Add Backend Integration**: Connect to Supabase or Firebase
2. **State Management**: Implement Provider/Riverpod for global state
3. **Implement Authentication**: Add real auth flows
4. **Add Form Validation**: Validate all user inputs
5. **Implement Search Logic**: Connect to real pharmacy database
6. **Add Push Notifications**: Alert users of new requests
7. **Implement Analytics**: Track user behavior
8. **Add Tests**: Unit and widget tests

## Contributing

When making changes:

1. Maintain design consistency with the original
2. Follow Flutter best practices
3. Keep the color scheme intact
4. Update this README with any new features

## License

Same as parent project.
