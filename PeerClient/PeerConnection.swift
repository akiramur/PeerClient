//
//  PeerConnection.swift
//  PeerClient
//
//  Created by Akira Murao on 10/16/15.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation
import libjingle_peerconnection

public protocol PeerConnectionDelegate {
    func connection(connection: PeerConnection, shouldSendMessage message: [String: Any], type: String)
    func connection(connection: PeerConnection, didReceiveRemoteStream stream: RTCMediaStream?)
    func connection(connection: PeerConnection, didClose error: Error?)

    func connection(connection: PeerConnection, didReceiveData data: Data)
}

enum PeerConnectionError: Error {
    case invalidState
    case creatingDataChannel
}

public class PeerConnection: NSObject {

    public enum ConnectionType {
        case media
        case data

        public var string: String {
            switch self {
            case .media:
                return "media"
            case .data:
                return "data"
            }
        }

        var prefix: String {
            switch self {
            case .media:
                return "mc_"
            case .data:
                return "dc_"
            }
        }
    }

    var delegate: PeerConnectionDelegate?
    var closeCompletionBlock: ((Error?) -> Void)?

    public private(set) var peerId: String

    public var connectionId: String {
        get {
            return self.options.connectionId
        }
    }

    public var connectionType: PeerConnection.ConnectionType {
        get {
            return self.options.connectionType
        }
    }

    var pc: RTCPeerConnection? {
        didSet {
            print("PeerConnection pc: \(String(describing: self.pc))")
        }
    }
    var isOpen: Bool

    var options: PeerConnectionOptions

    var lostMessages: [[String: Any]]
    var negotiator: Negotiator

    /*
    options = @{
    @"connectionId": connectionId,
    @"payload": payload,
    @"metadata": metadata}
    */
    init(peerId: String?, delegate: PeerConnectionDelegate?, options: PeerConnectionOptions) {

        //EventEmitter.call(this);  // lets move this to public method call

        self.delegate = delegate

        self.peerId = peerId ?? ""
        self.pc = nil
        self.isOpen = false

        self.options = options

        self.lostMessages = [[String: Any]]()
        self.negotiator = Negotiator()

        super.init()
        
        // lets call this in subclasses
        //self.startConnection(options)
    }
    
    func close(_ completion: @escaping (Error?) -> Void) {
        
        print("PeerConnection close() \(self.options.connectionId)")

        guard self.closeCompletionBlock == nil else {
            print("ERROR: closeCompletionBlock already exists. something went wrong.")
            return
        }
        
        if !self.isOpen {
            completion(PeerConnectionError.invalidState)
            return
        }

        self.closeCompletionBlock = completion
        
        self.isOpen = false
        if let pc = self.pc {
            self.negotiator.stopConnection(pc: pc)
        }
        self.pc = nil
        //this.emit('close')

        // MEMO: let's call this in iceConnectionChanged: RTCICEConnectionClosed
        //DispatchQueue.main.async {
        //    self.delegate?.connectionDidClose(connection: self)
        //}
    }

    // from Negotiator
    func handleLostMessages() {
        // Find messages.
        let messages = self.getMessages()
        for message in messages {
            self.handleMessage(message: message)
        }
    }
    
    func storeMessage(message: [String: Any]) {
        self.lostMessages.append(message)
    }
    
    func getMessages() -> [[String: Any]] {
        
        let messages = self.lostMessages
        self.lostMessages.removeAll()
        
        return messages
    }
    
    func handleMessage(message: [String: Any]) {
        print("handleMessage")

        guard let pc = self.pc else {
            print("ERROR: pc does't exist")
            return
        }

        guard let payload = message["payload"] as? [String: Any] else {
            print("ERROR: payload doesn't exist")
            return
        }

        guard let type = message["type"] as? String else {
            print("ERROR: type doesn't exist")
            return
        }
        print("TYPE: \(type)")

        // "OFFER", "ANSWER", "CANDIDATE"
        switch type {
        case "ANSWER":
            if let browser = payload["browser"] as? String {
                self.options.browser = browser
            }

            if let sdp = payload["sdp"] as? [String: Any] {
                self.negotiator.handleSDP(pc, peerId: self.peerId, type: "answer", message: sdp, options: self.options, completion: { [weak self] (result) in

                    switch result {
                    case let .success(message):
                        if let sself = self {
                            sself.delegate?.connection(connection: sself, shouldSendMessage: message, type: "offer")
                        }

                    case let .failure(error):
                        print("Error: something went wrong in handleSDP \(error)")
                        return
                    }
                })
                self.isOpen = true
            }

        case "CANDIDATE":
            if let candidate = payload["candidate"] as? [String: Any] {
                self.negotiator.handleCandidate(pc, message: candidate)
            }

        default:
            print("WARNING: Unrecognized message type: \(type) from peerId: \(self.peerId)")
            break
        }
    }
}

