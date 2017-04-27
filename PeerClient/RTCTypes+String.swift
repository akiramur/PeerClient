//
//  RTCICEConnectionState+String.swift
//  PeerClient
//
//  Created by Akira Murao on 2017/03/08.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation
import libjingle_peerconnection

public extension RTCICEConnectionState {

    func toString() -> String {

        switch self {
        case RTCICEConnectionNew:
            return "RTCICEConnectionNew"

        case RTCICEConnectionChecking:
            return "RTCICEConnectionChecking"

        case RTCICEConnectionConnected:
            return "RTCICEConnectionConnected"

        case RTCICEConnectionCompleted:
            return "RTCICEConnectionCompleted"

        case RTCICEConnectionFailed:
            return "RTCICEConnectionFailed"

        case RTCICEConnectionDisconnected:
            return "RTCICEConnectionDisconnected"

        case RTCICEConnectionClosed:
            return "RTCICEConnectionClosed"
        default:
            return ""
        }
    }
}

public extension RTCICEGatheringState {

    func toString() -> String {
        switch self {
        case RTCICEGatheringNew:
            return "RTCICEGatheringNew"

        case RTCICEGatheringGathering:
            return "RTCICEGatheringGathering"

        case RTCICEGatheringComplete:
            return "RTCICEGatheringComplete"

        default:
            return ""
        }
    }
}


public extension RTCSignalingState {

    func toString() -> String {
        switch self {
        case RTCSignalingStable:
            return "RTCSignalingStable"
        case RTCSignalingHaveLocalOffer:
            return "RTCSignalingHaveLocalOffer"
        case RTCSignalingHaveLocalPrAnswer:
            return "RTCSignalingHaveLocalPrAnswer"
        case RTCSignalingHaveRemoteOffer:
            return "RTCSignalingHaveRemoteOffer"
        case RTCSignalingHaveRemotePrAnswer:
            return "RTCSignalingHaveRemotePrAnswer"
        case RTCSignalingClosed:
            return "RTCSignalingClosed"
        default:
            return ""
        }
    }
}

