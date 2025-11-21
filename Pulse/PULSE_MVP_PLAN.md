# Pulse iOS 26 MVP - Complete Implementation Plan

## 1. MVP Requirements Summary

### Product Vision
Pulse solves "text me when you get there" for families and friends through a minimal, respectful safety coordination app.

### Core Value Proposition
- **Single-tap status updates** ("I am here", "I am leaving", "On my way")
- **User-controlled automation** (Bluetooth, geofence, hourly pulse)
- **Zero constant tracking** - presence and reassurance, not surveillance
- **Fast widget access** for immediate updates without opening the app

### Key Differentiators
- Privacy-first: all automation is opt-in and clearly indicated
- Minimal design using iOS 26 Liquid Glass for navigation/controls only
- Widget-first experience for speed
- Shared tasks and notes for coordination beyond status

### MVP Feature Set

#### Must Have (Week 1-4)
- Three main status actions with Supabase sync
- Group member status list
- Basic widget (small + medium sizes)
- Manual check-ins only
- Settings with profile management
- Supabase authentication and database
- PostHog basic event tracking

#### Should Have (Week 4-5)
- Car Bluetooth automation
- Geofence automation
- Tasks with completion tracking
- Widget task interactions via App Intents
- Push notifications for status updates

#### Could Have (Week 5-6)
- Simple notes list
- PencilKit drawing surface
- Hourly pulse updates
- Large widget size
- Advanced PostHog analytics

#### Won't Have (Post-MVP)
- Multiple groups
- Direct messaging
- Route tracking
- Photo sharing
- Calendar integration

---

## 2. Detailed UX Flows

### 2.1 First Launch Flow

```
Launch → Supabase Auth (Magic Link or Social) → Profile Setup (Name + Emoji) →
Permission Requests (Location + Notifications) → Join/Create Group → Home View
```

**Screens:**
1. Welcome screen with "Get Started" glass button
2. Auth screen (Supabase Auth UI or custom)
3. Profile form (name text field, emoji picker)
4. Permission cards with system prompts
5. Group creation/join (enter code or create new)

**Design notes:**
- Use `.glassEffect(.regular)` on "Get Started" and "Continue" buttons
- Keep forms minimal with standard `TextField` and system keyboards
- No glass on form backgrounds - flat and legible

### 2.2 Pulse Home Tab Flow

**Layout Structure:**
```
┌─────────────────────────────┐
│ Nav Bar (Glass toolbar)     │ ← .toolbar with .glass buttons
├─────────────────────────────┤
│                             │
│ Group Summary Card          │ ← GlassEffectContainer
│ [My Family • 4 members]     │    with tinted glass
│                             │
├─────────────────────────────┤
│                             │
│  [I am here] [Leaving]      │ ← GlassEffectContainer with
│           [On my way]       │    .glassProminent + .glass buttons
│                             │
├─────────────────────────────┤
│ Member Status List          │ ← Standard List (NO glass)
│ • Mom - At home (5m ago)    │
│ • Dad - On the way (12m)    │
│ • Sister - At work (1h)     │
│                             │
└─────────────────────────────┘
```

**User Interactions:**

1. **Tap "I am here"**
   - Button shows pressed state (Liquid Glass handles animation)
   - Haptic feedback
   - Immediate optimistic UI update (local status changes)
   - Background: Create status_event in Supabase
   - Update SwiftData cache
   - Write to App Group for widget
   - Trigger widget reload
   - Send push to group members
   - PostHog event: `check_in_performed` with type="arrived"

2. **Tap "Leaving" or "On my way"**
   - Same flow as above, different status type
   - PostHog event type varies

3. **Tap member row**
   - Navigate to member detail view (future)
   - For MVP: show simple sheet with recent history

4. **Toolbar actions**
   - Leading: Group selector (if multi-group in future)
   - Trailing: Manual check-in sheet with location note field

**Auto Mode Indicator:**
```
If automation enabled:
  Show small badge on group card: "Auto updates: ON"
  Badge uses .glassEffect(.regular.tint(.green))
```

### 2.3 Tasks Tab Flow

**Layout Structure:**
```
┌─────────────────────────────┐
│ Nav Bar                     │
│ [+ Add Task] (glass button) │
├─────────────────────────────┤
│ Segmented Control           │ ← System segmented control
│ [Tasks] [Notes]             │
├─────────────────────────────┤
│ Task List (NO GLASS)        │ ← Standard List
│ ○ Buy groceries             │
│ ✓ Pick up dry cleaning      │
│ ○ Call plumber              │
│                             │
└─────────────────────────────┘
```

**Interactions:**

1. **Tap task row**
   - Toggle completion state
   - Update SwiftData
   - Sync to Supabase
   - Reload widget timeline
   - PostHog: `task_completed` or `task_uncompleted`

2. **Tap + Add Task**
   - Present sheet with text field
   - Use `.glassProminent` on "Add" button
   - Assign to user or group
   - Create in Supabase and SwiftData
   - PostHog: `task_added`

3. **Swipe to delete**
   - Standard iOS swipe actions
   - Confirm deletion
   - Soft delete in Supabase

**Notes View (Segmented):**
- Simple list of text notes
- Tap to edit inline or in sheet
- Swipe to delete
- Notes table in Supabase

