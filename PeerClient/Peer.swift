//
//  Peer.swift
//  PeerClient
//
//  Created by Akira Murao on 7/12/15.
//  Copyright (c) 2017 Akira Murao. All rights reserved.
//

import Foundation
import AVFoundation
import libjingle_peerconnection

public enum Result<T, Error> {
    case success(T)
    case failure(Error)
}

enum PeerError: Error {
    case peerDisconnected
    case socketClosed
    case invalidState
    case invalidOptions
    case noLocalStreamAvailable
    case receivedExpire
    case invalidUrl
    case requestFailed
    case invalidJsonObject
}

public protocol PeerDelegate {
    
    func peer(_ peer: Peer, didOpen peerId: String?) // TODO: change method name
    func peer(_ peer: Peer, didClose peerId: String?)

    func peer(_ peer: Peer, didReceiveConnection connection: PeerConnection)
    func peer(_ peer: Peer, didCloseConnection connection: PeerConnection)

    func peer(_ peer: Peer, didReceiveRemoteStream stream: MediaStream)
    func peer(_ peer: Peer, didReceiveError error: Error?)

    func peer(_ peer: Peer, didReceiveData data: Data)
}

public class Peer {
    
    var keepAliveTimer: Timer?

    var webSocket: PeerSocket?
    public var delegate: PeerDelegate?

    // PeerJS port
    var isDestroyed: Bool       // Connections have been killed
    var isDisconnected: Bool    // Connection to PeerServer killed but P2P connections still active
    public internal(set) var isOpen: Bool     // Sockets and such are not yet open.
    
    public private(set) var peerId: String?
    var lastServerId: String?

    let token: String

    var options: PeerOptions?

    var connectionStore: PeerConnectionStore

    public var mediaConnections: [PeerConnection] {
        get {
            if self.connectionStore.mediaConnections().count != self.connectionStore.findConnections(connectionType: .media).count {
                var debug = 0
            }
            return self.connectionStore.findConnections(connectionType: .media)
        }
    }

    public var dataConnections: [PeerConnection] {
        get {
            if self.connectionStore.dataConnections().count != self.connectionStore.findConnections(connectionType: .data).count {
                var debug = 0
            }
            return self.connectionStore.findConnections(connectionType: .data)
        }
    }


    public init(options: PeerOptions?, delegate: PeerDelegate?) {

        self.token = Utility.randString(maxLength: 34)

        self.isDestroyed = false
        self.isDisconnected = false
        self.isOpen = false
        
        self.connectionStore = PeerConnectionStore()
        
        self.options = options
        self.delegate = delegate
    }
    
    deinit {
        self.keepAliveTimer?.invalidate()
        self.webSocket?.close({ (reason) in
            print("Socket closed reason: \(String(describing: reason))")
        })
        
    }

    // this method is added to keep something outside constructor

    public func open(_ peerId: String?, completion: @escaping (Result<String, Error>) -> Void) {
        self.setupSocket()
        if let peerId = peerId {
            self.initialize(peerId: peerId, completion: completion)
        }
        else {
            self.retrieveId({ [weak self] (result) -> Void in

                switch result {
                case let .success(peerId):
                    DispatchQueue.main.async {
                        self?.initialize(peerId: peerId, completion: completion)
                    }

                case .failure(_):
                    return
                }

            })
        }
    }
    
    func setupSocket() {

        guard let options = self.options else {
            return
        }

        self.webSocket = PeerSocket(options: options, delegate: self)
    }
    
