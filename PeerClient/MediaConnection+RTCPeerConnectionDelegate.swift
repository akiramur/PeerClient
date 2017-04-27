//
//  MediaConnection+RTCPeerConnection.swift
//  PeerClient
//
//  Created by Akira Murao on 2017/03/08.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation
import libjingle_peerconnection

extension MediaConnection {
    
    // MARK: RTCPeerConnectionDelegate

    override public func peerConnection(_ peerConnection: RTCPeerConnection!, addedStream stream: RTCMediaStream!) {

        print("Received remote stream")

        DispatchQueue.main.async {

            // 10/10/2014: looks like in Chrome 38, onaddstream is triggered after
            // setting the remote description. Our connection object in these cases
            // is actually a DATA connection, so addStream fails.
            // TODO: This is hopefully just a temporary fix. We should try to
            // understand why this is happening.

            self.remoteStream = stream
            //self.emit("stream", remoteStream)   // Should we call this `open`?
            // TODO: need to call follwoing to tell mainView about the video track?
            self.delegate?.connection(connection: self, didReceiveRemoteStream: stream)
        }
    }

    // TODO: no implementation in PeerJS?
    override public func peerConnection(_ peerConnection: RTCPeerConnection!, removedStream stream: RTCMediaStream!) {

        print("Removed remote stream")

        if self.remoteStream == stream {
            self.remoteStream = nil
        }

        DispatchQueue.main.async {
            //self.delegate?.connection(connection: self, didRemoveRemoteStream: stream)
        }
    }
}
