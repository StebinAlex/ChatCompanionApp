//
//  LoginViewModel.swift
//  ChatCompanion
//
//  Created by Nazik on 7.04.2024.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class FirebaseAPIClient: APIClient {
    
    
    override func register(username: String, email: String, password: String, completion: @escaping (Result<GenericAPIResponse, any Error>) -> Void) {
        
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                if let error = error {
                    completion(.failure(error))
                    return
                } else {
                    
                    // Create a reference to the user's document in Firestore
                    
                    let db = Firestore.firestore()
                    let userRef = db.collection("users").document(result!.user.uid)
                    
                    // Prepare user data dictionary with username
                    let userData = ["username": username, "email": email]
                    
                    userRef.setData(userData) { error in
                        if let error = error {
                            completion(.failure(error))
                            return
                        } else {
                            print(result)
                            completion(.success(.init(success: true, message: result?.description)))
                        }
                        // Handle successful signup
                    }
                    
                    
                }
                // Handle successful signup
            }
        
         
    }
    
    override func login(username: String, password: String, completion: @escaping (Result<GenericAPIResponse, any Error>) -> Void) {
        Auth.auth().signIn(withEmail: username, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            } else {
                print(result?.additionalUserInfo, result?.credential, result?.user)
                completion(.success(.init(success: true, message: result?.description)))
            }
            // Handle successful signup
        }
    }
    
    
}

class LoginViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isAuthenticated: Bool = false
    @Published var loginError: String? = nil
    @Published var isFormValid: Bool = false
    private var apiClient: APIClient
    private var cancellables = Set<AnyCancellable>()

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
        areCredentialsValidPublisher
            .receive(on: RunLoop.main)
            .assign(to: &$isFormValid)
    }
    
    func login() {
        apiClient.login(username: username, password: password) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.isAuthenticated = true
                    self?.loginError = nil
                case .failure(let error):
                    self?.isAuthenticated = false
                    self?.loginError = "Login failed: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private var isUsernameValidPublisher: AnyPublisher<Bool, Never> {
        $username
            .debounce(for: 0.8, scheduler: RunLoop.main)
            .removeDuplicates()
            .map { $0.count >= 3 }
            .eraseToAnyPublisher()
    }

    private var isPasswordValidPublisher: AnyPublisher<Bool, Never> {
        $password
            .debounce(for: 0.8, scheduler: RunLoop.main)
            .removeDuplicates()
            .map { $0.count >= 6 }
            .eraseToAnyPublisher()
    }

    private var areCredentialsValidPublisher: AnyPublisher<Bool, Never> {
        Publishers.CombineLatest(isUsernameValidPublisher, isPasswordValidPublisher)
            .map { $0 && $1 }
            .eraseToAnyPublisher()
    }
}