**Drawing View (Future):**
- PencilKit canvas
- Save as image to Supabase storage
- Store metadata in notes table

### 2.4 Settings Tab Flow

**Layout Structure:**
```
┌─────────────────────────────┐
│ Settings                    │
├─────────────────────────────┤
│ Current Mode Card (Glass)   │ ← Small hero card with
│ "Auto updates: Active"      │    .glassEffect(.regular)
│ Last update: 5 min ago      │
├─────────────────────────────┤
│ Form Sections (NO GLASS)    │
│                             │
│ PROFILE                     │
│ Name: [John]                │
│ Emoji: [👤]                 │
│                             │
│ GROUP                       │
│ My Family                   │
│ 4 members                   │
│ Invite Code: ABC123         │
│                             │
│ AUTOMATION                  │
│ ⊙ Car Bluetooth     [toggle]│
│ ⊙ Geofences         [toggle]│
│ ⊙ Hourly pulse      [toggle]│
│                             │
│ PRIVACY                     │
│ ⊙ Manual only mode  [toggle]│
│                             │
│ PERMISSIONS                 │
│ Location: Always            │
│ Notifications: Enabled      │
│                             │
└─────────────────────────────┘
```

**Key Settings:**

1. **Manual Only Mode Toggle**
   - Master override for all automation
   - When ON: disable all auto updates, show clear indicator
   - PostHog: `settings_changed` with key="manual_mode"

2. **Automation Toggles**
   - Each toggle grayed out if Manual Mode is ON
   - Car Bluetooth: Register for Core Bluetooth notifications
   - Geofence: Create CLCircularRegion for home/work
   - Hourly pulse: Schedule background updates

3. **Permission Status**
   - Read-only indicators
   - Tap to open Settings app (using `UIApplication.openSettingsURLString`)

### 2.5 Widget UX Flow

**Small Widget:**
```
┌─────────────────┐
│ Pulse           │
│                 │
│ You: At home    │
│ 5 min ago       │
│                 │
│ [Check in] ➔    │ ← App Intent button
└─────────────────┘
```

**Medium Widget:**
```
┌────────────────────────────┐
│ My Family • Updated 5m ago │
│                            │
│ Mom      At home      ✓    │
│ Dad      On the way   →    │
│ Sister   At work      ✓    │
│                            │
│ ○ Buy groceries            │
│                            │
│ [I am here] [Refresh] ↻    │
└────────────────────────────┘
```

**Interactions:**
- All buttons use App Intents (no closures)
- Tap "Check in" → MarkSafeIntent → status update
- Tap task row → TickTaskIntent → toggle completion
- Tap "Refresh" → RefreshPulseIntent → reload from Supabase

**Background:**
- Use `.containerBackground(.glass, for: .widget)` for proper Liquid Glass integration
- Timeline updates every 5 minutes or on widget reload calls

**Widget Configuration:**
- IntentConfiguration for group selection (if multi-group)
- For MVP: use default group

---

## 3. Liquid Glass Implementation Strategy

### 3.1 Where to Use Liquid Glass

**DO USE on:**
- ✅ Navigation bars and toolbars (automatic in iOS 26)
- ✅ Tab bars (automatic)
- ✅ Primary/secondary action buttons via `.buttonStyle(.glass)` and `.glassProminent`
- ✅ Small hero cards that summarize state (group card, settings mode card)
- ✅ Floating control clusters in `GlassEffectContainer`

**DO NOT USE on:**
- ❌ List backgrounds (use system List)
- ❌ Form fields (use system TextField, TextEditor)
- ❌ Content text (use system Text)
- ❌ Table rows
- ❌ Scrolling content areas

### 3.2 Specific API Usage Map

| Component | API | Notes |
|-----------|-----|-------|
| Main check-in buttons | `GlassEffectContainer { HStack { Button...buttonStyle(.glassProminent) } }` | Shared sampling region |
| Group summary card | `.glassEffect(.regular.tint(.blue))` | Tinted for visual hierarchy |
| Toolbar buttons | `.buttonStyle(.glass)` | System handles interaction |
| Settings mode card | `.glassEffect(.regular)` | Default glass |
| Widget background | `.containerBackground(.glass, for: .widget)` | Widget-specific API |
| Accessibility fallback | `.glassEffect(.identity)` when reduce transparency | Turns glass off |

### 3.3 Code Examples

**Home View Main Actions:**
```swift
GlassEffectContainer {
    HStack(spacing: 16) {
        Button {
            viewModel.checkIn(type: .arrived)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "location.fill")
                    .font(.title2)
                Text("I am here")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.glassProminent)
        .tint(.green)

        Button {
            viewModel.checkIn(type: .leaving)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                Text("Leaving")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.glass)

        Button {
            viewModel.checkIn(type: .onTheWay)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: "car.fill")
                    .font(.title2)
                Text("On my way")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.glass)
    }
    .padding(.horizontal)
}
```

**Group Summary Card:**
```swift
VStack(alignment: .leading, spacing: 8) {
    HStack {
        Text(group.name)
            .font(.headline)
        Spacer()
        if automationEnabled {
            Label("Auto", systemImage: "bolt.fill")
                .font(.caption)
                .foregroundStyle(.green)
        }
    }

    Text("\(group.memberCount) members • Last update \(lastUpdateText)")
        .font(.subheadline)
        .foregroundStyle(.secondary)
}
.padding()
.glassEffect(.regular.tint(.blue))
```

