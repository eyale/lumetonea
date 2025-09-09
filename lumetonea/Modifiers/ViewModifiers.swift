import SwiftUI

struct PrimaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(Color.navyBlue)
            .cornerRadius(8)
    }
}

extension View {
    func primaryButton() -> some View {
        modifier(PrimaryButtonModifier())
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

