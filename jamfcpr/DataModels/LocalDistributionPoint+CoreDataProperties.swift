//
//  LocalDistributionPoint+CoreDataProperties.swift
//  jamfcpr
//
//  Created by Leslie Helou on 1/27/24.
//  Copyright © 2024 jamf. All rights reserved.
//
//

import Foundation
import CoreData


extension LocalDistributionPoint {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocalDistributionPoint> {
        return NSFetchRequest<LocalDistributionPoint>(entityName: "LocalDistributionPoint")
    }

    @NSManaged public var owner: NSObject?
    @NSManaged public var id: NSObject?
    @NSManaged public var name: NSObject?
    @NSManaged public var ip_address: NSObject?
    @NSManaged public var is_master: NSObject?
    @NSManaged public var connection_type: NSObject?
    @NSManaged public var share_name: NSObject?
    @NSManaged public var workgroup_or_domain: NSObject?
    @NSManaged public var share_port: NSObject?
    @NSManaged public var read_write_username: NSObject?

}

extension LocalDistributionPoint : Identifiable {

}
