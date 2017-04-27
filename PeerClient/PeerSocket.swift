//
//  PeerSocket.swift
//  PeerClient
//
//  Created by Akira Murao on 9/23/15.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation
//import SRWebSocket
import SocketRocket

protocol PeerSocketDelegate {
    func webSocket(webSocket: PeerSocket, didReceiveMessage message: [String: Any]?)
    func webSocket(webSocket: PeerSocket, didCloseWithReason reason: String?)
    func webSocket(webSocket: PeerSocket, didFailWithError error: Error?)
}

enum PeerSocketError: Error {
    case socketClosed   // Socket was already closed
    case invalidState
    case socketAlreadyExists
}

class PeerSocket: NSObject, URLSessionDelegate, SRWebSocketDelegate {

    typealias SocketOpenCompletionBlock = (Result<String, Error>) -> Void
    typealias SocketCloseCompletionBlock = (Error?) -> Void
        
    var delegate: PeerSocketDelegate?

    var socketOpenCompletionBlock: SocketOpenCompletionBlock?
    var socketCloseCompletionBlock: SocketCloseCompletionBlock?

    // PeerJS port
    var messageQueue: [Any]
    var isDisconnected: Bool
    
    var httpUrl: String?
    var wsUrl: String?
    
    var peerId: String!
    
    var webSocket: SRWebSocket?
    
    var http: URLSessionDataTask?

    
    init(options: PeerOptions, delegate: PeerSocketDelegate?) {

        self.delegate = delegate

        // Disconnected manually.
        self.isDisconnected = false
        self.messageQueue = []

        self.httpUrl = options.httpUrl
        self.wsUrl = options.wsUrl

        self.socketOpenCompletionBlock = nil
        self.socketCloseCompletionBlock = nil

        super.init()
    }

    deinit {
        self.close { (error) in
            print("Socket closed reason: \(error.debugDescription)")
        }
    }
    
    func open(peerId: String, token: String, completion: @escaping SocketOpenCompletionBlock) {

        guard self.socketOpenCompletionBlock == nil else {
            print("ERROR: socketOpenCompletionBlock already exists. something went wrong.")
            return
        }

        print("PeerSocket open peerId: \(peerId), token: \(token)")
        self.socketOpenCompletionBlock = completion
        
        self.peerId = peerId
        
        self.httpUrl = self.httpUrl! + "/" + peerId + "/" + token
        self.wsUrl = self.wsUrl! + "&id=" + peerId + "&token=" + token
        
        //self.startXhrStream();
        self.openWebSocket(completion);
    }
    
    func openWebSocket(_ completion: SocketOpenCompletionBlock?) {

        if self.webSocket != nil {
            self.socketOpenCompletionBlock?(.failure(PeerSocketError.socketAlreadyExists))
            self.socketOpenCompletionBlock = nil
            return
        }
        
        if let url = URL(string: self.wsUrl!) {
            print("url \(url)")
            self.webSocket = SRWebSocket(url: url)
            self.webSocket?.delegate = self
            self.webSocket?.open()
        }
    }
    
