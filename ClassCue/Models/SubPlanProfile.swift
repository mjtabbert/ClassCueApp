import Foundation

struct SubPlanProfile: Identifiable, Codable, Equatable {
    struct AppCredential: Identifiable, Codable, Equatable {
        var id: UUID = UUID()
        var applicationName: String = ""
        var applicationLink: String = ""
        var username: String = ""
        var password: String = ""

        var hasContent: Bool {
            ![
                applicationName,
                applicationLink,
                username,
                password
            ]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .allSatisfy(\.isEmpty)
        }
    }

    var id: UUID = UUID()
    var teacherName: String = ""
    var room: String = ""
    var contactEmail: String = ""
    var contactPhone: String = ""
    var schoolFrontOfficeContact: String = ""
    var neighboringTeacher: String = ""
    var emergencyDrillProcedures: String = ""
    var emergencyDrillFileLink: String = ""
    var passwordsAccessNotes: String = ""
    var appCredentials: [AppCredential] = []
    var phoneExtensions: String = ""
    var staticNotes: String = ""

    var hasContent: Bool {
        ![
            teacherName,
            room,
            contactEmail,
            contactPhone,
            schoolFrontOfficeContact,
            neighboringTeacher,
            emergencyDrillProcedures,
            emergencyDrillFileLink,
            passwordsAccessNotes,
            phoneExtensions,
            staticNotes
        ]
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .allSatisfy(\.isEmpty)
        || appCredentials.contains(where: \.hasContent)
    }
}
