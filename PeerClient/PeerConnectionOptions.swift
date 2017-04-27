//
//  PeerConnectionOptions.swift
//  PeerClient
//
//  Created by Akira Murao on 2017/03/17.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation
import libjingle_peerconnection

public class PeerConnectionOptions {

    let defaultBrowser: String = "Chrome"

    enum SerializationType {
        case none
        case binary
        case binary_utf8
        case json

        init(_ type: String?) {

            guard let type = type else {
                self = .none
                return
            }

            switch type {
            case "none":
                self = .none
            case "binary":
                self = .binary
            case "binary_utf8":
                self = .binary_utf8
            case "json":
                self = .json
            default:
                self = .none
            }
        }

        var string: String {
            switch self {
            case .none:
                return "none"
            case .binary:
                return "binary"
            case .binary_utf8:
                return "binary_utf8"
            case .json:
                return "json"
            }
        }
    }

    let connectionType: PeerConnection.ConnectionType
    var connectionId: String    // should move back to conneciton?

    var label: String           // should move back to conneciton?
    var metadata: [String: Any]
    var payload: [String: Any]
    var browser: String
    let isReliable: Bool
    //var reliableObj: PeerReliable? // TODO: implement later
    let serialization: SerializationType

    var iceServers: [RTCICEServer]
    
    init (connectionType: PeerConnection.ConnectionType, iceServerOptions: [PeerIceServerOptions]?) {
        self.connectionType = connectionType

        self.connectionId  = self.connectionType.prefix + Utility.randString(maxLength: 20)
        self.payload = [:]
        self.metadata = [:]

        self.label = self.connectionId

        self.serialization = .none
        self.isReliable = false
        self.browser = self.defaultBrowser
        self.iceServers =  []

        self.iceServers = self.iceServers(iceServerOptions: iceServerOptions)
    }

    init (connectionType: PeerConnection.ConnectionType, connectionId: String?, payload: [String: Any]?, metadata: [String: Any]?, label: String?, serialization: String?, isReliable: Bool?, iceServerOptions: [PeerIceServerOptions]?) {

        self.connectionType = connectionType

        let cid = connectionId ?? ""
        if cid.characters.count == 0 {
            self.connectionId  = self.connectionType.prefix + Utility.randString(maxLength: 20)
        }
        else {
            self.connectionId  = cid
        }

        self.payload = payload ?? [:]
        self.metadata = metadata ?? [:]

        let la = label ?? ""
        if la.characters.count == 0 {
            self.label = self.connectionId
        }
        else {
            self.label = la
        }

        self.serialization = SerializationType(serialization)
        self.isReliable = isReliable ?? false
        self.browser = self.defaultBrowser

        self.iceServers = []
        self.iceServers = self.iceServers(iceServerOptions: iceServerOptions)
    }

    init (connectionType: PeerConnection.ConnectionType, label: String, serialization: SerializationType, isReliable: Bool, iceServerOptions: [PeerIceServerOptions]?) {

        self.connectionType = connectionType

        self.connectionId  = self.connectionType.prefix + Utility.randString(maxLength: 20)
        self.payload = [:]
        self.metadata = [:]

        self.label = label

        self.serialization = serialization
        self.isReliable = isReliable
        self.browser = self.defaultBrowser

        self.iceServers = []
        self.iceServers = self.iceServers(iceServerOptions: iceServerOptions)
    }

    func iceServers(iceServerOptions: [PeerIceServerOptions]?) -> [RTCICEServer] {
        var servers: [RTCICEServer] = []

        guard let options = iceServerOptions else {
            return servers
        }

        for option in options {
            let url = URL(string: option.url)
            if let server = RTCICEServer(uri: url, username: option.username, password: option.credential) {
                servers.append(server)
            }
        }

        return servers
    }
}