**Toolbar:**
```swift
.toolbar {
    ToolbarItem(placement: .topBarLeading) {
        Button {
            showGroupPicker = true
        } label: {
            Label(currentGroup.name, systemImage: "person.3")
        }
        .buttonStyle(.glass)
    }

    ToolbarItem(placement: .topBarTrailing) {
        Button {
            showManualCheckIn = true
        } label: {
            Image(systemName: "plus.circle.fill")
        }
        .buttonStyle(.glassProminent)
    }
}
```

**Accessibility Support:**
```swift
@Environment(\.accessibilityReduceTransparency) var reduceTransparency

var glassVariant: Glass {
    reduceTransparency ? .identity : .regular
}

// Usage:
.glassEffect(glassVariant)
```

---

## 4. Supabase Schema Design

### 4.1 Database Tables

```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL,
    emoji TEXT DEFAULT '👤',
    phone_number TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Groups table
CREATE TABLE groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    invite_code TEXT UNIQUE NOT NULL,
    created_by UUID REFERENCES users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Group members junction table
CREATE TABLE group_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member' CHECK (role IN ('admin', 'member')),
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(group_id, user_id)
);

-- Status events
CREATE TABLE status_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    status_type TEXT NOT NULL CHECK (status_type IN ('arrived', 'leaving', 'on_the_way', 'pulse')),
    trigger_type TEXT DEFAULT 'manual' CHECK (trigger_type IN ('manual', 'bluetooth', 'geofence', 'hourly')),
    location_name TEXT,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for fast recent status queries
CREATE INDEX idx_status_events_group_created
ON status_events(group_id, created_at DESC);

CREATE INDEX idx_status_events_user_created
ON status_events(user_id, created_at DESC);

-- Tasks table
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    created_by UUID REFERENCES users(id),
    assigned_to UUID REFERENCES users(id),
    title TEXT NOT NULL,
    completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    completed_by UUID REFERENCES users(id),
    due_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notes table
CREATE TABLE notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    note_type TEXT DEFAULT 'text' CHECK (note_type IN ('text', 'drawing')),
    drawing_url TEXT, -- Supabase Storage URL if drawing
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User settings table
CREATE TABLE user_settings (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    bluetooth_automation BOOLEAN DEFAULT FALSE,
    geofence_automation BOOLEAN DEFAULT FALSE,
    hourly_pulse BOOLEAN DEFAULT FALSE,
    manual_only_mode BOOLEAN DEFAULT FALSE,
    home_latitude DOUBLE PRECISION,
    home_longitude DOUBLE PRECISION,
    home_radius_meters INTEGER DEFAULT 100,
    work_latitude DOUBLE PRECISION,
    work_longitude DOUBLE PRECISION,
    work_radius_meters INTEGER DEFAULT 100,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Push notification tokens
CREATE TABLE push_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    device_id TEXT,
    platform TEXT DEFAULT 'ios',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, token)
);
```

### 4.2 Row Level Security Policies

```sql
-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE status_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;

-- Users: Can only see and update own profile
CREATE POLICY "Users can view own profile"
ON users FOR SELECT
USING (auth.uid() = auth_user_id);

CREATE POLICY "Users can update own profile"
ON users FOR UPDATE
USING (auth.uid() = auth_user_id);

CREATE POLICY "Users can insert own profile"
ON users FOR INSERT
WITH CHECK (auth.uid() = auth_user_id);

-- Groups: Can see groups they're a member of
CREATE POLICY "Users can view their groups"
ON groups FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM group_members
        WHERE group_members.group_id = groups.id
        AND group_members.user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    )
);

CREATE POLICY "Users can create groups"
ON groups FOR INSERT
WITH CHECK (
    created_by IN (
        SELECT id FROM users WHERE auth_user_id = auth.uid()
    )
);

-- Group members: Can see members of their groups
CREATE POLICY "Users can view group members"
ON group_members FOR SELECT
USING (
    group_id IN (
        SELECT group_id FROM group_members
        WHERE user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    )
);

CREATE POLICY "Users can join groups"
ON group_members FOR INSERT
WITH CHECK (
    user_id IN (
        SELECT id FROM users WHERE auth_user_id = auth.uid()
    )
);

-- Status events: Can see events from their groups
CREATE POLICY "Users can view group status events"
ON status_events FOR SELECT
USING (
    group_id IN (
        SELECT group_id FROM group_members
        WHERE user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    )
);

CREATE POLICY "Users can create status events"
ON status_events FOR INSERT
WITH CHECK (
    user_id IN (
        SELECT id FROM users WHERE auth_user_id = auth.uid()
    )
    AND group_id IN (
        SELECT group_id FROM group_members
        WHERE user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    )
);

-- Tasks: Can see tasks from their groups
CREATE POLICY "Users can view group tasks"
ON tasks FOR SELECT
USING (
    group_id IN (
        SELECT group_id FROM group_members
        WHERE user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    )
);

CREATE POLICY "Users can create tasks"
ON tasks FOR INSERT
WITH CHECK (
    created_by IN (
        SELECT id FROM users WHERE auth_user_id = auth.uid()
    )
);

CREATE POLICY "Users can update group tasks"
ON tasks FOR UPDATE
USING (
    group_id IN (
        SELECT group_id FROM group_members
        WHERE user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    )
);

-- Notes: Similar to tasks
CREATE POLICY "Users can view group notes"
ON notes FOR SELECT
USING (
    group_id IN (
        SELECT group_id FROM group_members
        WHERE user_id IN (
            SELECT id FROM users WHERE auth_user_id = auth.uid()
        )
    )
);

CREATE POLICY "Users can create notes"
ON notes FOR INSERT
WITH CHECK (
    user_id IN (
        SELECT id FROM users WHERE auth_user_id = auth.uid()
    )
);

-- User settings: Own settings only
CREATE POLICY "Users can view own settings"
ON user_settings FOR SELECT
USING (
    user_id IN (
        SELECT id FROM users WHERE auth_user_id = auth.uid()
    )
);

CREATE POLICY "Users can update own settings"
ON user_settings FOR UPDATE
USING (
    user_id IN (
        SELECT id FROM users WHERE auth_user_id = auth.uid()
    )
);

CREATE POLICY "Users can insert own settings"
ON user_settings FOR INSERT
WITH CHECK (
    user_id IN (
        SELECT id FROM users WHERE auth_user_id = auth.uid()
    )
);

-- Push tokens: Own tokens only
CREATE POLICY "Users can manage own push tokens"
ON push_tokens FOR ALL
USING (
    user_id IN (
        SELECT id FROM users WHERE auth_user_id = auth.uid()
    )
);
```

