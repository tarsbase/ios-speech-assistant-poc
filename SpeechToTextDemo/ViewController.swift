//
//  ViewController.swift
//  SpeechToTextDemo
//
//  Created by muhammad luqman on 10/05/2019.
//  Copyright © 2019 muhammad luqman. All rights reserved.

import UIKit
import AVFoundation
import Speech

class ViewController: UIViewController, VoiceOverlayDelegate, AVSpeechSynthesizerDelegate {
    
    let voiceOverlayController = VoiceOverlayController()
    let synthesizer = AVSpeechSynthesizer()
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var lblForTapToSpeak: UILabel!
    @IBOutlet weak var gradientView: UIView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        textView.text = "How may i help you.?"
        textView.font = UIFont.boldSystemFont(ofSize: 14)
        voiceOverlayController.delegate = self
        self.lblForTapToSpeak.isHidden = true
        
        let colorTop = hexStringToUIColor(hex: "00537E").cgColor
        let colorBottom = hexStringToUIColor(hex: "3AA17E").cgColor
        makeGradientView(view: self.gradientView, colorTop: colorTop, colorBottom: colorBottom)
        
        synthesizer.delegate = self
        
        // speech permissions
        Timer.scheduledTimer(withTimeInterval: 0.50, repeats: false, block: { (_) in
            
            switch SFSpeechRecognizer.authorizationStatus() {
            case .authorized:
                self.textToSpeech(text: "How may i help you.?")
                break
            case .denied, .restricted:
                self.showRecordingView()
                break
            case .notDetermined:
                self.showRecordingView()
                break
            }
        })
    }
    
    func topOnButton(text: String){
        
        self.textView.text = text
    }
    
    @objc func showRecordingView() {
        
        // First way to listen to recording through callbacks
        self.lblForTapToSpeak.isHidden = false
        self.textView.text = ""
        
        // If you want to start recording as soon as modal view pops up, change to true
        voiceOverlayController.settings.autoStart = false
        voiceOverlayController.settings.autoStop = true
        voiceOverlayController.settings.showResultScreen = false
        voiceOverlayController.settings.autoStopTimeout = 1.5
        
        voiceOverlayController.start(on: self, textHandler: { (text, final) in
            
            if final {
                if(text.count>0){
                    // here can process the result to post in a result screen
                    Timer.scheduledTimer(withTimeInterval: 0.50, repeats: false, block: { (_) in
                        self.voiceOverlayController.removeFromSuperView(viewContr: self.voiceOverlayController.recordingViewController!)
                        self.lblForTapToSpeak.isHidden = true
                        self.voiceOverlayController.recordingViewController?.speechController?.stopRecording()
                        self.textToSpeech(text: text)
                        
                        print("callback: getting \(String(describing: text))")
                    })
                }
            }
        }, errorHandler: { (error) in
            print("callback: error \(String(describing: error))")
        }, resultScreenHandler: { (text) in
            print("Result Screen: \(text)")
        })
    }
    
    // Second way to listen to recording through delegate
    func recording(text: String?, final: Bool?, error: Error?) {
        
        if let error = error {
            print("delegate: error \(error)")
        }
        if error == nil {
            if((text?.count)!>0){
                self.textView.text = text
            }
        }
    }
    
    func textToSpeech(text: String) {
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
        } catch let error as NSError {
            print("audioSession error: \(error.localizedDescription)")
        }
        
        print(text)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en_US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        utterance.volume = 1
        synthesizer.speak(utterance)
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        
        print("all done")
        showRecordingView()
    }
    
    func makeGradientView(view:UIView, colorTop:CGColor, colorBottom:CGColor) {
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [ colorTop, colorBottom]
        gradientLayer.locations = [ 0.0, 1.0]
        gradientLayer.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        view.layer.addSublayer(gradientLayer)
        
    }
    
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    func reverseWords(s: String) -> String {
        
        var newS: String = ""
        var bufferS: String = ""
        func joinBufferS() {
            if !bufferS.isEmpty {
                let midS = newS.isEmpty ? "" : " "
                newS = bufferS + midS + newS
                bufferS = ""
            }
        }
        for c in s {
            if String(c) == " " {
                joinBufferS()
            } else {
                bufferS += String(c)
            }
        }
        joinBufferS()
        return newS
    }
}