    // TODO: for XHR
    func startXhrStream() {
        //let configuration = URLSessionConfiguration.defaultSessionConfiguration()
        //let session = URLSession(configuration: configuration, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)

        //let url = NSURL(string: self.httpUrl! + "/id?i=\(self.http?.taskIdentifier)") // TODO: i should be zero?
        guard let url = URL(string: self.httpUrl! + "/id?i=0") else {
            return
        }

        var request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 5.0)
        request.httpMethod = "post"
        self.http = session.dataTask(with: request, completionHandler: { (data, response, error) in
            if error != nil {
                // TODO: error
            }
            else {
                guard let r = response as? HTTPURLResponse else {
                    return
                }

                guard let d = data else{
                    return
                }

                guard let responseText = String(data: d, encoding: String.Encoding.utf8) else {
                    return
                }

                guard let webSocket = self.webSocket else {
                    return
                }

                if webSocket.readyState.rawValue == 2 {
                    // TODO:
                }
                else if webSocket.readyState.rawValue > 2 && r.statusCode == 200 {
                    // TODO:
                    self.handleStream(responseText: responseText)
                }
            }
        })
/*
        self.http = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) in
        //self.http = session.dataTaskWithURL(url!, completionHandler: { (data, response, error) in
            if let e = error {
                // TODO: error
            }
            else {
                if let r = response as? NSHTTPURLResponse {
                    var responseText: NSString? = nil
                    if let d = data {
                        responseText = NSString(data: d, encoding: NSUTF8StringEncoding)
                    }
                    
                    if self.webSocket?.readyState.rawValue == 2 {
                        // TODO:
                        let debug = 0
                    }
                    else if self.webSocket?.readyState.rawValue > 2 && r.statusCode == 200 && responseText != nil {
                        // TODO:
                        self.handleStream(responseText!)
                    }
                }
            }
        })
 */
        self.http?.resume()
    }
    
    // TODO: for XHR
    func handleStream(responseText: String) {
        
    }
    
    // TODO: for XHR
    func setHTTPTimeout() {
        
    }
    
    func wsOpen() -> Bool {
        
        var socketOpen = false
        if let socket = self.webSocket {
            if socket.readyState == SRReadyState.OPEN {
                socketOpen = true
            }
        }
        
        return socketOpen
    }
    
    func sendQueuedMessages() {
        
        /*
        for var i = 0, ii = self.messageQueue.count; i<ii; i++ {
            self.send(self.messageQueue[i])
        }
        */
        for message in self.messageQueue {
            self.send(data: message)
        }
    }
    
    func send(data: Any!) {
        
        if self.isDisconnected {
            return
        }
        
        if self.peerId == nil {
            self.messageQueue.append(data)
            return
        }
        
        // TODO: what to do?
        /*
        if data.type == nil || data.type.count == 0 {
            self.emit("error", "Invalid message")
            return
        }
        */
        
        if self.wsOpen() {
            self.webSocket?.send(data)
        }
        else {
            // TODO: XMLHttpRequest
        }
    }
    
    func close(_ completion: @escaping SocketCloseCompletionBlock) {

        print("PeerSocket close peerId: \(self.peerId)")

        guard self.socketCloseCompletionBlock == nil else {
            print("ERROR: socketCloseCompletionBlock already exists. something went wrong.")
            // do nothing without calling callback here
            return
        }

        self.socketCloseCompletionBlock = completion
        
        if !self.isDisconnected && self.wsOpen() {
            self.webSocket?.close()
            self.isDisconnected = true
        }
        else {
            self.socketCloseCompletionBlock?(PeerSocketError.socketClosed)
            self.socketCloseCompletionBlock = nil
        }
    }
    
    // MARK: SRWebSocketDelegate
    
    // onmessage
    func webSocket(_ webSocket: SRWebSocket!, didReceiveMessage message: Any!) {

        if let messageString = message as? String {
            print("WebSocket receive message: \(messageString)")

            guard let data = messageString.data(using: String.Encoding.utf8) else {
                return
            }

            guard let messageDictionary = (try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)) as? [String: Any] else {
                return
            }

            self.delegate?.webSocket(webSocket: self, didReceiveMessage: messageDictionary)
        }
    }

    func webSocket(_ webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {

        print("WebSocket closed. reason: \(reason)")
        
        self.isDisconnected = true

        // socketCloseCompletionBlock can be nil here becuase socket can be closed by server
        self.socketCloseCompletionBlock?(PeerSocketError.socketClosed)
        self.socketCloseCompletionBlock = nil

        // in case of socket is closed by server, delegate is needed to notify socket closed
        self.delegate?.webSocket(webSocket: self, didCloseWithReason: reason)
    }

    func webSocketDidOpen(_ webSocket: SRWebSocket!) {

        NSLog("WebSocket opened!")
        
        /*
        if self.timeout != nil {
            self.timeout?.invalidate()
            self.timeout = NSTimer.scheduledTimerWithTimeInterval(5000, target: self, selector: Selector("onTimeout:"), userInfo: nil, repeats: false)
        }
        */
        
        self.sendQueuedMessages()

        guard self.socketOpenCompletionBlock != nil else {
            print("ERROR: socketOpenCompletionBlock does NOT exist in webSocketDidOpen. something went wrong.")
            return
        }

        self.socketOpenCompletionBlock?(.success(self.peerId))
        self.socketOpenCompletionBlock = nil
        //self.delegate?.webSocketDidOpen(webSocket: self)
    }

    func webSocket(_ webSocket: SRWebSocket!, didFailWithError error: Error!) {

        print("WebSocket Error: \(error)")

        self.delegate?.webSocket(webSocket: self, didFailWithError: error)
    }
    
    // MARK: NSURLSessionDelegate

    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        completionHandler(
            URLSession.AuthChallengeDisposition.useCredential,
            URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        print(request.description)
        completionHandler(request)
    }

    // MARK: timer handler
    /*
    func onTimeout(timer: NSTimer) {
        self.http.abort()
        self.http = nil
    }
    */
}
