//
//  slate_App.swift
//  slate.
//
//  Created by Daniel Jeranko on 24.05.26.
//

import SwiftUI

@main
struct slate_App: App {
    @State private var notifications = NotificationStore.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .task { await notifications.sync() }
        }
    }
}
