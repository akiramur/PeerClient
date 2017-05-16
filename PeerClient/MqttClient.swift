//
//  MqttClient.swift
//  PeerClient
//
//  Created by Akira Murao on 9/23/15.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation
import CocoaMQTT

protocol MqttClientDelegate {
    func mqttClient(_ mqttClient: MqttClient, didReceiveClientId clientId: String, message: [String: Any])
    func mqttClient(_ mqttClient: MqttClient, didReceiveMessage message: [String: Any])
    func mqttClient(_ mqttClient: MqttClient, didDisconnectWithError error: Error?)
}

enum MqttClientError: Error {
    case clientDisconnected   // Client was already closed
    case invalidState
    case clientAlreadyExists
}

class MqttClient: CocoaMQTTDelegate {

    enum TopicType {
        case offer
        case answer
    }

    typealias MqttConnectCompletionBlock = (Result<String, Error>) -> Void
    typealias MqttDisconnectCompletionBlock = (Error?) -> Void
        
    var delegate: MqttClientDelegate?

    var mqttConnectCompletionBlock: MqttConnectCompletionBlock?
    var mqttDisconnectCompletionBlock: MqttDisconnectCompletionBlock?


    var messageQueue: [CocoaMQTTMessage]
    var isDisconnected: Bool
    
    var mqttClient: CocoaMQTT?
    var mqttOptions: PeerOptions?

    var clientIds: [String]

    init(options: PeerOptions, delegate: MqttClientDelegate?) {

        self.delegate = delegate
        self.mqttOptions = options

        self.clientIds = []

        // Disconnected manually.
        self.isDisconnected = false
        self.messageQueue = []

        self.mqttConnectCompletionBlock = nil
        self.mqttDisconnectCompletionBlock = nil
    }

    deinit {
        self.disconnect { (error) in
            print("Client closed reason: \(error.debugDescription)")
        }
    }
    
    func connect(clientId: String?, options: MqttClientOptions, completion: @escaping MqttConnectCompletionBlock) {

        guard self.mqttConnectCompletionBlock == nil else {
            print("ERROR: mqttConnectCompletionBlock already exists. something went wrong.")
            return
        }

        print("Client connect clientId: \(String(describing: clientId))")
        self.mqttConnectCompletionBlock = completion
        

        if let myId = clientId {
            self.connectClient(myId, options: options, completion: completion);
        }
        else {
            let myId = self.generateClientId()
            self.connectClient(myId, options: options, completion: completion);
        }
    }

    func generateClientId() -> String {
        // TODO: replace this with something better
        return "PeerClient-" + String(ProcessInfo().processIdentifier)
    }

    func connectClient(_ clientId: String, options: MqttClientOptions, completion: MqttConnectCompletionBlock?) {

        guard self.mqttClient == nil else {
            self.mqttConnectCompletionBlock?(.failure(MqttClientError.clientAlreadyExists))
            self.mqttConnectCompletionBlock = nil
            return
        }

        let mqtt = CocoaMQTT(clientID: clientId, host: options.host, port: options.port)
        mqtt.username = options.username
        mqtt.password = options.password

        // this is to delete my clientId from the server when disconnected
        let message = CocoaMQTTWill(topic: "/clients/\(clientId)", message: "")
        message.retained = true
        mqtt.willMessage = message

        mqtt.keepAlive = options.keepAlive
        mqtt.delegate = self
        self.mqttClient = mqtt

        self.mqttClient?.connect()
    }

    func sendQueuedMessages() {
        
        for message in self.messageQueue {
            self.mqttClient?.publish(message)
        }
    }

    func publish(to: String, topic: TopicType, dictionary: [String: Any]) {

        if self.isDisconnected {
            return
        }

        guard let clientId = self.mqttClient?.clientID else {
            return
        }

        var topicString: String?
        switch topic {
        case .offer:
            topicString = "/signailing/offer/\(to)"
        case .answer:
            topicString = "/signailing/answer/\(to)"
        }

        guard let topic = topicString else {
            return
        }

        var dictionaryWithSrc: Dictionary = dictionary
        if dictionaryWithSrc["src"] == nil {
            dictionaryWithSrc["src"] = clientId
        }

        guard let data = try? JSONSerialization.data(withJSONObject: dictionaryWithSrc, options: []) else {
            return
        }

        guard let dataString = String(data: data, encoding: .utf8) else {
            return
        }

        let message = CocoaMQTTMessage(topic: topic, string: dataString)

        guard let mqttClient = self.mqttClient else {
            self.messageQueue.append(message)
            return
        }
        
        mqttClient.publish(message)
    }
    
