//
//  Peer+PeerConnectionDelegate.swift
//  PeerClient
//
//  Created by Akira Murao on 2017/03/15.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation
import libjingle_peerconnection

extension Peer: PeerConnectionDelegate {

    // MARK: PeerConnectionDelegate

    public func connection(connection: PeerConnection, shouldSendMessage message: [String: Any]) {
        let data = try? JSONSerialization.data(withJSONObject: message, options: [])
        self.webSocket?.send(data: data)
    }


    public func connection(connection: PeerConnection, didReceiveRemoteStream stream: RTCMediaStream?) {
        
        if let mediaStream = MediaStream(stream) {
            self.delegate?.peer(self, didReceiveRemoteStream: mediaStream)
        }
    }

    public func connection(connection: PeerConnection, didClose error: Error?) {
        // this is needed because connection can be closed by error inside

        self.delegate?.peer(self, didCloseConnection: connection)
        self.connectionStore.removeConnection(connection: connection)
    }

    public func connection(connection: PeerConnection, didReceiveData data: Data) {
        self.delegate?.peer(self, didReceiveData: data)
    }

}
