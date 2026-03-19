import SwiftUI

struct ContentView: View {
    private enum DisplayMode: String, CaseIterable {
        case now
        case next

        var title: String {
            switch self {
            case .now:
                return "Now"
            case .next:
                return "Next"
            }
        }
    }

    @EnvironmentObject private var snapshotStore: WatchSnapshotStore
    @State private var displayMode: DisplayMode = .now

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                header

                if snapshotStore.snapshot?.current != nil && snapshotStore.snapshot?.next != nil {
                    Picker("View", selection: $displayMode) {
                        ForEach(DisplayMode.allCases, id: \.self) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                }

                if displayMode == .now, let current = snapshotStore.snapshot?.current {
                    activeBlockCard(current)
                } else if let next = snapshotStore.snapshot?.next {
                    nextBlockCard(next)
                } else {
                    wrappedCard
                }

                if displayMode == .now, let next = snapshotStore.snapshot?.next, snapshotStore.snapshot?.current != nil {
                    upcomingCard(next)
                }
            }
            .padding(10)
        }
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

    private func nextBlockCard(_ block: ClassTraxWatchSnapshot.BlockSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            labelRow(title: "Next", block: block)

            Text(block.className)
                .font(.title3.weight(.bold))
                .lineLimit(2)

            Text(block.startTime, style: .timer)
                .font(.system(size: 30, weight: .black, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text("Starts at \(block.startTime.formatted(date: .omitted, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)

            metadata(for: block)

            HStack(spacing: 6) {
                Button("+1") {
                    snapshotStore.extend(itemID: block.id, minutes: 1)
                }
                .buttonStyle(.bordered)

                Button("+5") {
                    snapshotStore.extend(itemID: block.id, minutes: 5)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(accentColor(for: block.symbolName).opacity(0.18))
        )
    }

    private func upcomingCard(_ block: ClassTraxWatchSnapshot.BlockSummary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Up Next")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)

            Text(block.className)
                .font(.headline.weight(.semibold))
                .lineLimit(2)

            Text(block.startTime.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.gray.opacity(0.14))
        )
    }

    private var wrappedCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Day Wrapped")
                .font(.headline.weight(.bold))

            Text("No active class is being sent from the iPhone right now.")
                .font(.caption)
                .foregroundStyle(.secondary)
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
