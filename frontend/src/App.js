import React from "react";
import {
  Authenticator,
  Button,
  Card,
  Grid,
  Heading,
  Image,
  Text,
  View,
  Flex,
} from "@aws-amplify/ui-react";
import VideoStream from "./VideoStream";
import WebSocketClient from "./WebSocketClient";
import "@aws-amplify/ui-react/styles.css";
import "./App.css";

const App = () => {
  return (
    <Flex
      justifyContent="center"
      alignItems="center"
      minHeight="100vh"
      backgroundColor="#232f3e"
    >
      <Authenticator>
        {({ signOut, user }) => (
          <main
            style={{
              backgroundColor: "#232f3e",
              minHeight: "100vh",
              width: "100%",
              padding: "2rem",
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
            }}
          >
            {/* ✅ 헤더 (너비 확장) */}
            <Flex
              justifyContent="space-between"
              alignItems="center"
              padding="1.5rem"
              backgroundColor="#1a2533"
              width="100%"
              maxWidth="1440px" /* ✅ 너비 확장 */
              borderRadius="8px"
            >
              <Flex alignItems="center">
                <Image
                  alt="Amazon Kinesis Video Streams icon"
                  src="/kvs-icon.png"
                  height="3em"
                  style={{ paddingRight: "0.45em" }}
                />
                <Heading level={3} style={{ color: "white", margin: 0 }}>
                  Kinesis Video Streams - Real-Time Monitoring
                </Heading>
              </Flex>
              <Flex alignItems="center">
                <Text
                  as="span"
                  style={{ color: "white", paddingRight: "1.5em" }}
                >
                  Hello, <strong>{user?.attributes?.email}</strong>
                </Text>
                <Button
                  size="small"
                  style={{ color: "white" }}
                  onClick={signOut}
                >
                  Sign out
                </Button>
              </Flex>
            </Flex>

            {/* ✅ 콘텐츠 영역 (너비 확장) */}
            <Grid
              columnGap="1.5rem"
              rowGap="1.5rem"
              templateColumns={{
                base: "1fr",
                large: "1fr 3fr",
              }} /* ✅ 너비 확장 */
              templateRows="auto"
              marginTop="1.5rem"
              width="100%"
              maxWidth="1440px" /* ✅ 너비 확장 */
            >
              {/* 📡 WebSocket Client (알림 영역) */}
              <Card padding="1.5rem" backgroundColor="#1a2533">
                <WebSocketClient />
              </Card>

              {/* 📹 비디오 스트림 (메인 콘텐츠) */}
              <Card padding="1.5rem" backgroundColor="#1a2533">
                <VideoStream />
              </Card>
            </Grid>
          </main>
        )}
      </Authenticator>
    </Flex>
  );
};

export default App;
