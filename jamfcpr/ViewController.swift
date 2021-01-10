//
//  ViewController.swift
//  jamfcpr
//
//  Created by Leslie Helou on 12/5/18.
//  Copyright © 2018 jamf. All rights reserved.
//

import AppKit
import Cocoa
import Foundation

class packageData: NSObject {
    @objc dynamic var packageNameColumn: String
    @objc dynamic var sizeColumn: String

    init(packageNameColumn: String, sizeColumn: String) {
        self.packageNameColumn = packageNameColumn
        self.sizeColumn        = sizeColumn
    }
}

class ViewController: NSViewController, URLSessionDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {

    @objc dynamic var packageInfoArray: [packageData] = [packageData(packageNameColumn: "", sizeColumn: "")]

    @IBOutlet weak var table_HeaderView: NSTableHeaderView!
    @IBOutlet weak var          spinner: NSProgressIndicator!
    
    @IBOutlet weak var    sourceServer_TextField: NSTextField!
    @IBOutlet weak var      sourceUser_TextField: NSTextField!
    @IBOutlet weak var  sourcePassword_TextField: NSTextField!
    @IBOutlet weak var currentDownload_TextField: NSTextField!
    
    @IBOutlet weak var   destinationServer_TextField: NSTextField!
    @IBOutlet weak var     destinationUser_TextField: NSTextField!
    @IBOutlet weak var destinationPassword_TextField: NSTextField!
    @IBOutlet weak var       currentUpload_TextField: NSTextField!
    
    @IBOutlet weak var   uploadPercent_TextField: NSTextField!
    @IBOutlet weak var downloadPercent_TextField: NSTextField!
    @IBOutlet weak var     textMessage_TextField: NSTextField!
    
    @IBOutlet weak var downloadOptions_Button: NSPopUpButton!
    
    @IBOutlet weak var selectDistributionPoint_Button: NSPopUpButton!   // list of distribution points
    
    
    let userDefaults = UserDefaults.standard
    let fm           = FileManager()
    
    var localReplicate     = false
    var packageFolderRoot  = ""
    var localFolderUrl     = URL(string: "")
    var isDir: ObjCBool    = true
    
    var packageSource = ""
    var packagePath   = ""
    
    let sizeFormatter =    ByteCountFormatter()
    var directory:         Directory?
    var directoryItemsTmp: [Metadata]?
    var directoryItems:    [Metadata]?
    
    var webPackages:       [Metadata] = []
    
    var sortOrder     = Directory.FileOrder.Name
    var sortAscending = true

//  table to list packages and their size
    @IBOutlet weak var packageTableView: NSTableView!
    
    @IBOutlet weak var replicate_button: NSButton!
    
    @IBOutlet weak var downloadStatus_ProgressBar: NSProgressIndicator!
    @IBOutlet weak var uploadStatus_ProgressBar: NSProgressIndicator!
    var increment: Double = 100.0
    
    var      sourcePackageIdNamdDict:[String:Int] = [:]   // source server packageId, packageName
    var destinationPackageIdNamdDict:[String:Int] = [:]   // destination server packageId, packageName
    var                     sourcePackageInfoDict = Dictionary<String, Dictionary<String, String>>()
    var      sourcePackageDisplayNameFileNameDict = Dictionary<String, String>()
    var                       destPackageInfoDict = Dictionary<String, Dictionary<String, String>>()
    var        destPackageDisplayNameFileNameDict = Dictionary<String, String>()
    var                  packagesToReplicateArray = [String]()
    var                              destJcdsDict = Dictionary<String, String>()
    
    // package images
    @IBOutlet weak var p1_ImageView: NSImageView!
    @IBOutlet weak var p2_ImageView: NSImageView!
    @IBOutlet weak var p3_ImageView: NSImageView!
    @IBOutlet weak var p4_ImageView: NSImageView!
    @IBOutlet weak var p5_ImageView: NSImageView!
    
    var theAnimationQ = DispatchQueue(label: "com.jamfcpr.animation")
    var loop = true

    
    var              sourceServer = ""
    var                sourceUser = ""
    var            sourcePassword = ""
    var           sourceUserCreds = ""
    var         sourceBase64Creds = ""
    var      sourceServerClientId = ""
    var              mountedShare = ""
    
    var         destinationServer = ""
    var           destinationUser = ""
    var       destinationPassword = ""
    var      destinationUserCreds = ""
    var    destinationBase64Creds = ""
    var destinationServerClientId = ""
    
    var folderOrServer            = ""
    
    var task:Process!
    var pipeJamfPolicy:Pipe!
    
    let theCmdQ      = OperationQueue() // queue for the cmd function
    let theFetchQ    = OperationQueue() // queue to fetch ids and names of the packages
    let theDownloadQ = OperationQueue() // queue for downloading packages
    let theUploadQ   = OperationQueue() // queue to upload packages
    var remotepackageCount  = 0
    var failedDownloadCount = 0
    var uploadCount         = 1
    var downloadCount       = 1
    var httpStatusCode: Int = 0
    
    var messagesArray       = [String]()
    
