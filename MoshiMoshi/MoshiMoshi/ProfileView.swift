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
    @AppStorage("savedUserEmail") var savedUserEmail: String = ""

    var body: some View {
        ZStack {
            Color.sushiRice.ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("DEFAULT CONTACT INFO")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        //.padding(.leading, 4)
                        .padding(.top, 20)

                    OmakaseTextField(icon: "person.fill", placeholder: "Your Default Name", text: $savedUserName)
                    OmakaseTextField(icon: "envelope.fill", placeholder: "Your Email", text: $savedUserEmail)
                                            .keyboardType(.emailAddress)
                                            .textInputAutocapitalization(.never)
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
            }
        }
        .navigationTitle("Personal Information")
        .navigationBarTitleDisplayMode(.inline)
    }
}
