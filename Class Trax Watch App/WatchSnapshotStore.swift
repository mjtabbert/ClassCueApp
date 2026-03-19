import Foundation
import WatchConnectivity
import Combine

struct ClassTraxWatchSnapshot: Codable, Equatable {
    struct BlockSummary: Codable, Equatable {
        var id: UUID
        var className: String
        var room: String
        var gradeLevel: String
        var symbolName: String
        var startTime: Date
        var endTime: Date
        var typeName: String
    }

    var updatedAt: Date
    var current: BlockSummary?
    var next: BlockSummary?

    var isDayWrapped: Bool {
        current == nil && next == nil
    }
}

@MainActor
final class WatchSnapshotStore: NSObject, ObservableObject {
    static let shared = WatchSnapshotStore()

    @Published private(set) var snapshot: ClassTraxWatchSnapshot?

    private let contextKey = "classtrax_watch_snapshot"
    private let cacheKey = "classtrax_watch_snapshot_cache"
    private let actionKey = "action"
    private let itemIDKey = "itemID"
    private let minutesKey = "minutes"

    override init() {
        super.init()
        snapshot = loadCachedSnapshot()
        activate()
    }

    func activate() {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        if session.delegate == nil {
            session.delegate = self
        }
        session.activate()

        if !session.receivedApplicationContext.isEmpty {
            apply(context: session.receivedApplicationContext)
        }
    }

    private func apply(context: [String: Any]) {
        guard
            let data = context[contextKey] as? Data,
            let decoded = try? JSONDecoder().decode(ClassTraxWatchSnapshot.self, from: data)
        else {
            return
        }

        snapshot = decoded
        UserDefaults.standard.set(data, forKey: cacheKey)
    }

    private func loadCachedSnapshot() -> ClassTraxWatchSnapshot? {
        guard
            let data = UserDefaults.standard.data(forKey: cacheKey),
            let decoded = try? JSONDecoder().decode(ClassTraxWatchSnapshot.self, from: data)
        else {
            return nil
        }

        return decoded
    }

    func toggleHold(for itemID: UUID) {
        sendCommand(action: "toggleHold", itemID: itemID)
    }

    func extend(itemID: UUID, minutes: Int) {
        sendCommand(action: "extend", itemID: itemID, minutes: minutes)
    }

    func skipBell(for itemID: UUID) {
        sendCommand(action: "skipBell", itemID: itemID)
    }

    private func sendCommand(action: String, itemID: UUID, minutes: Int? = nil) {
        guard WCSession.isSupported() else { return }

        let payload: [String: Any] = {
            var value: [String: Any] = [
                actionKey: action,
                itemIDKey: itemID.uuidString
            ]
            if let minutes {
                value[minutesKey] = minutes
            }
            return value
        }()

        let session = WCSession.default
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil, errorHandler: nil)
        } else {
            session.transferUserInfo(payload)
        }
    }
}

extension WatchSnapshotStore: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if !session.receivedApplicationContext.isEmpty {
            Task { @MainActor in
                self.apply(context: session.receivedApplicationContext)
            }
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            self.apply(context: applicationContext)
        }
    }
}
