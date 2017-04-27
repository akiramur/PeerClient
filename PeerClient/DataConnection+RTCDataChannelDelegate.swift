//
//  Peer+RTCDataChannelDelegate.swift
//  PeerClient
//
//  Created by Akira Murao on 2017/03/15.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation
import libjingle_peerconnection

extension DataConnection: RTCDataChannelDelegate {

    // MARK: RTCDataChannelDelegate

    public func channelDidChangeState(_ channel: RTCDataChannel!) {
        print("channelDidChangeState: \(channel.state.rawValue)")

        if channel.state.rawValue == kRTCDataChannelStateOpen.rawValue {
            print("channel.state = open")
            /*
            DispatchQueue.main.async {
                self.delegate?.connection(connection: self, didOpenDataChannel: channel.label)
            }
            */
        }
        else if channel.state.rawValue == kRTCDataChannelStateClosed.rawValue {
            print("channel.state = closed")
            /*
            DispatchQueue.main.async {
                self.delegate?.connection(connection: self, didCloseDataChannel: channel.label)
            }
            */
        }
    }

    public func channel(_ channel: RTCDataChannel!, didReceiveMessageWith buffer: RTCDataBuffer!) {

        print("channel didReceiveMessageWith")

        if let data = buffer.data {
            DispatchQueue.main.async {
                self.delegate?.connection(connection: self, didReceiveData: data)
            }
        }
    }

    // optional
    public func channel(_ channel: RTCDataChannel!, didChangeBufferedAmount amount: UInt) {
        print("didChangeBufferedAmount")
    }
}
