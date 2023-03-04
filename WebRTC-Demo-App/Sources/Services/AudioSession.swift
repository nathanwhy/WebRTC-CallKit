//
//  AudioSession.swift
//  WebRTC-Demo
//
//  Created by nelson.wu on 2023/2/21.
//  Copyright © 2023 Stas Seldin. All rights reserved.
//

import Foundation
import WebRTC

enum Route: String {
    case speaker = "Speaker", builtIn = "BuiltIn", headphone = "Headphone", bluetooth = "Bluetooth"
}

class AudioSession {
    static let shared: AudioSession = AudioSession()
    private let audioQueue = DispatchQueue(label: "audio")
    
    private var rtcAudioSession: RTCAudioSession {
        return RTCAudioSession.sharedInstance()
    }
    var useMunualAudio: Bool {
        set {
            rtcAudioSession.useManualAudio = newValue
        }
        get {
            return rtcAudioSession.useManualAudio
        }
    }
    var isAudioEnabled: Bool {
        set {
            rtcAudioSession.isAudioEnabled = newValue
        }
        get {
            return rtcAudioSession.isAudioEnabled
        }
    }
    
    @Published var currentRoute: Route?
    
    init() {
        setup()
    }
    
    func setup() {
        NotificationCenter.default.addObserver(self, selector: #selector(routeChangeNotification(_:)), name: AVAudioSession.routeChangeNotification, object: nil)
        loadAudioRoute()
    }
    
    
    func configureAudioSession() {
        audioQueue.async {
            self._configureAudioSession()
        }
    }
    
    func loadAudioRoute() {
        audioQueue.async {
            let outputs = AVAudioSession.sharedInstance().currentRoute.outputs.last!
            var route = Route.builtIn
            switch outputs.portType {
            case .builtInSpeaker:
                route = .speaker
            case .bluetoothA2DP, .bluetoothLE, .bluetoothHFP:
                route = .bluetooth
            case .headphones, .headsetMic:
                route = .headphone
            default: break
            }
            DispatchQueue.main.async {
                self.currentRoute = route
            }
        }
    }
    
    private func _configureAudioSession() {
        self.rtcAudioSession.lockForConfiguration()
        do {
            // Using voiceChat has the side effect of enabling the allowBluetooth category option.
            // CallKit will activate audio session
            let config = RTCAudioSessionConfiguration.current()
            config.category = AVAudioSession.Category.playAndRecord.rawValue
            config.categoryOptions = []
            config.mode = AVAudioSession.Mode.voiceChat.rawValue
            try self.rtcAudioSession.setConfiguration(config)
        } catch let error {
            debugPrint("Error changeing AVAudioSession category: \(error)")
        }
        self.rtcAudioSession.unlockForConfiguration()
    }

    func didActivate(_ audioSession: AVAudioSession) {
        RTCAudioSession.sharedInstance().audioSessionDidActivate(audioSession)
    }

    func didDeactivate(_ audioSession: AVAudioSession) {
        RTCAudioSession.sharedInstance().audioSessionDidDeactivate(audioSession)
    }
    
    @objc func routeChangeNotification(_ notification: NSNotification) {
        loadAudioRoute()
        let dic = notification.userInfo as? [String: AnyObject]
        let num = dic?[AVAudioSessionRouteChangeReasonKey] as? NSNumber
        guard let num = num else { return }
        let reason = AVAudioSession.RouteChangeReason(rawValue: num.uintValue)
        print("routeChangeNotification:\(String(describing: reason))")
    }
}
