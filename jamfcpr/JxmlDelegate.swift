//
//  JxmlDelegate.swift
//  jamfcpr
//
//  Created by Leslie Helou on 6/26/19.
//  Copyright © 2019 jamf. All rights reserved.
//

import Cocoa

class JxmlDelegate: NSObject, XMLParserDelegate {
    
//    var id       = ""
    var name     = ""
    var filename = ""
    var checksum = ""
    var size     = ""
    
    var serverArray: [FileServer] = []
    enum State { case none, ip, share, type, domain, adminUsername, adminPassword, master, id, fileURL }
    var state: State = .none
    var newServer: FileServer? = nil
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        switch elementName {
        case "cloudDistributionPoint","fileserver","package" :
            self.newServer = FileServer()
            self.state = .none
        case "ip":
            self.state = .ip
        case "share":
            self.state = .share
        case "type":
            self.state = .type
        case "domain":
            self.state = .domain
        case "adminUsername":
            self.state = .adminUsername
        case "adminPassword":
            self.state = .adminPassword
        case "master":
            self.state = .master
        case "id":
            self.state = .id
        case "fileURL":
            self.state = .fileURL
        default:
            self.state = .none
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if let newServer = self.newServer, elementName == "fileserver" {
            self.serverArray.append(newServer)
            self.newServer = nil
        }
        if let newServer = self.newServer, elementName == "package" {
            self.serverArray.append(newServer)
            self.newServer = nil
        }
        self.state = .none
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard let _ = self.newServer else { return }
        switch self.state {
        case .ip:
            self.newServer!.ip = string
        case .share:
            self.newServer!.share = string
        case .type:
            self.newServer!.type = string
        case .domain:
            self.newServer!.domain = string
        case .adminUsername:
            self.newServer!.adminUsername = string
        case .adminPassword:
            self.newServer!.adminPassword = string
        case .master:
            self.newServer!.master = string
        case .id:
            self.newServer!.id = string
        case .fileURL:
            self.newServer!.fileURL = string
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
    }
    
    func tagValue(xmlString:String, startTag:String, endTag:String) -> String {
        var rawValue = ""
        if let start = xmlString.range(of: startTag),
            let end  = xmlString.range(of: endTag, range: start.upperBound..<xmlString.endIndex) {
            rawValue.append(String(xmlString[start.upperBound..<end.lowerBound]))
        } else {
            print("[tagValue] nothing found between \(startTag) and \(endTag) tags.\n")
        }
        return rawValue
    }
}

struct FileServer {
    var ip            = ""
    var share         = ""
    var type          = ""
    var domain        = ""
    var adminUsername = ""
    var adminPassword = ""
    var master        = ""
    var id            = ""
    var fileURL       = ""
}

