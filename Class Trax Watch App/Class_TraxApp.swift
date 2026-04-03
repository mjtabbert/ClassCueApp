//
//  Class_TraxApp.swift
//  Class Trax Watch App
//
//  Created by Mike Tabbert on 3/18/26.
//

import SwiftUI
import WatchKit
import UserNotifications

@main
struct Class_Trax_Watch_AppApp: App {
    @StateObject private var snapshotStore = WatchSnapshotStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(snapshotStore)
        }

        WKNotificationScene(
            controller: ClassTraxBellNotificationController.self,
            category: "CLASSTRAX_BELL"
        )
    }
}

struct WatchNotificationLaunchView: View {
    let launchAction: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Button(action: launchAction) {
                Image(systemName: "bell.badge.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)

            Text("Tap the bell to open ClassTrax")
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .containerBackground(.thinMaterial, for: .navigation)
    }
}

final class ClassTraxBellNotificationController: WKUserNotificationHostingController<WatchNotificationLaunchView> {
    private var hasLaunchedApp = false

    override var body: WatchNotificationLaunchView {
        WatchNotificationLaunchView { [weak self] in
            self?.launchApp()
        }
    }

    override func didReceive(_ notification: UNNotification) {
        hasLaunchedApp = false
    }

    private func launchApp() {
        guard !hasLaunchedApp else { return }
        hasLaunchedApp = true
        performNotificationDefaultAction()
    }
}
