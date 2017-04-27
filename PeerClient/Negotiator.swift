//
//  Negotiator.swift
//  PeerClient
//
//  Created by Akira Murao on 2017/03/10.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation
import libjingle_peerconnection

enum NegotiatorError: Error {
    case noSdp
    case settingRemoteDescription
    case settingLocalDescription
    case creatingOffer
    case creatingAnswer
    case invalidState
}

class Negotiator {

    // only for data?
    var supportSctp: Bool

    let sdpDispatcher: SdpDispatcher

    init() {
        
        //self.onNegotiationNeeded = nil
        self.supportSctp = false
        self.sdpDispatcher = SdpDispatcher()
    }

    // MARK: default constraints

    func defaultAnswerConstraints(_ connectionType: PeerConnection.ConnectionType) -> RTCMediaConstraints? {

        if connectionType == .data {
            return nil
        }
        else if connectionType == .media {
            let mandatoryConstraints: [RTCPair] = [RTCPair(key: "OfferToReceiveAudio", value: "true"), RTCPair(key: "OfferToReceiveVideo", value: "true")]
            let constraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)

            // from v1
            //let optionalConstraints = [RTCPair(key: "DtlsSrtpKeyAgreement", value: "true")]
            //let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: optionalConstraints)

            return constraints
        }

        return nil
    }

    func defaultOfferConstraints(_ connectionType: PeerConnection.ConnectionType) -> RTCMediaConstraints? {

        if connectionType == .data {
            /*
            if !self.supportSctp {
                let mandatoryConstraints = [RTCPair(key: "RtpDataChannels", value: "true")]
                let constraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
                return constraints
            }
            */
            return nil
        }
        else if connectionType == .media {
            //let mandatoryConstraints = [RTCPair(key: "DtlsSrtpKeyAgreement", value: "true")]
            let mandatoryConstraints: [RTCPair] = [RTCPair(key: "OfferToReceiveAudio", value: "true"), RTCPair(key: "OfferToReceiveVideo", value: "true")]
            let constraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
            return constraints
        }

        return nil
    }
    
    // options: options["payload"]
    func startConnection(_ pc: RTCPeerConnection, peerId: String, options: PeerConnectionOptions, completion: @escaping (Result<[String: Any], Error>) -> Void) {

        print("Starting connection")

        // this sholud be done in delegate method
        // peerConnection(onRenegotiationNeeded peerConnection: RTCPeerConnection!)

        //if (self.onNegotiationNeeded == nil) {
            self.makeOffer(pc, peerId: peerId, options: options, completion: completion)
        //}
    }

    func answerConnection(_ pc: RTCPeerConnection, peerId: String, options: PeerConnectionOptions, completion: @escaping (Result<[String: Any], Error>) -> Void) {

        print("Answering connection")
        
        guard let sdp = options.payload["sdp"] as? [String: Any] else {
            completion(.failure(NegotiatorError.noSdp))
            return
        }

        self.handleSDP(pc, peerId: peerId, type: "offer", message: sdp, options: options, completion: completion)
    }

    func stopConnection(pc: RTCPeerConnection) {
        print("Stopping connection")

        if pc.signalingState != RTCSignalingClosed {
            pc.close()
        }
    }
