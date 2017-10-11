//
//  DrawSubSetting+CoreDataProperties.swift
//  
//
//  Created by Jakub on 03.09.2017.
//
//

import Foundation
import CoreData


extension DrawSubSetting {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DrawSubSetting> {
        return NSFetchRequest<DrawSubSetting>(entityName: "DrawSubSetting")
    }

    @NSManaged public var itemsToDraw: Int64
    @NSManaged public var name: String?
    @NSManaged public var category: Category?
    @NSManaged public var subCategory: SubCategory?
    @NSManaged public var items: NSSet?

}

// MARK: Generated accessors for items
extension DrawSubSetting {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: Item)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: Item)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}
