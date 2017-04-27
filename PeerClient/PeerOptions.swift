//
//  PeerOptions.swift
//  PeerClient
//
//  Created by Akira Murao on 2017/03/29.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation

public class PeerOptions {

    var key: String
    var host: String
    var path: String
    var secure: Bool
    var port: Int
    var iceServerOptions: [PeerIceServerOptions]
    
    public var keepAliveTimerInterval: TimeInterval

    var httpUrl: String {
        get {

            let proto = self.secure ? "https" : "http"

            let urlStr = "\(proto)://\(self.host):\(self.port)\(self.path)/\(self.key)"
            return urlStr
        }
    }

    var wsUrl: String {
        get {
            let proto = self.secure ? "wss" : "ws"

            let urlStr = "\(proto)://\(self.host):\(self.port)\(self.path)/peerjs?key=\(self.key)"
            return urlStr
        }
    }

    public init(key: String, host: String, path: String, secure: Bool, port: Int, iceServerOptions: [PeerIceServerOptions]) {

        self.key = key
        self.host = host
        self.path = path
        self.secure = secure
        self.port = port
        self.iceServerOptions = iceServerOptions
        self.keepAliveTimerInterval = 0


        if self.port == 0 {
            self.port = 80
            if self.secure {
                self.port = 443
            }
        }

        if self.path == "/" {
            self.path = ""
        }

        if self.host == "/" {
            self.host = ""
        }
    }

}
