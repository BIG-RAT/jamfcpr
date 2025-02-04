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
        performSegue(withIdentifier: "resourceType", sender: nil)
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
    }
    
    func closeDpTypeWindow() {
//        Task { @MainActor in
//            updateRepoListDelegate?.updateRepoList()
            dismiss(self)
//        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
