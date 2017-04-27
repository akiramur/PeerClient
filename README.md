# PeerClient

## About
<b>PeerClient</b> is WebRTC client library for iOS which communicates to [peerjs-server](https://github.com/peers/peerjs-server).
This library is written with Swift, ported from [peerjs](https://github.com/peers/peerjs) client javascript code. 

## Dependencies

### [libgingle](https://cocoapods.org/pods/libjingle_peerconnection)
### [SocketRocket](https://github.com/facebook/SocketRocket)

## Usage

1. Clone this repository.

```
$ git clone https://github.com/akiramur/PeerClient.git
```

2. Download [libgingle](https://cocoapods.org/pods/libjingle_peerconnection)  .
you need to download it with [cocoapod](https://cocoapods.org/pods/libjingle_peerconnection) and put in project mannually.

3. Put the libgingle headers and objects in the Dependencies directory.  
you need to place following header files under 

```
Dependencies/libjingle_peerconnection/Headers
```

```
RTCAVFoundationVideoSource.h  
RTCOpenGLVideoRenderer.h  
RTCAudioSource.h  
RTCPair.h  
RTCAudioTrack.h  
RTCPeerConnection.h  
RTCDataChannel.h  
RTCPeerConnectionDelegate.h  
RTCEAGLVideoView.h  
RTCPeerConnectionFactory.h  
RTCFileLogger.h  
RTCPeerConnectionInterface.h  
RTCI420Frame.h  
RTCSessionDescription.h  
RTCICECandidate.h  
RTCSessionDescriptionDelegate.h  
RTCICEServer.h  
RTCStatsDelegate.h  
RTCLogging.h  
RTCStatsReport.h  
RTCMediaConstraints.h  
RTCTypes.h  
RTCMediaSource.h  
RTCVideoCapturer.h  
RTCMediaStream.h  
RTCVideoRenderer.h  
RTCMediaStreamTrack.h  
RTCVideoSource.h  
RTCNSGLVideoView.h  
RTCVideoTrack.h  
```
also need to place <b>libWebRTC.a</b> under  

```
Dependencies/libjingle_peerconnection
```

4. Download [SocketRocket](https://github.com/facebook/SocketRocket) with carthage  

```
% cd path_to_the_directory/PeerClient  
% carthage update --platform iOS  
```

5. Please refer to [PeerClientApp](https://github.com/akiramur/PeerClientApp) for more details.

## License

MIT
