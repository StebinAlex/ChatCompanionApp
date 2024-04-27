//
//  LoginView.swift
//  ChatCompanion
//
//  Created by Nazik on 7.04.2024.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject var userViewModel: UserViewModel
    @ObservedObject var viewModel: LoginViewModel
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var showRegister = false
    
    var body: some View {
        VStack {
            TextField("Username", text: $viewModel.username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            SecureField("Password", text: $viewModel.password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .autocapitalization(.none)
                .disableAutocorrection(true)
            
            if isLoading {
                ProgressView()
                    .padding()
            } else {
                VStack {
                    Button(action: {
                        isLoading = true
                        viewModel.login()
                    }) {
                        Text("Log In")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.isFormValid ? Color.blue : .gray.opacity(0.6))
                            .cornerRadius(10)
                    }
                    .disabled(!viewModel.isFormValid)
                    .padding()
                    
                    SignInWithAppleButton(.signUp) { request in
                        // Handle sign-in request here
                    } onCompletion: { result in
                        switch result {
                        case .success(let authorization):
                            // Extract user information (name, email, etc.)
                            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                if let userName = credential.fullName?.givenName, let email = credential.email {
                                    viewModel.username = userName
                                    viewModel.password = "apple-signup"
                                    isLoading = true
                                    viewModel.login()
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
                    .frame(height: 55)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            
            Button("Create user") {
                showRegister.toggle()
            }
            
        }
        .padding()
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Login Error"), message: Text(viewModel.loginError ?? "Unknown error"), dismissButton: .default(Text("OK")))
        }
        //        .analyticsScreen(name: "\(LoginView.self)")
        
        .onChange(of: viewModel.isAuthenticated, { oldValue, newValue in
            userViewModel.isAuthenticated = newValue
            isLoading = false
        })
        .onChange(of: viewModel.loginError) { _, _ in
            isLoading = false
            showAlert = viewModel.loginError != nil
        }
        .sheet(isPresented: $showRegister, content: {
            RegistrationView(viewModel: RegistrationViewModel())
        })
        
    }
}

// Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(viewModel: MockLoginViewModel())
            .environmentObject(UserViewModel(apiClient: MockAPIClient()))
    }
}
