# Tixxo

A Flutter-based event ticketing application that provides seamless ticket booking experience with integrated payment solutions and dynamic seat selection.

## Tech Stack

- **Flutter** - Cross-platform mobile application framework
- **Firebase** - Backend services (Authentication, Firestore, Storage)
- **Seats.io** - Interactive seat selection and venue management
- **Razorpay** - Payment gateway integration

## Database Structure

The application uses Firebase Firestore with the following collections:

### Collections

- **Events** - Stores all event information including embedded artist and promoter details for event detail pages
- **Users** - Stores all user information and profiles
- **Promoters** - Stores promoter details (fetched for the promoters section)
- **Artists** - Stores artist details (fetched for the artists section)

### Data Flow

- Events are displayed from the `Events` collection throughout the app
- User profiles and authentication data are managed in the `Users` collection
- Promoter listings in sections fetch data from the `Promoters` collection
- Artist listings in sections fetch data from the `Artists` collection
- Event detail pages use artist and promoter information embedded within the `Events` collection itself

## Folder Structure

```
lib/
├── auth/
│   └── Authentication files (login, signup, auth services)
│
├── screens/
│   └── Main screens navigated by the navigation bar + landing page
│
├── profile_pages/
│   └── All profile-related screens (clearly named)
│
├── supportive_pages/
│   ├── event_detail.dart
│   ├── artist_detail.dart
│   ├── promoter_detail.dart
│   ├── main_profile_page.dart
│   ├── ticket_detail_page.dart
│   └── ticket_selection_page.dart
│
├── sections/
│   ├── trending_section.dart
│   ├── upcoming_section.dart
│   ├── all_events_section.dart
│   ├── artists_section.dart
│   ├── offers_section.dart
│   └── benefits_section.dart
│   └── (All sections called on the home page)
│
├── classes/
│   ├── trending.dart
│   └── upcoming.dart
│   └── (Event structure classes)
│
├── models/
│   └── Main event model
│
└── widgets/
    ├── custom_textfield.dart
    ├── neopop_button.dart
    └── (Reusable widgets)
```

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Firebase account and project setup
- Seats.io account
- Razorpay account

### Installation

1. Clone the repository
```bash
git clone https://github.com/7-Seers/TixooApp.git
cd tixxo
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure Firebase
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Update Firebase configuration files

4. Configure API Keys
   - Add Seats.io API keys
   - Add Razorpay API keys

5. Run the application
```bash
flutter run
```

## Features

- User authentication and authorization
- Browse trending and upcoming events
- Detailed event and artist information
- Interactive seat selection with Seats.io
- Secure payment processing with Razorpay
- User profile management
- Ticket management and history
- Promoter details and listings
- Offers and benefits section

