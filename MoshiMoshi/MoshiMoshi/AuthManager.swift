//
//  AuthManager.swift
//  MoshiMoshi
//
//  Manages login state and Sign in with Apple. Token stored in Keychain (no separate DB).
//

import Foundation
import AuthenticationServices
import SwiftUI

@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var isLoggedIn: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    private let keychain = KeychainHelper.self

    init() {
        isLoggedIn = keychain.loadString(for: KeychainHelper.KeychainKeys.appleUserIdentifier) != nil
    }

    /// Call this from SignInWithAppleButton's onCompletion.
    func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        isLoading = false
        errorMessage = nil
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Invalid credential"
                return
            }
            let userId = credential.user
            keychain.save(userId, for: KeychainHelper.KeychainKeys.appleUserIdentifier)

            // Apple only sends name/email on first sign-in; save for display
            if let fullName = credential.fullName {
                let name = [fullName.givenName, fullName.familyName].compactMap { $0 }.joined(separator: " ")
                if !name.isEmpty {
                    keychain.save(name, for: KeychainHelper.KeychainKeys.userName)
                    UserDefaults.standard.set(name, forKey: "savedUserName")
                }
            }
            if let email = credential.email, !email.isEmpty {
                keychain.save(email, for: KeychainHelper.KeychainKeys.userEmail)
                UserDefaults.standard.set(email, forKey: "savedUserEmail")
            }

            // TODO: Send credential.identityToken to your backend; backend returns your token → save with keychain.save(..., for: KeychainHelper.KeychainKeys.backendToken)
            isLoggedIn = true

        case .failure(let error):
            if let authError = error as? ASAuthorizationError {
                if authError.code == .canceled {
                    return // user canceled, no message
                }
                errorMessage = authError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    func setLoading(_ loading: Bool) {
        isLoading = loading
    }

    func signOut() {
        KeychainHelper.clearAuthKeys()
        // Optionally clear default contact so next login is fresh (or keep for convenience)
        // UserDefaults.standard.removeObject(forKey: "savedUserName")
        // UserDefaults.standard.removeObject(forKey: "savedUserPhone")
        // UserDefaults.standard.removeObject(forKey: "savedUserEmail")
        isLoggedIn = false
    }
}
