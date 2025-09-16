import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 200, height: 50)
            .foregroundColor(.white)
            .background(Color.navyBlue)
            .cornerRadius(8)
    }
}

extension Button {
    func primaryButton() -> some View {
        buttonStyle(PrimaryButtonStyle())
    }
}

struct PrimaryTextModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.foregroundColor(.black.opacity(0.8))
    }
}

extension View {
    func primaryText() -> some View {
        modifier(PrimaryTextModifier())
    }
}

