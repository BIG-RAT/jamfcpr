//
//  ListPackages.swift
//  jamfcpr
//
//  Created by Leslie Helou on 12/6/18.
//  Copyright © 2018 jamf. All rights reserved.
//

import Cocoa
import Foundation
import NetFS


class ListPackages: NSViewController, URLSessionDelegate {
    
    var isDir: ObjCBool = true
    let userDefaults = UserDefaults.standard
//    var sourcePath = SourceValue(path: "")
    
    var httpStatusCode = 0
    var packageIdNamdDict:[String:Int] = [:]   // something like packageId, epoch of packageName
    
    var     packagesDict = Dictionary<String, Dictionary<String,String>>()
    var nameFilenameDict = Dictionary<String, String>()
    var  packageInfoDict = Dictionary<String, String>()
    var     jcdsInfoDict = Dictionary<String, String>()
    var    foundJcdsInfo = false
    var  jxmlResponseStr = ""
    
    let thePatchFetchQ  = OperationQueue() // que to fetch ids and names of the packages
        
//    func idName(server: String, creds: String, completion: @escaping (_ result: Dictionary<String, Int>) -> Void) {
//        let semaphore = DispatchSemaphore(value: 0)
//        
//        var packageNode = "\(server)/JSSResource/packages"
//        //        WriteToLog().message(stringOfText: "initial URL: \(self.serverURL)\n")
//        packageNode = packageNode.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
//        //        WriteToLog().message(stringOfText: "URL: \(self.serverURL)\n")
//        
//        thePatchFetchQ.addOperation {
//            let encodedURL = NSURL(string: packageNode)
//            let request = NSMutableURLRequest(url: encodedURL! as URL)
//            request.httpMethod = "GET"
//            let configuration = URLSessionConfiguration.default
//            configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(creds)", "Content-Type" : "application/json", "Accept" : "application/json"]
//            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
//            let task = session.dataTask(with: request as URLRequest, completionHandler: {
//                (data, response, error) -> Void in
//                if let httpResponse = response as? HTTPURLResponse {
//                    //                    WriteToLog().message(stringOfText: "httpResponse: \(String(describing: response))")
//                    
//                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
//                    if let endpointJSON = json as? [String: Any] {
//                        //                        WriteToLog().message(stringOfText: "endpointJSON: \(endpointJSON))")
//                        
//                        WriteToLog().message(stringOfText: "processing packages on destination server")
//                        if let endpointInfo = endpointJSON["packages"] as? [Any] {
//                            let packageCount: Int = endpointInfo.count
//                            WriteToLog().message(stringOfText: "Packages found on destination server: \(packageCount)")
//                            
//                            if packageCount > 0 {
//                                for i in (0..<packageCount) {
//                                    let record = endpointInfo[i] as! [String : AnyObject]
//                                    if let packageId: Int = (record["id"] as? Int), let packageName: String = (record["name"] as? String) {
//                                        self.packageIdNamdDict[packageName] = packageId
//                                    }
//                                    //WriteToLog().message(stringOfText: "\(packageName)")
//                                }
//                            }   // end if let buildings, departments...
//                        }   //if let endpointInfo = endpointJSON - end
//                        
//                    }   // if let endpointJSON - end
//                    
//                    if httpResponse.statusCode >= 199 && httpResponse.statusCode <= 299 {
//                        //print(httpResponse.statusCode)
//                        completion(self.packageIdNamdDict)
//                    } else {
//                        // something went wrong
//                        //self.writeToHistory(stringOfText: "**** \(self.getName(endpoint: endpointType, objectXML: endPointXML)) - Failed\n")
//                        WriteToLog().message(stringOfText: "\n\n---------- status code ----------")
//                        print(httpResponse.statusCode)
//                        self.httpStatusCode = httpResponse.statusCode
//                        WriteToLog().message(stringOfText: "---------- status code ----------")
//                        WriteToLog().message(stringOfText: "\n\n---------- response ----------")
//                        print(httpResponse)
//                        WriteToLog().message(stringOfText: "---------- response ----------\n\n")
//                        switch self.httpStatusCode {
//                        case 401:
//                            WriteToLog().message(stringOfText: "401")
//                        //self.alert_dialog(header: "Authentication Failure", message: "Please verify username and password for the source server.")
//                        default:
//                            WriteToLog().message(stringOfText: "default")
//                            //self.alert_dialog(header: "Error", message: "An unknown error occured trying to query the source server.")
//                        }
//                        
//                        //                        401 - wrong username and/or password
//                        //                        409 - unable to create object; already exists or data missing or xml error
//                        //                        self.spinner.stopAnimation(self)
//                        completion([:])
//                        
//                    }   // if httpResponse/else - end
//                }   // if let httpResponse - end
//                semaphore.signal()
//                if error != nil {
//                }
//            })  // let task = session - end
//            //WriteToLog().message(stringOfText: "GET")
//            task.resume()
//            semaphore.wait()
//        }   // thePatchFetchQ - end
//        
//        
//    }
    
