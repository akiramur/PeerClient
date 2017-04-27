//
//  DataConnection.swift
//  PeerClient
//
//  Created by Akira Murao on 10/16/15.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation
import libjingle_peerconnection

public class DataConnection: PeerConnection {

    var dc: RTCDataChannel? {
        didSet {
            self.configureDataChannel()
        }
    }

    var buffer: [String]
    var buffering: Bool
    var bufferSize: Int
    
    var chunkedData: [String]

    var util: Utility
    //var reliable: Reliable?
    
    override init(peerId: String?, delegate: PeerConnectionDelegate?, options: PeerConnectionOptions) {

        self.dc = nil

        // Data channel buffering.
        self.buffer = []
        self.buffering = false
        self.bufferSize = 0

        // For storing large data.
        self.chunkedData = []

        self.util = Utility()

        super.init(peerId: peerId, delegate: delegate, options: options)
    }

    func open(_ completion: @escaping (Result<[String: Any], Error>) -> Void) {

        print("open (\(self.options.connectionId) <<")

        // if payload does NOT exists, it is considered as originator
        guard self.options.payload.count == 0 else {
            print("ERROR: options.payload.count > 0")
            completion(.failure(PeerConnectionError.invalidState))
            return
        }

        let factory = PeerConnectionFactory.sharedInstance
        guard let pc = factory.createPeerConnection(self.options, delegate: self) else {
            print("ERROR: pc is nil")
            completion(.failure(PeerConnectionError.invalidState))
            return
        }
        self.pc = pc

        // moved from negotiator only for data
        guard let dc = negotiator.createDataChannel(pc, options: self.options) else {
            print("ERROR: dc is nil")
            completion(.failure(PeerConnectionError.creatingDataChannel))
            return
        }
        self.dc = dc

        self.negotiator.startConnection(pc, peerId: self.peerId, options: self.options, completion: completion)

        print("open (\(self.options.connectionId) >>")
    }

    func answer(_ completion: @escaping (Result<[String: Any], Error>) -> Void) {

        print("answer (\(self.options.connectionId) <<")

        guard self.options.payload.count > 0 else {
            print("ERROR: options.payload.count > 0")
            completion(.failure(PeerError.invalidState))
            return
        }
        
        let factory = PeerConnectionFactory.sharedInstance
        guard let pc = factory.createPeerConnection(self.options, delegate: self) else {
            print("ERROR: pc is nil")
            completion(.failure(PeerError.invalidState))
            return
        }
        self.pc = pc

        self.negotiator.answerConnection(pc, peerId: self.peerId, options: self.options) { [weak self] (result) in
            self?.isOpen = true
            completion(result)
        }
        
        print("answer (\(self.options.connectionId) >>")
    }
    
    func configureDataChannel() {

        self.dc?.delegate = self
        
        // TODO: implement later
/*
        if self.util.supports.sctp {
            //self.dc?.binaryType = "arraybuffer"
        }

        // isOpen is set true when offer or answer is received
        /*
        self.dc.onopen = function() {
            print("Data channel connection success")
            self.open = true
            //self.emit("open")
        }
         */

        // Use the Reliable shim for non Firefox browsers
        if !self.util.supports.sctp && self.options.isReliable {
            //self.reliable = Reliable(self._dc, util.debug);
            if let dc = self.dc {
                self.reliable = Reliable(dc)
            }
        }

        if self.reliableObj != nil {
            self.reliableObj.onmessage = function(msg) {
                self.emit("data", msg);
            }
        }
        else {
            self.dc.onmessage = function(e) {
                self.handleDataMessage(e)
            }
        }
        
        self.dc.onclose = function(e) {
            print("DataChannel closed for:", self.peerId)
            self.close()
        }
        */
    }
    
