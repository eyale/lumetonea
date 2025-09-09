import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
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
        content.foregroundColor(.black)
    }
}

extension View {
    func primaryText() -> some View {
        modifier(PrimaryTextModifier())
    }
}

