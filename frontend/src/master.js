import { Role } from 'amazon-kinesis-video-streams-webrtc'
import WebRtcClient from './webRtcClient'

export default class Master {
  constructor(setState, onStatsReport, onRemoteDataMessage, logEvent) {
    this.setState = setState
    this.onStatsReport = onStatsReport
    this.onRemoteDataMessage = onRemoteDataMessage
    this.logEvent = logEvent
    this.signalingClient = null
    this.peerConnectionByClientId = {}
    this.dataChannelByClientId = {}
    this.localStream = null
    this.remoteStreams = []
    this.peerConnectionStatsInterval = null
    this.remoteViewSrcObject = null
    this.peerConnection = null
    this.dataChannel = null
  }

  setLocalViewSrcObject(srcObject) {
    this.localViewSrcObject = srcObject
    this.setState({
      localViewSrcObject: srcObject
    })
  }

  setRemoteViewSrcObject(srcObject) {
    this.remoteViewSrcObject = srcObject
    this.setState({
      remoteViewSrcObject: srcObject
    })
  }

  async start(credentials, params) {

    const {
      region,
      endpoint,
      channelName,
      clientId,
      sendAudio,
      sendVideo,
      openDataChannel,
      widescreen,
      forceTURN,
      natTraversalDisabled,
      useTrickleICE,
    } = params


    this.webRtcClient = new WebRtcClient(
      Role.MASTER,
      credentials,
      region,
      endpoint,
      channelName,
      clientId,
      natTraversalDisabled,
      forceTURN,
      this.logEvent,
    )

    const channelARN = await this.webRtcClient.getChannelARN()
    this.logEvent('debug', `[MASTER] Channel ARN: ${channelARN}`)

    const endpointsByProtocol = await this.webRtcClient.getEndpointsByProtocol()
    this.logEvent('debug', `[MASTER] Signaling Channel Endpoints: ${JSON.stringify(endpointsByProtocol, null, 2)}`)

    const iceServers = await this.webRtcClient.getIceServers()
    this.logEvent('debug', `[MASTER] ICE servers: ${JSON.stringify(iceServers, null, 2)}`)

    this.signalingClient = await this.webRtcClient.getSignalingClient()

    const configuration = {
      iceServers,
      iceTransportPolicy: forceTURN ? 'relay' : 'all',
    };

    const resolution = widescreen ? { width: { ideal: 1280 }, height: { ideal: 720 } } : { width: { ideal: 640 }, height: { ideal: 480 } };
    const constraints = {
      video: sendVideo ? resolution : false,
      audio: sendAudio,
    };

    // Get a stream from the webcam and display it in the local view.
    // If no video/audio needed, no need to request for the sources.
    // Otherwise, the browser will throw an error saying that either video or audio has to be enabled.
    if (sendVideo || sendAudio) {
        try {
            this.localStream = await navigator.mediaDevices.getUserMedia(constraints);
            this.setLocalViewSrcObject(this.localStream)
        } catch (e) {
            this.logEvent('error', '[MASTER] Could not find webcam');
        }
    }

    this.signalingClient.on('open', async () => {
        this.logEvent('debug', '[MASTER] Connected to signaling service');
    });

    this.signalingClient.on('sdpOffer', async (offer, remoteClientId) => {
        this.logEvent('debug', '[MASTER] Received SDP offer from client: ' + remoteClientId);

        // Create a new peer connection using the offer from the given client
        const peerConnection = new RTCPeerConnection(configuration);
        this.peerConnectionByClientId[remoteClientId] = peerConnection;

        if (openDataChannel) {
            this.dataChannelByClientId[remoteClientId] = peerConnection.createDataChannel('kvsDataChannel');
            peerConnection.ondatachannel = event => {
                event.channel.onmessage = this.onRemoteDataMessage;
            };
        }

        // Poll for connection stats
        if (!this.peerConnectionStatsInterval) {
            this.peerConnectionStatsInterval = setInterval(() => peerConnection.getStats().then(this.onStatsReport), 1000);
        }

        // Send any ICE candidates to the other peer
        peerConnection.addEventListener('icecandidate', ({ candidate }) => {
            if (candidate) {
                this.logEvent('debug', `[MASTER] Generated ICE candidate for client: ${remoteClientId} ${JSON.stringify(candidate)}`);

                // When trickle ICE is enabled, send the ICE candidates as they are generated.
                if (useTrickleICE) {
                    this.logEvent('debug', `[MASTER] Sending ICE candidate to client: ${remoteClientId} ${JSON.stringify(candidate)}`);
                    this.signalingClient.sendIceCandidate(candidate, remoteClientId);
                }
            } else {
                this.logEvent('debug', '[MASTER] All ICE candidates have been generated for client: ' + remoteClientId);

                // When trickle ICE is disabled, send the answer now that all the ICE candidates have ben generated.
                if (!useTrickleICE) {
                    this.logEvent('debug', `[MASTER] Sending SDP answer to client: ${remoteClientId} Type: ${peerConnection.localDescription.type}\nSDP:\n${peerConnection.localDescription.sdp}`);
                    this.signalingClient.sendSdpAnswer(peerConnection.localDescription, remoteClientId);
                }
            }
        });

        // As remote tracks are received, add them to the remote view
        peerConnection.addEventListener('track', event => {
            this.logEvent('debug', '[MASTER] Received remote track from client: ' + remoteClientId);
            if (this.remoteViewSrcObject) {
                return
            }

            this.setRemoteViewSrcObject(event.streams[0])
        });

        // If there's no video/audio, master.localStream will be null. So, we should skip adding the tracks from it.
        if (this.localStream) {
            this.localStream.getTracks().forEach(track => peerConnection.addTrack(track, this.localStream));
        }
        await peerConnection.setRemoteDescription(offer);

        // Create an SDP answer to send back to the client
        this.logEvent('debug', '[MASTER] Creating SDP answer for client: ' + remoteClientId);
        await peerConnection.setLocalDescription(
            await peerConnection.createAnswer({
                offerToReceiveAudio: true,
                offerToReceiveVideo: true,
            }),
        );

        // When trickle ICE is enabled, send the answer now and then send ICE candidates as they are generated. Otherwise wait on the ICE candidates.
        if (useTrickleICE) {
            this.logEvent('debug', `[MASTER] Sending SDP answer to client: ${remoteClientId} Type: ${peerConnection.localDescription.type}\nSDP:\n${peerConnection.localDescription.sdp}`);
            this.signalingClient.sendSdpAnswer(peerConnection.localDescription, remoteClientId);
        }
        this.logEvent('debug', '[MASTER] Generating ICE candidates for client: ' + remoteClientId);
    });

    this.signalingClient.on('iceCandidate', async (candidate, remoteClientId) => {
        this.logEvent('debug', `[MASTER] Received ICE candidate from client ${remoteClientId}: ${candidate.candidate}`);

        // Add the ICE candidate received from the client to the peer connection
        const peerConnection = this.peerConnectionByClientId[remoteClientId];
        peerConnection.addIceCandidate(candidate);
    });

    this.signalingClient.on('close', () => {
        this.logEvent('debug', '[MASTER] Disconnected from signaling channel');
    });

    this.signalingClient.on('error', () => {
        this.logEvent('error', '[MASTER] Signaling client error');
    });

    this.logEvent('debug', '[MASTER] Starting master connection');
    this.signalingClient.open();
  }

