# Dermaire

Dermaire is a Flutter prototype for personal skin experiments. It includes onboarding, product and interaction management, experiment and check-in flows, reports, rewards, a safety-limited app guide, and a clinician workspace demonstration.

## Status

This repository is **not production medical software**. Authentication, camera analysis, OCR, messaging, notifications, clinical storage, consent enforcement, and server-side authorization require real services before human use. Demo screens and records are labelled in the UI.

## Architecture

- `lib/products/`: typed product domain, validation, repository, controller, and UI.
- `lib/access_control.dart`: role and permission policy used by the clinician demo.
- `lib/doctor_portal.dart`: clinician sign-in demo, authorized patient list, patient details, append-only notes, and local audit events.
- `lib/chatbot.dart`: deterministic help responses and urgent red-flag escalation.
- `lib/dermaire_state.dart`: shared prototype state and local preferences.
- `lib/app_shell.dart`: patient navigation and remaining prototype flows.

Product data and first-run preferences persist locally with `SharedPreferences`. Other health and experiment data is still prototype state.

## Verification

```sh
flutter analyze
flutter test
flutter build web
```

See `docs/READINESS_AUDIT.md` for the current readiness score, evidence, known limitations, and required production work.
