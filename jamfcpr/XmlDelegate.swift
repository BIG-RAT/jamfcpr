//
//  XmlDelegate.swift
//  jamfcpr
//
//  Created by Leslie Helou on 5/17/19.
//  Copyright © 2019 jamf. All rights reserved.
//

import Cocoa

class XmlDelegate: NSObject, XMLParserDelegate {
    
    var name          = ""
    var id            = ""
    var filename      = ""
    var hashType      = ""
    var checksum      = ""
    var size          = ""
    var fileURL       = ""
    var lastModified  = ""
    
    var packageArray: [Package] = []
    var newPackage: Package? = nil
    
    enum State { case none, name, id, filename, hashType, checksum, size, fileURL, lastModified }
    var state: State = .none
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        switch elementName {
        case "package" :
            self.newPackage = Package()
            self.state = .none
        case "id":
            self.state = .id
        case "name":
            self.state = .name
        case "filename":
            self.state = .filename
        case "hashType":
            self.state = .hashType
        case "checksum":
            self.state = .checksum
        case "size":
            self.state = .size
        case "fileURL":
            self.state = .fileURL
        case "lastModified":
            self.state = .lastModified
        default:
            self.state = .none
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if let newPackage = self.newPackage, elementName == "package" {
            self.packageArray.append(newPackage)
            self.newPackage = nil
        }
        self.state = .none
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard let _ = self.newPackage else { return }
        switch self.state {
        case .name:
            self.newPackage!.name = string
        case .id:
            self.newPackage!.id = string
        case .filename:
            self.newPackage!.filename = string
        case .hashType:
            self.newPackage!.hashType = (string == "0") ? "MD5":"SHA_512"
        case .checksum:
            self.newPackage!.checksum = string
        case .size:
            self.newPackage!.size = string
        case .fileURL:
            self.newPackage!.fileURL = string
        case .lastModified:
            self.newPackage!.lastModified = string
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
    }
    
    // extract the value between (different) tags - start
    func tagValue2(xmlString:String, startTag:String, endTag:String, includeTags: Bool) -> String {
        var rawValue = ""
        if let start = xmlString.range(of: startTag),
            let end  = xmlString.range(of: endTag, range: start.upperBound..<xmlString.endIndex) {
            rawValue.append(String(xmlString[start.upperBound..<end.lowerBound]))
        }
        if includeTags {
//            print("rawValue[\(startTag)]: \(startTag)\(rawValue)\(endTag)")
            return "\(startTag)\(rawValue)\(endTag)"
        } else {
//            print("rawValue[\(startTag)]: \(rawValue)")
            return rawValue
        }
    }
    //  extract the value between (different) tags - end
}

struct Package {
    var name          = ""
    var id            = ""
    var filename      = ""
    var hashType      = ""
    var checksum      = ""
    var size          = ""
    var fileURL       = ""
    var lastModified  = ""
}
