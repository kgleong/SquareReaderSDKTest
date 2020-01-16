//
//  SquareReaderAuthorize.swift
//  SquareReaderSDKTest
//
//  Created by Jonathan Cheng on 1/16/20.
//  Copyright © 2020 kios. All rights reserved.
//

import SquareReaderSDK

struct SquareReaderAuthorize {
                    
    static func authorize(withCode code: String, onSuccess: @escaping((SQRDLocation)->()), onError: @escaping((SQRDAuthorizationError)->())) {
        // Authorize Reader SDK
        SQRDReaderSDK.shared.authorize(withCode: code) { location, error in
            if let authError = error as? SQRDAuthorizationError {
                SquareReaderAuthorize.printAuthorizationError(authError)
                onError(authError)
            } else if let location = location {
                print("Authorized Reader SDK to take payments for \(location.name)")
                onSuccess(location)
            }
        }
    }
    
    static func printAuthorizationError(_ error: SQRDAuthorizationError) {
        guard let debugCode = error.userInfo[SQRDErrorDebugCodeKey] as? String,
              let debugMessage = error.userInfo[SQRDErrorDebugMessageKey] as? String else { return }
        
        // Print the debug code and message
        print(debugCode)
        print(debugMessage)
    }
}
