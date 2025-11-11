//
//  LoggerExtension
//

// log stream --info --predicate 'subsystem == "jamf.ie.jamfcpr"'
// log stream --debug --predicate 'subsystem == "jamf.ie.jamfcpr" AND category == "function"' | tee -a ~/Desktop/jamfcpr_functions.txt
// cat ~/Desktop/jamfcpr_functions.txt | awk '{for (i=11; i<=NF; i++) printf $i " "; print ""}' | tee -a ~/Desktop/jamfcpr_functions1.txt

import Foundation
import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier!
    
    // keychain related
    static let teamId              = Logger(subsystem: subsystem, category: "teamId")
    static let saveCredentials     = Logger(subsystem: subsystem, category: "saveCredentials")
    static let retrieveCredentials = Logger(subsystem: subsystem, category: "retrieveCredentials")
    static let credentialsLookup   = Logger(subsystem: subsystem, category: "credentialsLookup")
    
    static let awsAuthHeader                 = Logger(subsystem: subsystem, category: "awsAuthHeader")
    static let multipartUpload               = Logger(subsystem: subsystem, category: "multipartUpload")
    static let token                         = Logger(subsystem: subsystem, category: "token")
}
