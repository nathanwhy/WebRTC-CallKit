//
//  CallController.swift
//  WebRTC-Demo
//
//  Created by nelson.wu on 2023/2/21.
//  Copyright © 2023 Stas Seldin. All rights reserved.
//

import UIKit
import WebRTC

class CallController: NSObject {
    static let shared: CallController = CallController()
    let signalClient: SignalingClient
    let webRTCClient: WebRTCClient
    let uuid: UUID = UUID()
    
    @Published var signalingConnected: Bool = false
    @Published var hasLocalSdp: Bool = false
    @Published var localCandidateCount: Int = 0
    @Published var hasRemoteSdp: Bool = false
    @Published var remoteCandidateCount: Int = 0
    @Published var speakerOn: Bool = false
    @Published var mute: Bool = false
    @Published var webRTCStatusLabel: String? = "New"
    @Published var webRTCStatusColor: UIColor = UIColor.black
    @Published var dataReceived: String?
    
    override init() {
        let config = Config.default
        let webSocketProvider = NativeWebSocket(url: config.signalingServerUrl)
        self.signalClient = SignalingClient(webSocket: webSocketProvider)
        self.webRTCClient = WebRTCClient(iceServers: config.webRTCIceServers)
        super.init()
    }
    
    // MARK: WebRTC
    
    func connect() {
        webRTCClient.delegate = self
        signalClient.delegate = self
        signalClient.connect()
    }
    
    func offer() {
        webRTCClient.offer { [weak self] (sdp) in
            self?.hasLocalSdp = true
            self?.signalClient.send(sdp: sdp)
        }
    }
    
    func answer() {
        webRTCClient.answer { [weak self] (localSdp) in
            self?.hasLocalSdp = true
            self?.signalClient.send(sdp: localSdp)
        }
    }
    
    func sendData(_ dataToSend: Data) {
        webRTCClient.sendData(dataToSend)
    }

    func muteAudio(_ mute: Bool) {
        if mute {
            webRTCClient.muteAudio()
        } else {
            webRTCClient.unmuteAudio()
        }
    }
}

extension CallController: SignalClientDelegate {
    func signalClientDidConnect(_ signalClient: SignalingClient) {
        self.signalingConnected = true
    }
    
    func signalClientDidDisconnect(_ signalClient: SignalingClient) {
        self.signalingConnected = false
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveRemoteSdp sdp: RTCSessionDescription) {
        print("Received remote sdp")
        self.webRTCClient.set(remoteSdp: sdp) { (error) in
            self.hasRemoteSdp = true
        }
    }
    
    func signalClient(_ signalClient: SignalingClient, didReceiveCandidate candidate: RTCIceCandidate) {
        self.webRTCClient.set(remoteCandidate: candidate) { error in
            print("Received remote candidate")
            self.remoteCandidateCount += 1
        }
    }
}

extension CallController: WebRTCClientDelegate {
    func webRTCClient(_ client: WebRTCClient, didDiscoverLocalCandidate candidate: RTCIceCandidate) {
        print("discovered local candidate")
        self.localCandidateCount += 1
        self.signalClient.send(candidate: candidate)
    }
    
    func webRTCClient(_ client: WebRTCClient, didChangeConnectionState state: RTCIceConnectionState) {
        let textColor: UIColor
        switch state {
        case .connected, .completed:
            textColor = .green
        case .disconnected:
            textColor = .orange
        case .failed, .closed:
            textColor = .red
        case .new, .checking, .count:
            textColor = .black
        @unknown default:
            textColor = .black
        }
        DispatchQueue.main.async {
            self.webRTCStatusLabel = state.description.capitalized
            self.webRTCStatusColor = textColor
        }
    }
    
    func webRTCClient(_ client: WebRTCClient, didReceiveData data: Data) {
        dataReceived = String(data: data, encoding: .utf8) ?? "(Binary: \(data.count) bytes)"
    }
}