    @IBAction func selectFolder(_ sender: Any) {
        History.didRun = true
        let openPanel = NSOpenPanel()
        
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles       = false
        let oldSource = sourceServer_TextField.stringValue
        let oldUserName = sourceUser_TextField.stringValue
        let oldPassword = sourcePassword_TextField.stringValue
        let oldPackageSource = userDefaults.object(forKey: "packageSource")! as! String
        userDefaults.set("directory", forKey: "packageSource")
        userDefaults.synchronize()
        
        self.sourceServer_TextField.stringValue   = ""
        self.sourceUser_TextField.stringValue     = ""
        self.sourcePassword_TextField.stringValue = ""
        
        WriteToLog().message(stringOfText: "selectFolder - source value: \(userDefaults.object(forKey: "packageSource")!)")
        
        openPanel.begin { (result) in
            DispatchQueue.main.async {
                self.spinner.startAnimation(self)
                if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                    Parameters.cloudDistribitionPoint = false
                    self.localFolderUrl = openPanel.url
                    self.representedObject = openPanel.url
                    WriteToLog().message(stringOfText: "[selectFolder] representedObject: \(String(describing: self.representedObject))")
                    WriteToLog().message(stringOfText: "[selectFolder] representedObject: \(String(describing: self.representedObject))")
                    self.packageFolderRoot = (self.localFolderUrl?.absoluteString.replacingOccurrences(of: "file://", with: ""))!
                    self.packageFolderRoot = self.packageFolderRoot.replacingOccurrences(of: "%20", with: " ")
                    //                WriteToLog().message(stringOfText: "encoded packageFolderRoot: \(String(describing: packageFolderRoot))")
                    self.sourceServer_TextField.stringValue = self.packageFolderRoot
                    
                    self.localReplicate = true
                    self.userDefaults.set("unmounted", forKey: "share")
                    self.userDefaults.synchronize()
                } else {
                    // restore values
                    self.sourceServer_TextField.stringValue = oldSource
                    self.sourceUser_TextField.stringValue = oldUserName
                    self.sourcePassword_TextField.stringValue = oldPassword
                    self.userDefaults.set(oldPackageSource, forKey: "packageSource")
                    self.userDefaults.synchronize()
//                    self.sourceUser_TextField.isHidden = false
//                    self.sourcePassword_TextField.isHidden = false
                    if !self.localReplicate {
                        self.localReplicate = false
                    }
                }
                    self.spinner.stopAnimation(self)
            }
        } // openPanel.begin - end
    }  // @IBAction func selectFolder - end
    
    @IBAction func list_Button(_ sender: Any) {
        History.didRun = true
        folderOrServer = sourceServer_TextField.stringValue
        folderOrServer = String(folderOrServer.prefix(4))
        DispatchQueue.main.async {
            self.spinner.startAnimation(self)
            if (self.folderOrServer.lowercased() == "http") {
                self.sourceServer   = self.sourceServer_TextField.stringValue
                self.sourceUser     = self.sourceUser_TextField.stringValue
                self.sourcePassword = self.sourcePassword_TextField.stringValue
                
                if NSEvent.modifierFlags.contains(.option) {
                    Parameters.listOption = true
                    WriteToLog().message(stringOfText: "[VewController.list_Button] using option key")
                }
                
                ListPackages().casperJxmlGet(whichServer: "source", server: self.sourceServer, username: self.sourceUser, password: self.sourcePassword) {
                    (result: (Dictionary, Dictionary, Dictionary, String)) in
                    (self.sourcePackageInfoDict, self.sourcePackageDisplayNameFileNameDict, _, self.mountedShare) = result
//                    WriteToLog().message(stringOfText: "[list_Button] server representedObject: file://\(String(describing: self.representedObject!))")
                    
                    if Parameters.listOption {
                        // provide list of distribution points
                        self.selectDistributionPoint_Button.addItems(withTitles: Parameters.distributionPointArray.sorted())
                        self.selectDistributionPoint_Button.isHidden = false
                    } else {
                        WriteToLog().message(stringOfText: "[VewController.list_Button] self.mountedShare: file://\(String(describing: self.mountedShare))")
                        
                        self.representedObject = URL(fileURLWithPath: "\(self.mountedShare)Packages")
                        WriteToLog().message(stringOfText: "[VewController.list_Button] server self.representedObject: \(String(describing: self.representedObject!))")
                        //                WriteToLog().message(stringOfText: "list_Button packageDisplayNameFileNameDict: \(self.packageDisplayNameFileNameDict)")
                    }
//                    self.reloadFileList()
                    self.spinner.stopAnimation(self)
                }   // ListPackages().casperJxmlGet - end
            } else {
                Parameters.cloudDistribitionPoint = false
                WriteToLog().message(stringOfText: "[VewController.list_Button] using local folder: \(self.sourceServer_TextField.stringValue)")
                self.representedObject = URL(fileURLWithPath: "\(self.sourceServer_TextField.stringValue)")
                WriteToLog().message(stringOfText: "[VewController.list_Button] local self.representedObject: \(String(describing: self.representedObject!))")
                self.spinner.stopAnimation(self)
                //            WriteToLog().message(stringOfText: "source: folder")
            }
//            self.spinner.stopAnimation(self)
            return
        }
    }
    
    
    @IBAction func replicate_Button(_ sender: Any) {
//        var computerId = 0
        if Parameters.cloudDistribitionPoint {
            Parameters.downloadOption = "\(self.downloadOptions_Button.selectedItem!.title)"
        } else {
            Parameters.downloadOption = "Options"
            DispatchQueue.main.async {
                self.downloadOptions_Button.selectItem(at: 0)
            }
        }
        WriteToLog().message(stringOfText: "[ViewController replicate_Button] Parameters.downloadOption: \(Parameters.downloadOption)")
        
        DispatchQueue.main.async {
            self.uploadStatus_ProgressBar.increment(by: -100.0)
            self.currentUpload_TextField.stringValue = ""
        }
        
        if Parameters.downloadOption != "Save Only" {
            if destinationServer_TextField.stringValue == "" {
                Alert().display(header: "Attention", message: "A destination server address is required.")
                return()
            }
            if destinationUser_TextField.stringValue == "" || destinationPassword_TextField.stringValue == "" {
                Alert().display(header: "Attention", message: "Both a username and password are required for the destination server.")
                return()
            }
            // destination server info
            destinationServer      = destinationServer_TextField.stringValue
            destinationUser        = destinationUser_TextField.stringValue
            destinationPassword    = destinationPassword_TextField.stringValue
            destinationUserCreds   = "\(destinationUser):\(destinationPassword)"
            destinationBase64Creds = destinationUserCreds.data(using: .utf8)?.base64EncodedString() ?? ""
        }
        
        replicate_button.isEnabled = false

        uploadCount   = 1
        downloadCount = 1
        loop          = true
        
        // determine if packages are from a directory or server
        directoryOrServer()
        switch userDefaults.object(forKey: "packageSource")! as! String {
        case "server":
            // source server info
            sourceServer = sourceServer_TextField.stringValue
            sourceUser = sourceUser_TextField.stringValue
            sourcePassword = sourcePassword_TextField.stringValue
            sourceUserCreds = "\(sourceUser):\(sourcePassword)"
            sourceBase64Creds = sourceUserCreds.data(using: .utf8)?.base64EncodedString() ?? ""
//            uuid = cmdFn(type: "uuid", cmd: "/bin/bash", args: "-c", "ioreg -l | grep IOPlatformUUID | head -n 1 | awk -F' = ' '{ print $2 }' | sed 's/\"//g'")
//            WriteToLog().message(stringOfText: "[should be blank - uuid: \(uuid)")
        case "directory":
            WriteToLog().message(stringOfText: "Using packages from \(packagePath)")
        default:
            WriteToLog().message(stringOfText: "Source package location is not defined.")
        }
        
        if Parameters.downloadOption != "Save Only" {
            var authStatusCode = "0"
            // fetch current packages on destination server
            ListPackages().casperJxmlGet(whichServer: "destination", server: destinationServer, username: destinationUser, password: destinationPassword) {
                (result: (Dictionary, Dictionary, Dictionary, String)) in
                (self.destPackageInfoDict, self.destPackageDisplayNameFileNameDict, self.destJcdsDict, authStatusCode) = result
                
                if authStatusCode == "401" {
                    // authentication to the destination server failed
                    self.replicate_button.isEnabled = true
                    return
                }
                
                WriteToLog().message(stringOfText: "[ViewController-replicate_Button] destination server full package info: \(self.destPackageInfoDict)")
                WriteToLog().message(stringOfText: "[ViewController-replicate_Button] destination server package info: \(self.destPackageDisplayNameFileNameDict)")
                WriteToLog().message(stringOfText: "[ViewController-replicate_Button] JCDS info: \(self.destJcdsDict)")
//                if self.destPackageInfoDict.count > 0 {
                

    //            self.increment = 100.0/Double(self.destPackageInfoDict.count)
                if self.userDefaults.object(forKey: "packageSource")! as! String == "server" {
                    WriteToLog().message(stringOfText: "replicate from JCDS")
                    
                    self.fetchPackageList(server: self.sourceServer, creds: self.sourceBase64Creds, computerId: self.sourceServerClientId) {
                        (result: String) in
                            //                            WriteToLog().message(stringOfText: "package info:\n\(result)")
                            // download packages
                        }
//                    }
                } else {   // if self.packageSource - end
                    // replicate from local or mounted directory
                    WriteToLog().message(stringOfText: "replicate from local or mounted directory")
                    var localPackageSource = self.sourceServer
                    if self.userDefaults.object(forKey: "share") as! String == "mounted" {
                        localPackageSource = self.mountedShare+"Packages/"
                        self.packagePath = self.mountedShare+"Packages/"
                    }
                    self.fetchPackageList(server: localPackageSource, creds: self.sourceBase64Creds, computerId: "0") {
                        (result: String) in
                        //                            WriteToLog().message(stringOfText: "package info:\n\(result)")
                        // download packages
                    }
                    
                }
            }   // ListPackages().casperJxmlGet - end
        } else {
            // download packages only
            self.fetchPackageList(server: self.sourceServer, creds: self.sourceBase64Creds, computerId: self.sourceServerClientId) {
            (result: String) in
            WriteToLog().message(stringOfText: "[ViewController] replicate_Button: download packages only")
                // download packages
            }
        }
        
    }
    
    @IBAction func selectDp_Button(_ sender: Any) {
        let theDp = selectDistributionPoint_Button.selectedItem?.title
        if theDp != "Select" {
            self.spinner.startAnimation(self)
            
            WriteToLog().message(stringOfText: "[VewController.selectDp_Button] selectDp_Button: selected DP: \(String(describing: theDp!))")
            // create dictionary without password for logging
            var dpDict = Parameters.distributionPointDictionary[theDp!]!
            dpDict["adminPassword"] = "xxxxxxxx"
//            WriteToLog().message(stringOfText: "[VewController.selectDp_Button] DP info: \(String(describing: Parameters.distributionPointDictionary[theDp!]!))")
            WriteToLog().message(stringOfText: "[VewController.selectDp_Button] DP info: \(dpDict)")
            ListPackages().mountDp(distributionPoint: Parameters.distributionPointDictionary[theDp!]!) {
                           (result: (Dictionary, Dictionary, Dictionary, String)) in
                           (self.sourcePackageInfoDict, self.sourcePackageDisplayNameFileNameDict, _, self.mountedShare) = result
                WriteToLog().message(stringOfText: "[VewController.selectDp_Button] self.mountedShare: file://\(String(describing: self.mountedShare))")
                           
                self.representedObject = URL(fileURLWithPath: "\(self.mountedShare)Packages")
                
                WriteToLog().message(stringOfText: "[VewController.selectDp_Button] server self.representedObject: \(String(describing: self.representedObject!))")
                self.spinner.stopAnimation(self)
                
            }   // ListPackages().mountDp
        }   // if theDp != "Select"
    }   // @IBAction func selectDp_Button
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSApp.activate(ignoringOtherApps: true)
        
        packageTableView.delegate   = self
        packageTableView.dataSource = self
        
        textMessage_TextField.isHidden = true
        
        History.logFile = WriteToLog().getCurrentTime().replacingOccurrences(of: ":", with: "") + "_jamfcpr.log"
        
        // create log directory if missing - start
        if !fm.fileExists(atPath: History.logPath!) {
            do {
                try fm.createDirectory(atPath: History.logPath!, withIntermediateDirectories: true, attributes: nil )
                } catch {
                    Alert().display(header: "Error:", message: "Unable to create log directory:\n\(String(describing: History.logPath))\nTry creating it manually.")
                exit(0)
            }
        }
        // create log directory if missing - end
        
        // create log file
        isDir = false
        if !(fm.fileExists(atPath: History.logPath! + History.logFile, isDirectory: &isDir)) {
            fm.createFile(atPath: History.logPath! + History.logFile, contents: nil, attributes: nil)
        }
        
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        let appBuild   = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        WriteToLog().message(stringOfText: "-------------------------------------------------------")
        WriteToLog().message(stringOfText: "-        jamfcpr Version: \(appVersion) Build: \(appBuild )")
        WriteToLog().message(stringOfText: "-------------------------------------------------------")
        
        // Do any additional setup after loading the view.
        if userDefaults.object(forKey: "sourceServer") as? String == nil {
            sourceServer_TextField.stringValue = ""
        } else {
            sourceServer_TextField.stringValue = userDefaults.object(forKey: "sourceServer") as! String
        }
        if userDefaults.object(forKey: "sourceUser") as? String == nil {
            sourceUser_TextField.stringValue = ""
        } else {
            sourceUser_TextField.stringValue = userDefaults.object(forKey: "sourceUser") as! String
        }
        
        if userDefaults.object(forKey: "destinationServer") as? String == nil {
            destinationServer_TextField.stringValue = ""
        } else {
            destinationServer_TextField.stringValue = userDefaults.object(forKey: "destinationServer") as! String
        }
        if userDefaults.object(forKey: "destinationUser") as? String == nil {
            destinationUser_TextField.stringValue = ""
        } else {
            destinationUser_TextField.stringValue = userDefaults.object(forKey: "destinationUser") as! String
        }
        if userDefaults.object(forKey: "share") as? String == nil {
            userDefaults.set("unmounted", forKey: "share")
        }
        self.userDefaults.synchronize()
        directoryOrServer()
    }
    
    override func viewDidAppear() {
        //set textfield tab order
        sourceServer_TextField.nextKeyView      = sourceUser_TextField
        sourceUser_TextField.nextKeyView        = sourcePassword_TextField
        sourcePassword_TextField.nextKeyView    = destinationServer_TextField
        destinationServer_TextField.nextKeyView = destinationUser_TextField
        destinationUser_TextField.nextKeyView   = destinationPassword_TextField
        
        self.view.layer?.backgroundColor = CGColor(red: 0x5C/255.0, green: 0x78/255.0, blue: 0x94/255.0, alpha: 1.0)
        
    }
    