### 4.3 Database Functions

```sql
-- Function to generate unique invite codes
CREATE OR REPLACE FUNCTION generate_invite_code()
RETURNS TEXT AS $$
DECLARE
    chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    result TEXT := '';
    i INTEGER;
BEGIN
    FOR i IN 1..6 LOOP
        result := result || substr(chars, floor(random() * length(chars) + 1)::INTEGER, 1);
    END LOOP;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-generate invite codes
CREATE OR REPLACE FUNCTION set_invite_code()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.invite_code IS NULL THEN
        NEW.invite_code := generate_invite_code();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER groups_invite_code_trigger
BEFORE INSERT ON groups
FOR EACH ROW
EXECUTE FUNCTION set_invite_code();

-- Function to get latest status per user in a group
CREATE OR REPLACE FUNCTION get_group_latest_statuses(p_group_id UUID)
RETURNS TABLE (
    user_id UUID,
    display_name TEXT,
    emoji TEXT,
    status_type TEXT,
    trigger_type TEXT,
    location_name TEXT,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT ON (u.id)
        u.id as user_id,
        u.display_name,
        u.emoji,
        se.status_type,
        se.trigger_type,
        se.location_name,
        se.created_at
    FROM users u
    INNER JOIN group_members gm ON gm.user_id = u.id
    LEFT JOIN status_events se ON se.user_id = u.id AND se.group_id = p_group_id
    WHERE gm.group_id = p_group_id
    ORDER BY u.id, se.created_at DESC NULLS LAST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 4.4 Realtime Subscriptions

```sql
-- Enable realtime for status updates
ALTER PUBLICATION supabase_realtime ADD TABLE status_events;
ALTER PUBLICATION supabase_realtime ADD TABLE tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE notes;
```

---

## 5. Data Sync Architecture

### 5.1 Data Flow Diagram

```
┌─────────────┐
│   Widget    │ ← Reads from App Group (fast, local)
└─────────────┘
       ↑
       │ reloadTimelines()
       │
┌──────────────────────────────────────────┐
│         App Group Container              │
│  • CachedPulseSnapshot.json             │
│  • LastWidgetUpdate timestamp           │
└──────────────────────────────────────────┘
       ↑
       │ Write snapshot
       │
┌──────────────────────────────────────────┐
│           SwiftData Store                │
│  • UserProfile                           │
│  • PulseStatus (cached events)           │
│  • TaskItem                              │
│  • Note                                  │
└──────────────────────────────────────────┘
       ↑                    ↓
       │ Sync               │ Read
       │                    │
┌──────────────────────────────────────────┐
│        Supabase Client                   │
│  • StatusAPI                             │
│  • TaskAPI                               │
│  • Realtime subscriptions                │
└──────────────────────────────────────────┘
       ↑
       │ PostgreSQL + RLS
       │
┌──────────────────────────────────────────┐
│     Supabase PostgreSQL Database         │
└──────────────────────────────────────────┘
```

### 5.2 Sync Strategies

**Strategy 1: User Action → Full Sync**
```
User taps "I am here"
  ↓
1. Create PulseStatus in SwiftData (optimistic)
2. POST to Supabase status_events
3. On success: update SwiftData with server ID
4. Write snapshot to App Group
5. Call WidgetCenter.shared.reloadAllTimelines()
6. Show success feedback
```

**Strategy 2: Background Sync (Realtime)**
```
Supabase sends realtime event
  ↓
