//
//  AppDelegate.swift
//  TestCart
//
//  Created by Yannick Heinrich on 07.06.17.
//  Copyright © 2017 yageek. All rights reserved.
//

import UIKit
import CoreData
import XCGLogger

let Log = XCGLogger.default

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        // API Key
        API.Key = "MY_API_KEY"
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        Store.shared.saveContext()
    }
}
