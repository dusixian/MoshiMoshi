//
//  ProfileService.swift
//  MoshiMoshi
//
//  Fetches and updates user profile in Supabase `profiles` table.
//

import Foundation
import Supabase

@MainActor
final class ProfileService: ObservableObject {
    private var supabase: SupabaseClient { SupabaseClientManager.client }

    func currentUserId() async -> UUID? {
        guard let session = try? await supabase.auth.session else { return nil }
        return session.user.id
    }

    func fetchProfile() async throws -> UserProfile? {
        guard let uid = await currentUserId() else { return nil }
        do {
            let row: UserProfile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: uid)
                .single()
                .execute()
                .value
            return row
        } catch {
            return nil
        }
    }

    func updateDefaultRegion(_ region: String) async throws {
        guard let uid = await currentUserId() else { return }
        let now = ISO8601DateFormatter().string(from: Date())
        try await supabase
            .from("profiles")
            .update(["default_region": region, "updated_at": now])
            .eq("id", value: uid)
            .execute()
    }

    func upsertProfile(fullName: String?, email: String?, phone: String?, defaultRegion: String? = nil) async throws {
        guard let uid = await currentUserId() else { return }
        struct Row: Encodable {
            let id: UUID
            let full_name: String?
            let email: String?
            let phone: String?
            let updated_at: String
            let default_region: String?
        }
        let now = ISO8601DateFormatter().string(from: Date())
        let row = Row(
            id: uid,
            full_name: fullName?.isEmpty == true ? nil : fullName,
            email: email?.isEmpty == true ? nil : email,
            phone: phone?.isEmpty == true ? nil : phone,
            updated_at: now,
            default_region: defaultRegion?.isEmpty == true ? nil : defaultRegion
        )
        try await supabase
            .from("profiles")
            .upsert(row)
            .execute()
    }
}
