//
//  PeerVideoTrack.swift
//  PeerClient
//
//  Created by Akira Murao on 4/4/16.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import Foundation
import libjingle_peerconnection

public class VideoTrack {

    private(set) var videoTrack: RTCVideoTrack
    
    init?(_ videoTrack: RTCVideoTrack?) {
        
        if let track = videoTrack {
            self.videoTrack = track
        }
        else {
            return nil
        }
    }
    
    public func addVideoView(videoView: EAGLVideoView?) {
        if let renderer = videoView?.videoView {
            self.videoTrack.add(renderer)
        }
    }
    
    public func removeVideoView(videoView: EAGLVideoView?) {
        if let renderer = videoView?.videoView {
            self.videoTrack.remove(renderer)
        }
    }
    
}
