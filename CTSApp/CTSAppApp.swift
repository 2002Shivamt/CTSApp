//
//  CTSAppApp.swift
//  CTSApp
//
//  Created by Shivam Tewari on 12/02/26.
//

import SwiftUI

@main
struct CTSAppApp: App {
    private let env: AppEnvironment
    @StateObject private var appState: AppState

    init() {
        let env = AppEnvironment.ui()
        self.env = env
        _appState = StateObject(wrappedValue: AppState(env: env))
    }

    var body: some Scene {
        WindowGroup {
            RootView(env: env)
                .environmentObject(appState)
        }
    }
}
