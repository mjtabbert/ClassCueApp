import Foundation

enum ScheduleSnoozeStore {
    static let pauseUntilKey = "ignore_until_v1"
    private static let updatedAtKey = "ignore_until_updated_at_v1"

    @discardableResult
    static func synchronize() -> Double {
        let defaults = UserDefaults.standard
        let cloud = NSUbiquitousKeyValueStore.default

        let localUpdatedAt = defaults.double(forKey: updatedAtKey)
        let cloudUpdatedAt = cloud.double(forKey: updatedAtKey)

        let resolvedPauseUntil: Double
        let resolvedUpdatedAt: Double

        if cloudUpdatedAt > localUpdatedAt {
            resolvedPauseUntil = cloud.double(forKey: pauseUntilKey)
            resolvedUpdatedAt = cloudUpdatedAt
        } else {
            resolvedPauseUntil = defaults.double(forKey: pauseUntilKey)
            resolvedUpdatedAt = localUpdatedAt
        }

        defaults.set(resolvedPauseUntil, forKey: pauseUntilKey)
        defaults.set(resolvedUpdatedAt, forKey: updatedAtKey)
        cloud.set(resolvedPauseUntil, forKey: pauseUntilKey)
        cloud.set(resolvedUpdatedAt, forKey: updatedAtKey)
        cloud.synchronize()

        return resolvedPauseUntil
    }

    static func setPause(until date: Date?) {
        let pauseUntil = date?.timeIntervalSince1970 ?? 0
        let updatedAt = Date().timeIntervalSince1970
        let defaults = UserDefaults.standard
        let cloud = NSUbiquitousKeyValueStore.default

        defaults.set(pauseUntil, forKey: pauseUntilKey)
        defaults.set(updatedAt, forKey: updatedAtKey)
        cloud.set(pauseUntil, forKey: pauseUntilKey)
        cloud.set(updatedAt, forKey: updatedAtKey)
        cloud.synchronize()
    }
}
