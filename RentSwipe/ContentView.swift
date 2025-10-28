import SwiftUI

//#TODO: Fix all bugs, finish login page
struct LoginSignupView: View {
    @EnvironmentObject private var sessionStore: PrototypeSessionStore
    let roleType: AccountRole
    
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var message: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text(roleType == .tenant ? "Tenant Login" : "Landlord Login")
                .font(.largeTitle)
                .foregroundColor(.black)
            
            TextField("Username", text: $username)
                .autocapitalization(.none)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            SecureField("Password", text: $password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            if let msg = message {
                Text(msg)
                    .foregroundColor(.red)
            }
            
            Button(action: attemptLogin) {
                Text("Sign In")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black)
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func attemptLogin() {
        // Hard-coded credentials:
        if roleType == .tenant && username == "admin" && password == "123" {
            sessionStore.currentUser = PrototypeUser(email: "tenant@rentswipe.app",
                                                     displayName: "Tenant Admin",
                                                     role: .tenant)
            message = nil
        }
        else if roleType == .landlord && username == "admin" && password == "987" {
            sessionStore.currentUser = PrototypeUser(email: "landlord@rentswipe.app",
                                                     displayName: "Landlord Admin",
                                                     role: .landlord)
            message = nil
        }
        else {
            message = "Invalid login credentials"
        }
    }
}
