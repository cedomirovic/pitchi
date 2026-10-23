// Pokretanje aplikacije pri prijavi korisnika preko SMAppService (macOS 13+).
import Foundation
import ServiceManagement

enum Prijava {
    static var ukljucena: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static var zahtevaOdobrenje: Bool {
        SMAppService.mainApp.status == .requiresApproval
    }

    static func postavi(_ zeljeno: Bool) throws {
        if zeljeno {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } else if SMAppService.mainApp.status != .notRegistered {
            try SMAppService.mainApp.unregister()
        }
    }

    static func otvoriPodesavanja() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