1. RealtimeManager receives insert/update
2. Update SwiftData model
3. Write snapshot to App Group
4. Reload widget timelines
5. Show local notification (if app in background)
```

**Strategy 3: Widget Intent → Direct Write**
```
User taps widget button
  ↓
1. App Intent performs action
2. Write directly to Supabase (background URLSession)
3. On completion: update App Group snapshot
4. Return IntentResult
5. Background refresh updates SwiftData when app next launches
```

### 5.3 App Group Setup

**App Group Identifier:**
```
group.com.yourcompany.pulse
```

**Shared Container Structure:**
```
group.com.yourcompany.pulse/
  ├── PulseSnapshot.json
  ├── LastUpdate.txt
  └── WidgetCache/
      ├── members.json
      └── tasks.json
```

**PulseSnapshot.json Schema:**
```json
{
  "groupName": "My Family",
  "memberCount": 4,
  "lastUpdated": "2025-11-18T10:30:00Z",
  "members": [
    {
      "id": "uuid",
      "displayName": "Mom",
      "emoji": "👩",
      "statusType": "arrived",
      "statusText": "At home",
      "locationName": "Home",
      "timestamp": "2025-11-18T10:25:00Z",
      "minutesAgo": 5
    }
  ],
  "topTasks": [
    {
      "id": "uuid",
      "title": "Buy groceries",
      "completed": false,
      "assignedTo": "Dad"
    }
  ]
}
```

### 5.4 Code Architecture

**PulseDataManager (Singleton):**
```swift
@MainActor
class PulseDataManager: ObservableObject {
    static let shared = PulseDataManager()

    let supabaseClient: SupabaseClient
    let modelContext: ModelContext
    let appGroupStore: AppGroupStore
    let realtimeManager: RealtimeManager

    @Published var currentUser: UserProfile?
    @Published var currentGroup: Group?
    @Published var statuses: [PulseStatus] = []
    @Published var tasks: [TaskItem] = []

    func initialize() async throws
    func checkIn(type: StatusType, trigger: TriggerType) async throws
    func syncFromSupabase() async throws
    func updateWidget()
}
```

**AppGroupStore:**
```swift
class AppGroupStore {
    private let containerURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    func writeSnapshot(_ snapshot: PulseSnapshot) throws
    func readSnapshot() throws -> PulseSnapshot?
    func updateLastRefresh(_ date: Date)
}
```

---

## 6. PostHog Integration Plan

### 6.1 Event Taxonomy

| Event Name | Properties | Trigger |
|------------|-----------|---------|
| `app_opened` | `session_id`, `user_id`, `group_id` | App launch |
| `check_in_performed` | `status_type`, `trigger_type`, `group_id` | Manual or auto check-in |
| `auto_update_triggered` | `trigger_source` (bluetooth/geofence/hourly), `status_type` | Automation fires |
| `task_added` | `group_id`, `assigned_to` | New task created |
| `task_completed` | `task_id`, `completed_by`, `time_to_complete_hours` | Task marked done |
| `task_uncompleted` | `task_id` | Task unmarked |
| `widget_action_used` | `action_type`, `widget_size` | Widget button tapped |
| `settings_changed` | `setting_key`, `new_value` | User changes setting |
| `permission_requested` | `permission_type` | System permission prompt |
| `permission_granted` | `permission_type` | User grants permission |
| `permission_denied` | `permission_type` | User denies permission |
| `group_created` | `group_id`, `member_count` | New group |
| `group_joined` | `group_id`, `invite_code` | Join via code |
| `note_created` | `note_type` (text/drawing) | New note |

### 6.2 PostHog Setup

**PostHogManager.swift:**
```swift
import PostHog

class PostHogManager {
    static let shared = PostHogManager()
    private var client: PHGPostHog?

    func initialize(apiKey: String) {
        let config = PHGPostHogConfiguration(apiKey: apiKey, host: "https://app.posthog.com")
        client = PHGPostHog.setup(with: config)
    }

    func identify(userId: String, properties: [String: Any] = [:]) {
        client?.identify(userId, properties: properties)
    }

    func track(_ event: String, properties: [String: Any] = [:]) {
        client?.capture(event, properties: properties)
    }

    func screenViewed(_ screenName: String) {
        client?.screen(screenName)
    }
}
```

**Usage Examples:**
```swift
// App launch
PostHogManager.shared.track("app_opened", properties: [
    "session_id": sessionID,
    "user_id": currentUser.id,
    "group_id": currentGroup.id
])

// Check-in
PostHogManager.shared.track("check_in_performed", properties: [
    "status_type": "arrived",
    "trigger_type": "manual",
    "group_id": currentGroup.id
])

