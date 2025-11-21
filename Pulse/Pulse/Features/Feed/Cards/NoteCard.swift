import SwiftUI

// MARK: - Note Card
// Beautiful card for notes in the feed

struct NoteCard: View {
    let note: Note
    let userName: String?
    let userEmoji: String?

    @State private var isExpanded: Bool = false

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
                            Text("Note")
                                .font(DesignSystem.Typography.caption1(.medium))
                                .foregroundColor(DesignSystem.Colors.secondary)

                            Text("•")
                                .font(DesignSystem.Typography.caption2())
                                .foregroundColor(DesignSystem.Colors.tertiaryLabel)

                            Text(timeAgo)
                                .font(DesignSystem.Typography.caption1())
                                .foregroundColor(DesignSystem.Colors.secondaryLabel)
                        }
                    }

                    Spacer()

                    // Note type icon
                    Image(systemName: noteIcon)
                        .font(.system(size: DesignSystem.IconSize.medium))
                        .foregroundColor(DesignSystem.Colors.secondary)
                }

                // Note content
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(note.content)
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(DesignSystem.Colors.label)
                        .lineLimit(isExpanded ? nil : 3)
                        .fixedSize(horizontal: false, vertical: true)

                    // Show "Read more" if content is long
                    if note.content.count > 150 {
                        Button {
                            withAnimation(DesignSystem.Animation.spring) {
                                isExpanded.toggle()
                            }
                        } label: {
                            Text(isExpanded ? "Show less" : "Read more")
                                .font(DesignSystem.Typography.caption1(.medium))
                                .foregroundColor(DesignSystem.Colors.primary)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.top, 4)

                // Drawing preview if available
                if let drawingData = note.drawingData {
                    DrawingPreview(drawingData: drawingData)
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                        .background(DesignSystem.Colors.tertiaryBackground)
                        .cornerRadius(DesignSystem.CornerRadius.medium)
                        .padding(.top, 4)
                }
            }
        }
    }

    private var noteIcon: String {
        if note.drawingData != nil {
            return "scribble.variable"
        } else {
            return "note.text"
        }
    }

    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: note.createdAt, relativeTo: Date())
    }
}

// MARK: - Drawing Preview
// Placeholder for drawing visualization

struct DrawingPreview: View {
    let drawingData: Data

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                .fill(Color.white)

            // TODO: Render actual PencilKit drawing when we integrate PencilKit
            VStack(spacing: 8) {
                Image(systemName: "scribble.variable")
                    .font(.system(size: 32))
                    .foregroundColor(DesignSystem.Colors.tertiaryLabel)

                Text("Drawing")
                    .font(DesignSystem.Typography.caption1())
                    .foregroundColor(DesignSystem.Colors.secondaryLabel)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        NoteCard(
            note: Note(
                groupID: UUID(),
                createdByID: UUID(),
                content: "Don't forget we have a family dinner tomorrow at 7 PM. Please let me know if you can make it!",
                drawingData: nil
            ),
            userName: "Mom",
            userEmoji: "👩"
        )

        NoteCard(
            note: Note(
                groupID: UUID(),
                createdByID: UUID(),
                content: "Short note",
                drawingData: nil
            ),
            userName: "Dad",
            userEmoji: "👨"
        )

        NoteCard(
            note: Note(
                groupID: UUID(),
                createdByID: UUID(),
                content: "Here's a quick sketch of the floor plan for the renovation. I think we should expand the kitchen into the dining area and create an open concept space. What do you all think?",
                drawingData: Data() // Placeholder
            ),
            userName: "Sister",
            userEmoji: "👧"
        )
    }
    .padding()
}
