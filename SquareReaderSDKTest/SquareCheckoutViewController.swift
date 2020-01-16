//
//  SquareMobileAuthViewController.swift
//  dev
//
//  Created by Jonathan Cheng on 11/24/19.
//  Copyright © 2019 kios. All rights reserved.
//

import UIKit
import SquareReaderSDK

class SquareCheckoutViewController: UIViewController {
    
    var order: SquareOrder?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        authorizeReaderSDKIfNeeded() {
            self.startCheckout()
        }
    }
    
    func retrieveAuthorizationCode() -> String {
        
        var authCode: String?
        let group = DispatchGroup()
        group.enter()
        do {
            guard let locationID = order?.locationId else {
                showAlert(title: "Error", message: "No location for order")
                group.leave()
                return ""
            }
            
            let request = SquareMobileAuthorizationCodeCreateRequest(locationID: locationID)
            let data = try JSONEncoder().encode(request)
            try KiosApi.shared.call(endpoint: .sqApiMobileAuthCreate, httpBody: data, responseHandler: { (data, response, error) in
                
                guard let data = data,
                    let response = try? JSONDecoder().decode(SquareMobileAuthorizationCodeCreateResponse.self, from: data) else {
                        self.showAlert(title: "Error", message: "No Mobile Authorization")
                        group.leave()
                        return
                }
                authCode = response.authorizationCode
                group.leave()
            })
        } catch {
            showAlert(title: "Error", message: "\(error.localizedDescription)")
        }
        group.wait()
        return authCode!
    }
    
    func authorizeReaderSDKIfNeeded(_ completion: @escaping ()->()) {
        if SQRDReaderSDK.shared.isAuthorized {
            print("Already authorized.")
            completion()
        } else {
            let authCode = retrieveAuthorizationCode()
            print("authCode: \(authCode)")
            SQRDReaderSDK.shared.authorize(withCode: authCode) { _, error in
                if let authError = error {
                    // Handle the error
                    print(authError)
                } else {
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            }
        }
    }

    func startCheckout() {
        // Create a money amount in the currency of the authorized Square account
        guard let amount = order?.total_money?.amount else {
            print("No order")
            return
        }
        
        let amountMoney = SQRDMoney(amount: amount)
        
        // Create parameters to customize the behavior of the checkout flow.
        let params = SQRDCheckoutParameters(amountMoney: amountMoney)
        params.additionalPaymentTypes = [.cash]
        
        // Create a checkout controller and call present to start checkout flow.
        let checkoutController = SQRDCheckoutController(
            parameters: params,
            delegate: self
        )
        checkoutController.present(from: self)
    }
}

extension SquareCheckoutViewController: SQRDCheckoutControllerDelegate {
    
    func checkoutControllerDidCancel(_ controller: SQRDCheckoutController) {
        print("Checkout cancelled.")
    }
    
    func checkoutController(_ controller: SQRDCheckoutController, didFailWith error: Error) {
        // Checkout controller errors are always of type SQRDCheckoutControllerError
        let checkoutControllerError = error as! SQRDCheckoutControllerError
        
        switch checkoutControllerError.code {
        case .sdkNotAuthorized:
            // Checkout failed because the SDK is not authorized
            // with a Square merchant account.
            print("Error: SquareReaderSDK is not authorized.")
        case .usageError:
            // Checkout failed due to a usage error. Inspect the userInfo
            // dictionary for additional information.
            if let debugMessage = checkoutControllerError.userInfo[SQRDErrorDebugMessageKey],
                let debugCode = checkoutControllerError.userInfo[SQRDErrorDebugCodeKey] {
                print(debugCode, debugMessage)
            }
        default:
            print("Error: SquareReaderSDK \(error.localizedDescription)")
            
        }
        
        // Remove SQRDCheckoutController from view and show error
        DispatchQueue.main.async {
            self.presentedViewController?.dismiss(animated: false) { }
            self.navigationController?.popViewController(animated: false)
            self.showAlert(title: "Error", message: "Square Reader SDK error.")
        }
    }
    
    func checkoutController(_ controller: SQRDCheckoutController, didFinishCheckoutWith result: SQRDCheckoutResult) {
        print("Checkout completed: \(result.description).")

        DispatchQueue.main.async {
            if let vc = theStartingVc {
                self.navigationController?.popToViewController(vc, animated: true)
            }
        }
    }
}

