//
//  PeerConnectionStore.swift
//  PeerClient
//
//  Created by Akira Murao on 10/16/15.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation

class PeerConnectionStore {
    
    var connections: [PeerConnection]
    
    init() {
        connections = []
    }

    func findConnection(peerId: String, connectionId: String) -> PeerConnection? {
        
        let foundConnections = self.connections.filter { (connection: PeerConnection) -> Bool in
            return (connection.options.connectionId == connectionId &&
                connection.peerId == peerId)
        }
        
        if foundConnections.count > 1 {
            print("ERROR: more than 1 connections are found! count = \(foundConnections.count)")
        }
        
        let connection = foundConnections.first as PeerConnection?
        
        return connection
    }

    func findConnections(connectionId: String) -> [PeerConnection]? {

        let foundConnections = self.connections.filter { (connection: PeerConnection) -> Bool in
            return (connection.options.connectionId == connectionId)
        }

        if foundConnections.count > 1 {
            print("ERROR: more than 1 connections are found! count = \(connections.count)")
        }

        return foundConnections
    }

    func findConnections(peerId: String) -> [PeerConnection]? {
        
        let foundConnections = self.connections.filter { (connection: PeerConnection) -> Bool in
            return (connection.peerId == peerId)
        }
        
        return foundConnections
    }

    func findConnections(connectionType: PeerConnection.ConnectionType) -> [PeerConnection] {

        let foundConnections = self.connections.filter { (connection: PeerConnection) -> Bool in
            return (connection.connectionType == connectionType)
        }

        return foundConnections
    }

    func mediaConnections() -> [PeerConnection] {
        
        let foundConnections = self.connections.filter { (connection: PeerConnection) -> Bool in
            return (connection is MediaConnection)
        }
        
        return foundConnections
    }
    
    func dataConnections() -> [PeerConnection] {
        
        let foundConnections = self.connections.filter { (connection: PeerConnection) -> Bool in
            return (connection is DataConnection)
        }
        
        return foundConnections
    }
    
    func allConnections() -> [PeerConnection] {
        return self.connections
    }
    
    func addConnection(connection: PeerConnection) {
        print("PeerConnectionStore addConnection << \(self.connections.count)")
        print("connectionId: \(connection.connectionId)")
        self.connections.append(connection)

        print("PeerConnectionStore addConnection >> \(self.connections.count)")
    }
    
    func removeConnection(connection: PeerConnection) {
        print("PeerConnectionStore removeConnection << \(self.connections.count)")
        print("connectionId: \(connection.connectionId)")

        if let index = self.connections.index(of: connection) {
            self.connections.remove(at: index)
        }

        print("PeerConnectionStore removeConnection >> \(self.connections.count)")
    }
/*
    func removeConnections(connections: [PeerConnection]) {
        for connection in connections {
            self.removeConnection(connection: connection)
        }
    }
*/
}
