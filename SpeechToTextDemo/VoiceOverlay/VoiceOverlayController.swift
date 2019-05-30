//
//  VoiceOverlayController.swift
//  VoiceOverlay
//
//  Created by Guy Daher on 25/06/2018.
//  Copyright © 2018 Algolia. All rights reserved.
//

import Foundation
import UIKit
import Speech

/// Controller that takes care of launching a voice overlay and providing handlers to listen to text and error events.
@objc public class VoiceOverlayController: NSObject {
    
    let permissionViewController = PermissionViewController()
    let noPermissionViewController = NoPermissionViewController()
    let speechController = SpeechController()
    public weak var delegate: VoiceOverlayDelegate?
    var speechTextHandler: SpeechTextHandler?
    var speechErrorHandler: SpeechErrorHandler?
    var speechResultScreenHandler: SpeechResultScreenHandler?
  
    public var settings: VoiceUISettings = VoiceUISettings()
    var recordingViewController: RecordingViewController? = RecordingViewController()
  
    public var datasource: Any? = nil
  
    public override init() {
        super.init()
    }
    
    @objc public func start(on viewContr: UIViewController, textHandler: @escaping SpeechTextHandler, errorHandler: @escaping SpeechErrorHandler, resultScreenHandler: SpeechResultScreenHandler? = nil) {
        
        self.speechTextHandler = textHandler
        self.speechErrorHandler = errorHandler
        self.speechResultScreenHandler = resultScreenHandler
        
        checkPermissionsAndRedirectToCorrectScreen(viewContr)
        
        permissionViewController.dismissHandler = { [weak self] in
            self?.checkPermissionsAndRedirectToCorrectScreen(viewContr)
        }
        
        noPermissionViewController.dismissHandler = { [weak self] in
            if SFSpeechRecognizer.authorizationStatus() == .authorized {
                self?.checkPermissionsAndRedirectToCorrectScreen(viewContr)
            }
        }
    }
    
    fileprivate func checkPermissionsAndRedirectToCorrectScreen(_ view: UIViewController) {
        
        // Audio/Record permissions
        switch AVAudioSession.sharedInstance().recordPermission {
        case AVAudioSession.RecordPermission.granted:
            // If audio/record permission is granted, we need to check for the speech permission next
            checkSpeechAuthorizationStatusAndRedirectToCorrectScreen(view)
        case AVAudioSession.RecordPermission.denied:
            showNoPermissionScreen(view)
        case AVAudioSession.RecordPermission.undetermined:
            showPermissionScreen(view)
        }
    }
    
    fileprivate func checkSpeechAuthorizationStatusAndRedirectToCorrectScreen(_ view: UIViewController) {
        
        // speech permissions
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            showRecordingScreen(view)
        case .denied, .restricted:
            showNoPermissionScreen(view)
        case .notDetermined:
            showPermissionScreen(view)
        }
    }
    
    fileprivate func showPermissionScreen(_ view: UIViewController) {
        
        permissionViewController.speechController = speechController
        permissionViewController.constants = settings.layout.permissionScreen
        view.present(permissionViewController, animated: true)
    }
    
    fileprivate func showNoPermissionScreen(_ view: UIViewController) {
        
        noPermissionViewController.constants = settings.layout.noPermissionScreen
        view.present(noPermissionViewController, animated: true)
    }
    
    fileprivate func showRecordingScreen(_ viewContr: UIViewController) {
        
        recordingViewController = RecordingViewController()
        guard let controller = recordingViewController else { return }
        controller.delegate = delegate
        controller.speechTextHandler = speechTextHandler
        controller.speechErrorHandler = speechErrorHandler
        controller.speechResultScreenHandler = speechResultScreenHandler
        controller.speechController = SpeechController()
        controller.constants = settings.layout.recordingScreen
        controller.settings = settings
        
        controller.dismissHandler = { [unowned self] (retry) in
            self.recordingViewController = nil
            if retry {
                self.showRecordingScreen(viewContr)
            }
        }
        
        viewContr.addChild(controller)
        controller.view.frame = CGRect(x: 0, y: (viewContr.view.frame.height - 250), width: viewContr.view.frame.width, height: 250)
        controller.view.backgroundColor = UIColor.clear
        viewContr.view.addSubview((controller.view)!)
        controller.didMove(toParent: viewContr)
        
        //view.present(recordingViewController, animated: true)
    }
    
    func removeFromSuperView(viewContr: UIViewController) {
        
        viewContr.willMove(toParent: nil)
        viewContr.view.removeFromSuperview()
        viewContr.removeFromParent()
    }
}

public protocol VoiceOverlayDelegate: class {
    func recording(text: String?, final: Bool?, error: Error?)
}
