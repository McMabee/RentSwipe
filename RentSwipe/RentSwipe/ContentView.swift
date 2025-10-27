//
//  ContentView.swift
//  RentSwipe
//
//  Created by Codex CLI.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Text("RentSwipe")
                    .font(.largeTitle.weight(.bold))

                Text("Find the perfect student housing match with quick swipes and rich property details.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 32)

                Button(action: {}) {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 32)
                .disabled(true)

                Spacer()
            }
            .navigationTitle("Welcome")
        }
    }
}

#Preview {
    ContentView()
}
