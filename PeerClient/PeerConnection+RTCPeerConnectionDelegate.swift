//
//  PeerConnection+RTCPeerConnection.swift
//  PeerClient
//
//  Created by Akira Murao on 2017/03/08.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation
import libjingle_peerconnection

extension PeerConnection: RTCPeerConnectionDelegate {
    
    // TODO: no implementation in PeerJS?
    public func peerConnection(_ peerConnection: RTCPeerConnection!, signalingStateChanged stateChanged: RTCSignalingState) {

        print("Signaling state changed: \(stateChanged.toString())")

        /*
         switch(stateChanged.rawValue) {
         case RTCSignalingStable.rawValue:
         if peerConnection == self.peerConnection {
         self.delegate?.peerClient(self, didStartCall: self.isInitiator)
         }

         case RTCSignalingClosed.rawValue:
         if peerConnection == self.peerConnection {
         self.delegate?.peerClient(self, didEndCall: self.isInitiator)
         }

         default:
         break
         }
         */
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection!, addedStream stream: RTCMediaStream!) {
        print("Received remote stream")
        print("ERROR: this sholud be overridden")
    }

    // TODO: no implementation in PeerJS?
    public func peerConnection(_ peerConnection: RTCPeerConnection!, removedStream stream: RTCMediaStream!) {
        print("Stream was removed.")
        print("ERROR: this sholud be overridden")
    }
    
    public func peerConnection(onRenegotiationNeeded peerConnection: RTCPeerConnection!) {
        print("`negotiationneeded` triggered: \(String(describing: peerConnection))")

        guard self.pc == peerConnection else {
            print("ERROR: peerConnection mismatched pc: \(String(describing: self.pc))")
            return
        }

        if peerConnection.signalingState == RTCSignalingStable {
            //self.makeOffer()
        }
        else {
            print("onnegotiationneeded triggered when not stable. Is another connection being established?")
        }
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection!, iceConnectionChanged newState: RTCICEConnectionState) {
        print("ICE state changed: \(newState.toString()), connectionId: \(self.options.connectionId)")

        switch newState {
        case RTCICEConnectionFailed:
            print("RTCICEConnectionFailed  \(self.peerId)")
            //self.close()  // FIXME: need to close here?
        case RTCICEConnectionDisconnected:
            print("RTCICEConnectionDisconnected \(self.peerId)")
            self.close({ (error) in
                DispatchQueue.main.async {
                    self.delegate?.connection(connection: self, didClose: error)
                }
            })
        case RTCICEConnectionClosed:
            print("RTCICEConnectionClosed")

            if let callback = self.closeCompletionBlock {
                DispatchQueue.main.async {
                    callback(nil)
                }
                self.closeCompletionBlock = nil
            }
            else {
                print("ERROR: callback must not be nil here. something went wrong?")
                DispatchQueue.main.async {
                    self.delegate?.connection(connection: self, didClose: nil)
                }
            }

        case RTCICEConnectionCompleted:
            print("RTCICEConnectionCompleted")
        default:
            print("default: \(newState.toString())")
        }

    }

    public func peerConnection(_ peerConnection: RTCPeerConnection!, iceGatheringChanged newState: RTCICEGatheringState) {
        print("ICE gathering state changed: \(newState.toString())")

        // same as iceConnectionChanged...
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection!, gotICECandidate candidate: RTCICECandidate!) {
        print("gotICECandidate")

        print("Received ICE candidates for: \(self.peerId)")
        print("connection type: \(self.options.connectionType.string)")

        // TODO: what is the string evt.candidate like?
        let candidateMessage = ["sdpMLineIndex": candidate.sdpMLineIndex,
                                "sdpMid": candidate.sdpMid,
                                "candidate": candidate.sdp] as [String : Any]

        let message: [String: Any] = [
            "type": "CANDIDATE",
            "payload": [
                "candidate": candidateMessage,
                "type": self.options.connectionType.string,
                "connectionId": self.options.connectionId
            ],
            "dst": self.peerId]

        print("sendCandidateMessage: \(candidate)")

        DispatchQueue.main.async {
            self.delegate?.connection(connection: self, shouldSendMessage: message, type: peerConnection.localDescription.type)
        }
    }
    
    public func peerConnection(_ peerConnection: RTCPeerConnection!, didOpen dataChannel: RTCDataChannel!) {
        print("Opened data channel")
        print("ERROR: this sholud be overridden")
    }
}