//    func alert_dialog(header: String, message: String) {
//        let dialog: NSAlert = NSAlert()
//        dialog.messageText = header
//        dialog.informativeText = message
//        dialog.alertStyle = NSAlert.Style.warning
//        dialog.addButton(withTitle: "OK")
//        dialog.runModal()
//        //return true
//    }   // func alert_dialog - end
    
    func cmdFn2(type: String, cmd: String, args: String..., completion: @escaping (_ result: String) -> Void) {
        if type != "unknown" {
            theCmdQ.maxConcurrentOperationCount = 1
            
            theCmdQ.addOperation {
                var status  = ""
                var statusArray  = [String]()
                let pipe    = Pipe()
                let task    = Process()
                
                task.launchPath     = cmd
                switch type {
                case "MD5":
                    task.arguments = ["-c", "/sbin/md5 '\(args[0])' | awk '{print $NF}'"]
                case "SHA_512":
                    task.arguments = ["-c", "/usr/bin/shasum -a 512 '\(args[0])' | awk '{print $1}'"]
                default:
                    task.arguments = args
                }
//                task.arguments      = args
                task.standardOutput = pipe
                //            let outputHandle    = pipe.fileHandleForReading
                
                task.launch()
                
                let outdata = pipe.fileHandleForReading.readDataToEndOfFile()
                if var string = String(data: outdata, encoding: .utf8) {
                    string = string.trimmingCharacters(in: .newlines)
                    statusArray = string.components(separatedBy: "")
                    status = statusArray[0]
                    if type == "createPolicy" {
                        WriteToLog().message(stringOfText: "createPolicy: \(statusArray)")
                    }
                }
                
                task.waitUntilExit()
                completion(status)
            }   // theCmdQ.addOperation - end
        } else {
            completion("skipped")
        }
    }
    
    func directoryOrServer() {
        let sourceTextField = sourceServer_TextField.stringValue
        let sourceTextFieldPrefix = String(sourceTextField.prefix(4))
        WriteToLog().message(stringOfText: "[directoryOrServer] sourceTextFieldPrefix: \(sourceTextFieldPrefix.lowercased())")
        WriteToLog().message(stringOfText: "[directoryOrServer] userDefaults.object(forKey: \"share\"): \(userDefaults.object(forKey: "share") as! String)")
        // test if we're pullig from a cloud DP
        if (sourceTextFieldPrefix.lowercased() == "http") && userDefaults.object(forKey: "share") as! String != "mounted" {
            WriteToLog().message(stringOfText: "[directoryOrServer] source: server")

            userDefaults.set("server", forKey: "packageSource")
            userDefaults.synchronize()
            
            packageSource = "server"
            packagePath   = "/Library/Application Support/JAMF/Waiting Room/"
        } else {
            userDefaults.set("directory", forKey: "packageSource")
            userDefaults.synchronize()
            
            packageSource = "directory"
            packagePath   = sourceTextField
            WriteToLog().message(stringOfText: "source: folder: \(packagePath)")        }
    }
    
    func fetchPackageList(server: String, creds: String, computerId: String, completion: @escaping (_ result: String) -> Void) {
        
        theFetchQ.maxConcurrentOperationCount = 1
        
        var policyId        = ""
        var packageCount    = 0
        var missingPackages = 0
        
        var destChecksumIndex   = 0
        var destPackageChecksum = ""
        var packageIsCurrent    = false
        
        
//        var downloadedPackageList = [String]()

        var index = 0
        packagesToReplicateArray.removeAll()
        
        if !(directoryItems?.count ?? 0 > 0) {
            Alert().display(header: "Attention", message: "No packages appear in the list.  Try clicking the List button.")
            self.loop = false
            self.package_animation(animate: false)
            completion("nothing selected to replicate")
            return
        }
        
        // build list of packages to replicate based on selection - start
        // remove packages that are selected but don't exist on the source server
        // remove packages selected that have the same checksum
        for thePackage in directoryItems! {
            if self.packageTableView.isRowSelected(index) {
                var l_filename     = ""
                var l_packageInfo  = Dictionary<String,String>()
                var l_packageSize  = ""
                if packageSource == "server" && self.userDefaults.object(forKey: "share") as! String != "mounted" {
                    l_filename = self.sourcePackageDisplayNameFileNameDict[thePackage.name]!
                    l_packageInfo = self.sourcePackageInfoDict[l_filename]!
                    l_packageSize = l_packageInfo["size"]!
                } else {
                    l_packageSize = "\(thePackage.size)"
                }
                
                WriteToLog().message(stringOfText: "[ViewController.fetchPackageList] package: \(thePackage.name) has size: \(l_packageSize)")
                if l_packageSize != "" {
                    self.packagesToReplicateArray.append(thePackage.name)
                } else {
                    missingPackages += 1
                }
            }   // if self.packageTableView.isRowSelected(k) - end
            index+=1
        }   // for thePackage in - end
        // build list of packages to replicate based on selection - end
        
        if packagesToReplicateArray.count == 0 {
            var additionalMessage = ""
            if missingPackages > 0 {
                additionalMessage = "\nNote, \(missingPackages) selected package(s) are missing from the source server."
            }
            Alert().display(header: "Attention", message: "No packages were selected to replicate.\(additionalMessage)")
            self.loop = false
            self.package_animation(animate: false)
            completion("nothing selected to replicate")
            return
        }
        
        packageCount = self.packagesToReplicateArray.count
        WriteToLog().message(stringOfText: "[ViewController.fetchPackageList] Found \(packageCount) packages to sync from the source server.")
        WriteToLog().message(stringOfText: "[ViewController.fetchPackageList] Packages to replicate: \(packagesToReplicateArray)")
        self.increment = 100.0/Double(packageCount)
        
        if userDefaults.object(forKey: "packageSource") as! String == "server" && self.userDefaults.object(forKey: "share") as! String != "mounted" {
            WriteToLog().message(stringOfText: "[ViewController.fetchPackageList] download from JCDS")
            theFetchQ.addOperation {
                
                DispatchQueue.main.async {
                    self.downloadStatus_ProgressBar.increment(by: 100)
                    self.uploadStatus_ProgressBar.increment(by: 0.0)
                    
                }
                // start the animation
                self.loop = true
                self.package_animation(animate: true)
                // download each package and call upload function
                for packageDisplayName in self.packagesToReplicateArray {
//                    WriteToLog().message(stringOfText: "[ViewController fetchPackageList] sourcePackageDisplayNameFileNameDict: \(self.sourcePackageDisplayNameFileNameDict)")
                    
                    let packageFileName = self.sourcePackageDisplayNameFileNameDict[packageDisplayName]!
                    let sourcePackageRecord = self.sourcePackageInfoDict[packageFileName]
                    
                    if Parameters.downloadOption != "Save Only" {
                        if let destPackageRecord = self.destPackageInfoDict[packageFileName] {
                            destChecksumIndex   = (destPackageRecord["hashType"] == "MD5") ? 0:1
                            destPackageChecksum = destPackageRecord["checksum"]!
                        }
                        
                        // testing checksums - start
                        if let sourcePackageChecksum = sourcePackageRecord!["checksum"] {
                            WriteToLog().message(stringOfText: "[ViewController.fetchPackageList]             checking package: \(packageFileName)")
                            WriteToLog().message(stringOfText: "[ViewController.fetchPackageList]      source package checksum: \(sourcePackageChecksum)")
                            WriteToLog().message(stringOfText: "[ViewController-fetchPackageList] destination package checksum: \(destPackageChecksum)")
                            if sourcePackageChecksum == destPackageChecksum {
                                packageIsCurrent = true
                                WriteToLog().message(stringOfText: "[ViewController.fetchPackageList] source and destination packages are the same, no need to upload")                            } else {
                                packageIsCurrent = false
                            }
                        }
                        destPackageChecksum   = ""
                        // testing checksums - end
                    }   // if self.downloadOptions_Button - end
                    
                    if let packageId = sourcePackageRecord?["id"] {
                        
//                        if sourcePackageRecord?["size"] != "" {
                        if !packageIsCurrent {
                            //  (self.sourcePackageInfoDict, self.sourcePackageDisplayNameFileNameDict
                            let packageInfo = self.sourcePackageInfoDict["\(packageFileName)"]
                            WriteToLog().message(stringOfText: "[ViewController.fetchPackageList] download URL: \(packageInfo?["fileURL"] ?? "unknown")")
                            let downloadURL = packageInfo?["fileURL"] ?? "unknown"
                            self.download(packageURL: downloadURL, packageName: packageFileName) {
                                (result: Double) in
                                WriteToLog().message(stringOfText: "[ViewController.fetchPackageList] \(String(describing: packageFileName)) - downloaded")
                                self.downloadCount = self.updateDownloadCounters(packageCount: packageCount)

                                if Parameters.downloadOption != "Save Only" {
                                    self.uploadPackages(server: self.destinationServer, package: packageFileName) {
                                        (result: String) in
                                        packageCount = self.updateUploadCounters(packageCount: packageCount)
                                        do {
                                            if Parameters.downloadOption == "Options" {
                                                try FileManager.default.removeItem(at: Parameters.downloadsUrl.appendingPathComponent(packageFileName))
                                            }
                                        } catch {
                                            WriteToLog().message(stringOfText: "[ViewController.fetchPackageList] unable to remove \(Parameters.downloadsUrl.appendingPathComponent(packageFileName).path)")
                                        }
                                    }   // self.uploadPackages - end
                                }   // if Parameters.downloadOption - end
                            }
                            
                        } else {
//                            DispatchQueue.main.async {
//                                self.downloadStatus_ProgressBar.increment(by: -self.increment)
//                            }
                            DispatchQueue.main.async {
                                self.currentDownload_TextField.stringValue = packageFileName
                            }
                            self.downloadCount = self.updateDownloadCounters(packageCount: packageCount)
                            packageCount = self.updateUploadCounters(packageCount: packageCount)
                        }
                        
//                        } else {
//                            self.failedDownloadCount += 1
//                            WriteToLog().message(stringOfText: "\(packageFileName) missing on source server.")
//                        }   // if sourcePackageRecord?["size"] - end
                    }   // if let packageId = sourcePackageRecord?["id"] - end
                }   // for i in (0..<packageCount) - end
//               WriteToLog().message(stringOfText: "\(self.policyIdNamdDict)")
//               self.spinner.stopAnimation(self)
                completion("finished queueing downloads")
            }   // theFetchQ - end
        } else {
            // upload packages from directory
            self.loop = true
            self.package_animation(animate: true)
            for packageFileName in self.packagesToReplicateArray {
                
                var sourcePackageChecksum = ""
                
                let sourcePackageRecord = self.sourcePackageInfoDict[packageFileName]
                WriteToLog().message(stringOfText: "[ViewController.fetchPackageList] sourcePackageRecord: \(String(describing: sourcePackageRecord!))")
                WriteToLog().message(stringOfText: "[ViewController.fetchPackageList]         packagePath: \(packagePath)")
                WriteToLog().message(stringOfText: "[ViewController.fetchPackageList]     packageFileName: \(packageFileName)")
                
//                if let sourcePackageChecksumArray = sourcePackageRecord!["checksum"]?.split(separator: ",") {
//                    sourcePackageChecksum = String(sourcePackageChecksumArray[destChecksumIndex])
//                }
                packageIsCurrent = false
                
                if let destPackageRecord = self.destPackageInfoDict[packageFileName] {
                    // package exists on destination server, check if we have a different version as the source
                    packageCheck(localPackageFileName: packageFileName) {
                        (result: Bool) in
                        packageIsCurrent = result
                        WriteToLog().message(stringOfText: "[ViewController.fetchPackageList] packageIsCurrent (\(packageFileName)): \(packageIsCurrent)")
                        
                        if packageIsCurrent {
                            WriteToLog().message(stringOfText: "[ViewController.fetchPackageList] source and destination packages are the same, no need to upload")
                        } else {
                            WriteToLog().message(stringOfText: "[ViewController.fetchPackageList] source and destination packages differ, set to upload")
                        }
                        
                        if !packageIsCurrent {
                            WriteToLog().message(stringOfText: "[ViewController.fetchPackageList] call upload for \(packageFileName)")
//                          self.uploadPackages1(jcds: self.destJcdsDict, package: packageFileName) {
                            self.uploadPackages(server: self.destinationServer, package: packageFileName) {
                                (result: String) in
                                packageCount = self.updateUploadCounters(packageCount: packageCount)
                            }   // self.uploadPackages (directory) - end
                        } else {
                            packageCount = self.updateUploadCounters(packageCount: packageCount)
                        }
                        
                    }
                } else {
                    // new package to upload
                    WriteToLog().message(stringOfText: "[ViewController.fetchPackageList] call upload for \(packageFileName)")
//                  self.uploadPackages1(jcds: self.destJcdsDict, package: packageFileName) {
                    self.uploadPackages(server: self.destinationServer, package: packageFileName) {
                        (result: String) in
                        packageCount = self.updateUploadCounters(packageCount: packageCount)
                    }   // self.uploadPackages (directory) - end
                }  // if let destPackageRecord = self.destPackageInfoDict[packageFileName] - end
            }
        }   // upload packages from directory - end
    }   // func fetchPackageList - end
    
    func findPdInfo(_ task:Process) {
        
//        var currentString = ""
        pipeJamfPolicy = Pipe()
        task.standardOutput = pipeJamfPolicy
        
        pipeJamfPolicy.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: pipeJamfPolicy.fileHandleForReading , queue: nil) {
            
            notification in
            
            let output = self.pipeJamfPolicy.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            
            DispatchQueue.main.async(execute: {
                let outputArray = outputString.split(separator: " ")
                WriteToLog().message(stringOfText: "policy output:")
                for theText in outputArray {
                    WriteToLog().message(stringOfText: "\t \(theText)")
                }
//                let previousOutput = self.reconStatus.string ?? ""
//
//                //if outputString.lowercased().contains("nsunderlyingerror") == false {
//
//                let nextOutput = previousOutput + outputString
//                self.reconStatus.string = nextOutput
//
//                let range = NSRange(location:nextOutput.characters.count,length:0)
//                self.reconStatus.scrollRangeToVisible(range)
                //}
                
                
            })
            self.pipeJamfPolicy.fileHandleForReading.waitForDataInBackgroundAndNotify()
        }
    }
    
    func messageDisplay(hidden: Bool, message: String) {
        if message != "" {
            messagesArray.append(message)
        }
        DispatchQueue.main.async {
            if self.messagesArray.count > 0 {
                self.textMessage_TextField.stringValue = self.messagesArray[0]
                self.textMessage_TextField.isHidden = false
            } else {
                self.textMessage_TextField.isHidden = hidden
            }
        }
    }
    
    func packageCheck(localPackageFileName: String, completion: @escaping (_ result: Bool) -> Void) {
        // determine if source and destination packages are the same or not - using checksum
        var localPackageIsCurrent = false
        var localSourcePackageChecksum  = "" // reset source package checksum
        var localDestPackageChecksum    = "" // reset destination package checksum
        if let destPackageRecord = self.destPackageInfoDict[localPackageFileName] {
            //                    WriteToLog().message(stringOfText: "[ViewController] destPackageRecord: \(destPackageRecord)")
//            let localDestChecksumIndex   = (destPackageRecord["hashType"] == "MD5") ? 0:1
            let localChecksumType = destPackageRecord["hashType"] ?? ""
            
            localDestPackageChecksum = destPackageRecord["checksum"]!
            
            messageDisplay(hidden: false, message: "calculating checksum for: \(localPackageFileName)")
            
            WriteToLog().message(stringOfText: "[ViewController-packageCheck] calculating \(localChecksumType) checksum for: \(self.packagePath)\(localPackageFileName)")

            self.cmdFn2(type: localChecksumType, cmd: "/bin/bash", args: "\(self.packagePath)\(localPackageFileName)") {
                (result: String) in
                localSourcePackageChecksum = result
                WriteToLog().message(stringOfText: "[ViewController-packageCheck]             checking package: \(localPackageFileName)")
                WriteToLog().message(stringOfText: "[ViewController-packageCheck]      source package checksum: \(localSourcePackageChecksum)")
                WriteToLog().message(stringOfText: "[ViewController-packageCheck] destination package checksum: \(localDestPackageChecksum)")
                if localSourcePackageChecksum == localDestPackageChecksum {
                    localPackageIsCurrent = true
                }
                self.messagesArray.remove(at: 0)
                self.messageDisplay(hidden: true, message: "")
                completion(localPackageIsCurrent)
            }

        } else {
            messageDisplay(hidden: true, message: "")
            completion(localPackageIsCurrent)
        }
        // if let destPackageRecord = self.destPackageInfoDict[localPackageFileName] - end
    }
    
    private func download(packageURL: String, packageName: String, completion: @escaping (_ speedTestResult: Double) -> Void) {
        WriteToLog().message(stringOfText: "[download] initiating download process")
        
        var theFileSize = 0.0
        let startTime = Date()
        
        theDownloadQ.maxConcurrentOperationCount = 1
        let semaphore = DispatchSemaphore(value: 0)
        
        // Location to store the file
//        let fileUrl:URL =  (FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first as URL?)!
        let destinationFileUrl = Parameters.downloadsUrl.appendingPathComponent(packageName)
        
        // create download directory if it doesn't exist
        WriteToLog().message(stringOfText: "check download URL: \(Parameters.downloadsUrl.path)")
        if !(FileManager.default.fileExists(atPath: "\(Parameters.downloadsUrl.path)", isDirectory: &isDir)) {
            do {
                try FileManager.default.createDirectory(at: Parameters.downloadsUrl, withIntermediateDirectories: true, attributes: nil)
                WriteToLog().message(stringOfText: "created download URL: \(Parameters.downloadsUrl.path)")
            } catch {
                WriteToLog().message(stringOfText: "unable to create downloads directory.")
            }
        }
        
        var filePath = "\(destinationFileUrl)"
        // drop 'file://' from path
        filePath = String(filePath.dropFirst(7))
        filePath = filePath.replacingOccurrences(of: "%20", with: " ")
        
        let exists = FileManager.default.fileExists(atPath: filePath)
        if exists {
            do {
                try FileManager.default.removeItem(atPath: filePath)
                WriteToLog().message(stringOfText: "removed existing file")
            } catch {
                WriteToLog().message(stringOfText: "failed to remove existing file")
                exit(0)
            }
        } else {
            WriteToLog().message(stringOfText: "new download")
        }
        
        // Create URL to the source file you want to download - this must be a trusted server
        //        let fileURL = URL(string: "https://lhelou.jamfcloud.com/bin/SelfService.tar.gz")
        //        let fileURL = URL(string: "https://jamf.ccs-indy.com:8443/bin/SelfService.tar.gz")
        let fileURL = URL(string: packageURL)
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        
        let request = URLRequest(url:fileURL!)
        
        self.theDownloadQ.addOperation {
            URLCache.shared.removeAllCachedResponses()
            DispatchQueue.main.async {
                self.currentDownload_TextField.stringValue = packageName
            }
            let downloadTask = session.downloadTask(with: request, completionHandler: { (tempLocalUrl, response, error) in
                if let tempLocalUrl = tempLocalUrl, error == nil {
                    // Success
                    if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                        WriteToLog().message(stringOfText: "Response from server - Status code: \(statusCode)")
                    } else {
                        WriteToLog().message(stringOfText: "No response from the server.")
                        completion(0.0)
                    }
                    
                    switch (response as? HTTPURLResponse)?.statusCode {
                    case 200:
                        WriteToLog().message(stringOfText: "\t file successfully downloaded.")
                    case 401:
                        WriteToLog().message(stringOfText: "\t Authentication failed.")
                        completion(0.0)
                    case 404:
                        WriteToLog().message(stringOfText: "\t server / file not found.")
                        completion(0.0)
                    default:
                        WriteToLog().message(stringOfText: "\t unknown error occured.")
                        WriteToLog().message(stringOfText: "\t Error took place while downloading a file.")
                        completion(0.0)
                    }
                    
                    do {
                        try FileManager.default.copyItem(at: tempLocalUrl, to: destinationFileUrl)
                    } catch (let writeError) {
                        WriteToLog().message(stringOfText: "Error creating a file \(destinationFileUrl) : \(writeError)")
                        completion(0.0)
                    }
                    
                    let endTime = Date()
                    let components = Calendar.current.dateComponents([.second, .nanosecond], from: startTime, to: endTime)
                    
                    let timeDifference = Double(components.second!) + Double(components.nanosecond!)/1000000000
                    WriteToLog().message(stringOfText: "time difference: \(timeDifference) seconds")
                    
                    let fileProperties = try? FileManager.default.attributesOfItem(atPath: filePath)
                    
                    if let size = fileProperties![FileAttributeKey.size] as? NSNumber {
                        theFileSize = size.doubleValue / 1000000.0
                        WriteToLog().message(stringOfText: "file size: \(theFileSize)")
                    } else {
                        theFileSize = 0.0
                        WriteToLog().message(stringOfText: "unable to get filesize")
                    }

                    let downloadRate = theFileSize/timeDifference
                    completion(downloadRate)
                } else {
                    WriteToLog().message(stringOfText: "Error took place while downloading a file.");
                    completion(0.0)
                }
//            }
                semaphore.signal()
            })   // let downloadTask = session - end
            let downloadObserver = downloadTask.progress.observe(\.fractionCompleted) { progress, _ in
                let percentComplete = (round(progress.fractionCompleted*1000)/10)
                DispatchQueue.main.async {
                    self.downloadPercent_TextField.stringValue = "\(percentComplete)%"
                }
            }
            downloadTask.resume()
            semaphore.wait()
            NotificationCenter.default.removeObserver(downloadObserver)
        }
    }
    
    func uploadPackages(server: String, package: String, completion: @escaping (_ result: String) -> Void) {
        
        var newPackageId = "0"
        var hashBin      = ""
        var hash_type    = ""
        var position     = ""   // the field that awk will return
        var fileURL: URL!
//        var uploadResult = ""
        var destinationServer = server + "/dbfileupload"
        destinationServer = destinationServer.replacingOccurrences(of: "/JSSResources", with: "")
        destinationServer = destinationServer.replacingOccurrences(of: "//dbfileupload", with: "/dbfileupload")
        var httpResponse:HTTPURLResponse?
        var statusCode = 0
        
        theUploadQ.maxConcurrentOperationCount = 1
        let semaphore = DispatchSemaphore(value: 0)
        
        // check for existing package on destination server
        if self.destPackageInfoDict[package] != nil {
            newPackageId = self.destPackageInfoDict[package]!["id"]!
            hash_type    = self.destPackageInfoDict[package]!["hashType"]!
            switch hash_type {
            case "MD5":
                hashBin  = "/sbin/md5"
                position = "NF"
            case "SHA_512":
                hashBin  = "/usr/bin/shasum -a 512"
                position = "1"
            default:
                hashBin = "unknown"
            }
            WriteToLog().message(stringOfText: "hashType on destination server for \(package): \(hash_type)")
            WriteToLog().message(stringOfText: "existing packageChecksum on dest server for \(package): \(self.destPackageInfoDict[package]!["checksum"]!)")
        } else {
            // defaults for newly uploaded file
            hashBin  = "/sbin/md5"
            position = "NF"
        }

//        let packageChecksum = self.cmdFn(type: "\(hashBin)", cmd: "/bin/bash", args: "-c", "\(hashBin) '\(self.packagePath)\(package)' | awk '{print $\(position)}'")
//        WriteToLog().message(stringOfText: "source packageChecksum: \(packageChecksum)")
        
            WriteToLog().message(stringOfText: "[ViewController.uploadPackages] uploading package: \(package) with id: \(newPackageId)")
            
            self.theUploadQ.addOperation {
                let uploadCreds = "\(self.destinationUser):\(self.destinationPassword)"
                let base64Creds = uploadCreds.data(using: .utf8)?.base64EncodedString()
                
                var fileName:String?
                var fileType:String?
//                var mimeType:String?
                
                //        var theFileSize = 0.0
                let startTime = Date()
                var postData = Data()
                

                // Location to store the file
//                fileURL = (FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first as URL?)!
//                let destinationFileUrl = fileUrl.appendingPathComponent(packageName)
                
//                var filePath = "\(destinationFileUrl)"
//                // drop 'file://' from path
//                filePath = String(filePath.dropFirst(7))
//                filePath = filePath.replacingOccurrences(of: "%20", with: " ")
                
//                if (self.folderOrServer.lowercased() == "http") {
                if Parameters.cloudDistribitionPoint {
//                    fileURL = URL(fileURLWithPath: "\(self.packagePath)Packages/\(package)")
                    fileURL = Parameters.downloadsUrl.appendingPathComponent(package)
                } else {
                    fileURL = URL(fileURLWithPath: "\(self.packagePath)\(package)")
                }
                WriteToLog().message(stringOfText: "[ViewController.uploadPackages] package: \(self.packagePath)Packages/\(package)")
                WriteToLog().message(stringOfText: "[ViewController.uploadPackages] fileURL: \(String(describing: fileURL!))")
                let fullName = fileURL.lastPathComponent
                let fullNameArray = fullName.split(separator: ".")
                fileName = String(describing: fullNameArray.first!)
                fileType = String(describing: fullNameArray.last!)
                WriteToLog().message(stringOfText: "[ViewController.uploadPackages] uploading \(fileName!) of type: \(fileType!)")
                // use to add icons to web based packages?
//                switch "\(fileType!)" {
//                case "pkg":
//                    WriteToLog().message(stringOfText: "mime type: x-newton-compatible-pkg")
//                    mimeType = "x-newton-compatible-pkg"
//                case "dmg":
//                    WriteToLog().message(stringOfText: "mime type: application/octet-stream")
//                    mimeType = "application/octet-stream"
//                default:
//                    WriteToLog().message(stringOfText: "mime type: unknown")
//                    mimeType = ""
//                }

                // Create URL to the destination server - this must be a trusted server
                let serverURL = URL(string: "\(destinationServer)")!
                

                let sessionConfig = URLSessionConfiguration.default
                let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: OperationQueue.main)
                
                var request = URLRequest(url:serverURL)
                request.addValue("0", forHTTPHeaderField: "DESTINATION")
                request.addValue("\(newPackageId)", forHTTPHeaderField: "OBJECT_ID")
                request.addValue("0", forHTTPHeaderField: "FILE_TYPE")
                request.addValue("\(package)", forHTTPHeaderField: "FILE_NAME")
                request.addValue("Basic \(base64Creds!)", forHTTPHeaderField: "Authorization")
                
                // prep the data for uploading
                do {
                    let fileData = try Data(contentsOf:fileURL, options:[])
                    postData.append(fileData)
                    
                    // for large files
//                    request.addValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
//                    request.httpBodyStream = InputStream(data: fileData)
                    
                    WriteToLog().message(stringOfText: "loaded file to data.")
                }
                catch {
                    WriteToLog().message(stringOfText: "unable to get file")
                }

                request.httpBody   = postData
                request.httpMethod = "POST"
                
                // start upload process
                DispatchQueue.main.async {
                    self.currentUpload_TextField.stringValue = "\(package)"
                }
                URLCache.shared.removeAllCachedResponses()
                // let task = session.dataTask(with: request) { (data, response, error) in
                let task = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
                    // Success
    //                if let httpResponse = response as? HTTPURLResponse {
                    if let _ = (response as? HTTPURLResponse)?.statusCode {
                        httpResponse = response as? HTTPURLResponse
                        statusCode = httpResponse!.statusCode
                        WriteToLog().message(stringOfText: "Response from server - Status code: \(statusCode)")
//                        WriteToLog().message(stringOfText: "Response (package) data string: \(String(data: data!, encoding: .utf8)!)")
                    } else {
                        WriteToLog().message(stringOfText: "No response from the server.")
                        DispatchQueue.main.async {
                            self.currentUpload_TextField.stringValue = ""
                        }
                        completion("\(String(describing: httpResponse))")
                    }

                    switch (response as? HTTPURLResponse)?.statusCode {
                    case 200, 201:
                        WriteToLog().message(stringOfText: "\t file successfully uploaded.")
                    case 401:
                        WriteToLog().message(stringOfText: "\t Authentication failed.")
                    case 404:
                        WriteToLog().message(stringOfText: "\t server / file not found.")
                    default:
                        WriteToLog().message(stringOfText: "\t unknown error occured.")
                        WriteToLog().message(stringOfText: "\t Error took place while uploading a file.")
                    }


                    let endTime = Date()
                    let components = Calendar.current.dateComponents([.second, .nanosecond], from: startTime, to: endTime)

                    let timeDifference = Double(components.second!) + Double(components.nanosecond!)/1000000000
                    WriteToLog().message(stringOfText: "upload time: \(timeDifference) seconds")
                    
                    DispatchQueue.main.async {
                        self.currentUpload_TextField.stringValue = ""
                    }
                    completion("\(String(describing: httpResponse?.statusCode))")
                    // upload checksum - end
                    
                    semaphore.signal()
                })   // let task = session - end

                let uploadObserver = task.progress.observe(\.fractionCompleted) { progress, _ in
                    let uploadPercentComplete = (round(progress.fractionCompleted*1000)/10)
                    DispatchQueue.main.async {
                        self.uploadPercent_TextField.stringValue = "\(uploadPercentComplete)%"
                    }
                }
                task.resume()
                semaphore.wait()
                NotificationCenter.default.removeObserver(uploadObserver)
            }   // theUploadQ.addOperation - end
                // end upload procdess
