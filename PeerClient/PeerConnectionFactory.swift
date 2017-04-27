//
//  PeerConnectionFactory.swift
//  PeerClient
//
//  Created by Akira Murao on 10/22/15.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation
import libjingle_peerconnection

public class PeerConnectionFactory {
    
    public static let sharedInstance = PeerConnectionFactory()
    
    var factory: RTCPeerConnectionFactory
    
    init() {
        RTCPeerConnectionFactory.initializeSSL()
        self.factory = RTCPeerConnectionFactory()
    }
    
    deinit {
        RTCPeerConnectionFactory.deinitializeSSL()
    }

    func createPeerConnection(_ options: PeerConnectionOptions, delegate: RTCPeerConnectionDelegate?) -> RTCPeerConnection? {
        print("Creating RTCPeerConnection.")

        /*
         var pc: RTCPeerConnection? = nil
         if connection.options.type == .data {
         let config: RTCConfiguration = RTCConfiguration()
         config.iceServers = iceServers
         pc = self.factory.peerConnection(with: config, constraints: nil, delegate: connection)
         }
         else if connection.options.type == .media {
         let constraints = self.defaultPeerConnectionConstraints()

         /*
         let config: RTCConfiguration = RTCConfiguration()
         config.iceServers = iceServers
         let pc = self.factory.peerConnection(with: config, constraints: nil, delegate: connection)
         */
         pc = self.factory.peerConnection(withICEServers: iceServers, constraints: constraints, delegate: connection)
         }
         */

        let constraints = self.defaultPeerConnectionConstraints(options)
        let pc = self.factory.peerConnection(withICEServers: options.iceServers, constraints: constraints, delegate: delegate)

        /*
         let config: RTCConfiguration = RTCConfiguration()
         config.iceServers = iceServers
         let pc = self.factory.peerConnection(with: config, constraints: constraints, delegate: connection)
         */
        // TODO: something like ...
        //Negotiator.pcs[connection.type][connection.peer][id] = pc;
        
        return pc
    }

    //func createLocalMediaStream() -> RTCMediaStream? {
    public func createLocalMediaStream() -> MediaStream? {

        guard let stream = self.factory.mediaStream(withLabel: "ARDAMS") else {
            return nil
        }

        if let localVideoTrack = self.createLocalVideoTrack() {
            stream.addVideoTrack(localVideoTrack)
        }

        if let localAudioTrack = self.factory.audioTrack(withID: "ARDAMSa0") {
            stream.addAudioTrack(localAudioTrack)
        }

        return MediaStream(stream)
    }

    // MARK: Private

    func defaultPeerConnectionConstraints(_ options: PeerConnectionOptions) -> RTCMediaConstraints? {

        if options.connectionType == .data {
            /*
             if !self.supportSctp {
             let optionalConstraints = [RTCPair(key: "RtpDataChannels", value: "true")]
             let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: optionalConstraints)
             return constraints
             }
             */
            return nil

        }
        else if options.connectionType == .media {
            let optionalConstraints: [RTCPair] = [RTCPair(key: "DtlsSrtpKeyAgreement", value: "true")]
            let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: optionalConstraints)
            return constraints
        }

        return nil
    }

    func createLocalVideoTrack() -> RTCVideoTrack? {

        var videoTrack: RTCVideoTrack?

        // The iOS simulator doesn't provide any sort of camera capture
        // support or emulation (http://goo.gl/rHAnC1) so don't bother
        // trying to open a local stream.
        // TODO(tkchin): local video capture for OSX. See
        // https://code.google.com/p/webrtc/issues/detail?id=3417.

        #if !((arch(i386) || arch(x86_64)) && os(iOS))
            //let mediaConstraints = self.defaultMediaStreamConstraints()
            /*
             let mandatoryConstraints = [RTCPair(key: "OfferToReceiveAudio", value: "true"), RTCPair(key: "OfferToReceiveVideo", value: "true")]
             let mediaConstraints = RTCMediaConstraints(mandatoryConstraints: mandatoryConstraints, optionalConstraints: nil)
             */
            let mediaConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)

            let source = RTCAVFoundationVideoSource(factory: self.factory, constraints: mediaConstraints)
            videoTrack = self.factory.videoTrack(withID: "ARDAMSv0", source: source)
        #endif

        return videoTrack
    }
}
