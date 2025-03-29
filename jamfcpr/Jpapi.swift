//
//  Jpapi.swift
//  Jamf Transporter
//
//  Created by Leslie Helou on 12/17/19.
//  Copyright 2024 Jamf. All rights reserved.
//

import Cocoa

struct JsonUapiPackages: Decodable {
    let totalCount: Int
    let results: [JsonUapiPackageDetail]
}

struct JsonUapiPackageDetail: Codable {
    let id: String?
    let packageName: String?
    let fileName: String?
    var categoryId: String?
    var info: String?
    var notes: String?
    var priority: Int?
    var osRequirements: String?
    var fillUserTemplate: Bool?
    var indexed: Bool?
    var uninstall: Bool?
    var fillExistingUsers: Bool?
    var swu: Bool?
    var rebootRequired: Bool?
    var selfHealNotify: Bool?
    var selfHealingAction: String?
    var osInstall: Bool?
    var serialNumber: String?
    var parentPackageId: String?
    var basePath: String?
    var suppressUpdates: Bool?
    var cloudTransferStatus: String?
    var ignoreConflicts: Bool?
    var suppressFromDock: Bool?
    var suppressEula: Bool?
    var suppressRegistration: Bool?
    var installLanguage: String?
    var md5: String?
    var sha256: String?
    var hashType: String?
    var hashValue: String?
    var size: String?
    var osInstallerVersion: String?
    var manifest: String?
    var manifestFileName: String?
    var format: String?

    init(id: String?, packageName: String?, fileName: String?, categoryId: String? = nil, info: String? = nil, notes: String? = nil, priority: Int? = nil, osRequirements: String? = nil, fillUserTemplate: Bool? = nil, indexed: Bool? = nil, uninstall: Bool? = nil, fillExistingUsers: Bool? = nil, swu: Bool? = nil, rebootRequired: Bool? = nil, selfHealNotify: Bool? = nil, selfHealingAction: String? = nil, osInstall: Bool? = nil, serialNumber: String? = nil, parentPackageId: String? = nil, basePath: String? = nil, suppressUpdates: Bool? = nil, cloudTransferStatus: String? = nil, ignoreConflicts: Bool? = nil, suppressFromDock: Bool? = nil, suppressEula: Bool? = nil, suppressRegistration: Bool? = nil, installLanguage: String? = nil, md5: String? = nil, sha256: String? = nil, hashType: String? = nil, hashValue: String? = nil, size: String? = nil, osInstallerVersion: String? = nil, manifest: String? = nil, manifestFileName: String? = nil, format: String? = nil) {
        self.id = id
        self.packageName = packageName
        self.fileName = fileName
        self.categoryId = categoryId
        self.info = info
        self.notes = notes
        self.priority = priority
        self.osRequirements = osRequirements
        self.fillUserTemplate = fillUserTemplate
        self.indexed = indexed
        self.uninstall = uninstall
        self.fillExistingUsers = fillExistingUsers
        self.swu = swu
        self.rebootRequired = rebootRequired
        self.selfHealNotify = selfHealNotify
        self.selfHealingAction = selfHealingAction
        self.osInstall = osInstall
        self.serialNumber = serialNumber
        self.parentPackageId = parentPackageId
        self.basePath = basePath
        self.suppressUpdates = suppressUpdates
        self.cloudTransferStatus = cloudTransferStatus
        self.ignoreConflicts = ignoreConflicts
        self.suppressFromDock = suppressFromDock
        self.suppressEula = suppressEula
        self.suppressRegistration = suppressRegistration
        self.installLanguage = installLanguage
        self.md5 = md5
        self.sha256 = sha256
        self.hashType = hashType
        self.hashValue = hashValue
        self.size = size
        self.osInstallerVersion = osInstallerVersion
        self.manifest = manifest
        self.manifestFileName = manifestFileName
        self.format = format
    }
    /*
    init(jsonUapiPackageDetail: JsonUapiPackageDetail) {
        id = jsonUapiPackageDetail.id
        packageName = jsonUapiPackageDetail.packageName
        fileName = jsonUapiPackageDetail.fileName
        categoryId = jsonUapiPackageDetail.categoryId ?? "-1"
        priority = jsonUapiPackageDetail.priority ?? 10
        fillUserTemplate = jsonUapiPackageDetail.fillUserTemplate ?? false
        uninstall = jsonUapiPackageDetail.uninstall ?? false
        rebootRequired = jsonUapiPackageDetail.rebootRequired ?? false
        osInstall = jsonUapiPackageDetail.osInstall ?? false
        suppressUpdates = jsonUapiPackageDetail.suppressUpdates ?? false
        suppressFromDock = jsonUapiPackageDetail.suppressFromDock ?? false
        suppressEula = jsonUapiPackageDetail.suppressEula ?? false
        suppressRegistration = jsonUapiPackageDetail.suppressRegistration ?? false
        if let pkgSize = jsonUapiPackageDetail.size {
            size = String(pkgSize)
        } else {
            size = nil
        }

        info = jsonUapiPackageDetail.info
        notes = jsonUapiPackageDetail.notes
        osRequirements = jsonUapiPackageDetail.osRequirements
        indexed = jsonUapiPackageDetail.indexed
        fillExistingUsers = jsonUapiPackageDetail.fillExistingUsers
        swu = jsonUapiPackageDetail.swu
        selfHealNotify = jsonUapiPackageDetail.selfHealNotify
        selfHealingAction = jsonUapiPackageDetail.selfHealingAction
        serialNumber = jsonUapiPackageDetail.serialNumber
        parentPackageId = jsonUapiPackageDetail.parentPackageId
        basePath = jsonUapiPackageDetail.basePath
        cloudTransferStatus = jsonUapiPackageDetail.cloudTransferStatus
        ignoreConflicts = jsonUapiPackageDetail.ignoreConflicts
        installLanguage = jsonUapiPackageDetail.installLanguage
        osInstallerVersion = jsonUapiPackageDetail.osInstallerVersion
        format = jsonUapiPackageDetail.format
    }
    */
}
@MainActor final class Packages {
    static var source      = [JsonUapiPackageDetail]()
    static var destination = [JsonUapiPackageDetail]()
}

