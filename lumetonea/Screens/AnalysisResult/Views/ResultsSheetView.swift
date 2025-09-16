//
//  ResultsSheetView.swift
//  lumetonea
//
//  Created by Anton Honcharov on 16.09.2025.
//

import SwiftUI

struct ResultsSheetView: View {
    let result: SkinToneResult?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 40, height: 5)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)

            Text("Results")
                .font(.headline)
                .primaryText()

            if let result {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Undertone: \(result.temperature == .warm ? "Warm" : "Cool")")
                        .primaryText()
                    Text(result.temperature == .warm
                         ? "Warm = more red/yellow undertones (higher a*)."
                         : "Cool = more blue/green undertones (lower a*).")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Text("Shade: \(result.shade == .light ? "Light" : "Dark")")
                        .primaryText()
                    Text("Shade is based on L* (perceptual lightness). Higher L* looks lighter.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                    Text(String(format: "LAB ≈ L=%.1f a=%.1f b=%.1f", result.lab.l, result.lab.a, result.lab.b))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else {
                Text("Analyzing...")
                    .foregroundColor(.gray)
            }

            Spacer(minLength: 0)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
