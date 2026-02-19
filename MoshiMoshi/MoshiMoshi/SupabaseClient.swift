//
//  SupabaseClient.swift
//  MoshiMoshi
//
//  Shared Supabase client. Session is persisted by the SDK (e.g. Keychain).
//

import Foundation
import Supabase

enum SupabaseClientManager {
    static let client: SupabaseClient = {
        SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.anonKey
        )
    }()
}
