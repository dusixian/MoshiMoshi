//
//  ReservationDetailView.swift
//  MoshiMoshi
//
//  Created by Olivia on 2026/2/24.
//


import SwiftUI
import AVFoundation

struct ReservationDetailView: View {
    let item: ReservationItem
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 1. Details Grid Card
                detailsGridCard
                
                // 2. Call History Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Call History")
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(.sushiNori)
                        .padding(.horizontal, 4)
                    
                    CallHistoryExpandableCard(item: item)
                }
            }
            .padding()
        }
        .background(Color.sushiRice.ignoresSafeArea())
        .navigationTitle(item.request.restaurantName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Text(item.status.rawValue)
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(item.status.color.opacity(0.15))
                    .foregroundColor(item.status.color)
                    .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - 2x3 Details Grid
    private var detailsGridCard: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top) {
                InfoBlock(icon: "calendar", title: "DATE", value: formatDate(item.request.dateTime))
                Spacer()
                InfoBlock(icon: "dollarsign.circle", title: "PRICE ESTIMATE", value: "Price TBD\nPer Person")
            }
            
            HStack(alignment: .top) {
                InfoBlock(icon: "clock", title: "TIME", value: formatTime(item.request.dateTime))
                Spacer()
                InfoBlock(icon: "mappin.and.ellipse", title: "LOCATION", value: "Japan")
            }
            
            HStack(alignment: .top) {
                InfoBlock(icon: "person.2", title: "PARTY", value: "\(item.request.partySize) People")
                Spacer()
                InfoBlock(icon: "phone", title: "CONTACT INFO", value: item.request.restaurantPhone)
            }
            
            Divider().padding(.vertical, 8)
            
            // Modify / Cancel Buttons
            HStack(spacing: 16) {
                Button(action: { /* TODO: Modify */ }) {
                    Text("Modify")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5])))
                }
                .foregroundColor(.black)
                
                Button(action: { /* TODO: Cancel */ }) {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.sushiTuna.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5])))
                }
                .foregroundColor(.sushiTuna)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
    
    // Helpers
    private func InfoBlock(icon: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.sushiSalmon.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay(Image(systemName: icon).foregroundColor(.sushiSalmon))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter(); formatter.dateFormat = "MMM dd, yyyy"
        return formatter.string(from: date)
    }
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter(); formatter.dateFormat = "h:mm a"
        return formatter.string(from: date) + " (GMT+9)"
    }
}

// MARK: - Transcript Card
struct CallHistoryExpandableCard: View {
    let item: ReservationItem
    @State private var isExpanded = false
    @State private var selectedLanguage = "English"
    
    @State private var audioPlayer: AVPlayer?
    @State private var isPlaying = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(alignment: .top, spacing: 16) {
                    let isSuccess = item.status == .confirmed
                    let isFailed = item.status == .failed
                    let iconColor = isSuccess ? Color.green : (isFailed ? Color.black : Color.sushiSalmon)
                    let bgColor = isSuccess ? Color.green.opacity(0.15) : (isFailed ? Color.gray.opacity(0.2) : Color.sushiSalmon.opacity(0.15))
                    let iconName = isSuccess ? "phone.badge.checkmark" : (isFailed ? "phone.down.fill" : "phone.arrow.up.right.fill")
                    
                    // Left Icon
                    Circle()
                        .fill(bgColor)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: iconName)
                                .foregroundColor(iconColor)
                        )
                    
                    // Middle
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatTime(item.fullData?.updatedAt ?? ""))
                            .font(.subheadline.bold())
                            .foregroundColor(.black)
                        
                        // Summary
                        let summary = item.fullData?.confirmationDetails?.summary ?? "Call finished. Review details below."
                        Text(summary)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.leading)
                            .lineLimit(isExpanded ? nil : 2)
                        
                        if !isExpanded {
                            Text("↓ View Transcript & Audio")
                                .font(.caption2)
                                .foregroundColor(.sushiNori)
                                .padding(.top, 4)
                        }
                    }
                    
                    Spacer()
                    
                    // Right
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding(16)
                .background(Color.white)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Audio Player & Transcript
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                    
                    if let audioUrlString = item.fullData?.audioUrl, let _ = URL(string: audioUrlString) {
                        HStack {
                            Button(action: toggleAudio) {
                                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(.sushiSalmon)
                            }
                                                
                            GeometryReader { geo in
                            Capsule()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 4)
                                .overlay(
                                Capsule()
                                    .fill(Color.sushiSalmon)
                                    .frame(width: isPlaying ? geo.size.width * 0.8 : 0), // 简单的动画示意
                                    alignment: .leading
                                )
                                .animation(.linear(duration: isPlaying ? 20 : 0), value: isPlaying)
                            }
                        .frame(height: 32)
                        }
                    } else {
                        HStack {
                            Image(systemName: "speaker.slash.fill").foregroundColor(.gray)
                            Text("Audio recording not available").font(.caption).foregroundColor(.gray)
                        }
                    }
                    
                    // Transcript Language Toggle
                    HStack {
                        Image(systemName: "doc.plaintext")
                        Text("TRANSCRIPT")
                            .font(.subheadline.bold())
                        Spacer()
                        
                        // Mock Picker
                        HStack(spacing: 0) {
                            Text("English")
                                .font(.caption)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(selectedLanguage == "English" ? Color.sushiSalmon : Color.clear)
                                .foregroundColor(selectedLanguage == "English" ? .white : .gray)
                                .clipShape(Capsule())
                                .onTapGesture { selectedLanguage = "English" }
                            
                            Text("Original")
                                .font(.caption)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(selectedLanguage == "Original" ? Color.gray.opacity(0.2) : Color.clear)
                                .foregroundColor(selectedLanguage == "Original" ? .black : .gray)
                                .clipShape(Capsule())
                                .onTapGesture { selectedLanguage = "Original" }
                        }
                        .background(Color.gray.opacity(0.1))
                        .clipShape(Capsule())
                    }
                    .padding(.top, 8)
                    
                    // Transcript from Database
                    VStack(alignment: .leading, spacing: 8) {
                        if let transcript = item.fullData?.confirmationDetails?.transcript, !transcript.isEmpty {
                            ForEach(transcript) { msg in
                                Text("**\(msg.role.capitalized):** \(msg.message)")
                                    .padding(.bottom, 2)
                            }
                        } else {
                            Text("No transcript available.")
                                .foregroundColor(.gray)
                                .italic()
                        }
                    }
                    .font(.subheadline)
                    .padding(.leading, 12)
                    .overlay(
                        Rectangle()
                            .fill(Color.sushiSalmon)
                            .frame(width: 2),
                        alignment: .leading
                    )
                }
                .padding(16)
                .background(Color.white)
            }
        }
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        .onChange(of: isExpanded) { newValue in
            if !newValue {
                audioPlayer?.pause()
                isPlaying = false
            }
        }
    }
    
    private func toggleAudio() {
        guard let urlString = item.fullData?.audioUrl, let url = URL(string: urlString) else { return }
        
        if audioPlayer == nil {
            let playerItem = AVPlayerItem(url: url)
            audioPlayer = AVPlayer(playerItem: playerItem)
        }
            
        if isPlaying {
            audioPlayer?.pause()
        } else {
            audioPlayer?.play()
        }
        isPlaying.toggle()
    }
    
    private func formatTime(_ dateString: String) -> String {
        if dateString.isEmpty { return "Recently" }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else { return "Recently" }
        
        let outFormatter = DateFormatter(); outFormatter.dateFormat = "MMM dd, h:mm a"
        return outFormatter.string(from: date) + " (GMT+9)"
    }
}
