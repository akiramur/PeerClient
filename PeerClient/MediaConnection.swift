//
//  MediaConnection.swift
//  PeerClient
//
//  Created by Akira Murao on 10/8/15.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation
import libjingle_peerconnection

public class MediaConnection: PeerConnection {
    
    // only for media?
    var localStream: RTCMediaStream?
    var remoteStream: RTCMediaStream?
    
    func open(stream: RTCMediaStream, completion: @escaping (Result<[String: Any], Error>) -> Void) {

        print("open (\(self.options.connectionId) <<")

        guard self.localStream == nil else {
            print("ERROR: Local stream exists on this MediaConnection. Call is already on going?")
            completion(.failure(PeerConnectionError.invalidState))
            return
        }

        // for only media
        self.localStream = stream

        let factory = PeerConnectionFactory.sharedInstance
        guard let pc = factory.createPeerConnection(self.options, delegate: self) else {
            print("ERROR: pc is nil")
            completion(.failure(PeerConnectionError.invalidState))
            return
        }
        pc.add(stream)  // moved from negotiator only for media
        self.pc = pc

        self.negotiator.startConnection(pc, peerId: self.peerId, options: self.options, completion: completion)

        print("open (\(self.options.connectionId) >>")
    }

    func answer(stream: RTCMediaStream?, completion: @escaping (Result<[String: Any], Error>) -> Void) {

        print("answer (\(self.options.connectionId) <<")

        guard self.localStream == nil else {
            print("ERROR: Local stream already exists on this MediaConnection. Are you answering a call twice?")
            completion(.failure(PeerConnectionError.invalidState))
            return
        }

        self.localStream = stream
        self.options.payload["stream"] = stream

        // TODO: what to do?
        // Retrieve lost messages stored because PeerConnection not set up.
        /*
        var messages = self.provider._getMessages(this.id);
        for message in messages {
            self.handleMessage(message)
        }
        */
        
        let factory = PeerConnectionFactory.sharedInstance
        guard let pc = factory.createPeerConnection(self.options, delegate: self) else {
            print("ERROR: pc is nil")
            completion(.failure(PeerConnectionError.invalidState))
            return
        }

        pc.add(stream)  // moved from negotiator only for media
        self.pc = pc
        
        self.negotiator.answerConnection(pc, peerId: self.peerId, options: self.options) { [weak self] (result) in
            self?.isOpen = true
            completion(result)
        }

        self.handleLostMessages()

        print("answer (\(self.options.connectionId) >>")
    }

}
