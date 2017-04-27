//
//  Reliable.swift
//  PeerClient
//
//  Created by Akira Murao on 2017/03/31.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation
import libjingle_peerconnection

class Reliable {

    var dc: RTCDataChannel

    var window: Int
    var mtu: Int
    var interval: Int
    var count: Int

    init(_ dc: RTCDataChannel) {
        self.dc = dc

        self.window = 1000
        self.mtu = 500
        self.interval = 0
        self.count = 0
    }
}
