//
//  SplashView.swift
//  RentSwipe
//
//  Created by Ty Mabee on 2025-10-27.
//

import SwiftUI

struct SplashView: View {
    private let fullText = "RentSwipe"

    @State private var visibleCount: Int = 0
    @State private var whiteOverlayOpacity: Double = 0.0

    // <-- MUST be a Binding<Bool>
    @Binding var finished: Bool

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Text(String(fullText.prefix(visibleCount)))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .animation(.none, value: visibleCount)
                .onAppear {
                    startTypingAnimation()
                }

            Color.white
                .ignoresSafeArea()
                .opacity(whiteOverlayOpacity)
        }
    }

    private func startTypingAnimation() {
        let typingInterval = 0.08

        for i in 1...fullText.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * typingInterval) {
                visibleCount = i
            }
        }

        let holdAfterTyping: Double = 0.4
        let totalTypingTime = Double(fullText.count) * typingInterval

        DispatchQueue.main.asyncAfter(deadline: .now() + totalTypingTime + holdAfterTyping) {
            withAnimation(.easeIn(duration: 0.4)) {
                whiteOverlayOpacity = 1.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + totalTypingTime + holdAfterTyping + 0.45) {
            // tell parent we're done -> parent will hide splash
            finished = true
        }
    }
}
