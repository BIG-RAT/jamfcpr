//
//  JcdsDelegate.swift
//  jamfcpr
//
//  Created by Leslie Helou on 7/12/19.
//  Copyright © 2019 jamf. All rights reserved.
//

import Cocoa

class JcdsDelegate: NSObject, XMLParserDelegate {
    
    var skipPackages = false
    
    var serverArray: [ Jcds] = []
    enum State { case none, id, name, type, master }
    var state: State = .none
    var newServer:  Jcds? = nil
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if !skipPackages {
            switch elementName {
            case "cloudDistributionPoint":
                self.newServer =  Jcds()
                self.state = .none
            case "packages":
                skipPackages = true
            case "id":
                self.state = .id
            case "name":
                self.state = .name
            case "type":
                self.state = .type
            case "master":
                self.state = .master
            default:
                self.state = .none
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if let newServer = self.newServer, elementName == "cloudDistributionPoint" {
            self.serverArray.append(newServer)
            self.newServer = nil
            skipPackages = false
        }
//        if let newServer = self.newServer, elementName == "package" {
//            self.serverArray.append(newServer)
//            self.newServer = nil
//        }
        self.state = .none
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard let _ = self.newServer else { return }
        switch self.state {
        case .id:
            self.newServer!.id = string
        case .name:
            self.newServer!.name = string
        case .type:
            self.newServer!.type = string
        case .master:
            self.newServer!.master = string
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

struct  Jcds {
    var id     = ""
    var name   = ""
    var type   = ""
    var master = ""
}


