import Hls from "hls.js";

/**
 * Initialize and play an HLS stream using HLS.js
 * @param {string} videoElementId - The ID of the video element
 * @param {string} streamUrl - The HLS stream URL
 */
export function setupHLSPlayer(videoElementId, streamUrl) {
  const video = document.getElementById(videoElementId);

  if (!video) {
    console.error(`Video element with ID '${videoElementId}' not found.`);
    return;
  }

  if (Hls.isSupported()) {
    const hls = new Hls();
    hls.loadSource(streamUrl);
    hls.attachMedia(video);

    hls.on(Hls.Events.MANIFEST_PARSED, () => {
      video.play().catch((error) => {
        console.error("Error playing video:", error);
      });
    });

    hls.on(Hls.Events.ERROR, (event, data) => {
      console.error("HLS.js Error:", data);
    });
  } else if (video.canPlayType("application/vnd.apple.mpegurl")) {
    video.src = streamUrl;
    video.addEventListener("loadedmetadata", () => {
      video.play().catch((error) => {
        console.error("Error playing video:", error);
      });
    });
  } else {
    console.error("HLS.js is not supported in this browser.");
  }
}
