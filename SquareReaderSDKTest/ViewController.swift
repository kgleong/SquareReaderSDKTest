//
//  ViewController.swift
//  SquareReaderSDKTest
//
//  Created by Jonathan Cheng on 1/15/20.
//  Copyright © 2020 kios. All rights reserved.
//

import UIKit
import SquareReaderSDK

class ViewController: UIViewController {
    
    var currentViewController: UIViewController? {
        return children.first
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // The user may be directed to the Settings app to change their permissions.
        // When they return, update the current screen.
        NotificationCenter.default.addObserver(self, selector: #selector(updateScreen), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @objc internal func updateScreen() {
        let permissionsGranted = PermissionsViewController.areRequiredPermissionsGranted
        let readerSDKAuthorized = SQRDReaderSDK.shared.isAuthorized

        if !permissionsGranted {
            let permissionsViewController = PermissionsViewController()
            permissionsViewController.delegate = self
            show(viewController: permissionsViewController)
        } else if !readerSDKAuthorized {
            //Authorize SDK
            let code = "sq0acp-66GXz9TkJs6ZR76jUr2FYJk4Jg_g-M9nwyWhjG5YJ2U"
            SquareReaderAuthorize.authorize(withCode: code,
                                            onSuccess: { (location) in self.onAuthorizeSuccess(location: location)},
                                            onError: { (error) in self.onAuthorizeFail(error: error) })
        } else {
            let payViewController = PayViewController()
//            payViewController.delegate = self
            show(viewController: payViewController)
        }
    }
    
    func onAuthorizeSuccess(location: SQRDLocation) {
        DispatchQueue.main.async {
                self.updateScreen()
        }
    }
    
    func onAuthorizeFail(error: SQRDAuthorizationError) {
        
    }
    
}

extension ViewController: PermissionsViewControllerDelegate {
    func permissionsViewControllerDidObtainRequiredPermissions(_ permissionsViewController: PermissionsViewController) {
        updateScreen()
    }
}

// MARK: - Transitions
extension ViewController {
    /// Show the provided view controller
    public func show(viewController newViewController: UIViewController) {
        // If we're already displaying a view controller, transition to the new one.
        if let oldViewController = currentViewController,
            type(of: newViewController) != type(of: oldViewController) {
            transition(from: oldViewController, to: newViewController)
            
        } else if currentViewController == nil {
            // Add the view controller as a child view controller
            addChild(newViewController)
            newViewController.view.frame = view.bounds
            view.addSubview(newViewController.view)
            newViewController.didMove(toParent: self)
        }
    }
    
    /// Transition from one child view controller to another
    private func transition(from fromViewController: UIViewController, to toViewController: UIViewController) {
        // Remove any leftover child view controllers
        children.forEach { (childViewController) in
            if childViewController != fromViewController {
                childViewController.willMove(toParent: nil)
                childViewController.view.removeFromSuperview()
                childViewController.removeFromParent()
            }
        }
        
        addChild(toViewController)
        fromViewController.willMove(toParent: nil)
    
        toViewController.view.alpha = 0
        toViewController.view.layoutIfNeeded()
        
        let animations = {
            fromViewController.view.alpha = 0
            toViewController.view.alpha = 1
        }
        
        let completion: (Bool) -> Void = { _ in
            fromViewController.view.removeFromSuperview()
            fromViewController.removeFromParent()
            toViewController.didMove(toParent: self)
        }
        
        transition(from: fromViewController,
                   to: toViewController,
                   duration: 0.25,
                   options: [],
                   animations: animations,
                   completion: completion)
    }
}
