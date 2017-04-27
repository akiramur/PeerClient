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

2. Download [SocketRocket](https://github.com/facebook/SocketRocket) with carthage  

```
% cd path_to_the_directory/PeerClient  
% carthage update --platform iOS  
```

3. Please refer to [PeerClientApp](https://github.com/akiramur/PeerClientApp) for more details.

## License

MIT
