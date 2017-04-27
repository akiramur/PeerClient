//
//  Peer+PeerSocketDelegate.swift
//  PeerClient
//
//  Created by Akira Murao on 2017/03/15.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation

extension Peer: PeerSocketDelegate {

    // MARK: PeerSocketDelegate

    func webSocketDidOpen(webSocket: PeerSocket) {
        print("webSocketDidOpen")
    }

    func webSocket(webSocket: PeerSocket, didReceiveMessage message: [String: Any]?) {
        print("webSocket didReceiveMessage")

        if let m = message {
            self.handleMessage(message: m)
        }
    }

    func webSocket(webSocket: PeerSocket, didCloseWithReason reason: String?) {

        print("webSocket didCloseWithReason reason: \(reason ?? "Underlying socket is already closed.")")

        if !self.isDisconnected {
            self.abort(type: "socket-closed", completion: { (error) in

            })
        }

        self.isOpen = false
        self.keepAliveTimer?.invalidate()
    }

    func webSocket(webSocket: PeerSocket, didFailWithError error: Error?) {

        print("webSocket didFailWithError error: \(error?.localizedDescription ?? "")")

        self.abort(type: "socket-error", completion: { (error) in

        })

        self.keepAliveTimer?.invalidate()
    }

    // MARK: Private method

    func handleMessage(message: [String: Any]) {

        print("RECV MESSAGE: \(message)")

        //var connection: RTCPeerConnection?

        guard let type = message["type"] as? String else {
            print("ERROR: type doesn't exist")
            return
        }
        print("TYPE: \(type)")


        switch type {
        case "OPEN":    // The connection to the server is open.
            //this.emit('open', this.id);
            self.delegate?.peer(self, didOpen: self.peerId)
            self.isOpen = true
        case "ERROR":   // Server error.
            let payload = message["payload"] as? [String: Any]
            let payloadMessage = payload?["message"] as? String
            self.abort(type: "socket-error", completion: { (error) in
                print("payloadMessage: \(payloadMessage ?? "")")
            })
            break
        case "ID-TAKEN":    // The selected ID is taken.
            self.abort(type: "unavailable-id", completion: { (error) in
                print("ID \(self.peerId ?? "") is taken")
            })
            break
        case "INVALID-KEY": // The given API key cannot be found.
            //self.abort("invalid-key", message: "API KEY \(self.options.key) is invalid")
            break

        case "LEAVE":   // Another peer has closed its connection to this peer.

            guard let peerId = message["src"] as? String else {
                print("ERROR: src doesn't exist")
                return
            }

            print("Received leave message from  \(peerId)")
            self.cleanup(peerId: peerId)
            break

        case "EXPIRE":  // The offer sent to a peer has expired without response.
            //this.emitError('peer-unavailable', 'Could not connect to peer ' + peer)
            
            DispatchQueue.main.async {
                self.delegate?.peer(self, didReceiveError: PeerError.receivedExpire)
            }
            break

        case "OFFER":   // we should consider switching this to CALL/CONNECT, but this is the least breaking option.

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
