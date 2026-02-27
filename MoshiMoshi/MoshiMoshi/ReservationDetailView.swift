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
    @ObservedObject var viewModel: ReservationViewModel
    @State private var showResponseSheet = false
    @Environment(\.dismiss) private var dismiss

    private var isActionRequired: Bool { item.status == .actionRequired }
    private var canModifyOrCancel: Bool {
        switch item.status {
        case .confirmed, .cancelled: return false
        default: return true
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 0. Action Required banner (when applicable)
                if isActionRequired {
                    actionRequiredBanner
                }

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
        .sheet(isPresented: $showResponseSheet) {
            ActionResponseView(item: item)
        }
    }

    // MARK: - Action Required Banner
    private var actionRequiredBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(item.status.color)
                Text("Action Required")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.sushiNori)
            }
            Text(item.fullData?.failureReason ?? item.resultMessage ?? "The restaurant needs your response.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: { showResponseSheet = true }) {
                HStack(spacing: 6) {
                    Text("Respond to Request")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .semibold))
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.sushiTuna)
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(item.status.color.opacity(0.08))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(item.status.color.opacity(0.2), lineWidth: 1)
        )
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
                InfoBlock(icon: "clock", title: "TIME", value: reservationTimeDisplay(item.request.reservationTime))
                Spacer()
                InfoBlock(icon: "mappin.and.ellipse", title: "LOCATION", value: "Japan")
            }
            
            HStack(alignment: .top) {
                InfoBlock(icon: "person.2", title: "PARTY", value: "\(item.request.partySize) People")
                Spacer()
                InfoBlock(icon: "phone", title: "CONTACT INFO", value: item.request.restaurantPhone)
            }
            
            Divider().padding(.vertical, 8)

            // Modify / Cancel or status message
            if item.status == .cancelled {
                Text("This reservation was cancelled.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else if item.status == .confirmed {
                Text("Confirmed reservations cannot be modified or cancelled.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            } else if canModifyOrCancel {
                HStack(spacing: 16) {
                    Button(action: { /* TODO: Modify */ }) {
                        Text("Modify")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.gray.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5])))
                    }
                    .foregroundColor(.black)

                    Button(action: {
                        viewModel.cancelReservation(uiItemId: item.id)
                        dismiss()
                    }) {
                        Text("Cancel")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.sushiTuna.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5])))
                    }
                    .foregroundColor(.sushiTuna)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
    }
    
    // MARK: - UI Helpers
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

    /// Show reservation time as stored (local time), e.g. "19:00"
    private func reservationTimeDisplay(_ reservationTime: String) -> String {
        guard !reservationTime.isEmpty else { return "—" }
        return reservationTime.count >= 5 ? String(reservationTime.prefix(5)) : reservationTime
    }
}

// MARK: - Transcript & Audio Card
struct CallHistoryExpandableCard: View {
    let item: ReservationItem
    @State private var isExpanded = false
    @State private var selectedLanguage = "English"
    
    // Audio Player States
    @State private var audioPlayer: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: Double = 0.0
    @State private var totalDuration: Double = 0.0
    @State private var isDragging = false
    @State private var isFinished = false // Tracks if audio reached the end
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // Header Button (Tap to expand/collapse)
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
                    
