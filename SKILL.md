---
name: projecthud
description: >-
  ProjectHUD — Voice-first, AI-powered HUD navigation and road-safety app
  for two-wheeler riders and auto/cab drivers in India. Flutter + Google ecosystem.
---

# ProjectHUD — Development Guardrails

## Safety Rule (NON-NEGOTIABLE)
> **Never design any interaction that requires the rider to read text, type,
> or look at the phone screen for more than 2 seconds while riding.**
> Every riding interaction must work by voice command or a single glance.

## Code Style
- **Language**: Dart (Flutter 3.x)
- **State management**: Riverpod 2.x (providers + AsyncNotifier)
- **Routing**: GoRouter
- **Architecture**: Feature-first folder structure under `lib/features/`
- **Naming**: snake_case for files, PascalCase for classes, camelCase for variables
- **Imports**: relative within features, package imports across features
- **Null safety**: strict, no `!` operators without documented rationale
- **Constants**: collected in `lib/app/constants/`
- **Linting**: `flutter_lints` + `analysis_options.yaml` strict rules

## Design System: "Asphalt + Signal Amber"
- Background: `#0C0E0F` (asphalt near-black)
- Panels: `#16191B` (dark grey)
- Primary text: `#FFFFFF` (white)
- Accent: `#FFB300` (Signal Amber — guidance/caution)
- Danger: `#FF3B30` (Signal Red — hazard alerts ONLY)
- Verified: `#35C759` (Green — confirmed states ONLY)
- Secondary text: `#9BA1A6` (cool grey)
- Borders: `#26292C` (dark line)
- **BANNED**: gradients, glassmorphism, neon glow, purple/blue AI schemes, decorative shadows
- Fonts: Barlow Semi Condensed (headings, speed, distance), Inter (body)
- One colour = one meaning, always

## HUD Mode Rules
- Maximum 3 elements: turn arrow + distance, speed, hazard icon
- All content in lower third — centre of rider's view stays empty
- Amber monochrome only
- Readable at arm's length in sunlight
- Screen stays awake (WakeLock)

## UX Rules
- 2-second rule (NHTSA): every piece of info readable in one glance ≤ 2 seconds
- Voice-first: all riding actions by voice
- Touch targets ≥ 64dp (only when stopped)
- Alerts: single pulse, then steady — no continuous flashing while riding
- Hazard icons inside triangles (road-sign style)

## Tech Stack (Google Only)
- Flutter + Dart
- Google Maps SDK, Directions API, Places API
- Firebase Auth, Firestore, Cloud Messaging, Cloud Storage
- Gemini API (voice assistant brain)
- Google Cloud Speech-to-Text / Text-to-Speech (Hindi + English)
- BigQuery (Phase 3 telemetry warehouse)
- Vertex AI (Phase 3 accident-risk model)
- Cloud Run (Phase 3 risk-scoring API)

## File Structure
```
lib/
├── main.dart
├── app/
│   ├── theme/          # Asphalt+Amber theme, typography
│   ├── routes/         # GoRouter configuration
│   ├── constants/      # App-wide constants
│   └── providers/      # Global providers
├── features/
│   ├── navigation/     # Maps, directions, ride engine
│   ├── setup/          # Destination search, vehicle mode
│   ├── hud/            # HUD mode display
│   ├── voice/          # STT/TTS, Gemini assistant
│   ├── hazards/        # Hazard reporting & consensus
│   ├── demo/           # Demo mode simulation
│   ├── ride_summary/   # Post-ride stats
│   ├── hud_device/     # BLE/Cast connection, simulator
│   ├── gig_integration/# Share sheet, deep links
│   ├── telemetry/      # Sensor events, upload
│   ├── risk_zones/     # Heatmap, predictive alerts
│   └── explainer/      # Phase 3 pitch screen
├── models/             # Shared data models
├── services/           # API services, Firebase
└── utils/              # Helpers, extensions
```

## Commit Convention
- `feat:` new feature
- `fix:` bug fix
- `style:` design system changes
- `docs:` documentation
- `refactor:` code restructuring
