//
//  DpTypeVC.swift
//  jamfcpr
//
//  Created by leslie on 12/26/24.
//  Copyright © 2024 jamf. All rights reserved.
//

import AppKit
import Cocoa
import Foundation

class DpTypeVC: NSViewController, CloseWindowDelegate {
    
    var resourceType = ""
    var localPath = ""
    var updateRepoListDelegate: UpdateRepoListDelegate? = nil
    
    @IBAction func dismiss_Action(_ sender: NSButton) {
        resourceType = sender.identifier?.rawValue ?? ""
        print("[DPTypeVC] sender: \(resourceType)")
//        if resourceType == "local" {
//            selectFolder()
//        } else {
            performSegue(withIdentifier: "resourceType", sender: nil)
//        }
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let _ = segue.identifier else {
            return
        }
        
        print("[DPTypeVC] prepare resourceType: \(resourceType)")
        let sourceDestinationVC: SourceDestinationVC = segue.destinationController as! SourceDestinationVC
        sourceDestinationVC.delegate = self
        
        sourceDestinationVC.mode = "create"
        sourceDestinationVC.resourceType = resourceType
//        sourceDestinationVC.localPath = localPath
    }
    
    
//    func selectFolder() {
//        let openPanel = NSOpenPanel()
//        openPanel.canChooseDirectories = true
//        openPanel.canChooseFiles       = false
//        openPanel.canCreateDirectories = true
//        
//        openPanel.begin { [self] (result) in
//            DispatchQueue.main.async { [self] in
//                if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
//                    Parameters.cloudDistribitionPoint = false
//                    userDefaults.set("directory", forKey: "packageSource")
//
//                    Parameters.listOption = false
//                    packagesFolderUrl = openPanel.url!
//
//                    WriteToLog.shared.message(stringOfText: "[selectFolder] packagesFolderUrl: \(String(describing: packagesFolderUrl))")
//                    
//                    localPath = packagesFolderUrl.path
//                    
//                    userDefaults.set("unmounted", forKey: "share")
//                   
//                    storeBookmark(theURL: openPanel.url!)
//                    
//                    performSegue(withIdentifier: "resourceType", sender: nil)
//                }
//            }
//        }
//    }
    
    func closeDpTypeWindow() {
        Task { @MainActor in
            updateRepoListDelegate?.updateRepoList()
            dismiss(self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
