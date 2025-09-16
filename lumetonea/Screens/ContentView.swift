//
//  ContentView.swift
//  lumetonea
//
//  Created by Anton Honcharov on 08.09.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var nav = NavigationCoordinator()
    var body: some View {
        NavigationStack {
            PhotoPermissionView()
        }
        .background(Color.white)
        .environmentObject(nav)
    }
}

#Preview {
    ContentView()
}
