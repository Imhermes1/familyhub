import SwiftUI
import MapKit

// MARK: - Location Card
// Beautiful card for location/status updates

struct LocationCard: View {
    let status: PulseStatus
    let userName: String?
    let userEmoji: String?

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                // Header with avatar and user info
                HStack(spacing: DesignSystem.Spacing.sm) {
                    AvatarView(
                        emoji: userEmoji ?? "👤",
                        size: .medium,
                        showStatus: false
                    )

                    VStack(alignment: .leading, spacing: 2) {
                        Text(userName ?? "Unknown")
                            .font(DesignSystem.Typography.headline())

                        HStack(spacing: 4) {
                            Text(status.statusType.displayName)
                                .font(DesignSystem.Typography.caption1(.medium))
                                .foregroundColor(statusColor)

                            Text("•")
                                .font(DesignSystem.Typography.caption2())
                                .foregroundColor(DesignSystem.Colors.tertiaryLabel)

                            Text(timeAgo)
                                .font(DesignSystem.Typography.caption1())
                                .foregroundColor(DesignSystem.Colors.secondaryLabel)
                        }
                    }

                    Spacer()

                    // Status type icon
                    Image(systemName: status.statusType.icon)
                        .font(.system(size: DesignSystem.IconSize.medium))
                        .foregroundColor(statusColor)
                }

                // Location info
                if let locationName = status.locationName {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: DesignSystem.IconSize.small))
                            .foregroundColor(DesignSystem.Colors.primary)

                        Text(locationName)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(DesignSystem.Colors.label)
                    }
                    .padding(.top, 4)
                }

                // Map preview if coordinates available
                if status.latitude != nil && status.longitude != nil {
                    LocationMapPreview(
                        latitude: status.latitude!,
                        longitude: status.longitude!
                    )
                    .frame(height: 120)
                    .cornerRadius(DesignSystem.CornerRadius.medium)
                    .padding(.top, 4)
                }

                // Trigger type badge
                TriggerTypeBadge(triggerType: status.triggerType)
                    .padding(.top, 4)
            }
        }
    }

    private var statusColor: Color {
        switch status.statusType {
        case .arrived:
            return DesignSystem.Colors.success
        case .leaving:
            return DesignSystem.Colors.warning
        case .on_the_way:
            return DesignSystem.Colors.info
        case .pulse:
            return DesignSystem.Colors.primary
        }
    }

    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: status.createdAt, relativeTo: Date())
    }
}

// MARK: - Location Map Preview

struct LocationMapPreview: View {
    let latitude: Double
    let longitude: Double

    @State private var region: MKCoordinateRegion

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        Map(coordinateRegion: .constant(region), annotationItems: [MapLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))]) { location in
            MapMarker(coordinate: location.coordinate, tint: .red)
        }
        .allowsHitTesting(false)  // Disable interaction in preview
    }
}

// Helper for map annotation
struct MapLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Trigger Type Badge

struct TriggerTypeBadge: View {
    let triggerType: TriggerType

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))

            Text(displayName)
                .font(DesignSystem.Typography.caption2(.medium))
        }
        .foregroundColor(DesignSystem.Colors.secondaryLabel)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(DesignSystem.Colors.tertiaryBackground)
        .cornerRadius(DesignSystem.CornerRadius.small)
    }

    private var displayName: String {
        switch triggerType {
        case .manual:
            return "Manual"
        case .bluetooth:
            return "Car Connected"
        case .geofence:
            return "Auto"
        case .hourly:
            return "Pulse"
        }
    }

    private var icon: String {
        switch triggerType {
        case .manual:
            return "hand.tap.fill"
        case .bluetooth:
            return "car.fill"
        case .geofence:
            return "location.fill"
        case .hourly:
            return "clock.fill"
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        LocationCard(
            status: PulseStatus(
                userID: UUID(),
                groupID: UUID(),
                statusType: .arrived,
                triggerType: .geofence,
                locationName: "Home",
                latitude: 37.7749,
                longitude: -122.4194
            ),
            userName: "Mom",
            userEmoji: "👩"
        )

        LocationCard(
            status: PulseStatus(
                userID: UUID(),
                groupID: UUID(),
                statusType: .leaving,
                triggerType: .manual,
                locationName: "Work"
            ),
            userName: "Dad",
            userEmoji: "👨"
        )

        LocationCard(
            status: PulseStatus(
                userID: UUID(),
                groupID: UUID(),
                statusType: .on_the_way,
                triggerType: .bluetooth,
                locationName: nil
            ),
            userName: "Sister",
            userEmoji: "👧"
        )
    }
    .padding()
}
