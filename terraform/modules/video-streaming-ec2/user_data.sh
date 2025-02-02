#!/bin/bash
apt-get update -y 
apt-get install -y git unzip zip
apt-get groupinstall -y "Development Tools" 

# AWS CLI 
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# AWS CLI 
mkdir -p /home/ubuntu/.aws
cat <<EOF > /home/ubuntu/.aws/config
[default]
region = ${region}
EOF

# 환경 변수 파일 경로
ENV_FILE="/etc/profile.d/aws_credentials.sh"

# IAM Role에서 AWS Credentials 가져오기 (IMDSv2 사용)
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
ROLE_NAME=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/iam/security-credentials/)
AWS_CREDENTIALS=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/iam/security-credentials/$ROLE_NAME)

AWS_ACCESS_KEY_ID=$(echo $AWS_CREDENTIALS | jq -r '.AccessKeyId')
AWS_SECRET_ACCESS_KEY=$(echo $AWS_CREDENTIALS | jq -r '.SecretAccessKey')
AWS_SESSION_TOKEN=$(echo $AWS_CREDENTIALS | jq -r '.Token')

# 환경 변수 저장
cat <<EOF > $ENV_FILE
export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
export AWS_SESSION_TOKEN="$AWS_SESSION_TOKEN"
export AWS_REGION="ap-northeast-1"
EOF

# 권한 부여 및 적용
chmod +x $ENV_FILE
source $ENV_FILE
echo "AWS 환경변수 설정 완료"

# 시스템 전체에서 사용 가능하도록 적용
echo "source $ENV_FILE" >> /etc/bash.bashrc
echo "source $ENV_FILE" >> /root/.bashrc

sudo apt update;sudo apt install -y \
  automake \
  build-essential \
  cmake \
  git \
  gstreamer1.0-plugins-base-apps \
  gstreamer1.0-plugins-bad \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-ugly \
  gstreamer1.0-tools \
  gstreamer1.0-omx-generic \
  libcurl4-openssl-dev \
  libgstreamer1.0-dev \
  libgstreamer-plugins-base1.0-dev \
  liblog4cplus-dev \
  libssl-dev \
  pkg-config \
  ffmpeg;sudo apt-get -y install mkvtoolnix;cd;git clone https://github.com/awslabs/amazon-kinesis-video-streams-producer-sdk-cpp.git;mkdir -p ~/amazon-kinesis-video-streams-producer-sdk-cpp/build;cd ~/amazon-kinesis-video-streams-producer-sdk-cpp/build;cmake -DBUILD_GSTREAMER_PLUGIN=ON ..;make;cd;git clone --recursive https://github.com/awslabs/amazon-kinesis-video-streams-webrtc-sdk-c.git;mkdir -p ~/amazon-kinesis-video-streams-webrtc-sdk-c/build;cd ~/amazon-kinesis-video-streams-webrtc-sdk-c/build;cmake ..;make

# KVS Workshop Sample Video 다운로드
wget https://awsj-iot-handson.s3-ap-northeast-1.amazonaws.com/kvs-workshop/sample.mp4
cd ~/amazon-kinesis-video-streams-producer-sdk-cpp
export GST_PLUGIN_PATH=`pwd`/build
export LD_LIBRARY_PATH=`pwd`/open-source/local/lib

# KVS Workshop Sample Video 실행
export KINESIS_STREAM_NAME=${kinesis_stream_name}
cd ~/amazon-kinesis-video-streams-producer-sdk-cpp/build
while true; do ./kvs_gstreamer_sample $KINESIS_STREAM_NAME ~/sample.mp4 && sleep 10s; done