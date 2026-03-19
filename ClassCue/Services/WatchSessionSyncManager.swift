import Foundation

#if os(iOS)
import WatchConnectivity

final class WatchSessionSyncManager: NSObject {
    static let shared = WatchSessionSyncManager()

    private let snapshotContextKey = "classtrax_watch_snapshot"
    private let actionKey = "action"
    private let itemIDKey = "itemID"
    private let minutesKey = "minutes"

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        if session.delegate == nil {
            session.delegate = self
        }
        session.activate()
    }

    func sync(snapshot: ClassTraxWidgetSnapshot) {
        guard WCSession.isSupported() else { return }
        activate()

        guard let data = try? JSONEncoder().encode(snapshot) else { return }

        do {
            try WCSession.default.updateApplicationContext([snapshotContextKey: data])
        } catch {
            #if DEBUG
            print("Watch sync failed:", error.localizedDescription)
            #endif
        }
    }

    private func handleCommand(_ message: [String: Any]) {
        guard
            let action = message[actionKey] as? String,
            let itemIDRaw = message[itemIDKey] as? String,
            let itemID = UUID(uuidString: itemIDRaw)
        else {
            return
        }

        switch action {
        case "toggleHold":
            SessionControlStore.toggleHold(itemID: itemID, now: Date())
        case "extend":
            let minutes = message[minutesKey] as? Int ?? 1
            SessionControlStore.extend(itemID: itemID, byMinutes: minutes)
        case "skipBell":
            SessionControlStore.skipBell(itemID: itemID)
        default:
            break
        }
    }
}

extension WatchSessionSyncManager: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
    }

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        handleCommand(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        handleCommand(userInfo)
    }
}
#else
final class WatchSessionSyncManager {
    static let shared = WatchSessionSyncManager()

    func activate() {
    }

    func sync(snapshot: ClassTraxWidgetSnapshot) {
    }
}
#endif
