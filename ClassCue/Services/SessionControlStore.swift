import Foundation

enum SessionControlStore {
    private static let defaults = UserDefaults.standard
    private static let extraTimeKey = "classtrax_extra_time_by_item_v1"
    private static let heldItemIDKey = "classtrax_held_item_id_v1"
    private static let holdStartedAtKey = "classtrax_hold_started_at_v1"
    private static let skippedBellItemIDsKey = "classtrax_skipped_bell_item_ids_v1"

    static func extraTimeByItemID() -> [UUID: TimeInterval] {
        guard
            let data = defaults.data(forKey: extraTimeKey),
            let raw = try? JSONDecoder().decode([String: Double].self, from: data)
        else {
            return [:]
        }

        return raw.reduce(into: [:]) { result, entry in
            if let id = UUID(uuidString: entry.key) {
                result[id] = entry.value
            }
        }
    }

    static func setExtraTimeByItemID(_ value: [UUID: TimeInterval]) {
        let raw = Dictionary(uniqueKeysWithValues: value.map { ($0.key.uuidString, $0.value) })
        guard let data = try? JSONEncoder().encode(raw) else { return }
        defaults.set(data, forKey: extraTimeKey)
    }

    static func heldItemID() -> UUID? {
        guard let raw = defaults.string(forKey: heldItemIDKey), !raw.isEmpty else { return nil }
        return UUID(uuidString: raw)
    }

    static func setHeldItemID(_ value: UUID?) {
        defaults.set(value?.uuidString ?? "", forKey: heldItemIDKey)
    }

    static func holdStartedAt() -> Date? {
        let timestamp = defaults.double(forKey: holdStartedAtKey)
        guard timestamp > 0 else { return nil }
        return Date(timeIntervalSince1970: timestamp)
    }

    static func setHoldStartedAt(_ value: Date?) {
        defaults.set(value?.timeIntervalSince1970 ?? 0, forKey: holdStartedAtKey)
    }

    static func skippedBellItemIDs() -> Set<UUID> {
        guard
            let data = defaults.data(forKey: skippedBellItemIDsKey),
            let raw = try? JSONDecoder().decode([String].self, from: data)
        else {
            return []
        }

        return Set(raw.compactMap(UUID.init(uuidString:)))
    }

    static func setSkippedBellItemIDs(_ value: Set<UUID>) {
        guard let data = try? JSONEncoder().encode(value.map(\.uuidString)) else { return }
        defaults.set(data, forKey: skippedBellItemIDsKey)
    }

    static func extend(itemID: UUID, byMinutes minutes: Int) {
        var extra = extraTimeByItemID()
        extra[itemID, default: 0] += TimeInterval(minutes * 60)
        setExtraTimeByItemID(extra)

        var skipped = skippedBellItemIDs()
        skipped.remove(itemID)
        setSkippedBellItemIDs(skipped)
    }

    static func toggleHold(itemID: UUID, now: Date) {
        if heldItemID() == itemID {
            let additionalHold = liveHoldDuration(for: itemID, now: now)
            var extra = extraTimeByItemID()
            extra[itemID, default: 0] += additionalHold
            setExtraTimeByItemID(extra)
            setHeldItemID(nil)
            setHoldStartedAt(nil)
        } else {
            setHeldItemID(itemID)
            setHoldStartedAt(now)
        }
    }

    static func skipBell(itemID: UUID) {
        var skipped = skippedBellItemIDs()
        skipped.insert(itemID)
        setSkippedBellItemIDs(skipped)
    }

    static func isHeld(itemID: UUID) -> Bool {
        heldItemID() == itemID
    }

    static func liveHoldDuration(for itemID: UUID, now: Date) -> TimeInterval {
        guard heldItemID() == itemID, let holdStartedAt = holdStartedAt() else { return 0 }
        return max(now.timeIntervalSince(holdStartedAt), 0)
    }

    static func clearHoldIfNeeded(activeItemID: UUID?) {
        if let held = heldItemID(), held != activeItemID {
            setHeldItemID(nil)
            setHoldStartedAt(nil)
        }
    }
}