//        }   // self.cmdFn2
    }   // func uploadPackages - end
    
    func uploadPackages1(jcds: Dictionary<String, String>, package: String, completion: @escaping (_ result: String) -> Void) {
        // uploads to the JCDS rather then dbfileuploads
        // goal is to also chunk the upload - chunk to 10MB parts?
        
        var newPackageId = "0"
        var hashBin      = ""
        var hash_type    = ""
        var position     = ""   // the field that awk will return
        //        var uploadResult = ""
        var destinationServer = jcds["server"]! + "/dbfileupload"
        destinationServer = destinationServer.replacingOccurrences(of: "/JSSResources", with: "")
        destinationServer = destinationServer.replacingOccurrences(of: "//dbfileupload", with: "/dbfileupload")
        var httpResponse:HTTPURLResponse?
        var statusCode = 0
        
        theUploadQ.maxConcurrentOperationCount = 1
        let semaphore = DispatchSemaphore(value: 0)
        
        // check for existing package on destination server
        if self.destPackageInfoDict[package] != nil {
            newPackageId = self.destPackageInfoDict[package]!["id"]!
            hash_type    = self.destPackageInfoDict[package]!["hashType"]!
            switch hash_type {
            case "MD5":
                hashBin  = "/sbin/md5"
                position = "NF"
            case "SHA_512":
                hashBin  = "/usr/bin/shasum -a 512"
                position = "1"
            default:
                hashBin = "unknown"
            }
            WriteToLog().message(stringOfText: "[ViewController.uploadPackages1] hashType on destination server for \(package): \(hash_type)")
            WriteToLog().message(stringOfText: "[ViewController.uploadPackages1] existing packageChecksum on dest server for \(package): \(self.destPackageInfoDict[package]!["checksum"]!)")
        } else {
            // defaults for newly uploaded file
            hashBin  = "/sbin/md5"
            position = "NF"
        }
        
        WriteToLog().message(stringOfText: "[ViewController.uploadPackages1] uploading package: \(package) with id: \(newPackageId)")
        
        self.theUploadQ.addOperation {
            let uploadCreds = "\(self.destinationUser):\(self.destinationPassword)"
            let base64Creds = uploadCreds.data(using: .utf8)?.base64EncodedString()
            
            let startTime = Date()
            var postData = Data()
            var fileData = Data()
            
            var fileName:String?
            var fileType:String?
            var mimeType:String?
            
            WriteToLog().message(stringOfText: "[ViewController.uploadPackages1] package: \(self.packagePath)\(package)")
            let fileURL = URL(fileURLWithPath: "\(self.packagePath)\(package)")
            WriteToLog().message(stringOfText: "[ViewController.uploadPackages1] fileURL: \(fileURL)")
            let fullName = fileURL.lastPathComponent
            let fullNameArray = fullName.split(separator: ".")
            fileName = String(describing: fullNameArray.first!)
            fileType = String(describing: fullNameArray.last!)
            WriteToLog().message(stringOfText: "[ViewController.uploadPackages1] uploading \(fileName!) of type: \(fileType!)")
            
            switch "\(fileType!)" {
            case "pkg":
                WriteToLog().message(stringOfText: "[ViewController.uploadPackages1] mime type: x-newton-compatible-pkg")
                mimeType = "x-newton-compatible-pkg"
            case "dmg":
                WriteToLog().message(stringOfText: "[ViewController.uploadPackages1] mime type: application/octet-stream")
                mimeType = "application/octet-stream"
            default:
                WriteToLog().message(stringOfText: "[ViewController.uploadPackages1] mime type: unknown")
                mimeType = ""
            }
            
//            let boundary = "Boundary-\(UUID().uuidString)"
//            let fileBoundary = "\r\n--\(boundary)\r\nContent-Type: application/\(mimeType!)\r\n\r\n"
            
            // Create URL to the destination server - this must be a trusted server
            let serverURL = URL(string: "\(destinationServer)")!
            
            let sessionConfig = URLSessionConfiguration.default
            let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: OperationQueue.main)
            
            var request = URLRequest(url:serverURL)
            request.addValue("0", forHTTPHeaderField: "DESTINATION")
            request.addValue("\(newPackageId)", forHTTPHeaderField: "OBJECT_ID")
            request.addValue("0", forHTTPHeaderField: "FILE_TYPE")
            request.addValue("\(package)", forHTTPHeaderField: "FILE_NAME")
            request.addValue("Basic \(base64Creds!)", forHTTPHeaderField: "Authorization")
            
            // prep the data for uploading
            do {
                let fileData = try Data(contentsOf:fileURL, options:[])
                postData.append(fileData)
                
                // for large files
                //                    request.addValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
                //                    request.httpBodyStream = InputStream(data: fileData)
                
                WriteToLog().message(stringOfText: "[ViewController.uploadPackages1] loaded file to data.")
            }
            catch {
                WriteToLog().message(stringOfText: "[ViewController.uploadPackages1] unable to get file")
            }
            
            request.httpBody   = postData
            request.httpMethod = "POST"
            
            // start upload process
            DispatchQueue.main.async {
                self.currentUpload_TextField.stringValue = "\(package)"
            }
            URLCache.shared.removeAllCachedResponses()
            // let task = session.dataTask(with: request) { (data, response, error) in

            // split file into parts
            let dataLen = fileData.count
            let chunkSize = ((1024 * 1000) * 10) // MB
            let fullChunks = Int(dataLen / chunkSize)
            let totalChunks = fullChunks + (dataLen % 1024 != 0 ? 1 : 0)
            
            //            var chunks:[Data] = [Data]()
            for chunkCounter in 0..<totalChunks {
                var chunk:Data
                let chunkBase = chunkCounter * chunkSize
                var diff = chunkSize
                if(chunkCounter == totalChunks - 1) {
                    diff = dataLen - chunkBase
                }
                
                let range:Range<Data.Index> = chunkBase..<(chunkBase + diff)
                chunk = fileData.subdata(in: range)
                
                request.httpBody = chunk
                WriteToLog().message(stringOfText: "The size is \(chunk.count)")
                
                let task = session.dataTask(with: request) { (data, response, error) in
                    // Success
                    if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                        WriteToLog().message(stringOfText: "Response from server - Status code: \(statusCode)")
                        WriteToLog().message(stringOfText: "Response (package) data string: \(String(data: data!, encoding: .utf8)!)")
                        completion("Response from server - Status code: \(statusCode)")
                    }
                    
                    switch (response as? HTTPURLResponse)?.statusCode {
                    case 200:
                        WriteToLog().message(stringOfText: "\t file successfully uploaded.")
                    case 401:
                        WriteToLog().message(stringOfText: "\t Authentication failed.")
                        completion("\t Authentication failed.")
                    case 404:
                        WriteToLog().message(stringOfText: "\t server / file not found.")
                        completion("\t server / file not found.")
                    default:
                        WriteToLog().message(stringOfText: "\t unknown error occured.")
                        WriteToLog().message(stringOfText: "\t Error took place while uploading a file.")
                        completion("\t unknown error occured.")
                    }
                    
                    
                    let endTime = Date()
                    let components = Calendar.current.dateComponents([.second, .nanosecond], from: startTime, to: endTime)
                    
                    let timeDifference = Double(components.second!) + Double(components.nanosecond!)/1000000000
                    WriteToLog().message(stringOfText: "time difference: \(timeDifference) seconds")
                    
                    completion("Upload time: \(timeDifference)")
                }
                task.resume()
            }   // for chunkCounter - end
            semaphore.wait()
        }   // theUploadQ.addOperation - end
    }
    
    func updateDownloadCounters(packageCount: Int) -> Int {
        DispatchQueue.main.async {
            if self.downloadCount < packageCount {
                self.downloadCount += 1
                self.downloadStatus_ProgressBar.increment(by: -self.increment)
            } else {
                self.currentDownload_TextField.stringValue = "all downloads completed"
                self.downloadStatus_ProgressBar.increment(by: -100)
                if Parameters.downloadOption == "Save Only" {
                    self.loop = false
                    self.package_animation(animate: false)
                }
            }
        }
        return downloadCount
    }
    
    func updateUploadCounters(packageCount: Int) -> Int {
        DispatchQueue.main.async {
            if self.uploadCount < packageCount - self.failedDownloadCount {
                self.uploadCount += 1
                self.uploadStatus_ProgressBar.increment(by: self.increment)
            } else {
                self.loop = false
                self.package_animation(animate: false)
                self.currentUpload_TextField.stringValue = "all uploads completed"
                self.uploadStatus_ProgressBar.increment(by: self.increment)
                self.downloadStatus_ProgressBar.increment(by: -100)
            }
        }
        return packageCount
    }
    
    func package_animation(animate: Bool) {
        let packageImageArray = [p1_ImageView, p2_ImageView, p3_ImageView, p4_ImageView, p5_ImageView]
        let modulo = 5
        var counter = packageImageArray.count - 1   // index of last image in packageImageArray
            self.theAnimationQ.async {
                while self.loop {
                    DispatchQueue.main.async {
                        packageImageArray[counter % modulo]?.isHidden = true
                        counter += 1
                        packageImageArray[counter % modulo]?.isHidden = false
                    }
                    usleep(300000)
                }   // while animate - end
                if !self.loop {
                    DispatchQueue.main.async {
                        for i in 0..<packageImageArray.count {
                            packageImageArray[i]?.isHidden = true
                        }
                        self.replicate_button.isEnabled = true
                    }   // DispatchQueue.main.async - end
                }   // if !self.loop - end
            }   //theAnimationQ.async - end
    }   //     func package_animation - end

    @IBAction func QuitNow(sender: AnyObject) {
        userDefaults.set(sourceServer_TextField.stringValue, forKey: "sourceServer")
        userDefaults.set(sourceUser_TextField.stringValue, forKey: "sourceUser")
        userDefaults.set(destinationServer_TextField.stringValue, forKey: "destinationServer")
        userDefaults.set(destinationUser_TextField.stringValue, forKey: "destinationUser")
        
        WriteToLog().logCleanup()
        
//        let keys: [URLResourceKey] = [.volumeNameKey, .volumeIsRemovableKey, .volumeIsEjectableKey]
//        let paths = FileManager().mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [])
//        if let urls = paths {
//            for url in urls {
//                let components = url.pathComponents
//                print(url)
//                WriteToLog().message(stringOfText: "sourceServerInfo.name: \(sourceServerInfo.name)")
                // unmount shares the app mounted
        DispatchQueue.main.async {
            for (server,share) in Parameters.mountedSharesDict {
                let mountPath = "/private/tmp/\(server)/\(share)"
                WriteToLog().message(stringOfText: "[ViewController.quit] umounting \(server)")
                self.textMessage_TextField.stringValue = "unmounting \(server)"
                try? NSWorkspace().unmountAndEjectDevice(at: URL(fileURLWithPath: mountPath))
                try? FileManager.default.removeItem(atPath: mountPath)
            }
            NSApplication.shared.terminate(self)
        }
//            }
//        }
//        do {
//        try? NSWorkspace().unmountAndEjectDevice(at: URL(string: "file:///Volumes/CasperShare")!)
//        } catch {
//            WriteToLog().message(stringOfText: "failed to unmount")
//        }
        
        
    }
    
    func reloadFileList() {
        // determine if packages are from a directory or server
        
        directoryOrServer()
        WriteToLog().message(stringOfText: "[ViewController.reloadFileList] source: \(userDefaults.object(forKey: "packageSource")!)")
//        sourcePackageInfoDict.removeAll()
        if userDefaults.object(forKey: "packageSource")! as! String == "server" && userDefaults.object(forKey: "share") as! String != "mounted" {
            webPackages.removeAll()

            WriteToLog().message(stringOfText: "[ViewController.reloadFileList] display packages from server")
            for (name, fileName) in sourcePackageDisplayNameFileNameDict {
//                WriteToLog().message(stringOfText: "sourcePackageDisplayNameFileNameDict: \(sourcePackageDisplayNameFileNameDict)\n fileName: \(fileName)")
//                WriteToLog().message(stringOfText: "sourcePackageInfoDict: \(sourcePackageInfoDict)")
                let packageInfo = sourcePackageInfoDict[fileName]!
                WriteToLog().message(stringOfText: "[ViewController.reloadFileList] adding \(name) to webPackages")
                webPackages.append(Metadata(fileURL: URL(string: "file:///")!,
                                             name: name,
                                             filename: fileName,
                                             date: Date(),
                                             size: Int64(packageInfo["size"]!) ?? 0,
                                             hashType: packageInfo["hashType"]!,
                                             checksum: packageInfo["checksum"]!,
                                             icon: NSImage(),
                                             isFolder: false,
                                             color: NSColor()))
            }
            WriteToLog().message(stringOfText: "[ViewController.reloadFileList] webPackages: \(String(describing: webPackages))")
            directoryItems = webPackages.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
        } else {
            DispatchQueue.main.async {
                self.spinner.startAnimation(self)
            }
            WriteToLog().message(stringOfText: "[ViewController.reloadFileList] display packages in folder")
            directoryItems?.removeAll()
            directoryItems = directory?.contentsOrderedBy(sortOrder, ascending: sortAscending)
            var currentRow = 0
            for item in directoryItems! {
                WriteToLog().message(stringOfText: "[ViewController.reloadFileList] directory item: \(item)")
                if ((item.name.suffix(4) != ".pkg") && (item.name.suffix(4) != ".dmg") && (item.name.suffix(4) != ".zip")) || (item.isFolder) {
                    directoryItems?.remove(at: currentRow)
                } else {
                    if userDefaults.object(forKey: "packageSource")! as! String == "directory" {
                        sourcePackageInfoDict[item.name] = ["name":item.name, "hashType":item.hashType, "checksum":item.checksum, "size":"\(item.size)"]
                    }
                    currentRow+=1
                }
            }
//            WriteToLog().message(stringOfText: "directoryItems: \(String(describing: directoryItems!))")
        }

        WriteToLog().message(stringOfText: "[ViewController.reloadFileList] call packageTableView.reloadData()")
        packageTableView.reloadData()
        DispatchQueue.main.async {
            self.spinner.stopAnimation(self)
        }
    }
    
    override var representedObject: Any? {
        didSet {
            if let url = representedObject as? URL {
                directory = Directory(folderURL: url)
                WriteToLog().message(stringOfText: "[ViewController.representedObject] directory: \(String(describing: directory!))")
                reloadFileList()
            }
        }
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping(  URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
    /*
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent countOfBytesSent: Int64, totalBytesExpectedToSend countOfBytesExpectedToSend: Int64) {
        let uploadProgress: Double = Double(countOfBytesSent) / Double(countOfBytesExpectedToSend)
        let progressStringArray = String(uploadProgress * 100).split(separator: ".")
        let progressInt = progressStringArray[0]
        let progressDec  = progressStringArray[1].prefix(1)
        DispatchQueue.main.async {
            self.uploadPercent_TextField.stringValue = "\(progressInt).\(progressDec)%"
        }
        //        WriteToLog().message(stringOfText: "session: \(session) uploaded \(progressInt).\(progressDec)%")
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: (URLSession.ResponseDisposition) -> Void)
    {
        WriteToLog().message(stringOfText: "[ViewController-urlSession] didReceiveResponse: \(response)")
    }
    */
}

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in packageTableView: NSTableView) -> Int {
        var rowCount = 0
        if Parameters.cloudDistribitionPoint {
            rowCount = sourcePackageDisplayNameFileNameDict.count
//            WriteToLog().message(stringOfText: "[ViewController.NSTableViewDataSource] cloud rowCount: \(rowCount)")
        } else {
            rowCount = directoryItems?.count ?? 0
//            WriteToLog().message(stringOfText: "[ViewController.NSTableViewDataSource] directory rowCount: \(rowCount)")
        }
        return rowCount
    }
}

