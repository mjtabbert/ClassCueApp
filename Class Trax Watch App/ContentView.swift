import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var snapshotStore: WatchSnapshotStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            if let current = snapshotStore.snapshot?.current {
                activeBlockCard(current)
            } else {
                wrappedCard
            }
        }
        .padding(10)
        .containerBackground(.background, for: .navigation)
    }

    private var header: some View {
        HStack {
            Text("Class Trax")
                .font(.headline.weight(.bold))

            Spacer()

            if let updatedAt = snapshotStore.snapshot?.updatedAt {
                Text(updatedAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func activeBlockCard(_ block: ClassTraxWatchSnapshot.BlockSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            labelRow(title: "Now", block: block)

            Text(block.className)
                .font(.title3.weight(.bold))
                .lineLimit(2)

            Text(block.endTime, style: .timer)
                .font(.system(size: 30, weight: .black, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text("Ends at \(block.endTime.formatted(date: .omitted, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)

            metadata(for: block)

            Divider()

            HStack(spacing: 6) {
                Button {
                    snapshotStore.toggleHold(for: block.id)
                } label: {
                    Label("Hold", systemImage: "pause.fill")
                }
                .buttonStyle(.bordered)

                Button {
                    snapshotStore.skipBell(for: block.id)
                } label: {
                    Label("Skip", systemImage: "bell.slash")
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 6) {
                Button("+1") {
                    snapshotStore.extend(itemID: block.id, minutes: 1)
                }
                .buttonStyle(.borderedProminent)

                Button("+5") {
                    snapshotStore.extend(itemID: block.id, minutes: 5)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(accentColor(for: block.symbolName).opacity(0.18))
        )
    }

    private var wrappedCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Day Wrapped")
                .font(.headline.weight(.bold))

            if let next = snapshotStore.snapshot?.next {
                Text("Next class: \(next.className) at \(next.startTime.formatted(date: .omitted, time: .shortened)).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("No active class is being sent from the iPhone right now.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.gray.opacity(0.14))
        )
    }

    private func labelRow(title: String, block: ClassTraxWatchSnapshot.BlockSummary) -> some View {
        HStack(spacing: 6) {
            Image(systemName: block.symbolName)
                .font(.caption.weight(.bold))
                .foregroundStyle(accentColor(for: block.symbolName))

            Text(title.uppercased())
                .font(.caption2.weight(.black))
                .foregroundStyle(.secondary)

            Spacer()

            Text(block.typeName)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func metadata(for block: ClassTraxWatchSnapshot.BlockSummary) -> some View {
        let detail = [block.gradeLevel, block.room]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " • ")

        if !detail.isEmpty {
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
    }

    private func accentColor(for symbolName: String) -> Color {
        switch symbolName {
        case "function":
            return .red
        case "text.book.closed.fill":
            return .orange
        case "atom":
            return .yellow
        case "globe.americas.fill":
            return .green
        case "pencil.and.ruler.fill":
            return .blue
        case "figure.run":
            return .indigo
        case "fork.knife":
            return .purple
        case "arrow.left.arrow.right":
            return .gray
        default:
            return .cyan
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchSnapshotStore.shared)
}