// Settings change
PostHogManager.shared.track("settings_changed", properties: [
    "setting_key": "bluetooth_automation",
    "new_value": true
])
```

### 6.3 Privacy Considerations

**DO track:**
- Feature usage (which buttons, which screens)
- Automation trigger types (bluetooth vs geofence vs manual)
- Task completion rates
- Widget interaction rates
- Error events

**DO NOT track:**
- Raw coordinates or addresses
- Message content or notes text
- User names or phone numbers
- Precise timestamps that could reveal patterns

**User Control:**
- Provide analytics opt-out toggle in Settings
- Respect Do Not Track if enabled
- Anonymous mode option for extra privacy

---

## 7. 4-6 Week Development Timeline

### Week 1: Foundation & Auth
**Goal: Project setup, Supabase integration, authentication**

**Days 1-2:**
- [ ] Create Xcode project with iOS 26 target
- [ ] Configure App Groups and WidgetKit extension
- [ ] Add SwiftData model container
- [ ] Set up Supabase project and database schema
- [ ] Run all migration SQL scripts
- [ ] Test RLS policies with Supabase client

**Days 3-4:**
- [ ] Implement SupabaseClient wrapper
- [ ] Build authentication flow (magic link or OAuth)
- [ ] Create UserProfile SwiftData model
- [ ] Build profile setup screen
- [ ] Implement PostHog initialization

**Days 5-7:**
- [ ] Build group creation and joining flow
- [ ] Implement GroupMember SwiftData models
- [ ] Create invite code generation and validation
- [ ] Test full onboarding flow
- [ ] Basic error handling and loading states

**Deliverable:** Working auth and onboarding

---

### Week 2: Core Pulse Features
**Goal: Check-in functionality, status sync, member list**

**Days 8-10:**
- [ ] Build PulseHomeView with Liquid Glass layout
- [ ] Implement GlassEffectContainer for main buttons
- [ ] Create PulseStatus SwiftData model
- [ ] Build StatusAPI for Supabase operations
- [ ] Implement optimistic UI updates

**Days 11-12:**
- [ ] Build PulseDataManager singleton
- [ ] Implement check-in flow (manual only)
- [ ] Create AppGroupStore for widget data
- [ ] Test Supabase → SwiftData → App Group pipeline

**Days 13-14:**
- [ ] Build member status list with List view
- [ ] Implement Supabase Realtime subscriptions
- [ ] Add RealtimeManager for live updates
- [ ] Test multi-device sync
- [ ] Add PostHog tracking for check-ins

**Deliverable:** Working check-in system with live updates

---

### Week 3: Widget & Basic UI
**Goal: Functional widget, task list, settings foundation**

**Days 15-17:**
- [ ] Create PulseWidget with TimelineProvider
- [ ] Build small and medium widget layouts
- [ ] Implement App Intents (MarkSafeIntent, RefreshPulseIntent)
- [ ] Configure widget background with Liquid Glass
- [ ] Test widget updates via WidgetCenter

**Days 18-19:**
- [ ] Build TasksView with List interface
- [ ] Create TaskItem SwiftData model
- [ ] Implement TaskAPI for Supabase
- [ ] Add task creation and completion
- [ ] Add TickTaskIntent for widget

**Days 20-21:**
- [ ] Build SettingsView with Form
- [ ] Create current mode hero card with glass
- [ ] Add profile editing (name, emoji)
- [ ] Build group info section
- [ ] Add basic automation toggles (UI only)

**Deliverable:** Functional widget, task system, settings UI

---

### Week 4: Automation & Permissions
**Goal: Location, Bluetooth, geofence automation**

**Days 22-24:**
- [ ] Implement PulseLocationManager with CoreLocation
- [ ] Request and handle location permissions
- [ ] Build geofence creation and monitoring
- [ ] Store home/work locations in UserSettings
- [ ] Test geofence entry/exit triggers

**Days 25-26:**
- [ ] Implement PulseBluetoothManager with CoreBluetooth
- [ ] Detect car Bluetooth connect/disconnect
- [ ] Trigger status updates on BT events
- [ ] Add manual only mode override logic

**Days 27-28:**
- [ ] Wire automation toggles to managers
- [ ] Implement background task for hourly pulse
- [ ] Add clear UI indicators for auto mode
- [ ] Test all automation triggers
- [ ] Add PostHog events for auto updates

**Deliverable:** Full automation system with permissions

---

### Week 5: Push Notifications & Polish
**Goal: Push notifications, notes, UI refinement**

**Days 29-31:**
- [ ] Configure APNs and Supabase Functions for push
- [ ] Implement push token registration
- [ ] Build notification sending on status updates
- [ ] Handle notification taps (deep linking)
- [ ] Test notification delivery

**Days 32-33:**
- [ ] Build NotesView with simple text list
- [ ] Create Note SwiftData model and API
- [ ] Add note creation and deletion
- [ ] Optionally add PencilKit drawing surface

**Days 34-35:**
- [ ] UI polish: spacing, fonts, colors
- [ ] Accessibility audit (VoiceOver, Dynamic Type)
- [ ] Reduce transparency support for glass
- [ ] Error state improvements
- [ ] Loading state refinements

**Deliverable:** Notifications working, notes feature, polished UI

---

### Week 6: Testing & Release Prep
**Goal: Bug fixes, testing, App Store preparation**

**Days 36-38:**
- [ ] End-to-end testing of all flows
- [ ] Multi-device testing
- [ ] Edge case handling (offline, poor network)
- [ ] Memory leak checking with Instruments
- [ ] Performance optimization

**Days 39-40:**
- [ ] App Store screenshots and preview video
- [ ] Write App Store description
- [ ] Create privacy policy
- [ ] TestFlight build and internal testing

**Days 41-42:**
- [ ] Fix critical bugs from TestFlight
- [ ] Final PostHog event validation
- [ ] Submit to App Store review
- [ ] Prepare launch plan

**Deliverable:** App Store submission ready

---

## 8. File Structure Implementation

### Complete File Tree

```
Pulse/
├── Pulse.xcodeproj
├── Pulse/
│   ├── PulseApp.swift
│   ├── Info.plist
│   ├── Pulse.entitlements
│   │
│   ├── App/
│   │   ├── RootView.swift
│   │   ├── AppDelegate.swift
│   │   └── SceneDelegate.swift (if needed)
│   │
│   ├── Features/
│   │   ├── Auth/
│   │   │   ├── WelcomeView.swift
│   │   │   ├── AuthView.swift
│   │   │   ├── ProfileSetupView.swift
│   │   │   └── GroupJoinView.swift
│   │   │
│   │   ├── PulseHome/
│   │   │   ├── PulseHomeView.swift
│   │   │   ├── PulseStatusList.swift
│   │   │   ├── GroupSummaryCard.swift
│   │   │   ├── CheckInButtonsView.swift
│   │   │   └── MemberStatusRow.swift
│   │   │
│   │   ├── Tasks/
│   │   │   ├── TasksView.swift
│   │   │   ├── TaskRow.swift
│   │   │   ├── AddTaskSheet.swift
│   │   │   ├── NotesView.swift
│   │   │   ├── NoteRow.swift
│   │   │   └── DrawingView.swift (PencilKit)
│   │   │
│   │   └── Settings/
│   │       ├── SettingsView.swift
│   │       ├── ProfileSection.swift
│   │       ├── GroupSection.swift
│   │       ├── AutomationSection.swift
│   │       ├── PrivacySection.swift
│   │       └── CurrentModeCard.swift
│   │
│   ├── Core/
│   │   ├── Models/
│   │   │   ├── SwiftData/
│   │   │   │   ├── UserProfile.swift
│   │   │   │   ├── Group.swift
│   │   │   │   ├── PulseStatus.swift
│   │   │   │   ├── TaskItem.swift
│   │   │   │   └── Note.swift
│   │   │   │
│   │   │   └── DTO/
│   │   │       ├── StatusEventDTO.swift
│   │   │       ├── TaskDTO.swift
│   │   │       └── GroupMemberDTO.swift
│   │   │
│   │   ├── Data/
│   │   │   ├── PulseDataManager.swift
│   │   │   ├── AppGroupStore.swift
│   │   │   ├── ModelContainer+Pulse.swift
│   │   │   └── RealtimeManager.swift
│   │   │
│   │   ├── Location/
│   │   │   ├── PulseLocationManager.swift
│   │   │   ├── GeofenceManager.swift
│   │   │   └── PulseBluetoothManager.swift
│   │   │
│   │   ├── Network/
│   │   │   ├── SupabaseClient.swift
│   │   │   ├── StatusAPI.swift
│   │   │   ├── TaskAPI.swift
│   │   │   ├── UserAPI.swift
│   │   │   ├── GroupAPI.swift
│   │   │   └── NetworkError.swift
│   │   │
│   │   └── Analytics/
│   │       ├── PostHogManager.swift
│   │       └── AnalyticsEvent.swift
│   │
│   ├── Utilities/
│   │   ├── Extensions/
│   │   │   ├── Date+RelativeTime.swift
│   │   │   ├── View+Liquid Glass.swift
│   │   │   └── Color+Pulse.swift
│   │   │
│   │   └── Helpers/
│   │       ├── HapticManager.swift
│   │       └── NotificationManager.swift
│   │
│   └── Resources/
│       ├── Assets.xcassets/
│       ├── Localizable.strings
│       └── LaunchScreen.storyboard
│
├── PulseWidget/
│   ├── PulseWidgetBundle.swift
│   ├── PulseWidget.swift
│   ├── PulseWidgetEntry.swift
│   ├── Providers/
│   │   ├── PulseTimelineProvider.swift
│   │   └── WidgetDataLoader.swift
│   ├── Views/
│   │   ├── SmallWidgetView.swift
│   │   ├── MediumWidgetView.swift
│   │   └── LargeWidgetView.swift
│   ├── Info.plist
│   └── PulseWidget.entitlements
│
├── PulseIntents/
│   ├── MarkSafeIntent.swift
│   ├── MarkLeavingIntent.swift
│   ├── MarkOnTheWayIntent.swift
│   ├── TickTaskIntent.swift
│   └── RefreshPulseIntent.swift
│
├── Config/
│   ├── Supabase.plist
│   └── PostHog.plist
│
└── Tests/
    ├── PulseTests/
    │   ├── DataSyncTests.swift
    │   ├── StatusAPITests.swift
    │   └── AppGroupStoreTests.swift
    │
    └── PulseUITests/
        └── CheckInFlowTests.swift
