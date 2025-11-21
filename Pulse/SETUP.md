# Pulse iOS App - Complete Setup Guide

Welcome to Pulse! This guide will help you get the app up and running.

## Quick Start

```bash
# Run the automated setup script
./setup.sh

# Then follow the instructions it provides
```

## Manual Setup (Alternative)

### Prerequisites

- Xcode 16.0+ (for iOS 26 support)
- macOS Sequoia or later
- Active Apple Developer account
- Supabase account (free tier works)
- PostHog account (free tier works)

### Step 1: Configure API Keys

#### Option A: Use the Setup Script

```bash
./setup.sh
```

#### Option B: Manual Configuration

1. **Supabase Setup**:
   ```bash
   cp Config/Supabase.plist.template Config/Supabase.plist
   ```

   Then edit `Config/Supabase.plist`:
   - Create a Supabase project at https://supabase.com
   - Go to Settings → API
   - Replace `your-project.supabase.co` with your Project URL
   - Replace `your-supabase-anon-key-here` with your anon/public key

2. **PostHog Setup**:
   ```bash
   cp Config/PostHog.plist.template Config/PostHog.plist
   ```

   Then edit `Config/PostHog.plist`:
   - Create a PostHog project at https://posthog.com
   - Go to Project Settings
   - Replace `your-posthog-project-api-key-here` with your API key

### Step 2: Set Up Supabase Database

1. Open your Supabase project dashboard
2. Go to the SQL Editor
3. Open `PULSE_MVP_PLAN.md` and find Section 4.1 (Database Tables)
4. Copy and execute each SQL block in order:
   - Create all tables (users, groups, group_members, status_events, tasks, notes, user_settings, push_tokens)
   - Enable RLS on all tables
   - Create RLS policies (Section 4.2)
   - Create database functions (Section 4.3)
   - Enable realtime (Section 4.4)

### Step 3: Install Swift Package Dependencies

1. Open `Pulse.xcodeproj` in Xcode
2. Go to **File → Add Packages...**
3. Add the following packages:

   **Supabase Swift SDK**:
   - URL: `https://github.com/supabase/supabase-swift`
   - Version: Latest

   **PostHog iOS SDK**:
   - URL: `https://github.com/PostHog/posthog-ios`
   - Version: Latest

4. Make sure both packages are added to the Pulse target (NOT PulseWidget)

### Step 4: Configure App Groups

1. Select the **Pulse** target in Xcode
2. Go to **Signing & Capabilities**
3. Click **+ Capability** → **App Groups**
4. Add identifier: `group.com.yourcompany.pulse`
   (Replace `yourcompany` with your team identifier)

5. Select the **PulseWidget** target
6. Repeat steps 2-4 with the same identifier

7. Update the identifier in code:
   - Open `Pulse/Core/Data/AppGroupStore.swift`
   - Change `group.com.yourcompany.pulse` to match your identifier

### Step 5: Configure Bundle Identifiers

1. Select the **Pulse** target
2. Change Bundle Identifier to: `com.yourcompany.pulse`

3. Select the **PulseWidget** target
4. Change Bundle Identifier to: `com.yourcompany.pulse.PulseWidget`

### Step 6: Build and Run

1. Select a simulator or device (iOS 26+)
2. Build the project (⌘B)
3. Fix any dependency resolution issues if they appear
4. Run the app (⌘R)

## Verification

### Test Supabase Connection

1. Launch the app
2. Check Xcode console for:
   ```
   Supabase client initialized
   ```
3. Try signing in with a test email
4. Check Supabase Auth dashboard for the new user

### Test PostHog Tracking

1. Check Xcode console for:
   ```
   PostHog track: app_opened {...}
   ```
2. Go to PostHog dashboard → Live Events
3. Verify events are appearing

### Test Location/Bluetooth

1. Go to Settings tab
2. Enable automation toggles
3. Check Xcode console for permission requests
4. Grant permissions in simulator/device
5. Check console for manager initialization messages

## Common Issues

### Build Errors

**"No such module 'Supabase'"**
- Make sure Supabase package is added via SPM
- Clean build folder (⌘⇧K)
- Reset package caches: File → Packages → Reset Package Caches

**"Cannot find 'PHGPostHog' in scope"**
- Make sure PostHog package is added
- Verify package is added to main app target

**"Failed to create ModelContainer"**
- SwiftData error - check iOS version is 18.0+
- Verify app group is configured correctly

### Runtime Errors

**"App Group container not found"**
- Verify App Groups capability is enabled
- Check identifier matches in both targets
- Update identifier in `AppGroupStore.swift`

**"Location permission denied"**
- Check Info.plist has location usage descriptions
- Reset simulator: Device → Erase All Content and Settings

**"Supabase connection failed"**
- Verify Supabase.plist has correct credentials
- Check network connectivity
- Verify Supabase project is not paused (free tier)

**"PostHog not tracking"**
- Verify PostHog.plist has correct API key
- Check console for initialization errors
- Verify PostHog project is active

## Development Workflow

### Making Changes

1. **Models**: Edit SwiftData models in `Pulse/Core/Models/SwiftData/`
2. **API**: Update Supabase APIs in `Pulse/Core/Network/`
3. **UI**: Add views in `Pulse/Features/`
4. **Widget**: Edit widget in `PulseWidget/`

### Testing

```bash
# Run unit tests
⌘U

# Test on simulator
⌘R

# Test widget
- Add widget to simulator home screen
- Long press home screen → tap + icon
- Search for "Pulse"
```

### Debugging

**Enable verbose logging**:
- Check console output for `🔍` debug messages
- Use `print()` statements liberally
- PostHog events show in console before being sent

**Test automation without devices**:
- Use simulation buttons in settings
- Bluetooth: `PulseBluetoothManager.shared.simulateCarConnect()`
- Location: Simulator → Features → Location → Custom Location

## Next Steps

Once setup is complete:

1. **Review the architecture**: Read `PULSE_MVP_PLAN.md`
2. **Understand the data flow**: See Section 5 of the plan
3. **Implement TODOs**: Search codebase for `// TODO:`
4. **Follow the timeline**: Section 7 has week-by-week tasks
5. **Test thoroughly**: Build each feature incrementally

## Getting Help

- **Architecture questions**: See `PULSE_MVP_PLAN.md`
- **Project overview**: See `Pulse/README.md`
- **Config issues**: See `Config/README.md`
- **Supabase docs**: https://supabase.com/docs
- **PostHog docs**: https://posthog.com/docs
- **Liquid Glass reference**: https://github.com/conorluddy/LiquidGlassReference

## Production Deployment

Before releasing to TestFlight/App Store:

1. **Update version numbers** in Info.plist
2. **Switch to production API keys**
   - Supabase production project
   - PostHog production environment
3. **Configure push notifications**
   - Set up APNs certificates
   - Update entitlements to production
4. **Test on real devices**
   - Location services on physical iPhone
   - Bluetooth car integration
5. **Create App Store screenshots**
6. **Write App Store description**
7. **Submit for review**

---

**Happy coding! 🚀**

For questions or issues, refer to the comprehensive documentation in this repository.
