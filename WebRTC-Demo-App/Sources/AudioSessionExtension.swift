//
//  AVAudioSession+Extension.swift
//  RCCommon
//
//  Created by mario.lin on 2022/12/3.
//

import AVFoundation
import Foundation

private let AVAudioSessionHookTag = "AVAudioSessionHook"

func DLOG(_ tag: String, message: String) {
    print("why" + message)
}

var currentMode: AVAudioSession.Mode = .videoChat
var currentCagetory: AVAudioSession.Category = .playAndRecord
var cOptions: AVAudioSession.CategoryOptions = .allowBluetooth


var rate: Bool = false
var oooo: Bool = false

extension AVAudioSession {
    public class func swizzling() {
        
//        DispatchQueue.once("AVAudioSessionSwizzlingOnceToken") {
            AVAudioSession.swizzle(originalSel: #selector(AVAudioSession.setCategory(_:options:)),
                                   newSel: #selector(AVAudioSession.rc_setCategory(_:options:)))
            AVAudioSession.swizzle(originalSel: #selector(AVAudioSession.setCategory(_:mode:options:)),
                                   newSel: #selector(AVAudioSession.rc_setCategory(_:mode:options:)))
            AVAudioSession.swizzle(originalSel: #selector(AVAudioSession.setCategory(_:mode:policy:options:)),
                                   newSel: #selector(AVAudioSession.rc_setCategory(_:mode:policy:options:)))
            AVAudioSession.swizzle(originalSel: #selector(AVAudioSession.setMode(_:)),
                                   newSel: #selector(AVAudioSession.rc_setMode(_:)))
            AVAudioSession.swizzle(originalSel: #selector(AVAudioSession.setActive(_:options:)),
                                   newSel: #selector(AVAudioSession.rc_setActive(_:options:)))
        
        AVAudioSession.swizzle(originalSel: #selector(AVAudioSession.setPreferredInputNumberOfChannels(_:)),
                               newSel: #selector(AVAudioSession.rc_setPreferredInputNumberOfChannels(_:)))
        AVAudioSession.swizzle(originalSel: #selector(AVAudioSession.setPreferredOutputNumberOfChannels(_:)),
                               newSel: #selector(AVAudioSession.rc_setPreferredOutputNumberOfChannels(_:)))
        
        AVAudioSession.swizzle(originalSel: #selector(AVAudioSession.setPreferredSampleRate(_:)),
                               newSel: #selector(AVAudioSession.rc_setPreferredSampleRate(_:)))
        AVAudioSession.swizzle(originalSel: #selector(AVAudioSession.setPreferredIOBufferDuration(_:)),
                               newSel: #selector(AVAudioSession.rc_setPreferredIOBufferDuration(_:)))
//        }
    }
    @objc func rc_setPreferredSampleRate(_ count: Double) {
        print("why-rc_setPreferredSampleRate:\(count)")
        if rate {
            return
        }
        rate = true
        rc_setPreferredSampleRate(24000.0)
    }
    
    @objc func rc_setPreferredIOBufferDuration(_ count: TimeInterval) {
        print("why-rc_setPreferredIOBufferDuration:\(count)")
        if oooo {
            return
        }
        oooo = true
        rc_setPreferredIOBufferDuration(0.02)
    }
    
    @objc func rc_setPreferredInputNumberOfChannels(_ count: Int) {
        print("why-rc_setPreferredInputNumberOfChannels")
        rc_setPreferredInputNumberOfChannels(count)
    }
    
    @objc func rc_setPreferredOutputNumberOfChannels(_ count: Int) {
        print("why-rc_setPreferredOutputNumberOfChannels")
        rc_setPreferredOutputNumberOfChannels(count)
    }

    @objc
    func rc_setCategory(_ category: AVAudioSession.Category) {
        DLOG(AVAudioSessionHookTag, message: "current category1: \(self.category.rawValue), mode: \(mode) options: \(categoryOptions.rawValue)")
//        if category != currentCagetory || AVAudioSession.sharedInstance().categoryOptions != cOptions {
            rc_setCategory(category)
//        } else {
//            DLOG(AVAudioSessionHookTag, message: "-- return -- ")
//        }
        currentCagetory = category
        cOptions = AVAudioSession.sharedInstance().categoryOptions
        DLOG(AVAudioSessionHookTag, message: "set category1: \(category.rawValue)")
        logCallStack()
    }

    @objc
    func rc_setCategory(_ category: AVAudioSession.Category, options: AVAudioSession.CategoryOptions = []) {
        DLOG(AVAudioSessionHookTag, message: "current category2: \(self.category.rawValue), mode: \(mode) options: \(categoryOptions.rawValue)")
        
//        if category != currentCagetory || AVAudioSession.sharedInstance().categoryOptions != cOptions {
//            try? AVAudioSession.sharedInstance().setCategory(category)
//        rc_setCategory(category, options: options)
        if options.isEmpty {
//            try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, options: .defaultToSpeaker)
            try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .voiceChat, options: [.allowBluetooth, .defaultToSpeaker])
        }
        
//        } else {
//            DLOG(AVAudioSessionHookTag, message: "-- return -- ")
//        }
        currentCagetory = category
        cOptions = AVAudioSession.sharedInstance().categoryOptions
        
        DLOG(AVAudioSessionHookTag, message: "set category2: \(category.rawValue), options: \(options.rawValue)")
        logCallStack()
//        rc_setCategory(category, options: options)
//        rc_setCategory(category)
    }

    @objc
    func rc_setMode(_ mode: AVAudioSession.Mode) {
        DLOG(AVAudioSessionHookTag, message: "current category3: \(category.rawValue), mode: \(self.mode) options: \(categoryOptions.rawValue)")
//        if mode != currentMode {
//            rc_setMode(mode)
//        } else {
//            DLOG(AVAudioSessionHookTag, message: "-- return -- ")
//        }
        currentMode = mode
        DLOG(AVAudioSessionHookTag, message: "set mode3: \(mode.rawValue)")
        logCallStack()
    }

    @objc
    func rc_setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, options: AVAudioSession.CategoryOptions = []) {
        DLOG(AVAudioSessionHookTag, message: "current category: \(self.category.rawValue), mode: \(self.mode) options: \(categoryOptions.rawValue)")
        DLOG(AVAudioSessionHookTag, message: "set category: \(category.rawValue), mode: \(mode.rawValue), options: \(options.rawValue)")
        logCallStack()
        rc_setCategory(category, mode: mode, options: options)
    }

    @objc
    func rc_setCategory(_ category: AVAudioSession.Category, mode: AVAudioSession.Mode, policy: AVAudioSession.RouteSharingPolicy, options: AVAudioSession.CategoryOptions = []) {
        DLOG(AVAudioSessionHookTag, message: "current category: \(self.category.rawValue), mode: \(self.mode) options: \(categoryOptions.rawValue)")
        DLOG(AVAudioSessionHookTag, message: "set category: \(category.rawValue), mode: \(mode.rawValue), options: \(options.rawValue)")
        logCallStack()
        rc_setCategory(category, mode: mode, policy: policy, options: options)
    }

    @objc
    func rc_setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions = []) {
        DLOG(AVAudioSessionHookTag, message: "current category: \(category.rawValue), mode: \(mode) options: \(categoryOptions.rawValue)")
        DLOG(AVAudioSessionHookTag, message: "set setActive: \(active), options: \(options.rawValue)")
        logCallStack()
        rc_setActive(active, options: options)
    }

    static func swizzle(originalSel: Selector, newSel: Selector) {
        let originMethod = class_getInstanceMethod(self, originalSel)
        let swizzleMethod = class_getInstanceMethod(self, newSel)
        method_exchangeImplementations(originMethod!, swizzleMethod!)
    }

    func logCallStack() {
        let stackSymbols = Thread.callStackSymbols
        var string = ""
        for stack in stackSymbols {
            string = string + stack + "\n"
        }
        DLOG(AVAudioSessionHookTag, message: "thread: \(string)")
    }
}
