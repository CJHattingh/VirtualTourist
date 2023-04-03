//
//  AppDelegate.swift
//  Virtual Tourist
//
//  Created by Jandrè Hattingh on 2022/02/18.
//

import UIKit
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    //let dataController = DataController(modelName: "Virtual_Tourist")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //dataController.load()
        //let navigationController = window?.rootViewController as! UINavigationController
        //let mapViewController = navigationController.topViewController as! MapViewController
        //mapViewController.dataController = dataController
        return true
    }
}

