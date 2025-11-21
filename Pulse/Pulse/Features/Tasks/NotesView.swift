import SwiftUI

struct NotesView: View {
    @EnvironmentObject var dataManager: PulseDataManager

    var body: some View {
        List {
            ForEach(dataManager.notes) { note in
                NoteRow(note: note)
            }
        }
        .listStyle(.plain)
        .overlay {
            if dataManager.notes.isEmpty {
                ContentUnavailableView(
                    "No Notes",
                    systemImage: "note.text",
                    description: Text("Tap + to add a note")
                )
            }
        }
    }
}

struct NoteRow: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.content)
                .font(.body)

            Text(note.createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NotesView()
        .environmentObject(PulseDataManager.shared)
}