                    // Status Icon
                    Circle()
                        .fill(bgColor)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Image(systemName: iconName)
                                .foregroundColor(iconColor)
                        )
                    
                    // Call Details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(formatTime(item.fullData?.updatedAt ?? ""))
                            .font(.subheadline.bold())
                            .foregroundColor(.black)
                        
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
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding(16)
                .background(Color.white)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expanded Content (Audio Player & Transcript)
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                    
                    // MARK: - Authentic Audio Player
                    if let audioUrlString = item.fullData?.audioUrl, let _ = URL(string: audioUrlString) {
                        HStack(spacing: 12) {
                            // Play/Pause Button
                            Button(action: toggleAudio) {
                                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .resizable()
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(.sushiSalmon)
                            }
                            
                            // Interactive Slider for scrubbing
                            Slider(value: Binding(
                                get: { self.currentTime },
                                set: { newValue in
                                    self.currentTime = newValue
                                    // Seek to the exact time the user drags to
                                    audioPlayer?.seek(to: CMTime(seconds: newValue, preferredTimescale: 1000))
                                }
                            ), in: 0...(totalDuration > 0 ? totalDuration : 1)) { editing in
                                self.isDragging = editing
                            }
                            .tint(.sushiSalmon)
                            
                            // Dynamic Time Remaining
                            Text(formatDuration(totalDuration - currentTime))
                                .font(.caption.monospacedDigit())
                                .foregroundColor(.gray)
                                .frame(width: 40, alignment: .trailing)
                        }
                    } else {
                        // Fallback UI if audio URL is missing
                        HStack {
                            Image(systemName: "speaker.slash.fill").foregroundColor(.gray)
                            Text("Audio recording not available").font(.caption).foregroundColor(.gray)
                        }
                    }
                    
                    // MARK: - Transcript Language Toggle
                    HStack {
                        Image(systemName: "doc.plaintext")
                        Text("TRANSCRIPT")
                            .font(.subheadline.bold())
                        Spacer()
                        
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
                    
                    // MARK: - Transcript Chat List
                    VStack(alignment: .leading, spacing: 8) {
                        if let transcript = item.fullData?.confirmationDetails?.transcript, !transcript.isEmpty {
                            ForEach(transcript) { msg in
                                let displayRole: String = {
                                    let rawRole = msg.role.lowercased()
                                    if rawRole == "user" {
                                        return "Restaurant"
                                    } else if rawRole == "agent" {
                                        return "MoshiMoshi" // 换成你的专属 Agent 名字！
                                    } else {
                                        return msg.role.capitalized
                                    }
                                }()
                                Text("**\(displayRole):** \(msg.message)")
                                    .padding(.bottom, 4)
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
        
        // Stops playback if the card is collapsed
        .onChange(of: isExpanded) { newValue in
            if !newValue {
                audioPlayer?.pause()
                isPlaying = false
            }
        }
        
        // Stops playback if the user leaves the detail page
        .onDisappear {
            audioPlayer?.pause()
            isPlaying = false
        }
    }
    
    // MARK: - Audio Controller Logic
    private func toggleAudio() {
        guard let urlString = item.fullData?.audioUrl, let url = URL(string: urlString) else { return }
        
        // Initialize player only on first tap
        if audioPlayer == nil {
            let playerItem = AVPlayerItem(url: url)
            audioPlayer = AVPlayer(playerItem: playerItem)
            
            // 1. Fetch exact audio duration asynchronously
            Task {
                if let duration = try? await playerItem.asset.load(.duration) {
                    DispatchQueue.main.async {
                        self.totalDuration = duration.seconds
                    }
                }
            }
            
            // 2. Add an observer to update the slider every 0.1 seconds
            let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            audioPlayer?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                if !self.isDragging {
                    self.currentTime = time.seconds
                }
            }
            
            // 3. Listen for the exact moment the audio finishes playing
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { _ in
                self.isPlaying = false
                self.isFinished = true
                self.currentTime = self.totalDuration // Snap to end
            }
        }
        
        // Handle Play/Pause and Replay
        if isPlaying {
            audioPlayer?.pause()
            isPlaying = false
        } else {
            // FIX: If playback finished previously, rewind to 0:00 before playing
            if isFinished || currentTime >= totalDuration {
                audioPlayer?.seek(to: .zero)
                isFinished = false
            }
            audioPlayer?.play()
            isPlaying = true
        }
    }
    
    // Converts seconds into a clean "1:20" format
    private func formatDuration(_ seconds: Double) -> String {
        if seconds.isNaN || seconds < 0 { return "0:00" }
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
    
    // Converts ISO string to "Feb 5, 2:45 PM"
    private func formatTime(_ dateString: String) -> String {
        if dateString.isEmpty { return "Recently" }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else { return "Recently" }
        
        let outFormatter = DateFormatter(); outFormatter.dateFormat = "MMM dd, h:mm a"
        return outFormatter.string(from: date) + " (GMT+9)"
    }
}
