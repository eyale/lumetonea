//
//  ContentView.swift
//  lumetonea
//
//  Created by Anton Honcharov on 08.09.2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "lamp")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("lumetonea")
                .font(.title)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