@MainActor final class ExistingPackages {
    let shared = ExistingPackages()

    private let existingQueue       = DispatchQueue(label: "existing.packages", qos: .default, attributes: .concurrent)
    private var _packageGetsPending = 0
    private var _packageIDsNames    = [Int: String]()
    
    var packageIDsNames: [Int: String] {
        get {
            var packageIDsNames: [Int: String] = [:]
            existingQueue.sync {
                packageIDsNames = _packageIDsNames
            }
            return packageIDsNames
        }
        set {
            existingQueue.async(flags: .barrier) {
                self._packageIDsNames = newValue
            }
        }
    }

    var packageGetsPending: Int {
        get {
            var packageGetsPending: Int?
            existingQueue.sync {
                packageGetsPending = _packageGetsPending
            }
            return packageGetsPending ?? 0
        }
        set {
            existingQueue.async(flags: .barrier) {
                self._packageGetsPending = newValue
            }
        }
    }
    init(_packageGetsPending: Int = 0, _packageIDsNames: [Int : String] = [Int: String]()) {
        self._packageGetsPending = _packageGetsPending
        self._packageIDsNames = _packageIDsNames
    }
}

final class ExistingObject: NSObject {
    var type: String
    var id: Int
    var name: String
    var fileName: String?
    
    init(type: String, id: Int, name: String, fileName: String? = nil) {
        self.type = type
        self.id = id
        self.name = name
        self.fileName = fileName
    }
}

@MainActor var existingObjects       = [ExistingObject]()
@MainActor var duplicatePackages     = false
@MainActor var duplicatePackagesDict = [String:[String]]()

final class Jpapi: NSObject, URLSessionDelegate {
    
    static let shared = Jpapi()
    static let packages = Packages()
    
    @MainActor var stopProcessDelegate: StopProcessDelegate? = nil
    
