//
//  PreFlight.swift
//  jamfcpr
//
//  Created by Leslie Helou on 6/21/19.
//  Copyright © 2019 jamf. All rights reserved.
//

import Cocoa
import Foundation

/*
class PreFlight: NSViewController, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
    
    let preFlightQ  = OperationQueue() // que to fetch ids and names of the packages
    
    // create computer account, if needed
    func computerAccount(server: String, user: String, password: String, completion: @escaping (_ clientInfo: Dictionary<String,String>) -> Void) {
        
        var uuid:String?
//        var serialNumber:String?
        var clientInfo: Dictionary<String,String> = [:]
        let userPass  = "\(user):\(password)"
        let creds     = userPass.data(using: .utf8)?.base64EncodedString() ?? ""
        
        preFlightQ.maxConcurrentOperationCount = 1
        let semaphore = DispatchSemaphore(value: 0)
        
        if let systemUuid = getHardwareInfo(attribute: "uuid") {
            uuid = systemUuid
            print("System UUID: \(String(describing: uuid!))")
        } else {
            clientInfo["id"]      = "0"
            clientInfo["message"] = "unable to obtain machine UUID."
            completion(clientInfo)
        }
//        if let systemSerial = getHardwareInfo()["serialNumber"] {
//            serialNumber = systemSerial
//            print("System serial number: \(String(describing: serialNumber!))")
//        } else {
//            clientInfo["id"]      = "0"
//            clientInfo["message"] = "unable to obtain machine serial number."
//            completion(clientInfo)
//        }
        
        var httpStatusCode = 0
        var id = 0
        var computerNode = "\(server)/JSSResource/computers/udid/\(String(describing: uuid!))"
        //        print("initial URL: \(self.serverURL)\n")
        computerNode = computerNode.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
        //        print("URL: \(self.serverURL)\n")
        
        preFlightQ.addOperation {
            let encodedURL = NSURL(string: computerNode)
            let request = NSMutableURLRequest(url: encodedURL! as URL)
            request.httpMethod = "GET"
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(creds)", "Content-Type" : "application/json", "Accept" : "application/json"]
            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
                    //                    print("httpResponse: \(String(describing: response))")
                    
                    let json = try? JSONSerialization.jsonObject(with: data!, options: .allowFragments)
                    if let endpointJSON = json as? [String: Any] {
                        //                        print("fetch client endpointJSON: \(endpointJSON))")
                        
                        if let endpointInfo = endpointJSON["computer"] as? [String:Any], let generalInfo = endpointInfo["general"] as? [String:Any] {
                            id = (generalInfo["id"] as! Int)
                        } else {
                            id = 0
                        }   //if let endpointInfo = endpointJSON - end
                        print("computer id: \(id)")
                        if id == 0 {
                            // doesn't seem to get here!!!!!
                            print("Unable to locate computer record, creating an account")
                            
                            // still needs work - completion
                            self.createEndpoint(server: server, creds: creds, uuid: uuid!)
                            
                        }
                        
                    }   // if let endpointJSON - end
                    
                    httpStatusCode = httpResponse.statusCode
                    
                    if httpStatusCode >= 199 && httpStatusCode <= 299 {
                        clientInfo["id"]      = "\(id)"
                        clientInfo["message"] = "found id"
                        completion(clientInfo)
                        // fetch package ids and names

                        //print(httpResponse.statusCode)
                    } else {
                        // something went wrong
                        
                        switch httpStatusCode {
                        case 401:
                            print("401")
                            print("failed to authenticate on \(server), please verify credentials.")
                            clientInfo["id"]      = "0"
                            clientInfo["message"] = "failed to authenticate on \(server), please verify credentials."
                            Alert().display(header: "Authentication Failure", message: "Please verify username and password for the source server.")
                            completion(clientInfo)
                        case 404:
                            print("404")
                            print("failed to find client on \(server), attempting to create the record.")
                            clientInfo["id"]      = "0"
                            clientInfo["message"] = "failed to find client on \(server), attempting to create the record."
                            // still needs work - completion
//                            self.createEndpoint(server: server, creds: creds, uuid: uuid!)
                            
                            var serialNumber:String?
                            
                            if let systemSerialNumber = self.getHardwareInfo(attribute: "serialNumber") {
                                serialNumber = systemSerialNumber
                                print("System serial number: \(String(describing: serialNumber!))")
                            } else {
                                print("unable to get serial number")
                                //            clientInfo["id"]      = "0"
                                //            clientInfo["message"] = "unable to obtain machine UUID."
                                //            completion(clientInfo)
                            }
                            
                            let computerXml = """
                            <?xml version='1.0' encoding='UTF-8' standalone='yes'?>
                            <computer>
                            <general>
                            <name>jamfcpr host</name>
                            <mac_address>00:00:00:00:00:00</mac_address>
                            <ip_address>127.0.0.1</ip_address>
                            <serial_number>\(serialNumber!)</serial_number>
                            <udid>\(uuid!)</udid>
                            <jamf_version></jamf_version>
                            <platform>Mac</platform>
                            <remote_management>
                            <managed>true</managed>
                            <management_username>jamfcpr_manage</management_username>
                            <management_password>changemeow</management_password>
                            </remote_management>
                            </general>
                            <location/>
                            <hardware>
                            <make>Apple</make>
                            </hardware>
                            </computer>
                            """
                            
                            print("computerXml: \(computerXml)")
                            
                            ApiAction().create(server: server, creds: creds, endpointType: "computers", xmlData: computerXml) {
                                (returnInfo: Dictionary) in
                                clientInfo = returnInfo
                                print("clientInfo Dict from ApiAction: \(clientInfo)")
                                completion(clientInfo)
                            }
                            

                        default:
                            print("default")
                            print("An unknown error occurred, HTTP status code \(httpStatusCode).")
                            clientInfo["id"]      = "0"
                            clientInfo["message"] = "An unknown error occurred, HTTP status code \(httpStatusCode)."
                            completion(clientInfo)
                            //self.alert_dialog(header: "Error", message: "An unknown error occured trying to query the source server.")
                        }
                        
                    }   // if httpResponse/else - end
                }   // if let httpResponse - end
                semaphore.signal()
            })  // let task = session - end

            task.resume()
            semaphore.wait()
        }   // preFlightQ - end
    }
    
    func createEndpoint(server: String, creds: String, uuid: String) {
        
        var serialNumber:String?
        
        if let systemSerialNumber = getHardwareInfo(attribute: "serialNumber") {
            serialNumber = systemSerialNumber
            print("System serial number: \(String(describing: serialNumber!))")
        } else {
            print("unable to get serial number")
//            clientInfo["id"]      = "0"
//            clientInfo["message"] = "unable to obtain machine UUID."
//            completion(clientInfo)
        }
        
        let computerXml = """
<?xml version='1.0' encoding='UTF-8' standalone='yes'?>
<computer>
    <general>
        <name>jamfcpr host</name>
        <mac_address>00:00:00:00:00:00</mac_address>
        <ip_address>127.0.0.1</ip_address>
        <serial_number>\(serialNumber!)</serial_number>
        <udid>\(uuid)</udid>
        <jamf_version></jamf_version>
        <platform>Mac</platform>
        <remote_management>
            <managed>true</managed>
            <management_username>jamfcpr_manage</management_username>
            <management_password>changemeow</management_password>
        </remote_management>
    </general>
    <location/>
    <hardware>
        <make>Apple</make>
    </hardware>
</computer>
"""
        
        print("computerXml: \(computerXml)")
        
        
        
    }
    
    // create policies, if needed
    // jamf policy -id ... -skipAppUpdates -overRideJSS https://... will run the policy without messing with the updating binary
    // create a remote policy that's ongoing rather than once per computer, with a specific name jamfcpr_20130513
    func cachePolicy(server: String, creds: String) {
        
    }
    
    func getHardwareInfo(attribute: String) -> String? {
        
        var hardwareAttribute:String?
        var attributeRef: CFTypeRef?
        
        let dev = IOServiceMatching("IOPlatformExpertDevice")
        let platformExpert: io_service_t = IOServiceGetMatchingService(kIOMasterPortDefault, dev)
        
        if attribute == "uuid" {
            let attributeAsCFString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformUUIDKey as CFString, kCFAllocatorDefault, 0)
            IOObjectRelease(platformExpert)
            attributeRef = attributeAsCFString!.takeUnretainedValue()
        } else {
            let attributeAsCFString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey as CFString, kCFAllocatorDefault, 0)
            IOObjectRelease(platformExpert)
            attributeRef = attributeAsCFString!.takeUnretainedValue()
        }
        
        if let _ = attributeRef as? String {
            hardwareAttribute = "\(attributeRef as! String)"
        }
        
        return hardwareAttribute
    }

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }

}
*/