    // Handles a DataChannel message.
    func handleDataMessage(e: [String: Any]) {

        // TODO: implement later
/*
        var data = e["data"]
        var datatype = data.constructor
        if (self.serialization == "binary" || self.serialization == "binary-utf8") {
            if (datatype == Blob) {
                // Datatype should never be blob
                util.blobToArrayBuffer(data, function(ab) {
                    data = util.unpack(ab);
                    self.emit("data", data);
                    });
                return;
            }
            else if (datatype == ArrayBuffer) {
                data = util.unpack(data);
            }
            else if (datatype == String) {
                // String fallback for binary data for browsers that don't support binary yet
                var ab = util.binaryStringToArrayBuffer(data);
                data = util.unpack(ab);
            }
        }
        else if (self.serialization == "json") {
            data = JSON.parse(data);
        }
    
        // Check if we've chunked--if so, piece things back together.
        // We're guaranteed that this isn't 0.
        if (data.__peerData) {
            var id = data.__peerData;
            var chunkInfo = self._chunkedData[id] || {data: [], count: 0, total: data.total};
    
            chunkInfo.data[data.n] = data.data;
            chunkInfo.count += 1;
    
            if (chunkInfo.total == chunkInfo.count) {
                // Clean up before making the recursive call to `_handleDataMessage`.
                delete self._chunkedData[id];
    
                // We've received all the chunks--time to construct the complete data.
                data = new Blob(chunkInfo.data);
                self._handleDataMessage({data: data});
            }
    
            self._chunkedData[id] = chunkInfo;
            return;
        }
    
        self.emit("data", data);
*/
    }
    
    /**
    * Exposed functionality for users.
    */
        
    /** Allows user to send data. */
    // TODO: implement later
/*
    func send(data, chunked) {
        
        if !self.open {
            //self.emit('error', new Error('Connection is not open. You should listen for the `open` event before sending messages.'));
            return
        }
        
        if self.reliableObj != nil {
            // Note: reliable shim sending will make it so that you cannot customize
            // serialization.
            self.reliableObj.send(data)
            return
        }
    

        if self.serialization == "json" {
            self.bufferedSend(JSON.stringify(data))
        }
        else if self.serialization == "binary" || self.serialization == "binary-utf8" {
            var blob = util.pack(data)
    
            // For Chrome-Firefox interoperability, we need to make Firefox "chunk"
            // the data it sends out.
            var needsChunking = util.chunkedBrowsers[self._peerBrowser] || util.chunkedBrowsers[util.browser]
            if (needsChunking && !chunked && blob.size > util.chunkedMTU) {
                self._sendChunks(blob)
                return
            }
    
            // DataChannel currently only supports strings.
            if !self.supportSctp {
                util.blobToBinaryString(blob, function(str) {
                    self.bufferedSend(str)
                });
            }
            else if !util.supports.binaryBlob {
                // We only do this if we really need to (e.g. blobs are not supported),
                // because this conversion is costly.
                util.blobToArrayBuffer(blob, function(ab) {
                    self.bufferedSend(ab)
                });
            }
            else {
                self.bufferedSend(blob)
            }
        }
        else {
            self.bufferedSend(data)
        }
    }
    
    func bufferedSend(msg) {
        if self.buffering || !self.trySend(msg) {
            self.buffer.push(msg)
            self.bufferSize = self._buffer.length
        }
    }
    
    // Returns true if the send succeeds.
    func trySend(msg) {
        try {
            self.dc.send(msg)
        } catch (e) {
            self.buffering = true
    
            setTimeout(function() {
                // Try again.
                self.buffering = false
                self._tryBuffer()
            }, 100)
            return false
        }
        return true
    }
    
    // Try to send the first message in the buffer.
    func tryBuffer() {
        if self.buffer.length == 0 {
            return
        }
    
        var msg = self.buffer[0]
    
        if self._trySend(msg) {
            self.buffer.shift()
            self.bufferSize = self.buffer.length
            self.tryBuffer()
        }
    }
    
    func sendChunks(blob) {
        var blobs = util.chunk(blob)
        for let blob in blobs {
            self.send(blob, true);
        }
    }
*/
    
    // MARK: data channel utilities

    public func sendData(bytes: [UInt8]) {

        if let dataChannel = self.dc {
            let data = Data(bytes: bytes)
            let buffer = RTCDataBuffer(data: data, isBinary: true)
            dataChannel.sendData(buffer)
        }

    }
}
