//
//  ApiAction.swift
//  jamfcpr
//
//  Created by Leslie Helou on 6/25/19.
//  Copyright © 2019 jamf. All rights reserved.
//

import Cocoa
import Foundation

class ApiAction: NSViewController, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {
    
    var theApiQ = OperationQueue() // create operation queue for API calls
    
    func create(server: String, creds: String, endpointType: String, xmlData: String, completion: @escaping (_ returnInfo: Dictionary<String,String>) -> Void) {

        var workingUrl    = ""
        var responseData  = ""
        var returnInfo: Dictionary<String,String> = [:]
    
        theApiQ.maxConcurrentOperationCount = 1
        let semaphore = DispatchSemaphore(value: 0)
        var localEndPointType = ""
        switch endpointType {
        case "smartcomputergroups", "staticcomputergroups":
            localEndPointType = "computergroups"
        case "smartmobiledevicegroups", "staticmobiledevicegroups":
            localEndPointType = "mobiledevicegroups"
        case "smartusergroups", "staticusergroups":
            localEndPointType = "usergroups"
        default:
            localEndPointType = endpointType
        }
    
        workingUrl = "\(server)/JSSResource/" + localEndPointType + "/id/0"
        workingUrl = workingUrl.replacingOccurrences(of: "//JSSResource", with: "/JSSResource")
        workingUrl = workingUrl.replacingOccurrences(of: "/JSSResource/jamfusers/id", with: "/JSSResource/accounts/userid")
        workingUrl = workingUrl.replacingOccurrences(of: "/JSSResource/jamfgroups/id", with: "/JSSResource/accounts/groupid")
        workingUrl = workingUrl.replacingOccurrences(of: "id/id/", with: "id/")
    
        theApiQ.addOperation {

            let encodedURL = NSURL(string: workingUrl)
            let request = NSMutableURLRequest(url: encodedURL! as URL)
            request.httpMethod = "POST"
            let configuration = URLSessionConfiguration.default
            configuration.httpAdditionalHeaders = ["Authorization" : "Basic \(creds)", "Content-Type" : "text/xml", "Accept" : "text/xml"]
            
            let encodedXML = xmlData.data(using: String.Encoding.utf8)
            request.httpBody = encodedXML!
            
            let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: request as URLRequest, completionHandler: {
                (data, response, error) -> Void in
                if let httpResponse = response as? HTTPURLResponse {
                    //print(httpResponse.statusCode)
                    //print(httpResponse)
                    if let _ = String(data: data!, encoding: .utf8) {
                        responseData = String(data: data!, encoding: .utf8)!
                        print(responseData)
                        let deviceId = XmlDelegate().tagValue2(xmlString: responseData, startTag: "<id>", endTag: "</id>", includeTags: false)
                        print("deviceId: \(deviceId)")
                        returnInfo["id"] = "\(deviceId)"

                        //                        if self.debug { self.writeToLog(stringOfText: "[CreateEndpoints] \n\nfull response from create:\n\(responseData)") }
                        //                        print("create data response: \(responseData)")
                    } else {
                        print("\n\n[CreateEndpoints] No data was returned from post/put.\n")
                    }
                    
                    if httpResponse.statusCode >= 200 && httpResponse.statusCode <= 299 {
                        print("successfully created item")
                        returnInfo["response"] = responseData
                        completion(returnInfo)
                    } else {
                        print("\n\n")
                        print("[RemoveEndpoints] ---------- status code ----------\n")
                        print("[RemoveEndpoints] \(httpResponse.statusCode)\n")
                        print("[RemoveEndpoints] ---------- response ----------\n")
                        print("[RemoveEndpoints] \(httpResponse)\n")
                        print("[RemoveEndpoints] ---------- response ----------\n\n")
                        returnInfo["response"] = "\(httpResponse.statusCode)"
                        completion(returnInfo)
                    }
                    
                }

            })  // let task = session.dataTask - end
            task.resume()
            semaphore.wait()
        }   // theApiQ.addOperation - end
    }   // func create - end

    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    
}
