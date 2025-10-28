import SwiftUI

struct LoginEntryView: View {
    @EnvironmentObject private var sessionStore: PrototypeSessionStore
    @State private var appear: Double = 0.0

    var body: some View {
        ContentView()
            .environmentObject(sessionStore)
            .opacity(appear)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    appear = 1.0
                }
            }
    }
}

#Preview {
    LoginEntryView()
        .environmentObject(PrototypeSessionStore())
}
