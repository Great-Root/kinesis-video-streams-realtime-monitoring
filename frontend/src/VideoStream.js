import React, { useEffect, useState } from "react";
import AWS from "aws-sdk";
import { setupHLSPlayer } from "./hls";
import { Auth } from "aws-amplify";

const AWS_REGION = process.env.REACT_APP_AWS_PROJECT_REGION;

const STREAM_NAME = "groot-dev-kvs-stream";

const VideoStream = () => {
  const [streamUrl, setStreamUrl] = useState("");
  const [streamStatus, setStreamStatus] = useState("스트림 로딩 중...");

  const fetchStreamUrl = async () => {
    try {
      setStreamStatus("스트림을 다시 로드 중...");
      // AWS Cognito 인증 정보 가져오기
      const credentials = await Auth.currentCredentials();

      // AWS SDK의 글로벌 설정에 인증 정보 적용
      AWS.config.update({
        credentials: credentials, // Amplify에서 가져온 AWS 인증 정보 사용
        region: AWS_REGION,
      });

      const kinesisVideo = new AWS.KinesisVideo();
      const dataEndpointResponse = await kinesisVideo
        .getDataEndpoint({
          StreamName: STREAM_NAME,
          APIName: "GET_HLS_STREAMING_SESSION_URL",
        })
        .promise();

      const kinesisVideoArchivedContent = new AWS.KinesisVideoArchivedMedia({
        endpoint: dataEndpointResponse.DataEndpoint,
      });

      const hlsResponse = await kinesisVideoArchivedContent
        .getHLSStreamingSessionURL({
          StreamName: STREAM_NAME,
          PlaybackMode: "LIVE",
          HLSFragmentSelector: { FragmentSelectorType: "SERVER_TIMESTAMP" },
        })
        .promise();

      setStreamUrl(hlsResponse.HLSStreamingSessionURL);
      setStreamStatus("스트림 활성화됨");
    } catch (error) {
      console.error("Error fetching HLS stream:", error);
      setStreamStatus("스트림이 진행되지 않고 있습니다.");
    }
  };

  useEffect(() => {
    fetchStreamUrl();
  }, []);

  useEffect(() => {
    if (streamUrl) {
      setupHLSPlayer("videoPlayer", streamUrl);
    }
  }, [streamUrl]);

  return (
    <div>
      <h2>
        Live Video Stream -{" "}
        <span style={{ color: "lightgray" }}>{streamStatus}</span>
        <button onClick={fetchStreamUrl} style={{ marginLeft: "1rem" }}>
          새로고침
        </button>
      </h2>
      <video
        id="videoPlayer"
        controls
        autoPlay
        style={{ width: "100%" }}
      ></video>
    </div>
  );
};

export default VideoStream;
