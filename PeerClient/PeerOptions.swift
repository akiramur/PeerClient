//
//  PeerOptions.swift
//  PeerClient
//
//  Created by Akira Murao on 2017/03/29.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation

public class PeerOptions {

    var mqttClientOptions: MqttClientOptions
    var iceServerOptions: [PeerIceServerOptions]


    public init(mqttClientOptions: MqttClientOptions, iceServerOptions: [PeerIceServerOptions]) {
        self.mqttClientOptions = mqttClientOptions
        self.iceServerOptions = iceServerOptions
    }

}
