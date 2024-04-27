//
//  RegistrationView.swift
//  ChatCompanion
//
//  Created by Nazik on 12.04.2024.
//

import SwiftUI
import AuthenticationServices

struct RegistrationView: View {
    @ObservedObject var viewModel: RegistrationViewModel

    @State private var isLoading = false
    @State private var showAlert = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("User Information")) {
                    TextField("Username", text: $viewModel.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)

                    TextField("Email", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                Section(header: Text("Password")) {
                    SecureField("Password", text: $viewModel.password)
                    SecureField("Confirm Password", text: $viewModel.passwordConfirmation)
                }

                VStack {
                    Button(action: {
                        isLoading = true
                        viewModel.register()
                    }) {
                        Text(isLoading ? "Registering..." : "Register")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(!isFormValid() ? Color.gray : Color.blue)
                            .cornerRadius(8)
                    }
                    .disabled(!isFormValid() || isLoading)
                    
                    SignInWithAppleButton(.signUp) { request in
                        // Handle sign-in request here
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            // Extract user information (name, email, etc.)
                            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                if let userName = credential.fullName?.givenName, let email = credential.email {
                                    viewModel.username = userName
                                    viewModel.email = email
                                    viewModel.password = "apple-signup"
                                } else {
                                    print("User name or email not available")
                                }
                            } else {
                                print("credentials not available")
                            }
                        case .failure(let error):
                            print(error.localizedDescription)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationBarTitle("Register", displayMode: .inline)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Registration Error"), message: Text(viewModel.registrationError ?? "Unknown error"), dismissButton: .default(Text("OK")))
            }
            .onChange(of: viewModel.isRegistered) { isRegistered in
                if isRegistered {
                    // Handle successful registration, e.g., navigate away or clear form
                }
                isLoading = false
            }
            .onChange(of: viewModel.registrationError) { _ in
                isLoading = false
                showAlert = viewModel.registrationError != nil
            }
        }
    }

    private func isFormValid() -> Bool {
        !viewModel.username.isEmpty &&
        viewModel.email.contains("@") && viewModel.email.contains(".") &&
        !viewModel.password.isEmpty &&
        viewModel.password == viewModel.passwordConfirmation &&
        viewModel.password.count >= 8
    }
}

// Preview for SwiftUI Canvas
struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView(viewModel: RegistrationViewModel())
    }
}
