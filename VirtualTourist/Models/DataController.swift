//
//  DataController.swift
//  VirtualTourist
//
//  Created by Nguyen Quyet Thang on 11/8/24.
//

import Foundation
import CoreData

class DataController {
    let persistentContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    static let shared: DataController = DataController(modelName: "VirtualTourist")
    
    init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func load(completion: (() -> ())? = nil ) {
        persistentContainer.loadPersistentStores { (storesDescription, error) in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            completion?()
        }
    }
}
