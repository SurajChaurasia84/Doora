# Dooro

A production-style Flutter Task Management / Productivity app.

## Features

- Login and Registration UI with API integration (`reqres.in`)
- Home screen with task list fetched from API (`dummyjson.com`)
- Create, Edit, Delete task flow
- Task fields: Title, Description, Status, Due Date
- Pull-to-refresh and pagination (infinite scroll)
- Loading, empty, and error states with retry
- Token storage using `flutter_secure_storage`
- Local task caching using `shared_preferences`
- Light/Dark theme with smooth transition
- Basic unit test for validation module

## Setup Instructions

## Prerequisites

- Flutter SDK `3.38.x` (or compatible stable)
- Dart SDK `3.10.x`
- Android Studio / VS Code with Flutter plugin
- Android/iOS emulator or physical device

## Install and Run

```bash
flutter pub get
flutter run
```

## Run Tests

```bash
flutter test
```

## Static Analysis

```bash
flutter analyze
```

## API Configuration

Update API constants in:

- `lib/src/core/constants/api_constants.dart`

If using ReqRes auth endpoints, set your API key:

```dart
static const reqResApiKey = 'YOUR_REQRES_API_KEY';
```

## Demo Credentials (ReqRes)

- Email: `eve.holt@reqres.in`
- Login password: `cityslicka`
- Register password: `pistol`

## Architecture

The project follows a clean, feature-first structure:

```text
lib/src/
  core/                 # shared app-level code (theme, network, constants, storage)
  features/
    auth/
      data/             # API services
      domain/           # state/domain models
      presentation/     # screens + providers/controllers
    tasks/
      data/             # API + local cache services
      domain/           # task model + validation
      presentation/     # screens + providers/controllers + widgets
  shared/
    widgets/            # reusable UI components
```

Separation of concerns:

- `data`: HTTP calls, persistence, and external integrations
- `domain`: entities and validation logic
- `presentation`: UI + state orchestration

This keeps modules testable, maintainable, and easy to scale.

## State Management Choice

This app uses **Riverpod** (`flutter_riverpod`) with `StateNotifier`.

Why Riverpod:

- Predictable unidirectional data flow
- Clear dependency injection through providers
- Test-friendly controllers with minimal widget coupling
- Better scalability than local `setState` for multi-screen apps

How it is used here:

- `AuthController` manages auth lifecycle (restore/login/register/logout)
- `TaskController` manages task lifecycle (fetch/refresh/paginate/create/update/delete)
- UI listens to provider state and renders loading/empty/error/success accordingly

## Notes

- `reqres.in` is a mock auth API; registration works for supported test users only.
- User-created tasks are persisted locally and merged with remote task data.
