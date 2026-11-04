//
//  LoginView.swift
//  Firechat
//
//  Created by Ritch Barlatier on 10/28/26.
//
import SwiftUI

struct LoginView: View {

    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        VStack {
            Text("Welcome!")
                .font(.largeTitle)

            // Email + password fields
            VStack {
                TextField("Email", text: $email)
                SecureField("Password", text: $password)
            }
            .textFieldStyle(.roundedBorder) // <-- Style text fields (applies to both text fields within the VStack)
            .textInputAutocapitalization(.never) // <-- No auto capitalization (can be annoying for emails and passwords)
            .padding(40)

            // Sign up + Login buttons
            HStack {
                Button("Sign Up") {
                    print("Sign up user: \(email), \(password)")
                    // TODO: Sign up user

                }
                .buttonStyle(.borderedProminent) // <-- Style button

                Button("Login") {
                    print("Login user: \(email), \(password)")
                    // TODO: Login user

                }
                .buttonStyle(.bordered) // <-- Style button
            }
        }
    }
}
