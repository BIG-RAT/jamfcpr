//
//  Globals.swift
//  jamfcpr
//
//  Created by Leslie Helou on 3/24/20.
//  Copyright © 2020 Leslie Helou. All rights reserved.
//

import Foundation

struct Parameters {
    static var distributionPointDictionary = [String:[String:String]]()
    static var distributionPointArray      = [String]()
    static var mountedSharesDict           = [String:String]() // Array of shares mounted by the app
    static var listOption                  = false
    static var cloudDistribitionPoint      = false
    static var downloadsUrl                = (FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first! as URL).appendingPathComponent("jamfcpr")
    static var downloadOption              = "Options"
}

struct History {
    static var logPath: String? = (NSHomeDirectory() + "/Library/Logs/jamfcpr/")
    static var logFile  = ""
    static var didRun   = false
    static var maxFiles = 20
}
