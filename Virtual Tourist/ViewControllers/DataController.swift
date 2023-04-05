//
//  DataController.swift
//  Virtual Tourist
//
//  Created by Jandrè Hattingh on 2022/02/21.
//

import Foundation
import CoreData
import UIKit

class DataController {
    var viewController = UIViewController()
    
    let persistentContainer:NSPersistentContainer
    
    var viewContext:NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init(modelName:String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            completion?()
        }
    }
    
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                viewController.showFailure(title: "Could not save images", message: "Could not save images")
            }
        }
    }
    
    func deleteImages(images: [CoreDataPhoto], pin: CoreDataPin) {
        let context = persistentContainer.viewContext
        for _ in images {
            let fetchRequest:NSFetchRequest<CoreDataPhoto> = CoreDataPhoto.fetchRequest()
            let predicate = NSPredicate(format: "pin == %@", pin)
            fetchRequest.predicate = predicate
            
            do {
                let result = try context.fetch(fetchRequest)
                guard let objectToDelete = result.first else {return}
                context.delete(objectToDelete)
                saveContext()
            } catch {
                viewController.showFailure(title: "Could not delete images", message: "Could not delete images")
            }
        }
    }
}
