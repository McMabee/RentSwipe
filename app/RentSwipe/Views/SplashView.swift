import SwiftUI

struct SplashView: View {
    private let fullText = "RentSwipe"

    @State private var visibleCount: Int = 0

    @Binding var finished: Bool
    var namespace: Namespace.ID

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            Text(String(fullText.prefix(visibleCount)))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .matchedGeometryEffect(id: "rentswipe-logo", in: namespace)
                .animation(.none, value: visibleCount)
                .onAppear {
                    startTypingAnimation()
                }
        }
    }

    private func startTypingAnimation() {
        let typingInterval: Double = 0.08

        for i in 1...fullText.count {
            let delay = Double(i) * typingInterval
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                visibleCount = i
            }
        }

        let totalTypingTime = Double(fullText.count) * typingInterval
        let holdAfterTyping: Double = 1.0

        DispatchQueue.main.asyncAfter(deadline: .now() + totalTypingTime + holdAfterTyping) {
            finished = true
        }
    }
}