```

### Key File Purposes

**PulseApp.swift:**
- App entry point
- Configure SwiftData ModelContainer
- Initialize PostHog
- Set up app group

**RootView.swift:**
- TabView with three tabs
- Manages authentication state
- Shows onboarding if needed

**PulseDataManager.swift:**
- Singleton orchestrating all data operations
- Owns Supabase client, SwiftData context, AppGroupStore
- Publishes state to views via @Published properties

**AppGroupStore.swift:**
- Reads/writes PulseSnapshot.json to app group
- Simple file-based cache for widget
- No dependencies on SwiftData or Supabase

**SupabaseClient.swift:**
- Wraps Supabase Swift SDK
- Handles auth token refresh
- Provides typed API methods

**PulseLocationManager.swift:**
- Manages CLLocationManager
- Creates and monitors geofences
- Triggers check-ins on region events

**PulseBluetoothManager.swift:**
- Uses CoreBluetooth to detect car connections
- Fires delegate callbacks on connect/disconnect

**RealtimeManager.swift:**
- Subscribes to Supabase Realtime channels
- Updates SwiftData on remote changes
- Triggers widget reloads

---

## 9. Critical Implementation Notes

### 9.1 Common Pitfalls to Avoid

**Liquid Glass Mistakes:**
- ❌ Don't apply `.glassEffect` to scrolling content or large surfaces
- ❌ Don't layer glass on glass (causes double blur)
- ❌ Don't use custom blur/vibrancy when Liquid Glass APIs exist
- ✅ Use `GlassEffectContainer` for grouped controls
- ✅ Use `.identity` glass for accessibility

**SwiftData Pitfalls:**
- ❌ Don't create multiple ModelContainers
- ❌ Don't access ModelContext off main thread without @ModelActor
- ✅ Use single shared container in App
- ✅ Pass context via environment

**Widget Pitfalls:**
- ❌ Don't fetch data in widget views (they rebuild constantly)
- ❌ Don't use @State or complex logic in widget views
- ✅ Pre-compute everything in TimelineProvider
- ✅ Use simple, cached data from App Group

**Supabase Pitfalls:**
- ❌ Don't forget RLS policies (data will leak!)
- ❌ Don't store secrets in code
- ✅ Test RLS with different user contexts
- ✅ Use environment variables or .plist for keys

### 9.2 Performance Optimizations

**Widget Performance:**
- Limit timeline entries (max 50-100)
- Use small JSON snapshots, not full database dumps
- Batch widget reloads (debounce rapid updates)

**SwiftData Performance:**
- Use `@Query` with predicates to limit fetches
- Add indexes on frequently queried fields
- Batch saves when inserting multiple records

**Network Performance:**
- Use Supabase's batch operations for multiple inserts
- Cache user/group data locally
- Use Realtime only for critical updates

### 9.3 Security Checklist

- [ ] All Supabase tables have RLS enabled
- [ ] RLS policies tested with different user IDs
- [ ] API keys stored in .plist, not committed to git
- [ ] App Transport Security configured correctly
- [ ] User location data never logged to analytics
- [ ] Push tokens cleaned up on logout
- [ ] Keychain used for sensitive tokens

### 9.4 Accessibility Checklist

- [ ] All images have accessibility labels
- [ ] Buttons have meaningful labels (not just icons)
- [ ] Support Dynamic Type (no fixed font sizes)
- [ ] Respect Reduce Motion (disable animations)
- [ ] Respect Reduce Transparency (use `.identity` glass)
- [ ] VoiceOver tested on all screens
- [ ] Sufficient color contrast (WCAG AA minimum)

---

## 10. Success Metrics for MVP

### User Engagement
- DAU/MAU ratio > 40% (daily vs monthly active)
- Average check-ins per user per week > 10
- Widget tap-through rate > 20%

### Technical Health
- Crash-free rate > 99.5%
- Average app launch time < 1 second
- Widget load time < 500ms

### Feature Adoption
- % users with automation enabled > 30%
- % users who complete at least 1 task > 50%
- Push notification open rate > 40%

### Retention
- Day 1 retention > 60%
- Day 7 retention > 40%
- Day 30 retention > 25%

---

## 11. Next Steps After MVP

### Post-Launch Priorities

**Quick Wins (1-2 weeks):**
- Add haptic feedback polish
- Onboarding tutorial
- Share invite via system share sheet
- Dark app icon option

**Medium Features (1 month):**
- Multiple groups per user
- Group member roles (admin vs member)
- Custom status messages
- Location name customization

**Long-term Features (2-3 months):**
- Direct messaging between members
- Photo attachments to check-ins
- Integration with Calendar for events
- Apple Watch complications
- Shortcuts app integration
- Live Activities for iOS 26

### Scaling Considerations

**When you hit 1000 users:**
- Monitor Supabase database performance
- Consider upgrading Supabase plan
- Add database connection pooling
- Implement retry logic for API calls

**When you hit 10,000 users:**
- Add rate limiting to prevent abuse
- Implement caching layer (Redis)
- Use Supabase Edge Functions for complex operations
- Consider CDN for static assets

---

## Conclusion

This plan provides a complete blueprint for building Pulse as a production-ready iOS 26 app using Liquid Glass design principles, modern SwiftUI patterns, Supabase backend, and comprehensive analytics.

Key principles:
- **Minimal by design** - system defaults first
- **Liquid Glass for controls** - not content
- **Privacy-first automation** - user controlled
- **Widget-first experience** - fast and accessible
- **Clean architecture** - easy to maintain and extend

The 6-week timeline is realistic for a single experienced iOS developer, with clear milestones and deliverables each week.
