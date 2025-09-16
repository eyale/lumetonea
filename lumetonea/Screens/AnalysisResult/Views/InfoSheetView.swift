//
//  InfoSheetView.swift
//  lumetonea
//
//  Created by Anton Honcharov on 16.09.2025.
//

import SwiftUI

struct InfoSheetView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)

            Text("Overlay Info")
                .font(.headline)
                .primaryText()

            Text("The horizontal line aligns with the detected chin. The area below the line is highlighted using your selected color and opacity. Use this to preview how different shirt colors might look.")
                .font(.body)
                .foregroundColor(.gray)

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