    func disconnect(_ completion: @escaping MqttDisconnectCompletionBlock) {

        //self.clearAllClientIds()    // debug

        print("Client close peerId: \(String(describing: self.mqttClient?.clientID))")

        // need to send empty payload to delete the retained message
        if let clientId = self.mqttClient?.clientID {
            let message = CocoaMQTTMessage(topic: "/clients/\(clientId)", payload: [])
            message.retained = true
            self.mqttClient?.publish(message)
        }

        guard self.mqttDisconnectCompletionBlock == nil else {
            print("ERROR: mqttDisconnectCompletionBlock already exists. something went wrong.")
            // do nothing without calling callback here
            return
        }

        self.mqttDisconnectCompletionBlock = completion
        
        if !self.isDisconnected && self.mqttClient?.connState == .connected {
            self.mqttClient?.disconnect()
            self.isDisconnected = true
        }
        else {
            self.mqttDisconnectCompletionBlock?(MqttClientError.clientDisconnected)
            self.mqttDisconnectCompletionBlock = nil
        }
    }

    // MARK: debug
    func clearAllClientIds() {

        for clientId in self.clientIds {
            let message = CocoaMQTTMessage(topic: "/clients/\(clientId)", payload: [])
            message.retained = true
            self.mqttClient?.publish(message)
        }
    }



    // MARK: MtqqClientDelegate

    func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {

        print("mqttDidConnect")

        guard let clientId = self.mqttClient?.clientID else {
            self.mqttConnectCompletionBlock?(.failure(MqttClientError.invalidState))
            self.mqttConnectCompletionBlock = nil
            return
        }

        self.mqttClient?.subscribe("/clients/#")
        self.mqttClient?.subscribe("/signailing/offer/\(clientId)")
        self.mqttClient?.subscribe("/signailing/answer/\(clientId)")

        let dictionary = ["status": "connected"]
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []) else {
            return
        }

        guard let dataString = String(data: data, encoding: .utf8) else {
            return
        }

        let message = CocoaMQTTMessage(topic: "/clients/\(clientId)", string: dataString)
        message.retained = true
        self.messageQueue.append(message)

        self.sendQueuedMessages()

        guard self.mqttConnectCompletionBlock != nil else {
            print("ERROR: mqttConnectCompletionBlock does NOT exist in mqttDidConnect. something went wrong.")
            return
        }

        self.mqttConnectCompletionBlock?(.success(clientId))
        self.mqttConnectCompletionBlock = nil
    }

    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        print("mqttDidConnectAck")
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("mqttDidPublishMessage")
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("mqttDidPublishAck")
    }

    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {

        print("mqttDidReceiveMessage: \(message.description), topic: \(message.topic)")

        guard let messageString = message.string else {
            return
        }

        guard let data = messageString.data(using: String.Encoding.utf8) else {
            return
        }

        guard let messageDictionary = (try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)) as? [String: Any] else {
            return
        }

        if message.topic.hasPrefix("/clients/") {

            let offset = "/clients/".characters.count
            let clientId = message.topic.substring(from: message.topic.index(message.topic.startIndex, offsetBy: offset))

            if let status = messageDictionary["status"] as? String {
                if status == "connected" {
                    if !self.clientIds.contains(clientId) {
                        self.clientIds.append(clientId)
                    }
                }
                else {
                    if let index = self.clientIds.index(of: clientId) {
                        self.clientIds.remove(at: index)
                    }
                }
            }

            self.delegate?.mqttClient(self, didReceiveClientId: clientId, message: messageDictionary)
        }
        else {
            self.delegate?.mqttClient(self, didReceiveMessage: messageDictionary)
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {

    }

    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {

    }

    func mqttDidPing(_ mqtt: CocoaMQTT) {

    }

    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {

    }

    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {

        print("mqttDidDisconnect error: \(err.debugDescription)")

        self.isDisconnected = true

        // mqttDisconnectCompletionBlock can be nil here becuase client can be disconnected by server
        self.mqttDisconnectCompletionBlock?(MqttClientError.clientDisconnected)
        self.mqttDisconnectCompletionBlock = nil

        // in case of cllient is disconnected by server, delegate is needed to notify client disconnected
        self.delegate?.mqttClient(self, didDisconnectWithError: err)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        
    }

}
