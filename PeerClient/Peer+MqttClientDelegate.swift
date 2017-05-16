//
//  Peer+MqttClientDelegate.swift
//  PeerClient
//
//  Created by Akira Murao on 2017/03/15.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation

extension Peer: MqttClientDelegate {

    // MARK: MqttClientDelegate
/*
    func mqttClient(_ mqttClient: MqttClient, didReceiveClientId clientId: String, message: [String: Any]) {

        if let status = message["status"] as? String {
            if status == "connected" {
                if !self.mqttClientIds.contains(clientId) {
                    self.mqttClientIds.append(clientId)
                    self.delegate?.peer(self, didUpdatePeerIds: self.mqttClientIds)
                }
            }
            else {
                if let index = self.mqttClientIds.index(of: clientId) {
                    self.mqttClientIds.remove(at: index)
                    self.delegate?.peer(self, didUpdatePeerIds: self.mqttClientIds)
                }
            }
        }
        else {
            print("could not find status")
        }

    }
*/
    func mqttClient(_ mqttClient: MqttClient, didReceiveClientId clientId: String, message: [String: Any]) {

        self.delegate?.peer(self, didUpdatePeerIds: self.mqttClient?.clientIds ?? [])
    }

    func mqttClient(_ mqttClient: MqttClient, didReceiveMessage message: [String: Any]) {
        print("mqttClient didReceiveMessage")

        self.handleMessage(message: message)
    }
    
    func mqttClient(_ mqttClient: MqttClient, didDisconnectWithError error: Error?) {

        print("mqttClient didDisconnectWithError error: \(error.debugDescription)")

        if !self.isDisconnected {
            self.abort(type: "mqttClient-disconnected", completion: { (error) in

            })
        }

        self.isOpen = false
    }
    
    // MARK: Private method

    func handleMessage(message: [String: Any]) {

        print("Peer.handleMessage: \(message)")

        //var connection: RTCPeerConnection?

        guard let type = message["type"] as? String else {
            print("ERROR: type doesn't exist")
            return
        }
        print("TYPE: \(type)")


        switch type {
        case "OFFER":

            guard let peerId = message["src"] as? String else {
                print("ERROR: src is nil")
                return
            }

            guard let payload = message["payload"] as? [String: Any] else {
                print("ERROR: payload is nil")
                return
            }

            guard let connectionId = payload["connectionId"] as? String else {
                print("ERROR: connectionId is nil")
                return
            }

            if let _ = self.connectionStore.findConnection(peerId: peerId, connectionId: connectionId) {
                print("Offer received for existing Connection ID: \(connectionId)")
            }
            else {
                // Create a new connection.
                guard let connectionType = payload["type"] as? String else {
                    print("ERROR: type doesn't exist")
                    return
                }

                var connection: PeerConnection?
                if connectionType == "media" {

                    let metadata = payload["metadata"] as? [String: Any]

                    let connectionOptions = PeerConnectionOptions(connectionType: .media, connectionId: connectionId, payload: payload, metadata: metadata, label: nil, serialization: nil, isReliable: nil, iceServerOptions: self.options?.iceServerOptions)
                    let mediaConnection = MediaConnection(peerId: peerId, delegate: self, options: connectionOptions)
                    self.connectionStore.addConnection(connection: mediaConnection)
                    
                    connection = mediaConnection

                    // this calls mediaConnection.answer
                    // once answer is triggered by user in upper layer, startConnection is called.

                    // emit -> peer.on('call', function(call)) in index.html -> mediaConnection.answer
                    //self.emit('call', connection)
                    DispatchQueue.main.async {
                        self.delegate?.peer(self, didReceiveConnection: mediaConnection)
                    }
                }
                else if connectionType == "data" {

                    let label = payload["label"] as? String
                    let serialization = payload["serialization"] as? String
                    let reliable = payload["reliable"] as? Bool

                    let metadata = payload["metadata"] as? [String: Any]

                    let connectionOptions = PeerConnectionOptions(connectionType: .data, connectionId: connectionId, payload: payload, metadata: metadata, label: label, serialization: serialization, isReliable: reliable, iceServerOptions: self.options?.iceServerOptions)
                    let dataConnection = DataConnection(peerId: peerId, delegate: self, options: connectionOptions)
                    self.connectionStore.addConnection(connection: dataConnection)

                    connection = dataConnection

                    //this.emit('connection', connection)
                    DispatchQueue.main.async {
                        self.delegate?.peer(self, didReceiveConnection: dataConnection)
                    }
                }
                else {
                    print("Received malformed connection type: \(connectionType)")
                    return
                }

                /*
                 // Find messages.
                 let messages = self.getMessages(connectionId)
                 for var message in messages {
                 self.handleMessage(connection, message: message)
                 }
                 */
                connection?.handleLostMessages()
            }

        default:
            guard let peerId = message["src"] as? String else {
                print("You received a malformed message \(message)")
                return
            }

            guard let type = message["type"] as? String else {
                print("You received a malformed message \(message)")
                print("from \(peerId)")
                return
            }

            guard let payload = message["payload"] as? [String: Any] else {
                print("You received a malformed message \(message)")
                print("from \(peerId) type \(type)")
                return
            }

            guard let connectionId = payload["connectionId"] as? String else {
                print("You received an unrecognized message: \(message)")
                print("from \(peerId), type \(type), payload \(payload)")
                return
            }

            guard let connection = self.connectionStore.findConnection(peerId: peerId, connectionId: connectionId) else {
                print("You received an unrecognized message: \(message)")
                print("from \(peerId), type \(type), payload \(payload), connectionId \(connectionId)")
                return
            }

            if connection.pc != nil {
                // Pass it on.
                connection.handleMessage(message: message)
            }
            else {
                // Store for possible later use
                connection.storeMessage(message: message)
            }
        }
    }
}