    @MainActor func action(whichServer: String, endpoint: String, apiData: [String: Any], id: String, token: String, method: String, completion: @escaping (_ returnedJSON: [String: Any]) -> Void) {
        
        if method.lowercased() == "skip" {
            completion(["JPAPI_result":"no valid token found", "JPAPI_response":0])
            return
        }
        
        let serverUrl = JamfProServer.url[whichServer]
                
        // cookie stuff
//        var sessionCookie: HTTPCookie?
        var cookieName         = "" // name of cookie to look for
        
        if method.lowercased() == "skip" {
            WriteToLog.shared.message(stringOfText: "[Jpapi.action] skipping \(endpoint) endpoint with id \(id).")
            let JPAPI_result = (endpoint == "auth/invalidate-token") ? "no valid token":"failed"
            completion(["JPAPI_result":JPAPI_result, "JPAPI_response":000])
            return
        }
        
        URLCache.shared.removeAllCachedResponses()
        var contentType: String = "application/json"
        var accept: String      = "application/json"

        let path = "api/v2/\(endpoint)"

        var urlString = "\(serverUrl ?? "")/\(path)"
        urlString     = urlString.replacingOccurrences(of: "//api", with: "/api")
        if id != "" && id != "0" {
            urlString = (urlString.contains("/api/")) ? urlString + "/\(id)":urlString + "/id/\(id)"
        }
        print("[Jpaapi.action] \(endpoint) id \(id)")
        
        let url            = URL(string: "\(urlString)")
        let configuration  = URLSessionConfiguration.default
        var request        = URLRequest(url: url!)
        switch method.lowercased() {
        case "get":
            request.httpMethod = "GET"
        case "create", "post":
            request.httpMethod = "POST"
        default:
            request.httpMethod = "PUT"
        }
        print("[Jpaapi.action] Perform \(request.httpMethod ?? "") on urlString: \(urlString)")
        
        if apiData.count > 0 {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: apiData, options: .prettyPrinted)
            } catch let error {
                print(error.localizedDescription)
            }
        }
        
        WriteToLog.shared.message(stringOfText: "[Jpapi.action] Attempting \(method) on \(urlString).")
//        print("[Jpapi.action] Attempting \(method) on \(urlString).")
        
        configuration.httpAdditionalHeaders = ["Authorization" : "Bearer \(JamfProServer.accessToken[whichServer] ?? "")", "Content-Type" : contentType, "Accept" : accept, "User-Agent" : AppInfo.userAgentHeader]
        
//        print("jpapi sticky session for \(serverUrl)")
        // sticky session
