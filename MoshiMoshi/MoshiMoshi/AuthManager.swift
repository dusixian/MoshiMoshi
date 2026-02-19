//
//  AuthManager.swift
//  MoshiMoshi
//
//  Manages login state: Sign in with Apple → Supabase Auth. Session stored by Supabase SDK.
//

import Foundation
import AuthenticationServices
import SwiftUI
import Supabase

@MainActor
final class AuthManager: ObservableObject {
    @Published private(set) var isLoggedIn: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String?

    /// Nonce for current Apple Sign In flow (set in LoginView onRequest, used in onCompletion).
    var currentAppleNonce: String?

    private let keychain = KeychainHelper.self
    private var supabase: SupabaseClient { SupabaseClientManager.client }

    init() {
        Task { await checkSession() }
    }

    /// Call once at app launch or when coming to foreground to restore session from storage.
    func checkSession() async {
        do {
            let session = try await supabase.auth.session
            isLoggedIn = true
            syncUserToLocalIfNeeded(session.user)
        } catch {
            isLoggedIn = false
        }
    }

    /// Call this from SignInWithAppleButton's onRequest: set nonce so we can pass it to Supabase.
    func setNonceForAppleSignIn(_ nonce: String) {
        currentAppleNonce = nonce
    }

    /// Call this from SignInWithAppleButton's onCompletion.
    func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) {
        isLoading = false
        errorMessage = nil
        let nonce = currentAppleNonce ?? ""
        currentAppleNonce = nil

        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = "Invalid credential"
                return
            }
            guard let idTokenData = credential.identityToken,
                  let idTokenString = String(data: idTokenData, encoding: .utf8) else {
                errorMessage = "No identity token"
                return
            }

            Task {
                do {
                    _ = try await supabase.auth.signInWithIdToken(
                        credentials: OpenIDConnectCredentials(
                            provider: .apple,
                            idToken: idTokenString,
                            nonce: nonce
                        )
                    )
                    // Apple sends name/email only on first sign-in; save locally for display
                    if let fullName = credential.fullName {
                        let name = [fullName.givenName, fullName.familyName].compactMap { $0 }.joined(separator: " ")
                        if !name.isEmpty { UserDefaults.standard.set(name, forKey: "savedUserName") }
                    }
                    if let email = credential.email, !email.isEmpty {
                        UserDefaults.standard.set(email, forKey: "savedUserEmail")
                    }
                    await MainActor.run { isLoggedIn = true }
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                    }
                }
            }

        case .failure(let error):
            if let authError = error as? ASAuthorizationError {
                if authError.code == .canceled { return }
                errorMessage = authError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func syncUserToLocalIfNeeded(_ user: User) {
        if let name = user.userMetadata["full_name"] as? String, !name.isEmpty {
            UserDefaults.standard.set(name, forKey: "savedUserName")
        }
        if let email = user.email, !email.isEmpty {
            UserDefaults.standard.set(email, forKey: "savedUserEmail")
        }
    }

    func setLoading(_ loading: Bool) {
        isLoading = loading
    }

    func signOut() {
        Task {
            try? await supabase.auth.signOut()
            KeychainHelper.clearAuthKeys()
            await MainActor.run { isLoggedIn = false }
        }
    }
}
