//
//  ViewController.swift
//  WebRTC
//
//  Created by Stasel on 20/05/2018.
//  Copyright © 2018 Stasel. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import WebRTC
import Combine

class MainViewController: UIViewController {

    private let callController: CallController
    private lazy var videoViewController = VideoViewController(webRTCClient: self.callController.webRTCClient)
    
    @IBOutlet private weak var speakerButton: UIButton?
    @IBOutlet private weak var signalingStatusLabel: UILabel?
    @IBOutlet private weak var localSdpStatusLabel: UILabel?
    @IBOutlet private weak var localCandidatesLabel: UILabel?
    @IBOutlet private weak var remoteSdpStatusLabel: UILabel?
    @IBOutlet private weak var remoteCandidatesLabel: UILabel?
    @IBOutlet private weak var muteButton: UIButton?
    @IBOutlet private weak var webRTCStatusLabel: UILabel?
    @IBOutlet weak var outgoingCallButton: UIButton!
    @IBOutlet weak var incomingCallButton: UIButton!
    
    private var signalingConnected: Bool = false {
        didSet {
            DispatchQueue.main.async {
                if self.signalingConnected {
                    self.signalingStatusLabel?.text = "Connected"
                    self.signalingStatusLabel?.textColor = UIColor.green
                }
                else {
                    self.signalingStatusLabel?.text = "Not connected"
                    self.signalingStatusLabel?.textColor = UIColor.red
                }
            }
        }
    }
    
    private var hasLocalSdp: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.localSdpStatusLabel?.text = self.hasLocalSdp ? "✅" : "❌"
            }
        }
    }
    
    private var localCandidateCount: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                self.localCandidatesLabel?.text = "\(self.localCandidateCount)"
            }
        }
    }
    
    private var hasRemoteSdp: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.remoteSdpStatusLabel?.text = self.hasRemoteSdp ? "✅" : "❌"
            }
        }
    }
    
    private var remoteCandidateCount: Int = 0 {
        didSet {
            DispatchQueue.main.async {
                self.remoteCandidatesLabel?.text = "\(self.remoteCandidateCount)"
            }
        }
    }
    
    private var speakerOn: Bool = false {
        didSet {
            let title = "Speaker: \(self.speakerOn ? "On" : "Off" )"
            self.speakerButton?.setTitle(title, for: .normal)
        }
    }
    
    private var mute: Bool = false {
        didSet {
            let title = "Mute: \(self.mute ? "on" : "off")"
            self.muteButton?.setTitle(title, for: .normal)
        }
    }
    
    init(callController: CallController) {
        self.callController = callController
        super.init(nibName: String(describing: MainViewController.self), bundle: Bundle.main)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private var cancelable = Set<AnyCancellable>()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "WebRTC Demo"
        
        callController.$signalingConnected
            .assign(to: \.signalingConnected, on: self)
            .store(in: &cancelable)
        callController.$hasLocalSdp
            .assign(to: \.hasLocalSdp, on: self)
            .store(in: &cancelable)
        callController.$hasRemoteSdp
            .assign(to: \.hasRemoteSdp, on: self)
            .store(in: &cancelable)
        callController.$localCandidateCount
            .assign(to: \.localCandidateCount, on: self)
            .store(in: &cancelable)
        callController.$remoteCandidateCount
            .assign(to: \.remoteCandidateCount, on: self)
            .store(in: &cancelable)
        callController.$webRTCStatusLabel.sink { [weak self] text in
            self?.webRTCStatusLabel?.text = text
        }.store(in: &cancelable)
        callController.$webRTCStatusLabel.assign(to: \.text, on: self.webRTCStatusLabel!).store(in: &cancelable)
        callController.$webRTCStatusColor.assign(to: \.textColor, on: self.webRTCStatusLabel!).store(in: &cancelable)
        callController.$dataReceived
            .filter{ $0 != nil }
            .sink { [weak self] message in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Message from WebRTC", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
        }.store(in: &cancelable)
        
        callManager.$calls.sink { [weak self] calls in
            if let call = calls.first {
                if call.hasStartedConnecting || call.hasConnected || !call.hasEnded {
                    self?.incomingCallButton.setTitle(call.isOnHold ? "Hold" : "Unhold", for: .normal)
                    self?.outgoingCallButton.setTitle("End", for: .normal)
                } else {
                    self?.incomingCallButton.setTitle("Incoming Call", for: .normal)
                    self?.outgoingCallButton.setTitle("Outgoing Call", for: .normal)
                }
            } else {
                self?.incomingCallButton.setTitle("Incoming Call", for: .normal)
                self?.outgoingCallButton.setTitle("Outgoing Call", for: .normal)
            }
        }.store(in: &cancelable)
        
        AudioSession.shared.$currentRoute.sink { [weak self] route in
            self?.speakerButton?.setTitle(route?.rawValue, for: .normal)
        }.store(in: &cancelable)
        AudioSession.shared.configureAudioSession()
        
        self.callController.connect()
    }

    @IBAction func incomingCallDidTap(_ sender: UIButton) {
        if let call = callManager.calls.first {
            callManager.setOnHoldStatus(for: call, to: !call.isOnHold)
        } else {
            let uuid = callController.uuid
            AppDelegate.shared.displayIncomingCall(uuid: uuid, handle: "Tim Cook")
        }
    }
    
    @IBAction func outgoingCallDidTap(_ sender: UIButton) {
        if let call = callManager.calls.first {
            callManager.end(call: call)
        } else {
            callManager.startCall(handle: "Nelson", video: true)
        }
    }

    @IBAction private func offerDidTap(_ sender: UIButton) {
        callController.offer()
    }
    
    @IBAction private func answerDidTap(_ sender: UIButton) {
        callController.answer()
    }
    
    private var routePicker: AVRoutePickerView?
    @IBAction private func speakerDidTap(_ sender: UIButton) {
        if routePicker != nil {
            routePicker?.removeFromSuperview()
        }
        let picker = AVRoutePickerView()
        picker.alpha = 0.0
        routePicker = picker
        sender.addSubview(picker)
        if let btn = picker.subviews.last as? UIButton {
            btn.sendActions(for: [.touchUpInside])
        }
    }
    
    @IBAction private func videoDidTap(_ sender: UIButton) {
        self.present(videoViewController, animated: true, completion: nil)
    }
    
    @IBAction private func muteDidTap(_ sender: UIButton) {
        self.mute = !self.mute
        if let call = callManager.calls.first {
            callManager.setMuteStatus(for: call, to: mute)
        } else {
            callController.muteAudio(mute)
        }
    }
    
    @IBAction func sendDataDidTap(_ sender: UIButton) {
        let alert = UIAlertController(title: "Send a message to the other peer",
                                      message: "This will be transferred over WebRTC data channel",
                                      preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Message to send"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { [weak self, unowned alert] _ in
            guard let dataToSend = alert.textFields?.first?.text?.data(using: .utf8) else {
                return
            }
            self?.callController.sendData(dataToSend)
        }))
        self.present(alert, animated: true, completion: nil)
    }
}