//        if JamfProServer.sessionCookie.count > 0 && JamfProServer.stickySession {
//            URLSession.shared.configuration.httpCookieStorage!.setCookies(JamfProServer.sessionCookie, for: URL(string: serverUrl), mainDocumentURL: URL(string: serverUrl))
//        }
        
        let session = Foundation.URLSession(configuration: configuration, delegate: self as URLSessionDelegate, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            session.finishTasksAndInvalidate()
            if let httpResponse = response as? HTTPURLResponse {
//                print("[Jpaapi.action] Api response for \(endpoint): \(String(data: data ?? Data(), encoding: .utf8))")
                if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                    
                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    
                    if let endpointJSON = json as? [String: Any] {
                        WriteToLog.shared.message(stringOfText: "[Jpapi.action] Data retrieved from \(urlString).")
                        completion(endpointJSON)
                        return
                    } else {    // if let endpointJSON error
                        if httpResponse.statusCode == 204 && endpoint == "auth/invalidate-token" {
                            completion(["JPAPI_result":"token terminated", "JPAPI_response":httpResponse.statusCode])
                        } else {
                            WriteToLog.shared.message(stringOfText: "[Jpapi.action] JSON error.  Returned data: \(String(describing: json))")
                            completion(["JPAPI_result":"failed", "JPAPI_response":httpResponse.statusCode])
                        }
                        return
                    }
                } else {    // if httpResponse.statusCode <200 or >299
                    WriteToLog.shared.message(stringOfText: "[Jpapi.action] Response error: \(httpResponse.statusCode).")
                    if endpoint == "sites" {
                        completion(["sites":[]])
                    } else {
                        completion(["JPAPI_result":"failed", "JPAPI_method":request.httpMethod ?? method, "JPAPI_response":httpResponse.statusCode, "JPAPI_server":urlString, "JPAPI_token":token])
                    }
                    return
                }
            } else {
                WriteToLog.shared.message(stringOfText: "[Jpapi.action] GET response error.  Verify url and port.")
                completion([:])
                return
            }
        })
        task.resume()
    }   // func action - end
    
    /*
    func getAllDelegate(whichServer: String, theEndpoint: String, whichPage: Int, lastPage: Bool = false, completion: @escaping (_ result: [Any]) -> Void) async {
        
        if whichPage == 0 {
            Task { @MainActor in
                existingObjects.removeAll()
            }
        }
        
        print("[getAllDelegate] lastPage: \(lastPage), whichPage: \(whichPage), whichServer: \(whichServer) server.")
        if !lastPage {
            let returnedResults = (try? await getAll(whichServer: whichServer, theEndpoint: theEndpoint)) ?? <#default value#> //{
//                returnedResults in
                
                Task { @MainActor in
                    if duplicatePackages {
                        print("[getAllDelegate] duplicate packages found on \(whichServer) server.")
                        
                            var message = "\tFilename : Display Name\n"
                            for (pkgFilename, displayNames) in duplicatePackagesDict {
                                if displayNames.count > 1 {
                                    for dup in displayNames {
                                        message = "\(message)\t\(pkgFilename) : \(dup)\n"
                                    }
                                }
                            }
                        let theServer = JamfProServer.url[whichServer] ?? "unknown server"
                        WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] Duplicate references to the same package were found on \(theServer)\n\(message)")
                            if !CmdLine.mode {
                                let theButton = Alert.shared.display(header: "Warning:", message: "Several packages on \(theServer), having unique display names, are linked to a single file.  Check the log for 'Duplicate references to the same package' for details.", secondButton: "Stop")
    //                                if theButton == "Stop" {
    //                                    updateView(["function": "stopButton"])
    ////                                    stopButton(self)
    //                                }
                            }
                    }
                    duplicatePackages = false
                    duplicatePackagesDict.removeAll()
                    completion(returnedResults)
                }
//            }
        }
    }
    */
    
    @MainActor private func displayDuplicatePackages(whichServer: String) {
        print("[getAllDelegate] duplicate packages found on \(whichServer) server.")
        
        var message = "\tFilename : Display Name\n"
        for (pkgFilename, displayNames) in jamfcpr.duplicatePackagesDict {
            if displayNames.count > 1 {
                for dup in displayNames {
                    message = "\(message)\t\(pkgFilename) : \(dup)\n"
                }
            }
        }
        let theServer = JamfProServer.url[whichServer] ?? "unknown server"
        WriteToLog.shared.message(stringOfText: "[ViewController.getEndpoints] Duplicate references to the same package were found on \(theServer)\n\(message)")
        if !CmdLine.mode {
            let theButton = Alert.shared.display(header: "Warning:", message: "Several packages on \(theServer), having unique display names, are linked to a single file.  Check the log for 'Duplicate references to the same package' for details.", secondButton: "Stop")
                if theButton == "Stop" {
                    existingObjects.removeAll()
                    Packages.source.removeAll()
                    Packages.destination.removeAll()
                    print("stop process")
                    stopProcessDelegate?.stopProcess()
                }
        }
        duplicatePackages = false
        duplicatePackagesDict.removeAll()
    }
    
    func getAll(whichServer: String, theEndpoint: String) async throws {
        
        let pageSize = 100
        var pageOfPackages = await pagedGet(whichServer: whichServer, theEndpoint: theEndpoint, whichPage: 0)
        if let totalPackages = pageOfPackages["totalCount"] as? Int, let packageRecords = pageOfPackages["results"] as? [[String : Any]], totalPackages > 0 {
            await processPackages(whichServer: whichServer, returnedRecords: packageRecords)
            await WriteToLog.shared.message(stringOfText: "[Jpapi.getAll] found \(packageRecords.count) packages on page 1")
            let pages = (totalPackages + (pageSize - 1)) / pageSize
            if pages > 1 {
                for whichPage in 1..<pages {
                    pageOfPackages = await pagedGet(whichServer: whichServer, theEndpoint: theEndpoint, whichPage: whichPage)
                    if let packageRecords = pageOfPackages["results"] as? [[String : Any]] {
                        await WriteToLog.shared.message(stringOfText: "[Jpapi.getAll] found \(packageRecords.count) packages on page \(whichPage + 1)")
                        await processPackages(whichServer: whichServer, returnedRecords: packageRecords)
                    }
                }
            }
        }
        
        if await duplicatePackages {
            await displayDuplicatePackages(whichServer: whichServer)
        }
        
        print("[Jpapi.getAll] returning \(whichServer) package count: \(await existingObjects.count)")
        return //await existingObjects
    }
    
    @MainActor private func processPackages(whichServer: String, returnedRecords: [[String: Any]]) async {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: returnedRecords as Any)
            let somePackages = try JSONDecoder().decode([JsonUapiPackageDetail].self, from: jsonData)
            if whichServer == "source" {
                //                                    print("getAll: somePackages count: \(somePackages.count)")
                Packages.source.append(contentsOf: somePackages)
                print("[Jpapi.processPackages]: source package count: \(Packages.source.count)")
                for thePackage in somePackages {
                    if let id = thePackage.id, let idNum = Int(id), let packageName = thePackage.packageName, let fileName = thePackage.fileName {
                        // looking for duplicates
                        if duplicatePackagesDict[fileName] == nil {
                            //                                                AvailableObjsToMig.byId[idNum] = fileName
                            duplicatePackagesDict[fileName] = [packageName]
                        } else {
                            duplicatePackages = true
                            duplicatePackagesDict[fileName]!.append(packageName)
                        }
                        existingObjects.append(ExistingObject(type: "package", id: idNum, name: packageName, fileName: fileName))
                    }
                }
            } else {
                Packages.destination.append(contentsOf: somePackages)
                print("[Jpapi.processPackages]: somePackages destination count: \(Packages.destination.count)")
                for thePackage in somePackages {
                    if let id = thePackage.id, let idNum = Int(id), let packageName = thePackage.packageName, let fileName = thePackage.fileName {
                        // looking for duplicates
                        if duplicatePackagesDict[fileName] == nil {
                            duplicatePackagesDict[fileName] = [packageName]
                        } else {
                            duplicatePackages = true
                            duplicatePackagesDict[fileName]!.append(packageName)
                        }
                        existingObjects.append(ExistingObject(type: "package", id: idNum, name: packageName, fileName: fileName))
                    }
                }
            }
        } catch {
            print("[Jpapi.processPackages] error decoding: \(error)")
        }
        
        print("[Jpapi.processPackages] added: \(returnedRecords.count) records")
    }
    
    @MainActor func get(whichServer: String, theEndpoint: String, id: String = "", whichPage: Int = -1, completion: @escaping (_ returnedJson: [[String: Any]]) -> Void) {
        var endpointVersion = ""
        switch theEndpoint {
        case "packages":
           endpointVersion = "v1"
        default:
            break
        }
        
        var endpointParent = "\(theEndpoint)"
        
        print("[ExistingObjects.get] JamfProServer.url: \(JamfProServer.url)")
        var endpoint = (JamfProServer.url[whichServer] ?? "") + "/api/\(endpointVersion)/\(theEndpoint)"
        
        endpoint = endpoint.replacingOccurrences(of: "//api", with: "/api")
        print("[ExistingObjects.get] endpoint: \(endpoint)")
        
        guard let endpointUrl = URL(string: endpoint) else {
            completion([])
            return
        }
        
//        let endpointUrl = tmpUrl.appending(path: "/api/\(endpointVersion)/\(theEndpoint)")
        print("[ExistingObjects.get] endpointUrl: \(endpointUrl.path())")
//        let endpointUrl    = URL(string: "\(endpoint)")
        let configuration  = URLSessionConfiguration.ephemeral
        var request        = URLRequest(url: endpointUrl)
        request.httpMethod = "GET"
        configuration.httpAdditionalHeaders = ["Authorization" : "Bearer \(JamfProServer.accessToken[whichServer] ?? "")", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
//        print("[getAllPolicies] configuration.httpAdditionalHeaders: \(configuration.httpAdditionalHeaders ?? [:])")
        let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) -> Void in
            session.finishTasksAndInvalidate()
            if let httpResponse = response as? HTTPURLResponse {
                print("[ExistingObjects.get] response statusCode: \(httpResponse.statusCode)")
                if httpSuccess.contains(httpResponse.statusCode) {
//                    print("[ExistingObjects.get] data as string: \(String(data: data ?? Data(), encoding: .utf8))")
                    let responseData = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    
                    if let recordsJson = responseData as? [String: [[String: Any]]], let recordsArray = recordsJson[endpointParent] {
                            print("[Jpapi.get] \(theEndpoint) - found \(recordsArray.description)")
                            completion(recordsArray)
                    } else {
                        WriteToLog.shared.message(stringOfText: "[ExistingObjects.get] No data was returned from the GET.")
                        completion([])
                    }
                } else {
                    WriteToLog.shared.message(stringOfText: "[ExistingObjects.get] response statusCode: \(httpResponse.statusCode)")
                    completion([])
                }
            } else {
                WriteToLog.shared.message(stringOfText: "[ExistingObjects.get] unable to read the response from the GET.")
                completion([])
            }
        })
        task.resume()
    }
    
    
