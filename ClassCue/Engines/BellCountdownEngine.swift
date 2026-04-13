//
//  BellCountdownEngine.swift
//  ClassTrax
//

import AVFoundation
import AudioToolbox
import UIKit

final class BellCountdownEngine {

    static let shared = BellCountdownEngine()

    private var lastSecondTriggered: Int?

    private init() {}

    func process(secondsRemaining: Int) {

        guard secondsRemaining <= 5 else { return }
        guard secondsRemaining >= 0 else { return }

        if lastSecondTriggered == secondsRemaining { return }

        lastSecondTriggered = secondsRemaining

        if secondsRemaining == 0 {
            playBell()
        } else {
            playTick()
        }
    }

    private func playTick() {
        guard !BellFeedbackManager.areSoundsMuted else { return }
        AudioServicesPlaySystemSound(1104)
    }

    private func playBell() {
        guard !BellFeedbackManager.areSoundsMuted else { return }
        AudioServicesPlaySystemSound(1005)

#if !targetEnvironment(macCatalyst)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
#endif
    }

    func reset() {
        lastSecondTriggered = nil
    }
}
