//
//  AppDelegate.swift
//  SquareReaderSDKTest
//
//  Created by Jonathan Cheng on 1/15/20.
//  Copyright © 2020 kios. All rights reserved.
//

import UIKit
import SquareReaderSDK

extension UIApplication {
    var applicationStateString: String {
        switch applicationState {
        case .active:
            return "Active"
        case .background:
            return "Background"
        case .inactive:
            return "Inactive"
        @unknown default:
            fatalError()
        }
    }
}

@available(iOS 13.0, *)
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        print("App Delegate didFinishLaunchinWithOptions applicationState: \(UIApplication.shared.applicationStateString)")

        SQRDReaderSDK.initialize(applicationLaunchOptions: launchOptions)

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        print("App Delegate configurationForConnecting:connectingSceneSession: applicationState: \(UIApplication.shared.applicationStateString)")
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

