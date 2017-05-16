//
//  MqttClientOptions.swift
//  PeerClient
//
//  Created by Akira Murao on 2017/03/29.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation

public class MqttClientOptions {

    var host: String
    var port: UInt16

    var username: String
    var password: String
    var keepAlive: UInt16

    public init(host: String, port: UInt16, username: String, password: String, keepAlive: UInt16) {

        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.keepAlive = keepAlive
    }

}
