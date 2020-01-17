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
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        print("App Delegate didFinishLaunchinWithOptions applicationState: \(UIApplication.shared.applicationStateString)")

        SQRDReaderSDK.initialize(applicationLaunchOptions: launchOptions)

        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = SampleApp.backgroundColor
        window.rootViewController = ViewController()
        window.makeKeyAndVisible()
        self.window = window

        return true
    }

}

