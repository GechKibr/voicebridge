# VoiceBridge (Flutter Frontend)

VoiceBridge is a Flutter app for student complaint management, helpdesk support,
appointments, feedback, notifications, and announcements.

## Backend Project

- Backend GitHub repository: https://github.com/GechKibr/CMFS-.git


## Features

- Student dashboard with responsive sidebar/drawer navigation
- Submit complaint with category and CC officers
- My complaints with status/category filtering and complaint thread view
- Helpdesk chat and real-time call support (LiveKit)
- Announcements (public read, authenticated interactions)
- Notifications, appointments, and feedback forms
- Microsoft authentication support

## Tech Stack

- Flutter (Dart)
- Provider for state management
- REST API integration with token authentication
- LiveKit and WebRTC for calls

## Prerequisites

- Flutter SDK installed and configured
- Android Studio or VS Code with Flutter tooling
- Running backend API

## Project Setup

1. Clone this repository.
2. Install dependencies:

```bash
flutter pub get
```

3. Create an environment file named `.env` in the project root.
4. Add the required values:

```env
BACKEND_URL=http://127.0.0.1:8000
MICROSOFT_CLIENT_ID=your-client-id
MICROSOFT_TENANT_ID=common
MICROSOFT_REDIRECT_URI=com.voicebridge://callback
MICROSOFT_SCOPES=openid profile email offline_access
```

## Run the App

```bash
flutter run
```

## Backend API Base

The app expects backend endpoints under:

- `${BACKEND_URL}/api/...`

Example announcements endpoint:

- `${BACKEND_URL}/api/announcements/`

## Authentication Notes

- Login supports Microsoft and email/password.
- Registration flow uses Microsoft support.
- Keep sensitive secrets on backend only.

## Troubleshooting

- If packages are missing:

```bash
flutter clean
flutter pub get
```

- If backend calls fail, confirm:
- Backend server is running
- `BACKEND_URL` is reachable from device/emulator
- API routes are available under `/api/`

## Build

```bash
flutter build apk
```


