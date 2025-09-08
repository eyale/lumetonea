//
//  ContentView.swift
//  lumetonea
//
//  Created by Anton Honcharov on 08.09.2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            PhotoPermissionView()
        }
        .background(Color.white)
    }
}

#Preview {
    ContentView()
}

