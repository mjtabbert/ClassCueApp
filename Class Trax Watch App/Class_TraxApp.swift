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
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "bell.badge.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(.blue)

            Text("Opening ClassTrax")
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
        WatchNotificationLaunchView()
    }

    override func didReceive(_ notification: UNNotification) {
        guard !hasLaunchedApp else { return }
        hasLaunchedApp = true

        Task { @MainActor in
            performNotificationDefaultAction()
        }
    }
}
