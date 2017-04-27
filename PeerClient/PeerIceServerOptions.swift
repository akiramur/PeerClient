//
//  PeerIceServerOptions.swift
//  PeerClient
//
//  Created by Akira Murao on 2017/04/26.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation

public struct PeerIceServerOptions {

    var url: String
    var username: String
    var credential: String

    public init(url: String, username: String, credential: String) {
        self.url = url
        self.username = username
        self.credential = credential
    }
}
