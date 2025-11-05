//
//  AppleAppExampleApp.swift
//  AppleAppExample
//
//  Created by Maximilian Alexander on 11/4/25.
//

import SwiftUI

@main
struct AppleAppExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        #if os(macOS)
        .defaultSize(width: 1200, height: 600)
        #endif
    }
}
