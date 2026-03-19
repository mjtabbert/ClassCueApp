//
//  Class_TraxApp.swift
//  Class Trax Watch App
//
//  Created by Mike Tabbert on 3/18/26.
//

import SwiftUI

@main
struct Class_Trax_Watch_AppApp: App {
    @StateObject private var snapshotStore = WatchSnapshotStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(snapshotStore)
        }
    }
}
