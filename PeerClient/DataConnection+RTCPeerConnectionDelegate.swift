//
//  PeerConnection+RTCPeerConnection.swift
//  PeerClient
//
//  Created by Akira Murao on 2017/03/08.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation
import libjingle_peerconnection

extension DataConnection {
    
    // MARK: RTCPeerConnectionDelegate

    override public func peerConnection(_ peerConnection: RTCPeerConnection!, didOpen dataChannel: RTCDataChannel!) {

        print("Received data channel")

        //self.initialize(dc: dataChannel)
        self.dc = dataChannel
/*
        let test = "b"
        let data = test.data(using: .utf8, allowLossyConversion: false)
        let buffer = RTCDataBuffer(data: data, isBinary: false)
        dataChannel.sendData(buffer)
 */
    }
}
