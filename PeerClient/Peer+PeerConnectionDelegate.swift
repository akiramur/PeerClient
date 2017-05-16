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

    public func connection(connection: PeerConnection, shouldSendMessage message: [String: Any], type: String) {
    
        var topic = MqttClient.TopicType.offer
        if type == "offer" {
            topic = .offer
        }
        else if type == "answer" {
            topic = .answer
        }
        else {
            print("ERROR: type is not offer or answer !!! \(type)")
        }
        self.mqttClient?.publish(to: connection.peerId, topic: topic, dictionary: message)
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