  stop(){
    this.logEvent('debug', '[MASTER] Stopping master connection');
    if (this.signalingClient) {
        this.signalingClient.close();
        this.signalingClient = null;
    }

    Object.keys(this.peerConnectionByClientId).forEach(clientId => {
        this.peerConnectionByClientId[clientId].close();
    });
    this.peerConnectionByClientId = [];

    if (this.localStream) {
        this.localStream.getTracks().forEach(track => track.stop());
        this.localStream = null;
    }

    this.remoteStreams.forEach(remoteStream => remoteStream.getTracks().forEach(track => track.stop()));
    this.remoteStreams = [];

    if (this.peerConnectionStatsInterval) {
        clearInterval(this.peerConnectionStatsInterval);
        this.peerConnectionStatsInterval = null;
    }

    if (this.localViewSrcObject) {
        this.setLocalViewSrcObject(null)
    }

    if (this.remoteViewSrcObject) {
        this.setRemoteViewSrcObject(null)
    }

    if (this.dataChannelByClientId) {
        this.dataChannelByClientId = {};
    }
  }

  sendMessage(message){
    Object.keys(this.dataChannelByClientId).forEach(clientId => {
        try {
            this.dataChannelByClientId[clientId].send(message);
        } catch (e) {
            this.logEvent('error', '[MASTER] Send DataChannel: ', e.toString());
        }
    });
  }
}
