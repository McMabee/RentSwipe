//
//  LoginEntryView.swift
//  RentSwipe
//
//  Created by Ty Mabee on 2025-10-27.
//

import SwiftUI

struct LoginEntryView: View {
    @EnvironmentObject private var sessionStore: PrototypeSessionStore
    @State private var appear: Double = 0.0

    //#TODO: fix ContentView scope issue
    var body: some View {
        ContentView()
            .environmentObject(sessionStore)
            .opacity(appear)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4)) {
                    appear = 1.0
                }
            }
    }
}

#Preview {
    LoginEntryView()
        .environmentObject(PrototypeSessionStore())
}
