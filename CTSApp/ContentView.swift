//
//  ContentView.swift
//  CTSApp
//
//  Created by Shivam Tewari on 12/02/26.
//

import SwiftUI

struct ContentView: View {
    private let env: AppEnvironment
    @StateObject private var appState: AppState

    init(env: AppEnvironment = .ui()) {
        self.env = env
        _appState = StateObject(wrappedValue: AppState(env: env))
    }

    var body: some View {
        RootView(env: env)
            .environmentObject(appState)
    }
}

#Preview {
    ContentView()
}
