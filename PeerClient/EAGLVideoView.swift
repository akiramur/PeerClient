//
//  EAGLVideoView.swift
//  PeerClient
//
//  Created by Akira Murao on 4/4/16.
//  Copyright © 2017 Akira Murao. All rights reserved.
//

import UIKit
import libjingle_peerconnection

public protocol EAGLVideoViewDelegate {
    func videoView(videoView: EAGLVideoView!, didChangeVideoSize size: CGSize)
}

public class EAGLVideoView: UIView, RTCEAGLVideoViewDelegate {
    
    public var delegate: EAGLVideoViewDelegate?
    var videoView: RTCEAGLVideoView?
    
    public override var frame: CGRect {
        willSet {
            let videoViewFrame = CGRect(x: 0, y: 0, width: newValue.width, height: newValue.height)
            self.videoView?.frame = videoViewFrame
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.videoView = RTCEAGLVideoView(coder: aDecoder)
        self.videoView?.delegate =  self
        
        self.addSubview(videoView!)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        let videoViewFrame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        self.videoView = RTCEAGLVideoView(frame: videoViewFrame)
        self.videoView?.delegate =  self
        
        self.addSubview(videoView!)
    }

    public func renderFrame() {
        self.videoView?.renderFrame(nil)
    }

    // MARK: RTCEAGLVideoViewDelegate

    public func videoView(_ videoView: RTCEAGLVideoView!, didChangeVideoSize size: CGSize) {
        self.frame.size = size
        self.delegate?.videoView(videoView: self, didChangeVideoSize: size)
    }
}