    func retrieveId(_ completion: @escaping (Result<String, Error>) -> Void) {

        guard let options = self.options else {
            completion(.failure(PeerError.invalidOptions))
            return
        }
        var urlStr = options.httpUrl + "/id"

        
        let now = Date()
        let dateString = "\(now.timeIntervalSince1970)"
        let mathRandomString = "\(CGFloat(Float(arc4random()) / Float(UINT32_MAX)))"
        let queryString = "?ts=" + dateString + mathRandomString
        urlStr += queryString
        
        print("urlStr: \(urlStr)")
        
        guard let url = URL(string: urlStr) else {
            completion(.failure(PeerError.invalidUrl))
            return
        }
        
        let request = URLRequest(url: url)

        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: request) { (data, response, error) in
            guard error == nil  else {
                completion(.failure(PeerError.requestFailed))
                return
            }

            guard let d = data else {
                completion(.failure(PeerError.requestFailed))
                return
            }

            guard let peerId = String(data: d, encoding: String.Encoding.utf8) else {
                completion(.failure(PeerError.requestFailed))
                return
            }

            completion(.success(peerId))
        }
        task.resume()
    }
    
    func initialize(peerId: String, completion: @escaping (Result<String, Error>) -> Void) {
        self.peerId = peerId
        self.webSocket?.open(peerId: peerId, token: self.token, completion: { (result) in
            print("socket opened")
            DispatchQueue.main.async {
                completion(result)
            }
        })

        if let interval = self.options?.keepAliveTimerInterval, interval > 0 {
            self.keepAliveTimer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(self.onTimeout(timer:)), userInfo: nil, repeats: true)
        }
    }

    /**
     * Returns a DataConnection to the specified peer. See documentation for a
     * complete list of options.
     */
    public func connect(peerId: String, completion: @escaping (Result<DataConnection, Error>) -> Void ) {
        
        guard !self.isDisconnected else {
            print("You cannot connect to a new Peer because you called " +
                    ".disconnect() on this Peer and ended your connection with the " +
                    "server. You can create a new Peer to reconnect, or call reconnect " +
                    "on this peer if you believe its ID to still be available.")
            
            //this.emitError('disconnected', 'Cannot connect to new Peer after disconnecting from server.')
            completion(.failure(PeerError.peerDisconnected))
            return
        }

        guard self.dataConnections.count == 0 else {
            // do nothing
            print("data connection already exists")
            completion(.failure(PeerError.invalidState))
            return
        }

        let connectionOptions = PeerConnectionOptions(connectionType: .data, label: "RTCDataChannel", serialization: .binary, isReliable: false, iceServerOptions: self.options?.iceServerOptions)

        let connection = DataConnection(peerId: peerId, delegate: self, options: connectionOptions)
        self.connectionStore.addConnection(connection: connection)

        connection.open { [weak self] (result) in

            switch result {
            case let .success(message):
                let data = try? JSONSerialization.data(withJSONObject: message, options: [])
                self?.webSocket?.send(data: data)

                completion(.success(connection))

            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    // MEMO
    // mainView prepare localVideoTrack and do something and pass it as call parameter in options 
    // factory can accessed from singleton object of PeerConnectionFactory

    /**
     * Returns a MediaConnection to the specified peer. See documentation for a
     * complete list of options.
     */
    public func call(peerId: String, mediaStream: MediaStream, completion: @escaping (Result<MediaConnection, Error>) -> Void ) {
        guard  !self.isDisconnected else {
            print("You cannot connect to a new Peer because you called " +
                    ".disconnect() on this Peer and ended your connection with the " +
                    "server. You can create a new Peer to reconnect.")
            
            //this.emitError('disconnected', 'Cannot connect to new Peer after disconnecting from server.')
            completion(.failure(PeerError.peerDisconnected))
            return
        }

        let connectionOptions = PeerConnectionOptions(connectionType: .media, iceServerOptions: self.options?.iceServerOptions)
        let connection = MediaConnection(peerId: peerId, delegate: self, options: connectionOptions)
        self.connectionStore.addConnection(connection: connection)

        connection.open(stream: mediaStream.stream) { [weak self] (result) in
            
            switch result {
            case let .success(message):
                let data = try? JSONSerialization.data(withJSONObject: message, options: [])
                self?.webSocket?.send(data: data)

                completion(.success(connection))

            case let .failure(error):
                completion(.failure(error))
            }
        }

    }
    
    // MARK: moved from Upper layer
    public func answer(mediaStream: MediaStream, mediaConnection: MediaConnection, completion: @escaping (Error?) -> Void ) {

        mediaConnection.answer(stream: mediaStream.stream) { [weak self] (result) in

            switch result {
            case let .success(message):
                let data = try? JSONSerialization.data(withJSONObject: message, options: [])
                self?.webSocket?.send(data: data)
                completion(nil)

            case let .failure(error):
                completion(error)
            }
        }
    }

    public func answer(dataConnection: DataConnection, completion: @escaping (Error?) -> Void ) {

        dataConnection.answer { [weak self] (result) in

            switch result {
            case let .success(message):
                let data = try? JSONSerialization.data(withJSONObject: message, options: [])
                self?.webSocket?.send(data: data)
                completion(nil)

            case let .failure(error):
                completion(error)
            }
        }
    }

    public func closeConnections(_ connectionType: PeerConnection.ConnectionType, completion: @escaping (Error?) -> Void) {

        let connections = self.connectionStore.findConnections(connectionType: connectionType)
        guard connections.count > 0 else {
            completion(PeerError.invalidState)

            print("no connections are found. something went wrong? \(connectionType.string)")
            return
        }

        self.closeConnections(connections, completion: completion)
    }

    public func closeConnection(_ connectionId: String, completion: @escaping (Error?) -> Void) {

        guard let connections = self.connectionStore.findConnections(connectionId: connectionId), connections.count > 0 else {
            completion(PeerError.invalidState)

            print("no connections are found. something went wrong? \(connectionId)")
            return
        }

        self.closeConnections(connections, completion: completion)
    }

    public func closeAllConnections(_ completion: @escaping (Error?) -> Void) {

        let connections = self.connectionStore.allConnections()
        self.closeConnections(connections, completion: completion)
    }

    func closeConnections(_ connections: [PeerConnection], completion: @escaping (Error?) -> Void) {

        print("Peer closeConnections \(connections.count)")

        if connections.count == 0 {
            completion(nil)
            return
        }

        var closed = 0
        for connection in connections {
            connection.close({ [weak self] (error) in
                print("connection close done \(error.debugDescription)")
                self?.connectionStore.removeConnection(connection: connection)

                closed += 1
                if closed == connections.count {
                    completion(error)
                }
            })
        }
    }

    /*
    func delayedAbort(type: String, message: [String: Any]) {

    }
    */
    
    func abort(type: String, completion: @escaping (Error?) -> Void ) {

        print("Abort type: \(type)")

        if self.lastServerId == nil {
            self.destroy(completion)
        }
        else {
            self.disconnect(completion)
        }
        //this.emitError(type, message)
    }
    

    /**
     * Destroys the Peer: closes all active connections as well as the connection
     *  to the server.
     * Warning: The peer can no longer create or accept connections after being
     *  destroyed.
     */
    public func destroy(_ completion: @escaping (Error?) -> Void) {
        if !self.isDestroyed {
            self.cleanup()
            self.disconnect(completion)
            self.isDestroyed = true
        }
    }

    /** Disconnects every connection on this peer. */
    func cleanup() {
        let connections = self.connectionStore.allConnections()
        
        for connection in connections {
            connection.close({ (error) in
                self.delegate?.peer(self, didCloseConnection: connection)
                self.connectionStore.removeConnection(connection: connection)
            })
        }
        
        //this.emit('close');

        // TODO: check if this should call in callback of peer close
        DispatchQueue.main.async {
            self.delegate?.peer(self, didClose: self.peerId)
        }
    }

    /** Closes all connections to this peer. */
    func cleanup(peerId: String) {
        
        guard let connections = self.connectionStore.findConnections(peerId: peerId) else {
            return
        }

        for connection in connections {
            connection.close({ (error) in
                self.delegate?.peer(self, didCloseConnection: connection)
                self.connectionStore.removeConnection(connection: connection)
            })
        }
    }

    /**
     * Disconnects the Peer's connection to the PeerServer. Does not close any
     *  active connections.
     * Warning: The peer can no longer create or accept connections after being
     *  disconnected. It also cannot reconnect to the server.
     */
    public func disconnect(_ completion: @escaping (Error?) -> Void) {

        print("Peer disconnect")
        // TODO: when disconnect and connect again the disconnected flag should be initialized?

        //util.setZeroTimeout(function(){   // TODO
        if !self.isDisconnected {
            self.isDisconnected = true
            self.isOpen = false
            if let webSocket = self.webSocket {
                webSocket.close(completion)
            }
            else {
                // Socket does not exist!
                completion(PeerError.socketClosed)
            }
            
            //self.emit('disconnected', self.id);
            self.delegate?.peer(self, didClose: self.peerId)  // TODO: should this be here? or in socket delegate?
            self.lastServerId = self.peerId
            self.peerId = nil
        }
        else {
            // Peer already disconnected!
            completion(PeerError.peerDisconnected)
        }
    }

    /** Attempts to reconnect with the same ID. */
    func reconnect(_ completion: @escaping (Result<String, Error>) -> Void) {
        if self.isDisconnected && !self.isDestroyed {
            print("Attempting reconnection to server with ID \(self.lastServerId ?? "")")
            self.isDisconnected = false
            self.setupSocket()
            if let lastServerId = self.lastServerId {
                self.initialize(peerId: lastServerId, completion: completion)
            }
            else {
                completion(.failure(PeerError.invalidState))
            }
        }
        else if self.isDestroyed {
            //throw new Error('This peer cannot reconnect to the server. It has already been destroyed.');
            print("This peer cannot reconnect to the server. It has already been destroyed.")
        }
        else if !self.isDisconnected && !self.isOpen {
            // Do nothing. We're still connecting the first time.
            print("In a hurry? We\'re still trying to make the initial connection!")
        }
        else {
            //throw new Error('Peer ' + this.id + ' cannot reconnect because it is not disconnected from the server!');
            print("Peer \(String(describing: self.peerId)) cannot reconnect because it is not disconnected from the server!")
        }
    }

    /**
     * Get a list of available peer IDs. If you're running your own server, you'll
     * want to set allow_discovery: true in the PeerServer options. If you're using
     * the cloud server, email team@peerjs.com to get the functionality enabled for
     * your key.
     */
    public func listAllPeers(_ completion: @escaping (Result<[String], Error>) -> Void) {

        guard let options = self.options else {
            completion(.failure(PeerError.invalidOptions))
            return
        }
        let urlStr = options.httpUrl + "/peers"
        print("API URL: \(urlStr)")
        

        guard let url = URL(string: urlStr) else {
            completion(.failure(PeerError.invalidUrl))
            return
        }
        
        let request = URLRequest(url: url)

        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: request) { (data, response, error) in
            if error == nil, let d = data {
                do {
                    if let peerIds = try JSONSerialization.jsonObject(with: d, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String] {
                        completion(.success(peerIds))
                    }
                    else {
                        completion(.failure(PeerError.invalidJsonObject))
                    }
                } catch {
                    print("NSJSONSerialization.JSONObjectWithData failed")
                    completion(.failure(PeerError.invalidJsonObject))
                }
            }
            else {
                completion(.failure(PeerError.requestFailed))
            }
        }
        task.resume()
    }

    // MARK: data channel utilities

    
    // MARK: timer handler
    
    @objc func onTimeout(timer: Timer) {
        
        var socketClosed = false
        
        if let ws = self.webSocket {
            if ws.isDisconnected {
                socketClosed = true
            }
        }
        else {
            socketClosed = true
        }
        
        if socketClosed {
            print("time out with socket closed")
            self.keepAliveTimer?.invalidate()
        }
        else {
            print("ping to server")
            self.pingToServer()
        }
    }
    
    // MARK: private method
    
    // this method is needed for Heroku to prevent connection from closing with time out
    func pingToServer() {
        let message: [String: Any] = [
            "type": "ping"
        ]
        let data = try? JSONSerialization.data(withJSONObject: message, options: [])
        self.webSocket?.send(data: data)
    }
}
