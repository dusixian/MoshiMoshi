//
//  LoginView.swift
//  MoshiMoshi
//
//  Login screen: Sign in with Apple only. No separate database — auth state in Keychain.
//

import SwiftUI
import AuthenticationServices
import CryptoKit

struct LoginView: View {
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        ZStack {
            Color.sushiRice.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.sushiSalmon)
                    Text("MoshiMoshi")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.sushiNori)
                    Text("Reserve with a tap. We call for you.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                VStack(spacing: 16) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.fullName, .email]
                        let rawNonce = UUID().uuidString
                        request.nonce = sha256Hex(rawNonce)
                        auth.setNonceForAppleSignIn(rawNonce)
                        auth.setLoading(true)
                    } onCompletion: { result in
                        auth.handleAppleSignInResult(result)
                    }
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 52)
                    .cornerRadius(12)

                    if let message = auth.errorMessage {
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.sushiTuna)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
            .overlay {
                if auth.isLoading {
                    Color.black.opacity(0.2)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                }
            }
        }
    }
}

private func sha256Hex(_ string: String) -> String {
    let data = Data(string.utf8)
    let hash = SHA256.hash(data: data)
    return hash.map { String(format: "%02x", $0) }.joined()
}

#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
