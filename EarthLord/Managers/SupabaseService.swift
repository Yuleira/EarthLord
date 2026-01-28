import Foundation
import Supabase

final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        // Replace with your project URL and anon key
        let supabaseURL = URL(string: "https://zkcjvhdhartrrekzjtjg.supabase.co")!
        let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InprY2p2aGRoYXJ0cnJla3pqdGpnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY3NDYyMDksImV4cCI6MjA4MjMyMjIwOX0.MN4GjMaD3Ti8rgsYhCX07t68XHa7QW6TjixGPFdbZjk"

        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseAnonKey,
            options: .init(
                auth: .init(emitLocalSessionAsInitialSession: true)
            )
        )
    }
}
