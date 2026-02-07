//
//  ProfileView.swift
//  MoshiMoshi
//
//  Created by Olivia on 2026/1/23.
//

import SwiftUI

struct ProfileView: View {
    @AppStorage("savedUserName") var savedUserName: String = ""
    @AppStorage("savedUserPhone") var savedUserPhone: String = ""
    var isSheet: Bool = false

    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        let content = ZStack {
            Color.sushiRice.ignoresSafeArea()

            VStack(spacing: 24) {
                if isSheet {
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 40, height: 4)
                        .padding(.top, 12)
                }

                Text("User Profile")
                    .font(.system(.title2, design: .serif))
                    .fontWeight(.bold)
                    .foregroundColor(.sushiNori)
                    .padding(.bottom, 20)
                    .padding(.top, isSheet ? 0 : 20)

                VStack(alignment: .leading, spacing: 8) {
                    Text("DEFAULT CONTACT INFO")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .padding(.leading, 4)

                    OmakaseTextField(icon: "person.fill", placeholder: "Your Default Name", text: $savedUserName)

                    OmakaseTextField(icon: "phone.fill", placeholder: "Your Default Phone", text: $savedUserPhone)
                        .keyboardType(.phonePad)
                }
                .padding(.horizontal)

                Text("This information will be automatically filled in when you make a new reservation request.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                if isSheet {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Save Profile")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.sushiSalmon)
                            .foregroundColor(.white)
                            .cornerRadius(25)
                    }
                    .padding()
                }
            }
        }

        if isSheet {
            content
        } else {
            NavigationView {
                content
                    .navigationTitle("Profile")
            }
        }
    }
}