    func casperJxmlGet(whichServer: String, server: String, username: String, password: String, completion: @escaping (_ result: (Dictionary<String, Dictionary<String,String>>, Dictionary<String, String>, Dictionary<String,String>, String)) -> Void) {
        
        // hashType 0 - MD5
        // hashType 1 - SHA_512
        
        let semaphore = DispatchSemaphore(value: 0)
        var mountPoint = ""
//        var foundJcdsInfo = false
                
        var casperJxmlNode = "\(server)/casper.jxml"
        casperJxmlNode = casperJxmlNode.replacingOccurrences(of: "//casper.jxml", with: "/casper.jxml")
        
        thePatchFetchQ.addOperation {
            let encodedURL = NSURL(string: casperJxmlNode)
            let request = NSMutableURLRequest(url: encodedURL! as URL)
            request.httpBody = "source=jamfCPR&username=\(username)&password=\(password)&skipComputers=true".data(using: String.Encoding.utf8)
            request.httpMethod = "POST"
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = ["Content-Type" : "application/x-www-form-urlencoded"]
            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
//                    WriteToLog().message(stringOfText: "httpResponse: \(String(describing: response))")

                    if httpResponse.statusCode > 199 && httpResponse.statusCode <= 299 {
                        self.jxmlResponseStr = String(data: data!, encoding: .utf8) ?? ""
//                        var     packagesDict = Dictionary<String, Dictionary<String,String>>()
//                        var nameFilenameDict = Dictionary<String, String>()
//                        var  packageInfoDict = Dictionary<String, String>()
//                        var     jcdsInfoDict = Dictionary<String, String>()

                        if whichServer == "destination" {
//                            WriteToLog().message(stringOfText: "[ListPackages.casperJmmlGet] source=jamfCPR&username=\(username)&password=\(password)&skipComputers=true")
                            let jxmlResponse = XmlDelegate().tagValue2(xmlString: self.jxmlResponseStr, startTag: "<response>", endTag: "</response>", includeTags: false)
//                            WriteToLog().message(stringOfText: "[ListPackages.casperJmmlGet] jxmlResponse: \(jxmlResponse) ")
                            self.jxmlResponseStr = self.betweenTags(xmlString: self.jxmlResponseStr, startTag: "<packages>", endTag: "</packages>")
                            
                            if jxmlResponse.lowercased() == "bad username or password" {
                                WriteToLog().message(stringOfText: "Authentication Failure.  Please verify username and password for the destination server.")
                                Alert().display(header: "Authentication Failure:", message: "Please verify username and password for the destination server.")
                                completion(([:], [:], [:],"401"))
                                return
                            }
                            
                            // Wrap it up or it won't be valid XML
                            let xmlData = "<packages>" + self.jxmlResponseStr + "</packages>"
                            
                            // We can create a parser from a URL, a Stream, or NSData.
                            if let data = xmlData.data(using: .utf16) { // Get the NSData
                                let xmlParser = XMLParser(data: data)
                                let delegate = XmlDelegate()
                                xmlParser.delegate = delegate
                                if xmlParser.parse() {
                                    for entry in delegate.packageArray {
                                        WriteToLog().message(stringOfText: "[ListPackages-casperJxmlGet] entry: \(entry)")
                                        self.packagesDict[entry.filename] = ["name":entry.name, "filename":entry.filename, "id":entry.id, "hashType":entry.hashType, "checksum":entry.checksum, "size":entry.size]
                                        self.nameFilenameDict[entry.name] = entry.filename
                                    }
                                }
                            }
                            
                            // get info about package download URL, token, distribution server -  start
                            var packageXml = String(data: data!, encoding: .utf8)
                            packageXml = self.betweenTags(xmlString: packageXml!, startTag: "<cloudDistributionPoints>", endTag: "</cloudDistributionPoints>")
                            
                            // Wrap it up or it won't be valid XML
                            let packageData = "<cloudDistributionPoints>" + packageXml! + "</cloudDistributionPoints>"
                            
                            // We can create a parser from a URL, a Stream, or NSData.
                            if let data = packageData.data(using: .utf16) { // Get the NSData
                                let xmlParser = XMLParser(data: data)
                                let delegate = JxmlDelegate()
                                xmlParser.delegate = delegate
                                if xmlParser.parse() {
                                    for entry in delegate.serverArray {
                                        //            WriteToLog().message(stringOfText: "\(entry)")
                                        self.packageInfoDict[entry.id] = entry.fileURL
                                        if !self.foundJcdsInfo {
                                            let jcdsServer = self.betweenTags(xmlString: entry.fileURL, startTag: "https://", endTag: "//")
                                            let jcdsShare = self.betweenTags(xmlString: entry.fileURL, startTag: "download/", endTag: "/")
                                            let tokenArray = entry.fileURL.split(separator: "=")
                                            let jcdsToken = tokenArray.last
                                            
                                            if jcdsServer != "" && jcdsShare != "" && jcdsToken != "" {
                                                WriteToLog().message(stringOfText: "[ListPackages-casperJxmlGet] JCDS Server: \(jcdsServer)")
                                                WriteToLog().message(stringOfText: "[ListPackages-casperJxmlGet]  JCDS Share: \(jcdsShare)")
                                                WriteToLog().message(stringOfText: "[ListPackages-casperJxmlGet]  JCDS Token: \(String(describing: jcdsToken!))")
                                                self.jcdsInfoDict = ["server":jcdsServer, "share":jcdsShare, "token":"\(String(describing: jcdsToken!))"]
                                                self.foundJcdsInfo = true
                                            }
                                        }
                                        
                                        
                                        
                                    }
//                                    WriteToLog().message(stringOfText: "[ListPackages]  packageInfoDict: \(packageInfoDict)")
                                }
                            }
                            // merge fileURL into packagesDict -  start
                            for (pkgName,pkgAttributes) in self.packagesDict {
                                if let pkgId = pkgAttributes["id"] {
                                    if let pkgDownloadURL = self.packageInfoDict["\(pkgId)"] {
                                        var pkgAttributesUpdate = pkgAttributes
                                        pkgAttributesUpdate["fileURL"] = pkgDownloadURL
                                        self.packagesDict["\(pkgName)"] = pkgAttributesUpdate
                                    }
                                }
                            }
                            // merge fileURL into packagesDict -  end
//                            WriteToLog().message(stringOfText: "[ListPackages]     packagesDict: \(packagesDict)")
//                            WriteToLog().message(stringOfText: "[ListPackages] nameFilenameDict: \(nameFilenameDict)")
                        } else {
                            // grab distribution points for source server from casper.jxml and try to mount - start

                            Parameters.cloudDistribitionPoint = false
                            
                            if NSEvent.modifierFlags.contains(.option) {
                                WriteToLog().message(stringOfText: "[JxmlDelegate] using option key")
                                completion(([:], [:], [:],""))
                            }
                            
                            let rawXml = String(data: data!, encoding: .utf8)
//                            WriteToLog().message(stringOfText: "[casperJxmlGet] raw fileServerXml: \(String(describing: rawXml!))")
                            var fileServerXml = ""
                            fileServerXml = "<fileservers>" + self.betweenTags(xmlString: rawXml!, startTag: "<fileservers>", endTag: "</fileservers>") + "</fileservers>"
//                            WriteToLog().message(stringOfText: "fileServerXml: \(String(describing: fileServerXml))")
                            var masterDistroDict = Dictionary<String,String>()
//                            WriteToLog().message(stringOfText: "[casperJxmlGet] fileServerXml: \(String(describing: fileServerXml))")
                        
                            if let data = fileServerXml.data(using: .utf16) { // Get the NSData
                                let xmlParser = XMLParser(data: data)
                                let delegate = JxmlDelegate()
                                xmlParser.delegate = delegate
                                if xmlParser.parse() {
//                                    WriteToLog().message(stringOfText: "[JxmlDelegate] serverArray: \(delegate.serverArray)")
                                    
                                    for entry in delegate.serverArray {
                                        Parameters.distributionPointDictionary[entry.ip] = ["ip":entry.ip, "share":entry.share, "type":entry.type, "domain":entry.domain, "adminUsername":entry.adminUsername, "adminPassword":entry.adminPassword, "master":entry.master]
                                        Parameters.distributionPointArray.append(entry.ip)
                                        
                                        WriteToLog().message(stringOfText: "[JxmlDelegate] checking \(entry.ip)")
                                        if entry.master == "true" && !Parameters.listOption {
                                            masterDistroDict = ["ip":entry.ip, "share":entry.share, "type":entry.type, "domain":entry.domain, "adminUsername":entry.adminUsername, "adminPassword":entry.adminPassword, "master":entry.master]
//                                            WriteToLog().message(stringOfText: "[casperJxmlGet] master disto point info: \(masterDistroDict)")
                                            
                                            sourceServerInfo.name = entry.ip
                                            
                                            let url = NSURL(string: "\(entry.type)://\(entry.ip)/\(entry.share)")
                                            WriteToLog().message(stringOfText: "[casperJxmlGet] url: \(url!)")  // -> smb://server.lab/Package%20Storage
                                            var userDomain = ""
                                            if entry.domain != "" {
                                                userDomain = "\(String(describing: masterDistroDict["domain"]!))\\"
                                                WriteToLog().message(stringOfText: "full login name: \(userDomain)\(String(describing: masterDistroDict["adminUsername"]!))")
                                            }
                                            
                                            let uuid = "\(UUID())".replacingOccurrences(of: "-", with: "")
                                            WriteToLog().message(stringOfText: "uuid: \(uuid)")
                                            if !FileManager.default.fileExists(atPath: "/private/tmp/\(entry.ip)", isDirectory: &self.isDir) {
                                                do {
                                                 try FileManager.default.createDirectory(atPath: "/private/tmp/\(entry.ip)", withIntermediateDirectories: true, attributes: nil)
                                                } catch {
                                                    WriteToLog().message(stringOfText: "failed to create mount point.")
                                                }
                                                
                                            }
//                                            let localMount = URL(fileURLWithPath: "/private/tmp/\(entry.ip)/\(uuid)")
                                            let localMount = URL(fileURLWithPath: "/private/tmp/\(entry.ip)")
                                            let result = NetFSMountURLSync(url!, localMount as CFURL, "\(userDomain)\(String(describing: masterDistroDict["adminUsername"]!))" as CFString, "\(String(describing: masterDistroDict["adminPassword"]!))" as CFString,  nil, nil, nil)
                                            
                                            WriteToLog().message(stringOfText: "[JxmlDelegate] result of mount: \(result)")
                                            //   0 - new mount
                                            //   2 - share does not exist on the server
                                            //  17 - mount point already exists, we'll use it
                                            //  65 - unable to reach server
                                            // 128 - credentials error?
                                            switch result {
                                            case 0:
                                                self.userDefaults.set("mounted", forKey: "share")
                                                self.userDefaults.set("directory", forKey: "packageSource")
                                                self.userDefaults.synchronize()
                                                Parameters.mountedSharesDict[entry.ip] = masterDistroDict["share"]!
//                                                mountPoint = "/private/tmp/\(entry.ip)/\(uuid)/\(masterDistroDict["share"]!)/"
                                                mountPoint = "/private/tmp/\(entry.ip)/\(masterDistroDict["share"]!)/"
                                            case 17:
                                                if FileManager.default.fileExists(atPath: "/private/tmp/\(entry.ip)/\(masterDistroDict["share"]!)/", isDirectory: &self.isDir) {

                                                    self.userDefaults.set("mounted", forKey: "share")
                                                    self.userDefaults.set("directory", forKey: "packageSource")
                                                    self.userDefaults.synchronize()
                                                    mountPoint = "/private/tmp/\(entry.ip)/\(masterDistroDict["share"]!)/"
                                                    
                                                } else {
                                                    Alert().display(header: "Attention:", message: "It appears the server/share (\(entry.ip)/\(masterDistroDict["share"]!)) is already mounted.  Unmount and run again.")
                                                    completion(([:], [:], [:],""))
                                                    return
                                                }
                                            default:
                                                break
                                            }
                                        }
                                    }
                                } else {
                                    WriteToLog().message(stringOfText: "No distributions points found.")
                                }
                            }
                            // grab distribution points from casper.jxml and try to mount - end
                            
                            // if no mountable distribution points are found look for JCDS - start
                            if masterDistroDict.count == 0 {
                                var jcdsServerXml = ""
                                jcdsServerXml = "<cloudDistributionPoints>" + self.betweenTags(xmlString: rawXml!, startTag: "<cloudDistributionPoints>", endTag: "</cloudDistributionPoints>") + "</cloudDistributionPoints>"
                                WriteToLog().message(stringOfText: "JcdsServerXml: \(String(describing: jcdsServerXml))")
                                
                                if let data = jcdsServerXml.data(using: .utf16) { // Get the NSData
                                    // put cloud packages into dictionaries
                                    (self.packagesDict, self.nameFilenameDict, self.jcdsInfoDict, mountPoint) = self.listCloudPackages(jxmlString: self.jxmlResponseStr)
                                    
//                                    WriteToLog().message(stringOfText: "\n[ListPackages casperJxmlGet] packagesDict: \(self.packagesDict) \n")
//                                    WriteToLog().message(stringOfText: "\n[ListPackages casperJxmlGet] nameFilenameDict: \(self.nameFilenameDict) \n")
                                    
                                    let xmlParser = XMLParser(data: data)
                                    let delegate = JcdsDelegate()
                                    xmlParser.delegate = delegate
                                    if xmlParser.parse() {
                                        WriteToLog().message(stringOfText: "[JcdsDelegate] serverArray: \(delegate.serverArray)")
                                        for entry in delegate.serverArray {
                                            WriteToLog().message(stringOfText: "checking \(entry.name)")
                                            if entry.master == "Yes" {
                                                masterDistroDict = ["id":entry.id, "name":entry.name, "type":entry.type, "master":entry.master]
                                                WriteToLog().message(stringOfText: "master disto point info: \(masterDistroDict)")
                                                
                                                self.userDefaults.set("unmounted", forKey: "share")
                                                self.userDefaults.set("server", forKey: "packageSource")
                                                self.userDefaults.synchronize()
                                                
//                                                let jcdsPackagesXml = "<packages>" + self.betweenTags(xmlString: jcdsServerXml, startTag: "<packages>", endTag: "</packages>") + "</packages>"
//                                                WriteToLog().message(stringOfText: "jcdsPackagesXml: \(String(describing: jcdsPackagesXml))")
//                                                 Add loop to parse xml link id / name / download url
                                                let jcdsPackagesXml = self.betweenTags(xmlString: jcdsServerXml, startTag: "<packages>", endTag: "</packages>")
                                                let packageTmp = jcdsPackagesXml.replacingOccurrences(of: "</package><package>", with: "</package>\n<package>")
                                                let jcdsPackagesArray = packageTmp.split(separator: "\n")
                                                WriteToLog().message(stringOfText: "JCDS Packages:")
                                                for thePackage in jcdsPackagesArray {
                                                    WriteToLog().message(stringOfText: "\t\(thePackage)")
                                                }
                                            }
                                        }
                                    } else {
                                        WriteToLog().message(stringOfText: "No distributions points found.")
                                    }
                                }
                            }   // if masterDistroDict.count == 0 - end
                        }
                        
                        //print(httpResponse.statusCode)
                        // only use this if type is not smb or afp - changed 200505 to include JCDS
                        // cloud looks to use a number for type
                        // 4 - JCDS
//                        if mountPoint == "" && whichServer != "destination" && !Parameters.listOption {
                        if mountPoint == "" && !Parameters.listOption && !self.foundJcdsInfo && whichServer != "destination" {

                            WriteToLog().message(stringOfText: "[ListPackages.casperJxmlGet] No packages found.  Please verify server, username, and password are correct.")
                            Alert().display(header: "Attention:", message: "No packages found.  Please verify server, username, and password are correct.")
                            completion(([:], [:], [:],""))
                        } else {
                            completion((self.packagesDict, self.nameFilenameDict, self.jcdsInfoDict, mountPoint))
                        }
                        
                    } else {
                        // something went wrong
                        //self.writeToHistory(stringOfText: "**** \(self.getName(endpoint: endpointType, objectXML: endPointXML)) - Failed\n")
                        WriteToLog().message(stringOfText: "\n\n---------- status code ----------")
                        print(httpResponse.statusCode)
                        self.httpStatusCode = httpResponse.statusCode
                        WriteToLog().message(stringOfText: "---------- status code ----------")
                        WriteToLog().message(stringOfText: "\n\n---------- response ----------")
                        print(httpResponse)
                        WriteToLog().message(stringOfText: "---------- response ----------\n\n")
                        switch self.httpStatusCode {
                        case 401:
                            WriteToLog().message(stringOfText: "Authentication Failure.  Please verify username and password for the source server.")
                            Alert().display(header: "Authentication Failure:", message: "Please verify username and password for the source server.")
                        default:
                            Alert().display(header: "Unknown Error:", message: "Status Code: \(httpResponse.statusCode)\nMessage: \(httpResponse.description)")
                            WriteToLog().message(stringOfText: "Unknown error.")
                            //self.alert_dialog(header: "Error", message: "An unknown error occured trying to query the source server.")
                        }
                        
                        //                        401 - wrong username and/or password
                        //                        409 - unable to create object; already exists or data missing or xml error
                        //                        self.spinner.stopAnimation(self)
                        completion(([:], [:], [:],""))
                    }   // if httpResponse/else - end
                }   // if let httpResponse - end
                semaphore.signal()
                if error != nil {
                }
            })  // let task = session - end
            //WriteToLog().message(stringOfText: "GET")
            task.resume()
            semaphore.wait()
        }   // thePatchFetchQ - end
    }
    
    func listCloudPackages(jxmlString: String) -> (Dictionary<String, Dictionary<String,String>>, Dictionary<String, String>, Dictionary<String,String>, String) {
        self.jxmlResponseStr = self.betweenTags(xmlString: self.jxmlResponseStr, startTag: "<packages>", endTag: "</packages>")
        
        // Wrap it up or it won't be valid XML
        let xmlData = "<packages>" + self.jxmlResponseStr + "</packages>"
        WriteToLog().message(stringOfText: "[ListCloudPackages-casperJxmlGet] xmlData: \(xmlData)\n")
        
        // We can create a parser from a URL, a Stream, or NSData.
        if let data = xmlData.data(using: .utf16) { // Get the NSData
            let xmlParser = XMLParser(data: data)
            let delegate = XmlDelegate()
            xmlParser.delegate = delegate
            if xmlParser.parse() {
                for entry in delegate.packageArray {
                    WriteToLog().message(stringOfText: "[ListCloudPackages-casperJxmlGet] entry: \(entry)")
                    self.packagesDict[entry.filename] = ["name":entry.name, "id":entry.id, "hashType":entry.hashType, "checksum":entry.checksum, "size":entry.size]
                    self.nameFilenameDict[entry.name] = entry.filename
                }
            }
        }
        
        // get info about package download URL, token, distribution server -  start
//                                    var packageXml = String(data: data!, encoding: .utf8)
        let packageXml = self.betweenTags(xmlString: jxmlString, startTag: "<cloudDistributionPoints>", endTag: "</cloudDistributionPoints>")
        
        // Wrap it up or it won't be valid XML
        var packageData = "<cloudDistributionPoints>" + packageXml + "</cloudDistributionPoints>"
        packageData = self.betweenTags(xmlString: packageData, startTag: "<packages>", endTag: "</packages>")
        packageData = "<packages>" + packageData + "</packages>"
        WriteToLog().message(stringOfText: "[ListCloudPackages-casperJxmlGet] packageData: \(packageData)\n")
        
        // We can create a parser from a URL, a Stream, or NSData.
        if let data = packageData.data(using: .utf16) { // Get the NSData
            let xmlParser = XMLParser(data: data)
            let delegate = JxmlDelegate()
            xmlParser.delegate = delegate
            if xmlParser.parse() {
                for entry in delegate.serverArray {
                    WriteToLog().message(stringOfText: "[ListCloudPackages-casperJxmlGet] entry: \(entry)")
                    self.packageInfoDict[entry.id] = entry.fileURL
                    if !self.foundJcdsInfo {
                        let jcdsServer = self.betweenTags(xmlString: entry.fileURL, startTag: "https://", endTag: "//")
                        let jcdsShare = self.betweenTags(xmlString: entry.fileURL, startTag: "download/", endTag: "/")
                        let tokenArray = entry.fileURL.split(separator: "=")
                        let jcdsToken = tokenArray.last
                        
                        if jcdsServer != "" && jcdsShare != "" && jcdsToken != "" {
                            WriteToLog().message(stringOfText: "[ListCloudPackages-casperJxmlGet] JCDS Server: \(jcdsServer)")
                            WriteToLog().message(stringOfText: "[ListCloudPackages-casperJxmlGet]  JCDS Share: \(jcdsShare)")
                            WriteToLog().message(stringOfText: "[ListCloudPackages-casperJxmlGet]  JCDS Token: \(String(describing: jcdsToken!))")
                            self.jcdsInfoDict = ["server":jcdsServer, "share":jcdsShare, "token":"\(String(describing: jcdsToken!))"]
                            self.foundJcdsInfo = true
                        }   // if jcdsServer != "" && jcdsShare != "" && jcdsToken != ""
                    }   // if !self.foundJcdsInfo
                }   // for entry in delegate.serverArray
//                                    WriteToLog().message(stringOfText: "[ListPackages]  packageInfoDict: \(packageInfoDict)")
            }
        }
        // merge fileURL into packagesDict -  start
        for (pkgName,pkgAttributes) in self.packagesDict {
            if let pkgId = pkgAttributes["id"] {
                if let pkgDownloadURL = self.packageInfoDict["\(pkgId)"] {
                    var pkgAttributesUpdate = pkgAttributes
                    pkgAttributesUpdate["fileURL"] = pkgDownloadURL
                    self.packagesDict["\(pkgName)"] = pkgAttributesUpdate
                }
            }
        }
        WriteToLog().message(stringOfText: "[ListCloudPackages-casperJxmlGet] self.packagesDict: \(self.packagesDict)")
        // merge fileURL into packagesDict -  end
        //                            WriteToLog().message(stringOfText: "[ListPackages]     packagesDict: \(packagesDict)")
        //                            WriteToLog().message(stringOfText: "[ListPackages] nameFilenameDict: \(nameFilenameDict)")
        Parameters.cloudDistribitionPoint = true
        return ((self.packagesDict, self.nameFilenameDict, self.jcdsInfoDict, ""))

    }   // func listCloudPackages
    
    // extract the value between (different) tags - start
    func betweenTags(xmlString:String, startTag:String, endTag:String) -> String {
        var rawValue = ""
        if let start = xmlString.range(of: startTag),
            let end  = xmlString.range(of: endTag, range: start.upperBound..<xmlString.endIndex) {
            rawValue.append(String(xmlString[start.upperBound..<end.lowerBound]))
        } else {
            WriteToLog().message(stringOfText: "[betweenTags] Nothing found between \(startTag) and \(endTag).\n")
        }
        return rawValue
    }
    //  extract the value between (different) tags - end
    
    // mount distribution point - start
    func mountDp(distributionPoint: [String:String], completion: @escaping (_ result: (Dictionary<String, Dictionary<String,String>>, Dictionary<String, String>, Dictionary<String,String>, String)) -> Void) {

        Parameters.cloudDistribitionPoint = false
        
        sourceServerInfo.name = distributionPoint["ip"]!
        var mountPoint = ""
            
        let url = NSURL(string: "\(String(describing: distributionPoint["type"]!))://\(String(describing: distributionPoint["ip"]!))/\(String(describing: distributionPoint["share"]!))")
            WriteToLog().message(stringOfText: "[ListPackages.mountDp] url: \(url!)")  // -> smb://server.lab/Package%20Storage
            var userDomain = ""
            if distributionPoint["domain"] != "" {
                userDomain = "\(String(describing: distributionPoint["domain"]!))\\"
                WriteToLog().message(stringOfText: "[ListPackages.mountDp] full login name: \(userDomain)\(String(describing: distributionPoint["adminUsername"]!))")
            }
            
            let uuid = "\(UUID())".replacingOccurrences(of: "-", with: "")
            WriteToLog().message(stringOfText: "[ListPackages.mountDp] uuid: \(uuid)")
        if !FileManager.default.fileExists(atPath: "/private/tmp/\(String(describing: distributionPoint["ip"]!))", isDirectory: &self.isDir) {
                do {
                    try FileManager.default.createDirectory(atPath: "/private/tmp/\(String(describing: distributionPoint["ip"]!))", withIntermediateDirectories: true, attributes: nil)
                } catch {
                    WriteToLog().message(stringOfText: "[ListPackages.mountDp] failed to create mount point.")
                }
                
            }
//            let localMount = URL(fileURLWithPath: "/private/tmp/\(String(describing: distributionPoint["ip"]!))/\(uuid)")
        let localMount = URL(fileURLWithPath: "/private/tmp/\(String(describing: distributionPoint["ip"]!))")
            let result = NetFSMountURLSync(url!, localMount as CFURL, "\(userDomain)\(String(describing: distributionPoint["adminUsername"]!))" as CFString, "\(String(describing: distributionPoint["adminPassword"]!))" as CFString,  nil, nil, nil)
            
            WriteToLog().message(stringOfText: "[ListPackages.mountDp] result of mount: \(result)")
            //   0 - new mount
            //   2 - share does not exist on the server
            //  17 - mount point already exists, we'll use it
            //  65 - unable to reach server
            // 128 - credentials error?
            switch result {
            case 0:
                self.userDefaults.set("mounted", forKey: "share")
                self.userDefaults.set("directory", forKey: "packageSource")
                self.userDefaults.synchronize()
                Parameters.mountedSharesDict[distributionPoint["ip"]!] = distributionPoint["share"]!
//                mountPoint = "/private/tmp/\(String(describing: distributionPoint["ip"]!))/\(uuid)/\(distributionPoint["share"]!)/"
                mountPoint = "/private/tmp/\(String(describing: distributionPoint["ip"]!))/\(distributionPoint["share"]!)/"
            case 17:
                if FileManager.default.fileExists(atPath: "/private/tmp/\(distributionPoint["ip"]!)/\(distributionPoint["share"]!)", isDirectory: &self.isDir) {

                    self.userDefaults.set("mounted", forKey: "share")
                    self.userDefaults.set("directory", forKey: "packageSource")
                    self.userDefaults.synchronize()
                    mountPoint = "/private/tmp/\(String(describing: distributionPoint["ip"]!))/\(distributionPoint["share"]!)/"
                    
                } else {
                    Alert().display(header: "Attention:", message: "It appears the server/share (\(String(describing: distributionPoint["ip"]!))/\(distributionPoint["share"]!)) is already mounted.  Unmount and run again.")
                    completion(([:], [:], [:],""))
                    return
                }
            default:
                break
            }

        //print(httpResponse.statusCode)
        // only use this if type is not smb or afp
        // cloud looks to use a number for type
        // 4 - JCDS
        if mountPoint == "" {
            WriteToLog().message(stringOfText: "[ListPackages.mountDp] No packages found.  Please verify server, username, and password are correct.")
                Alert().display(header: "Attention:", message: "No packages found.  Please verify server, username, and password are correct.")
                completion(([:], [:], [:],""))
        } else {
            completion((packagesDict, nameFilenameDict, jcdsInfoDict, mountPoint))
        }
    }
    // mount distribution point - end

    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
}
