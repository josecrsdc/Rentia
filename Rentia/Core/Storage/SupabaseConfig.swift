import Foundation

/// Credenciales de Supabase Storage.
/// Rellena estos valores con los de tu proyecto en https://supabase.com/dashboard
enum SupabaseConfig {
    /// URL del proyecto: https://{ref}.supabase.co
    static let projectURL = "https://jdfjfxzjupyhhnzfjyfv.supabase.co"

    /// Anon key (Project Settings → API → Project API keys → anon public)
    // swiftlint:disable:next line_length
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpkZmpmeHpqdXB5aGhuemZqeWZ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQwNDQ3NDksImV4cCI6MjA4OTYyMDc0OX0.GpntjP5Se14bEIolse_VTGll7eE9Ed2ADKJSSD22H-E"

    /// Nombre del bucket en Supabase → Storage (créalo como público)
    static let bucket = "rentia"
}
