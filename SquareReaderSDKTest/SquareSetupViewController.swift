//
//  SquareLoginViewController.swift
//  demo
//
//  Created by Jonathan Cheng on 11/26/19.
//  Copyright © 2019 kios. All rights reserved.
//

import UIKit
import AVFoundation
import CoreLocation
import Photos

class SquareSetupViewController: UIViewController {
    
    
    @IBOutlet weak var connectSquareButton: UIButton!
    @IBOutlet weak var connectLocationButton: UIButton!
    @IBOutlet weak var connectMicrophoneButton: UIButton!
    @IBOutlet weak var connectPhotosButton: UIButton!
    
    private lazy var locationManager = CLLocationManager()
    private let squareAuthVc = SquareAuthWebViewController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        connectSquareButton.addTarget(self, action: #selector(connectSquare(_:)), for: .touchUpInside)
        connectLocationButton.addTarget(self, action: #selector(connectLocation(_:)), for: .touchUpInside)
        connectMicrophoneButton.addTarget(self, action: #selector(connectMicrophone(_:)), for: .touchUpInside)
        connectPhotosButton.addTarget(self, action: #selector(connectPhotos(_:)), for: .touchUpInside)
        
        // The user may be directed to the Settings app to change their permissions.
        // When they return, update the button titles.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateMicrophoneButton),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updateLocationButton),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(updatePhotosButton),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        // Do these early so they are not displayed incorrectly
        updateSquareButton()
        updateLocationButton()
        updateMicrophoneButton()
        updatePhotosButton()
    }
   
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkPermissionsAndPush()
    }
        
    static var hasRequiredPermissions: Bool {
        let microphonePermission = (AVAudioSession.sharedInstance().recordPermission == .granted)
        let locationPermission = [.authorizedAlways, .authorizedWhenInUse].contains(CLLocationManager.authorizationStatus())
        let squarePermission = SquareSetupViewController.hasSquareAuthorization
        let photoPermission = PHPhotoLibrary.authorizationStatus() == .authorized
        
        return microphonePermission && locationPermission && squarePermission && photoPermission
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private func updateScreen() {
        print("Update permission screen")
        
        updateSquareButton()
        updateLocationButton()
        updateMicrophoneButton()
        updatePhotosButton()

        checkPermissionsAndPush()
    }
    
    private func checkPermissionsAndPush() {
        if SquareSetupViewController.hasRequiredPermissions {
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "SquareConnectViewController") as! SquareConnectViewController
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// MARK: - Square Authorization Request

extension SquareSetupViewController {
    @objc func connectSquare(_ sender: UIButton) {
        if sender == connectSquareButton {
            requestSquareAccess()
        }
    }
    
    func requestSquareAccess() {
        
        do {
            try KiosApi.shared.call(endpoint: .sqAuthLogin, responseHandler: { (data, response, error) in
                guard let data = data,
                    let response = try? JSONDecoder().decode(SquareAuthorizationResponse.self, from: data),
                    let urlString = response.url,
                    let url = URL(string: urlString) else {
                        self.showAlert(title: "Error", message: "Could not decode Square Authorization URL")
                        return
                }
                
                DispatchQueue.main.async {
                    self.squareAuthVc.delegate = self
                    self.squareAuthVc.modalPresentationStyle = .fullScreen
                    self.squareAuthVc.url = url
                    self.present(self.squareAuthVc, animated: true) { }
                }
                
            })
        } catch {
            showAlert(title: "Error", message: "\(error.localizedDescription)")
        }
    }
    
    func updateSquareButton() {
        let title: String
        let isEnabled: Bool
        
        if SquareSetupViewController.hasSquareAuthorization {
            title = "Square Enabled"
            isEnabled = false
        } else {
            title = "Authorize"
            isEnabled = true
        }
        
        connectSquareButton.setTitle(title, for: [])
        connectSquareButton.isEnabled = isEnabled
        connectSquareButton.backgroundColor = isEnabled ? UIColor.systemIndigo : nil
    }
    
    static var hasSquareAuthorization: Bool {
        var hasAuth = false
        
        let group = DispatchGroup()
        group.enter()
        
        do {
            try KiosApi.shared.call(endpoint: .sqAuthTry) { (data, response, error) in
                guard let data = data else {
                    print("Failed to check Square Authorization.  Invalid server response.")
                    group.leave()
                    return
                }
                guard let response = try? JSONDecoder().decode(SquareAuthorizationResponse.self, from: data) else {
                    print("Could not decode Square Authorization response.")
                    group.leave()
                    return
                }
                hasAuth = response.hasSquareAuth ?? false
                group.leave()
            }
        } catch {
            group.leave()
            print("Could not check Square Authorization. \(error.localizedDescription)")
        }
        
        group.wait()
        return hasAuth
    }
}

// MARK: - Square Web Auth Delegate

extension SquareSetupViewController: SquareAuthWebViewControllerDelegate {
    func squareAuthWebViewController(_ controller: SquareAuthWebViewController, success: Bool) {
        controller.dismiss(animated: true) {
            DispatchQueue.main.async {
                self.updateScreen()
            }
        }
    }
}

// MARK: - Location Permission Request

extension SquareSetupViewController: CLLocationManagerDelegate {
    
    @objc func connectLocation(_ sender: UIButton) {
        if sender == connectLocationButton {
            switch CLLocationManager.authorizationStatus() {
            case .denied, .restricted:
                openSettings()
            case .notDetermined:
                requestLocationAccess()
            case .authorizedAlways, .authorizedWhenInUse:
                return
            default:
                return
            }
        }
    }
    
    @objc func requestLocationAccess() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.updateScreen()
    }
    
    @objc func updateLocationButton() {
        let title: String
        let isEnabled: Bool
        
        switch CLLocationManager.authorizationStatus() {
        case .denied, .restricted:
            title = "Enable Location in Settings"
            isEnabled = true
        case .authorizedAlways, .authorizedWhenInUse:
            title = "Location Enabled"
            isEnabled = false
        case .notDetermined:
            title = "Enable Location Access"
            isEnabled = true
        default:
            return
        }
        
        connectLocationButton.setTitle(title, for: [])
        connectLocationButton.isEnabled = isEnabled
        connectLocationButton.backgroundColor = isEnabled ? UIColor.systemIndigo : nil
    }
}

// MARK: - Microphone Permission Request

extension SquareSetupViewController {
    
    @objc func connectMicrophone(_ sender: UIButton) {
        if sender == connectMicrophoneButton {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .denied:
                openSettings()
            case .undetermined:
                requestMicrophoneAccess()
            case .granted:
                return
            default:
                return
            }
        }
    }
    
    @objc func requestMicrophoneAccess() {
        AVAudioSession.sharedInstance().requestRecordPermission { _ in
            DispatchQueue.main.async {
                self.updateScreen()
            }
        }
    }
    
    @objc func updateMicrophoneButton() {
        let title: String
        let isEnabled: Bool
        
        switch AVAudioSession.sharedInstance().recordPermission {
        case .denied:
            title = "Enable Microphone in Settings"
            isEnabled = true
        case .granted:
            title = "Microphone Enabled"
            isEnabled = false
        case .undetermined:
            title = "Enable Microphone Access"
            isEnabled = true
        default:
            return
        }
        
        connectMicrophoneButton.setTitle(title, for: [])
        connectMicrophoneButton.isEnabled = isEnabled
        connectMicrophoneButton.backgroundColor = isEnabled ? UIColor.systemIndigo : nil
    }
}

// MARK: - Photos permissions

extension SquareSetupViewController {
    
    @objc func connectPhotos(_ sender: UIButton) {
        if sender == connectPhotosButton {
            switch PHPhotoLibrary.authorizationStatus() {
            case .authorized:
                return
            case .denied:
                openSettings()
            case .notDetermined:
                requestPhotosAccess()
            case .restricted:
                openSettings()
            default:
                return
            }
        }
    }
    
    @objc func updatePhotosButton() {
        let title: String
        let isEnabled: Bool

        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            title = "Photos Enabled"
            isEnabled = false
        case .denied:
            title = "Enable Photos in Settings"
            isEnabled = true
        case .notDetermined:
            title = "Enable Photos Access"
            isEnabled = true
        case .restricted:
            title = "Cannot enable Photos"
            isEnabled = true
        default:
            return
        }
        
        connectPhotosButton.setTitle(title, for: [])
        connectPhotosButton.isEnabled = isEnabled
        connectPhotosButton.backgroundColor = isEnabled ? UIColor.systemIndigo : nil

    }

    func requestPhotosAccess() {
        PHPhotoLibrary.requestAuthorization { (status) in
            DispatchQueue.main.async {
                self.updateScreen()
            }
        }
    }
}
