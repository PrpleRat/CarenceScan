import SwiftUI

struct ContexteNoteView: View {
    let icon: String
    let note: NoteContexte
    let background: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 6) {
                Text(icon)
                    .font(.caption2)
                Text(note.message)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CarenceColors.textPrimary)
            }

            if let explication = note.explication {
                Text(explication)
                    .font(.caption2)
                    .foregroundStyle(CarenceColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !note.sources.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sources")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CarenceColors.textSecondary)
                    ForEach(note.sources) { source in
                        if let url = URL(string: source.url) {
                            Link(destination: url) {
                                HStack(spacing: 4) {
                                    Image(systemName: "link")
                                        .font(.caption2)
                                    Text(source.label)
                                        .font(.caption2)
                                }
                            }
                            .tint(CarenceColors.primary)
                        }
                    }
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
