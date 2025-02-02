import { Role } from "amazon-kinesis-video-streams-webrtc";
import WebRtcClient from "../../backup/webRtcClient";
import { logger } from "./logger";

export default class Viewer {
  constructor(setState, onStatsReport, onRemoteDataMessage) {
    this.setState = setState;
    this.onStatsReport = onStatsReport;
    this.onRemoteDataMessage = onRemoteDataMessage;
    this.signalingClient = null;
    this.peerConnection = null;
    this.dataChannel = null;
    this.peerConnectionStatsInterval = null;
    this.localStream = null;
    this.remoteStream = null;
    this.localViewSrcObject = null;
    this.remoteViewSrcObject = null;
  }

  setLocalViewSrcObject(srcObject) {
    logger.debug(`setting local view srcObject: ${srcObject}`);
    this.localViewSrcObject = srcObject;
    this.setState({
      localViewSrcObject: srcObject,
    });
  }

  setRemoteViewSrcObject(srcObject) {
    logger.debug(`setting remote view srcObject: ${srcObject}`);
    this.remoteViewSrcObject = srcObject;
    this.setState({
      remoteViewSrcObject: srcObject,
    });
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
      natTraversal,
      useTrickleICE,
    } = params;

    this.webRtcClient = new WebRtcClient(
      Role.VIEWER,
      credentials,
      region,
      endpoint,
      channelName,
      clientId,
      natTraversal
    );

    const channelARN = await this.webRtcClient.getChannelARN();
    logger.debug("[VIEWER] Channel ARN: " + channelARN);

    const endpointsByProtocol =
      await this.webRtcClient.getEndpointsByProtocol();
    logger.debug(
      "[VIEWER] Signaling Channel Endpoints: " +
        JSON.stringify(endpointsByProtocol, null, 2)
    );

    const iceServers = await this.webRtcClient.getIceServers();
    logger.debug(
      "[VIEWER] ICE servers: " + JSON.stringify(iceServers, null, 2)
    );

    this.signalingClient = await this.webRtcClient.getSignalingClient();

    const resolution = widescreen
      ? {
          width: {
            ideal: 1280,
          },
          height: {
            ideal: 720,
          },
        }
      : {
          width: {
            ideal: 640,
          },
          height: {
            ideal: 480,
          },
        };

    const constraints = {
      video: sendVideo ? resolution : false,
      audio: sendAudio,
    };

    const configuration = {
      iceServers,
      iceTransportPolicy: natTraversal === "forceTURN" ? "relay" : "all",
    };

    this.peerConnection = new RTCPeerConnection(configuration);
    if (openDataChannel) {
      this.dataChannel =
        this.peerConnection.createDataChannel("kvsDataChannel");
      this.peerConnection.ondatachannel = (event) => {
        event.channel.onmessage = this.onRemoteDataMessage;
      };
    }

    // Poll for connection stats
    this.peerConnectionStatsInterval = setInterval(
      () => this.peerConnection.getStats().then(this.onStatsReport),
      1000
    );

    this.signalingClient.on("open", async () => {
      logger.debug("[VIEWER] Connected to signaling service");

      // Get a stream from the webcam, add it to the peer connection, and display it in the local view.
      // If no video/audio needed, no need to request for the sources.
      // Otherwise, the browser will throw an error saying that either video or audio has to be enabled.
      if (sendVideo || sendAudio) {
        try {
          this.localStream = await navigator.mediaDevices.getUserMedia(
            constraints
          );
          this.localStream
            .getTracks()
            .forEach((track) =>
              this.peerConnection.addTrack(track, this.localStream)
            );
          this.setLocalViewSrcObject(this.localStream);
        } catch (e) {
          logger.error("[VIEWER] Could not find webcam");
          return;
        }
      }

      // Create an SDP offer to send to the master
      logger.debug("[VIEWER] Creating SDP offer");
      await this.peerConnection.setLocalDescription(
        await this.peerConnection.createOffer({
          offerToReceiveAudio: true,
          offerToReceiveVideo: true,
        })
      );

      // When trickle ICE is enabled, send the offer now and then send ICE candidates as they are generated. Otherwise wait on the ICE candidates.
      if (useTrickleICE) {
        logger.debug(
          `[VIEWER] Sending SDP offer. Type: ${this.peerConnection.localDescription.type}\nSDP:\n${this.peerConnection.localDescription.sdp}`
        );
        this.signalingClient.sendSdpOffer(this.peerConnection.localDescription);
      }
      logger.debug("[VIEWER] Generating ICE candidates");
    });

