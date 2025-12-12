//
//  Copyright © 2025 Jamf. All rights reserved.
//

import TelemetryDeck

struct TelemetryDeckConfig {
    static let appId = "4D46F8A7-D26D-44CD-AC97-A2FEB3E6FABD"
    @MainActor static var parameters: [String: String] = [:]
}

extension AppDelegate {
    @MainActor func configureTelemetryDeck() {
        
        let config = TelemetryDeck.Config(appID: TelemetryDeckConfig.appId)
        TelemetryDeck.initialize(config: config)
    }
}
