//
//  UserSelectView.swift
//  RentSwipe
//
//  Created by Ty Mabee on 2025-10-28.
//

import SwiftUI

//#TODO: Fix AccountRole bug
struct UserSelectView: View {
    @Binding var selectedRole: AccountRole?
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Text("RentSwipe")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.black)
            
            Text("Which are you?")
                .font(.title2)
                .foregroundColor(.gray)
            
            HStack(spacing: 30) {
                Button(action: {
                    selectedRole = .tenant
                }) {
                    Text("Tenant")
                        .font(.headline)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 32)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.black)
                }
                
                Button(action: {
                    selectedRole = .landlord
                }) {
                    Text("Landlord")
                        .font(.headline)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 32)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.black)
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationBarHidden(true)
    }
}