    this.signalingClient.on("sdpAnswer", async (answer) => {
      // Add the SDP answer to the peer connection
      logger.debug(
        `[VIEWER] Received SDP answer; type: ${answer.type}\nSDP:\n${answer.sdp}`
      );
      await this.peerConnection.setRemoteDescription(answer);
    });

    this.signalingClient.on("iceCandidate", (candidate) => {
      // Add the ICE candidate received from the MASTER to the peer connection
      logger.debug(`[VIEWER] Received ICE candidate: ${candidate.candidate}`);
      this.peerConnection.addIceCandidate(candidate);
    });

    this.signalingClient.on("close", () => {
      logger.debug("[VIEWER] Disconnected from signaling channel");
    });

    this.signalingClient.on("error", (error) => {
      logger.error("[VIEWER] Signaling client error: ", error);
    });

    // Send any ICE candidates to the other peer
    this.peerConnection.addEventListener("icecandidate", ({ candidate }) => {
      if (candidate) {
        logger.debug(
          `[VIEWER] Generated ICE candidate: ${candidate.candidate}`
        );

        // When trickle ICE is enabled, send the ICE candidates as they are generated.
        if (useTrickleICE) {
          logger.debug(`[VIEWER] Sending ICE candidate ${candidate.candidate}`);
          this.signalingClient.sendIceCandidate(candidate);
        }
      } else {
        logger.debug("[VIEWER] All ICE candidates have been generated");

        // When trickle ICE is disabled, send the offer now that all the ICE candidates have ben generated.
        if (!useTrickleICE) {
          logger.debug(
            `[VIEWER] Sending SDP offer. Type: ${this.peerConnection.localDescription.type}\nSDP:\n${this.peerConnection.localDescription.sdp}`
          );
          this.signalingClient.sendSdpOffer(
            this.peerConnection.localDescription
          );
        }
      }
    });

    // As remote tracks are received, add them to the remote view
    this.peerConnection.addEventListener("track", (event) => {
      logger.debug("[VIEWER] Received remote track");
      if (this.remoteViewSrcObject) {
        return;
      }

      this.setRemoteViewSrcObject(event.streams[0]);
    });

    logger.debug("[VIEWER] Starting viewer connection");
    this.signalingClient.open();
  }

  stop() {
    logger.debug("[VIEWER] Stopping viewer connection");
    if (this.signalingClient) {
      this.signalingClient.close();
      this.signalingClient = null;
    }

    if (this.peerConnection) {
      this.peerConnection.close();
      this.peerConnection = null;
    }

    if (this.localStream) {
      this.localStream.getTracks().forEach((track) => track.stop());
      this.localStream = null;
    }

    if (this.remoteStream) {
      this.remoteStream.getTracks().forEach((track) => track.stop());
      this.remoteStream = null;
    }

    if (this.peerConnectionStatsInterval) {
      clearInterval(this.peerConnectionStatsInterval);
      this.peerConnectionStatsInterval = null;
    }

    if (this.localViewSrcObject) {
      this.localViewSrcObject = null;
    }

    if (this.remoteViewSrcObject) {
      this.remoteViewSrcObject = null;
    }

    if (this.dataChannel) {
      this.dataChannel = null;
    }
  }

  sendMessage(message) {
    if (this.dataChannel) {
      try {
        this.dataChannel.send(message);
      } catch (e) {
        logger.error("[VIEWER] Send DataChannel: ", e.toString());
      }
    }
  }
}