/*
    func getPeerConnection(_ options: PeerConnectionOptions, delegate: RTCPeerConnectionDelegate?) ->  RTCPeerConnection? {

        // TODO: do more something here

        let pc = self.createPeerConnection(options, delegate: delegate)
        return pc
    }

    func getDataChannel(_ pc: RTCPeerConnection, options: PeerConnectionOptions) ->  RTCDataChannel? {

        // TODO: do more something here

        let dc = self.createDataChannel(pc, options: options)
        return dc
    }
*/

    func createDataChannel(_ pc: RTCPeerConnection, options: PeerConnectionOptions) -> RTCDataChannel? {

        // Create the datachannel.
        //var config = [String: Any]()
        // Dropping reliable:false support, since it seems to be crashing
        // Chrome.
        /*if (util.supports.sctp && !options.reliable) {
         // If we have canonical reliable support...
         config = {maxRetransmits: 0};
         }*/
        // Fallback to ensure older browsers don't crash.
        //if (!self.supportSctp) {
        //    config["reliable"] = options["reliable"]
        //}

        let config = RTCDataChannelInit()
        if (!self.supportSctp) {
            // The stream id, or SID, for SCTP data channels. -1 if unset.
            //config.streamId = ?   // TODO: what should I set?
        }

        let dc = pc.createDataChannel(withLabel: options.label, config: config)
        
        return dc
    }
    
    func makeOffer(_ pc: RTCPeerConnection, peerId: String, options: PeerConnectionOptions, completion: @escaping (Result<[String: Any], Error>) -> Void) {

        print("Created offer. \(peerId)")

        self.sdpDispatcher.createOffer(pc, constraints: self.defaultOfferConstraints(options.connectionType)) { [weak self] (result) -> Void in

            var offerSdp: RTCSessionDescription

            switch result {
            case let .success(sdp):
                offerSdp = sdp

            case let .failure(error):
                print("Failed to create offer \(error)")
                DispatchQueue.main.async {
                    completion(.failure(NegotiatorError.creatingOffer))
                }
                return
            }

            guard let sself = self else {
                DispatchQueue.main.async {
                    completion(.failure(NegotiatorError.invalidState))
                }
                return
            }

            // TODO: implement later
            /*
            var serialization: String = options.serialization
            if (!sself.supportSctp && options.connectionType == .data && options.reliable) {
                //sdp = Reliable.higherBandwidthSDP(offer.sdp);
                serialization = "binary"
            }
            */
            
            DispatchQueue.main.async {
                sself.sdpDispatcher.setLocalDescription(pc, sdp: offerSdp, completion: { (error) -> Void in

                    guard error == nil else {
                        //provider.emitError("webrtc", err)
                        print("Failed to setLocalDescription \(String(describing: error))")
                        DispatchQueue.main.async {
                            completion(.failure(NegotiatorError.settingLocalDescription))
                        }
                        return
                    }

                    print("Set localDescription: offer for: \(peerId)")

                    let message: [String: Any] = [
                        "type": "OFFER",
                        "payload": [
                            "sdp": [
                                "sdp": offerSdp.description,
                                "type": "offer"
                            ],
                            "type": options.connectionType.string,
                            "label": options.label,
                            "connectionId": options.connectionId,
                            "reliable": options.isReliable,
                            "serialization": options.serialization.string,
                            "metadata": options.metadata,
                            "browser": options.browser //util.browser
                        ],
                        "dst": peerId
                    ]

                    print("sendOfferMessage: \(offerSdp.description)")

                    DispatchQueue.main.async {
                        completion(.success(message))
                    }
                })

            }
        }
    }

    func makeAnswer(_ pc: RTCPeerConnection, peerId: String, options: PeerConnectionOptions, completion: @escaping (Result<[String: Any], Error>) -> Void) {

        print("Created answer.")

        self.sdpDispatcher.createAnswer(pc, constraints: self.defaultAnswerConstraints(options.connectionType)) { [weak self] (result) -> Void in

            var answerSdp: RTCSessionDescription

            switch result {
            case let .success(sdp):
                answerSdp = sdp

            case let .failure(error):
                //provider.emitError("webrtc", err);
                print("Failed to create answer \(error)")
                DispatchQueue.main.async {
                    completion(.failure(NegotiatorError.creatingAnswer))
                }
                return
            }

            guard let sself = self else {
                DispatchQueue.main.async {
                    completion(.failure(NegotiatorError.invalidState))
                }
                return
            }

            // TODO: implement later
            if (!sself.supportSctp && options.connectionType == .data && options.isReliable) {
                //sdp = Reliable.higherBandwidthSDP(answer.sdp)
            }

            DispatchQueue.main.async {
                sself.sdpDispatcher.setLocalDescription(pc, sdp: answerSdp, completion: { (error) -> Void in

                    guard error == nil else {
                        //provider.emitError("webrtc", err)
                        print("Failed to setLocalDescription \(String(describing: error))")
                        DispatchQueue.main.async {
                            completion(.failure(NegotiatorError.settingLocalDescription))
                        }
                        return
                    }

                    print("Set localDescription: answer for: \(peerId)")

                    let message: [String: Any] = [
                        "type": "ANSWER",
                        "payload": [
                            "sdp": [
                                "sdp": answerSdp.description ?? "",
                                "type": "answer"
                            ],
                            "type": options.connectionType.string,
                            "connectionId": options.connectionId,
                            "browser": options.browser //util.browser
                        ],
                        "dst": peerId
                    ]

                    DispatchQueue.main.async {
                        completion(.success(message))
                    }
                })
            }
        }
    }

    /** Handle an SDP. */
    // sdp: payload["sdp"]
    func handleSDP(_ pc: RTCPeerConnection, peerId: String, type: String, message: [String: Any], options: PeerConnectionOptions, completion: @escaping (Result<[String: Any], Error>) -> Void) {

        print("handleSDP")

        let sdpMessage = message["sdp"] as? String
        let sdp = RTCSessionDescription(type: type, sdp: sdpMessage)

        print("Setting remote description \(String(describing: sdp))")

        self.sdpDispatcher.setRemoteDescription(pc, sdp: sdp, completion: { [weak self] (error) -> Void in

            guard error == nil else {
                //provider.emitError("webrtc", err);
                print("Failed to setRemoteDescription \(String(describing: error))")
                DispatchQueue.main.async {
                    completion(.failure(NegotiatorError.settingRemoteDescription))
                }
                return
            }

            print("Set remoteDescription: \(options.connectionType.string)")

            if type == "offer" {
                self?.makeAnswer(pc, peerId: peerId, options: options, completion: completion)
            }
        })
    }

    /** Handle a candidate. */
    // ice: payload["candidate"]
    func handleCandidate(_ pc: RTCPeerConnection, message: [String: Any]) {

        print("handleCandidate")

        guard let candidate = message["candidate"] as? String else {
            print("ERROR: candidate is nil")
            return
        }
        
        guard let sdpMLineIndex = message["sdpMLineIndex"] as? Int else {
            print("ERROR: sdpMLineIndex is nil")
            return
        }
        
        guard let sdpMid = message["sdpMid"] as? String else {
            print("ERROR: sdpMid is nil")
            return
        }
        
        let iceCandidate = RTCICECandidate(mid: sdpMid, index: sdpMLineIndex, sdp: candidate)
        pc.add(iceCandidate)
        
        print("Added ICE candidate")
    }

}
