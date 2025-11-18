# Pulse - iOS 26 MVP

A family and friends safety and coordination app built with iOS 26, SwiftUI 6, Liquid Glass, Supabase, and PostHog.

## Project Structure

```
Pulse/
├── App/                       # App entry and root views
├── Features/                  # Feature modules
│   ├── Auth/                 # Authentication and onboarding
│   ├── PulseHome/            # Main check-in and status view
│   ├── Tasks/                # Tasks and notes
│   └── Settings/             # Settings and preferences
├── Core/                      # Core business logic
│   ├── Models/               # Data models (SwiftData + DTOs)
│   ├── Data/                 # Data management and caching
│   ├── Network/              # Supabase API layer
│   ├── Location/             # Location and Bluetooth managers
│   └── Analytics/            # PostHog integration
├── Utilities/                 # Helpers and extensions
└── Resources/                 # Assets and localization

PulseWidget/                   # Widget extension
├── Providers/                # Timeline providers
└── Views/                    # Widget layouts

PulseIntents/                  # App Intents for widget actions

Config/                        # Configuration files
```

## Key Technologies

- **SwiftUI 6** - Modern declarative UI
- **SwiftData** - Local persistence
- **Liquid Glass** - iOS 26 design language for navigation and controls
- **Supabase** - Backend (PostgreSQL + Realtime + Auth)
- **PostHog** - Analytics
- **WidgetKit** - Home screen widgets
- **App Intents** - Widget interactivity

## Liquid Glass Usage

Following Apple's guidelines, Liquid Glass is used for **navigation and control layers only**:

✅ **Used on:**
- Main check-in buttons (GlassEffectContainer)
- Group summary card
- Current mode card in settings
- Toolbar and tab bar buttons (.buttonStyle(.glass))
- Widget backgrounds (.containerBackground(.glass))

❌ **NOT used on:**
- List content (member status list, tasks list)
- Form fields
- Text content
- Scrolling areas

## Architecture

### Data Flow

```
User Action → PulseDataManager → Supabase Client
                ↓
          SwiftData (local cache)
                ↓
          App Group Store
                ↓
            Widget
```

### Key Components

**PulseDataManager** - Singleton managing all data operations
- Orchestrates Supabase, SwiftData, and App Group
- Published properties for reactive UI
- Handles sync and realtime updates

**AppGroupStore** - Widget data bridge
- Writes snapshots to shared container
- Enables widget to read data without Supabase calls

**SupabaseClient** - API wrapper
- Handles authentication
- Provides typed database operations
- Manages realtime subscriptions

## Setup Instructions

### 1. Install Dependencies

Add via Swift Package Manager:
- Supabase Swift SDK: `https://github.com/supabase/supabase-swift`
- PostHog iOS SDK: `https://github.com/PostHog/posthog-ios`

### 2. Configure Supabase

1. Create a Supabase project at https://supabase.com
2. Run the SQL migrations from `PULSE_MVP_PLAN.md` section 4
3. Update `Config/Supabase.plist` with your project URL and anon key

### 3. Configure PostHog

1. Create a PostHog project
2. Update `Config/PostHog.plist` with your API key

### 4. Configure App Groups

1. Add App Group capability to both Pulse and PulseWidget targets
2. Use identifier: `group.com.yourcompany.pulse`
3. Update `AppGroupStore.swift` if you change the identifier

### 5. Build and Run

1. Select Pulse target
2. Build for iOS 26+ simulator or device
3. Complete onboarding flow
4. Add widget to home screen

## Development Roadmap

See `PULSE_MVP_PLAN.md` for the complete 6-week development timeline.

**Week 1:** Foundation & Auth
**Week 2:** Core Pulse Features
**Week 3:** Widget & Basic UI
**Week 4:** Automation & Permissions
**Week 5:** Push Notifications & Polish
**Week 6:** Testing & Release Prep

## TODOs

Current implementation status:

- [x] Project structure scaffolded
- [x] SwiftData models defined
- [x] Basic UI views created with Liquid Glass
- [x] Widget layouts designed
- [x] App Intents defined
- [ ] Supabase SDK integration (install package)
- [ ] PostHog SDK integration (install package)
- [ ] Complete Supabase API implementations
- [ ] Location and Bluetooth managers
- [ ] Push notification setup
- [ ] Realtime subscription implementation
- [ ] Complete widget intent implementations
- [ ] End-to-end testing

## Notes

- This is a scaffold/blueprint for the MVP
- All TODO comments indicate where actual implementations are needed
- Focus on system defaults and simplicity
- Liquid Glass is only for controls, not content
- Privacy-first: all automation is opt-in
- Widget-first design for speed

## Resources

- [Liquid Glass Reference](https://github.com/conorluddy/LiquidGlassReference)
- [Supabase Swift Docs](https://supabase.com/docs/reference/swift)
- [PostHog iOS Docs](https://posthog.com/docs/libraries/ios)
- [WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [App Intents](https://developer.apple.com/documentation/appintents)
