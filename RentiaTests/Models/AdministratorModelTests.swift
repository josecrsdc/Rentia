import Testing
import Foundation
@testable import Rentia

@Suite("Administrator Model — initials")
struct AdministratorModelTests {
    private func makeAdmin(name: String) -> Administrator {
        Administrator(
            id: nil,
            ownerId: "owner1",
            name: name,
            phone: "600000000",
            landlinePhone: nil,
            email: "admin@example.com",
            createdAt: Date()
        )
    }

    @Test func initialsFromTwoWords() {
        #expect(makeAdmin(name: "Juan Pérez").initials == "JP")
    }

    @Test func initialsFromOneWord() {
        #expect(makeAdmin(name: "Juan").initials == "J")
    }

    @Test func initialsFromThreeWords() {
        // takes first and last
        #expect(makeAdmin(name: "Juan Carlos Pérez").initials == "JP")
    }

    @Test func initialsAreUppercased() {
        #expect(makeAdmin(name: "ana García").initials == "AG")
    }

    @Test func initialsWithAccentedChars() {
        let admin = makeAdmin(name: "Álvaro Íñiguez")
        // prefix(1).uppercased() of "Álvaro" → "Á", of "Íñiguez" → "Í"
        #expect(admin.initials == "ÁÍ")
    }

    @Test func initialsEmptyString() {
        #expect(makeAdmin(name: "").initials == "")
    }
}
