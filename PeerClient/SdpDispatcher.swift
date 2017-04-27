//
//  SdpDispatcher.swift
//  PeerClient
//
//  Created by Akira Murao on 10/17/15.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation
import libjingle_peerconnection

typealias CreateSdpCompletionBlock = (Result<RTCSessionDescription, Error>) -> Void
typealias SetSdpCompletionBlock = (Error?) -> Void

enum SdpDispatcherError: Error {
    case invalidParameter
}

class SdpDispatcher: NSObject, RTCSessionDescriptionDelegate {

    var createSdpCompletionBlock: CreateSdpCompletionBlock?
    var setSdpCompletionBlock: SetSdpCompletionBlock?
    var connection: RTCPeerConnection?

    func createOffer(_ peerConnection: RTCPeerConnection, constraints: RTCMediaConstraints?, completion: @escaping CreateSdpCompletionBlock) {
        
        print("createOffer")

        guard self.createSdpCompletionBlock == nil else {
            print("ERROR: createSdpCompletionBlock already exists. something went wrong.")
            return
        }

        self.connection = peerConnection
        self.createSdpCompletionBlock = completion
        peerConnection.createOffer(with: self, constraints: constraints)
    }
    
    func createAnswer(_ peerConnection: RTCPeerConnection, constraints: RTCMediaConstraints?, completion: @escaping CreateSdpCompletionBlock) {
        
        print("createAnswer")

        guard self.createSdpCompletionBlock == nil else {
            print("ERROR: createSdpCompletionBlock already exists. something went wrong.")
            return
        }

        self.connection = peerConnection
        self.createSdpCompletionBlock = completion
        peerConnection.createAnswer(with: self, constraints: constraints)
    }

    func setLocalDescription(_ peerConnection: RTCPeerConnection, sdp: RTCSessionDescription!, completion: @escaping SetSdpCompletionBlock) {

        guard self.setSdpCompletionBlock == nil else {
            print("ERROR: setSdpCompletionBlock already exists. something went wrong.")
            return
        }

        self.connection = peerConnection
        self.setSdpCompletionBlock = completion
        peerConnection.setLocalDescriptionWith(self, sessionDescription: sdp)
    }
    
    func setRemoteDescription(_ peerConnection: RTCPeerConnection, sdp: RTCSessionDescription!, completion: @escaping SetSdpCompletionBlock) {

        guard self.setSdpCompletionBlock == nil else {
            print("ERROR: setSdpCompletionBlock already exists. something went wrong.")
            return
        }

        self.connection = peerConnection
        self.setSdpCompletionBlock = completion
        peerConnection.setRemoteDescriptionWith(self, sessionDescription: sdp)
    }

    // MARK: RTCSessionDescriptionDelegate

    public func peerConnection(_ peerConnection: RTCPeerConnection!, didCreateSessionDescription sdp: RTCSessionDescription!, error: Error!) {
        
        print("didCreateSessionDescription")
        
        if peerConnection == self.connection {
            if error == nil {
                self.createSdpCompletionBlock?(.success(sdp))
            }
            else {
                self.createSdpCompletionBlock?(.failure(error))
            }
        }
        else {
            print("WARNING: something may have go wrong...")
            self.createSdpCompletionBlock?(.failure(SdpDispatcherError.invalidParameter))
        }

        self.createSdpCompletionBlock = nil
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection!, didSetSessionDescriptionWithError error: Error!) {
        
        print("didSetSessionDescriptionWithError")
        
        if peerConnection == self.connection {
            self.setSdpCompletionBlock?(error)
        }
        else {
            print("WARNING: something may have go wrong...")
            self.setSdpCompletionBlock?(SdpDispatcherError.invalidParameter)
        }

        self.setSdpCompletionBlock = nil
    }
}
