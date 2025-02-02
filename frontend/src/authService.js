import { Auth } from "aws-amplify";

// ✅ AWS Amplify 인증 정보를 가져오는 함수
export async function getAmplifyAuthCredentials() {
  try {
    console.log("🔄 AWS Amplify 자격 증명 가져오는 중...");
    const credentials = await Auth.currentCredentials();

    if (!credentials || !credentials.accessKeyId) {
      throw new Error("❌ Amplify Auth에서 자격 증명을 가져오지 못했습니다.");
    }

    console.log("✅ AWS Amplify 자격 증명 획득 완료:", credentials);
    return credentials;
  } catch (error) {
    console.error("🚨 AWS Amplify 자격 증명 가져오기 실패:", error);
    return null;
  }
}