//    func pagedGet(whichServer: String, theEndpoint: String, id: String = "", whichPage: Int = -1, completion: @escaping (_ returnedResults:  Any) -> Void) {
    // returns {"totalCount": Int, "results": [{String: Any}]}
    func pagedGet(whichServer: String, theEndpoint: String, id: String = "", whichPage: Int = -1) async -> [String: Any] {
        
        var endpointVersion = ""
        var pageSize = 100
        
        switch theEndpoint {
        case "packages":
           endpointVersion = "v1"
        default:
            break
        }
        
        guard let url = await URL(string: JamfProServer.url[whichServer] ?? "") else {
//            completion([] as Any)
            print("[ExistingObjects.pagedGet] can not convert \(await JamfProServer.url[whichServer] ?? "") to URL")
            return [:]
        }
        
        var endpointUrl = url.appendingPathComponent("/api/\(endpointVersion)/\(theEndpoint)")

        let pageParameters = [URLQueryItem(name: "page", value: "\(whichPage)"), URLQueryItem(name: "page-size", value: "\(pageSize)")]
        endpointUrl = endpointUrl.appending(queryItems: pageParameters)

        
//        print("[ExistingObjects.getAll] whichServer: \(whichServer)")
//        print("[ExistingObjects.getAll] accessToken: \(JamfProServer.accessToken[whichServer] ?? "")")
        print("[ExistingObjects.pagedGet] endpointUrl: \(endpointUrl.absoluteString)")
        
        let configuration  = URLSessionConfiguration.ephemeral
        var request        = URLRequest(url: endpointUrl)
        request.httpMethod = "GET"
        configuration.httpAdditionalHeaders = ["Authorization" : "Bearer \(await JamfProServer.accessToken[whichServer] ?? "")", "Content-Type" : "application/json", "Accept" : "application/json", "User-Agent" : AppInfo.userAgentHeader]
//        print("[getAllPolicies] configuration.httpAdditionalHeaders: \(configuration.httpAdditionalHeaders ?? [:])")
        let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
//        let task = session.dataTask(with: request as URLRequest, completionHandler: {
//            (data, response, error) -> Void in
        do {
            let response = try await session.data(for: request)
            session.finishTasksAndInvalidate()
            if let httpResponse = response.1 as? HTTPURLResponse {
                print("[ExistingObjects.pagedGet] response statusCode: \(httpResponse.statusCode)")
                if httpSuccess.contains(httpResponse.statusCode) {
                    //                    print("[ExistingObjects.get] data as string: \(String(data: data ?? Data(), encoding: .utf8))")
                    let responseData = try? JSONSerialization.jsonObject(with: response.0, options: .allowFragments)
                    if let endpointJSON = responseData! as? [String: Any], let objectOnPage = endpointJSON["results"] as? [[String: Any]] {
//                        print("[ExistingObjects.get] endpointJSON for page \(whichPage): \(endpointJSON)")
                        print("[ExistingObjects.get] packages found on page \(whichPage): \(objectOnPage.count)")
                        return endpointJSON
                        //                           print("[ExistingObjects.get] endpointJSON for page \(whichPage): \(endpointJSON)")
                    } else {
                        await WriteToLog.shared.message(stringOfText: "[ExistingObjects.pagedGet] No data was returned from the GET.")
//                        completion([:])
                        return [:]
                    }
                } else {
                    return [:]
                }
            } else {
                await WriteToLog.shared.message(stringOfText: "[ExistingObjects.get] unable to read the response from the GET.")
                //                        completion([:])
                return [:]
            }
        } catch {
            return [:]
        }
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}
