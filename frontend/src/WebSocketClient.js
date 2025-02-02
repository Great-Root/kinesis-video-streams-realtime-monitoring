import React, { useEffect, useState, useRef } from "react";
import { Auth } from "aws-amplify";

// 📌 WebSocket API URL 가져오기
const WEBSOCKET_API_URL = process.env.REACT_APP_WEBSOCKET_API_URL;

if (!WEBSOCKET_API_URL || !WEBSOCKET_API_URL.startsWith("wss://")) {
  console.error("❌ WebSocket URL이 잘못되었습니다! .env 파일을 확인하세요.");
}

const WebSocketClient = ({ onMessageReceived }) => {
  const [messages, setMessages] = useState([]);
  const [connectionStatus, setConnectionStatus] = useState("🔴 Disconnected");
  const [socket, setSocket] = useState(null);
  const [reconnectAttempts, setReconnectAttempts] = useState(0);
  const maxReconnectAttempts = 5;

  const messagesEndRef = useRef(null); // 🔹 스크롤을 최신 메시지로 이동하기 위한 ref

  /**
   * 🔄 AWS Cognito 인증 토큰 가져오기
   */
  const getCognitoToken = async () => {
    try {
      console.log("🔄 AWS Cognito 인증 토큰 가져오는 중...");
      const session = await Auth.currentSession();
      return session.getIdToken().getJwtToken();
    } catch (error) {
      console.error("❌ Cognito 인증 실패:", error);
      return null;
    }
  };

  /**
   * 🔗 WebSocket 연결
   */
  const connectToWebSocket = async () => {
    if (!WEBSOCKET_API_URL) {
      console.error("❌ WebSocket API URL이 설정되지 않았습니다.");
      return;
    }

    const idToken = await getCognitoToken();
    if (!idToken) return;

    const signedWebSocketUrl = `${WEBSOCKET_API_URL}?Authorization=${encodeURIComponent(
      idToken
    )}`;
    console.log("🔗 WebSocket 연결 시도:", signedWebSocketUrl);

    const websocket = new WebSocket(signedWebSocketUrl);

    websocket.onopen = () => {
      console.log("✅ WebSocket 연결 성공!");
      setSocket(websocket);
      setReconnectAttempts(0);
      setConnectionStatus("🟢 Connected");
    };

    websocket.onmessage = (event) => {
      console.log("📩 원본 메시지:", event.data);
      try {
        const parsedData = JSON.parse(event.data);
        if (parsedData.message) {
          const formattedMessage = formatRecognizedFaces(parsedData.message);
          setMessages((prevMessages) => [...prevMessages, formattedMessage]);
          if (onMessageReceived) onMessageReceived(formattedMessage);
        }
      } catch (error) {
        console.error("❌ 메시지 파싱 실패:", error);
      }
    };

    websocket.onerror = (error) => {
      console.error("⚠️ WebSocket 오류:", error);
      setConnectionStatus("⚠️ Error");
    };

    websocket.onclose = () => {
      console.warn("🚫 WebSocket 연결 종료됨");
      setConnectionStatus("🔴 Disconnected");
      if (reconnectAttempts < maxReconnectAttempts) {
        console.warn(
          `♻️ ${
            reconnectAttempts + 1
          }/${maxReconnectAttempts} 번째 재연결 시도 중...`
        );
        setReconnectAttempts((prev) => prev + 1);
        setTimeout(connectToWebSocket, 3000);
      }
    };

    setSocket(websocket);
  };

  /**
   * 🔍 Recognized Faces 메시지를 보기 좋게 변환
   */
  const formatRecognizedFaces = (message) => {
    const regex = /Recognized faces: (.+)/;
    const match = message.match(regex);

    if (!match || !match[1]) return "❌ 잘못된 메시지 형식";

    const faces = match[1].split(", ").map((name) => name.trim());
    const faceCount = faces.reduce((acc, face) => {
      acc[face] = (acc[face] || 0) + 1;
      return acc;
    }, {});

    let formattedMessage = `👤 Recognized Faces:\n`;
    for (const [face, count] of Object.entries(faceCount)) {
      formattedMessage += `- ${face} (${count})\n`;
    }

    return formattedMessage;
  };

  /**
   * 🔹 메시지가 추가될 때 최신 메시지로 스크롤 이동
   */
  useEffect(() => {
    if (messagesEndRef.current) {
      messagesEndRef.current.scrollIntoView({ behavior: "smooth" });
    }
  }, [messages]);

  /**
   * 🗑 알림 내역 삭제 기능
   */
  const clearMessages = () => {
    setMessages([]);
  };

  useEffect(() => {
    connectToWebSocket();
    return () => socket && socket.close();
  }, []);

  return (
    <div>
      <h2>얼굴 인식 알림</h2>
      <p>
        🔗 WebSocket 상태: <strong>{connectionStatus}</strong>
      </p>

      {/* 🗑 알림 내역 삭제 버튼 */}
      <button
        onClick={clearMessages}
        style={{ marginBottom: "10px", padding: "5px 10px", cursor: "pointer" }}
      >
        🗑 알림 삭제
      </button>

      <ul
        style={{
          border: "1px solid gray",
          padding: "10px",
          maxHeight: "300px",
          overflowY: "auto",
          backgroundColor: "#f9f9f9",
        }}
      >
        {messages.length === 0 ? (
          <li className="empty-message">📭 아직 수신된 메시지가 없습니다.</li>
        ) : (
          messages.map((msg, index) => (
            <li
              className="alert-message"
              key={index}
              style={{ whiteSpace: "pre-wrap", fontFamily: "monospace" }}
            >
              {msg}
            </li>
          ))
        )}

        <div ref={messagesEndRef} />
      </ul>
    </div>
  );
};

export default WebSocketClient;