extension ViewController: NSTableViewDelegate {
    
    fileprivate enum CellIdentifiers {
        static let NameCell     = "NameCell_id"
        static let SizeCell     = "SizeCell_id"
//        static let ChecksumCell = "ChecksumCell_id"
    }
    
    func tableView(_ packageTableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        var image: NSImage?
        var text: String = ""
        var cellIdentifier: String = ""

            guard let item = directoryItems?[row] else {
                return nil
            }
            
            if tableColumn == packageTableView.tableColumns[0] {
                if Parameters.cloudDistribitionPoint {
                    
                    let nameArray = item.filename.split(separator: ".")
                    let fileType  = nameArray.last?.lowercased()
                    switch fileType {
                    case "pkg","zip":
                        image = NSImage(named: "pkgIcon")!
                    case "dmg":
                        image = NSImage(named: "dmgIcon")!
                    default:
                        image = nil
                    }
                } else {
                    image = item.icon
                }
                text = item.name
                cellIdentifier = CellIdentifiers.NameCell
            } else if tableColumn == packageTableView.tableColumns[1] {
                if userDefaults.object(forKey: "packageSource")! as! String == "server" {
                    text = sizeFormatter.string(fromByteCount: item.size)
                    text = text.replacingOccurrences(of: "Zero", with: "0")
    //                text = item.checksum
    //                text = ""
                } else {
                    text = item.isFolder ? "--" : sizeFormatter.string(fromByteCount: item.size)
                }
                cellIdentifier = CellIdentifiers.SizeCell
            } //else if tableColumn == packageTableView.tableColumns[2] {
    //            let checksumArray = item.checksum.split(separator: ",")
    //            if checksumArray.count > 0 {
    //                text = String(checksumArray[0])
    //            } else {
    //                text = ""
    //            }
    //            cellIdentifier = CellIdentifiers.ChecksumCell
    //        }
            // non-cloud distributions points - end
//        }
    
        if let cell = packageTableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellIdentifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = text
            cell.imageView?.image = image ?? nil
            return cell
        }
        return nil
    }
    
}

struct sourceServerInfo {
    static var name = ""
}

