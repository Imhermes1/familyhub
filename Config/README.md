# Configuration Setup

This directory contains configuration files for Pulse external services.

## Setup Instructions

### 1. Supabase Configuration

1. Copy `Supabase.plist.template` to `Supabase.plist`:
   ```bash
   cp Supabase.plist.template Supabase.plist
   ```

2. Create a Supabase project at https://supabase.com

3. Get your project credentials:
   - Go to Settings → API
   - Copy the Project URL
   - Copy the `anon/public` key

4. Edit `Supabase.plist` and replace:
   - `your-project.supabase.co` with your actual project URL
   - `your-supabase-anon-key-here` with your anon key

5. Run the SQL migrations from `PULSE_MVP_PLAN.md` section 4 in your Supabase SQL editor

### 2. PostHog Configuration

1. Copy `PostHog.plist.template` to `PostHog.plist`:
   ```bash
   cp PostHog.plist.template PostHog.plist
   ```

2. Create a PostHog project at https://posthog.com

3. Get your API key:
   - Go to Project Settings
   - Copy your Project API Key

4. Edit `PostHog.plist` and replace:
   - `your-posthog-project-api-key-here` with your actual API key

### 3. Security Notes

- **NEVER commit the actual .plist files** (they are gitignored)
- Only commit the .template files
- Keep your API keys secure
- Use environment-specific keys for development vs production

### 4. Verification

After setup, verify your configuration:

1. Build the app in Xcode
2. Check console logs for successful initialization messages
3. Test authentication flow
4. Verify PostHog events are being tracked (check PostHog dashboard)

## File Structure

```
Config/
├── README.md                  # This file
├── Supabase.plist.template   # Template for Supabase config
├── PostHog.plist.template    # Template for PostHog config
├── Supabase.plist            # Your actual config (gitignored)
└── PostHog.plist             # Your actual config (gitignored)
```

## Troubleshooting

### Supabase Connection Issues
- Verify your project URL is correct
- Check that the anon key has the right permissions
- Ensure RLS policies are set up correctly
- Check App Transport Security settings in Info.plist

### PostHog Not Tracking
- Verify API key is correct
- Check network connectivity
- Look for console errors
- Verify PostHog.shared.initialize() is called in app startup

### Build Errors
- Make sure you copied the templates to .plist files
- Verify the files are in the Config directory
- Check that the .plist files are properly formatted XML
