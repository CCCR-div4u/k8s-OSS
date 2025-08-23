#!/bin/bash

# Kube-bench S3 버킷 생성 스크립트
# 방금 생성한 버킷과 동일한 설정으로 새 버킷을 만듭니다.

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 설정
BUCKET_NAME="${1:-kube-bench-results-$(date +%Y%m%d)-$(whoami)}"
REGION="${AWS_REGION:-ap-northeast-2}"

echo -e "${BLUE}🪣 Creating S3 bucket for kube-bench results...${NC}"
echo "Bucket Name: $BUCKET_NAME"
echo "Region: $REGION"
echo ""

# AWS CLI 설치 확인
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed${NC}"
    exit 1
fi

# AWS 자격 증명 확인
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS credentials not configured${NC}"
    echo "Please run: aws configure"
    exit 1
fi

# 버킷 존재 확인
echo -e "${BLUE}🔍 Checking if bucket already exists...${NC}"
if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Bucket $BUCKET_NAME already exists${NC}"
    read -p "Continue with existing bucket? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ Aborted${NC}"
        exit 1
    fi
    BUCKET_EXISTS=true
else
    BUCKET_EXISTS=false
fi

# 1. 버킷 생성
if [ "$BUCKET_EXISTS" = false ]; then
    echo -e "${BLUE}📦 Creating S3 bucket...${NC}"
    if [ "$REGION" = "us-east-1" ]; then
        aws s3api create-bucket --bucket "$BUCKET_NAME"
    else
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --create-bucket-configuration LocationConstraint="$REGION"
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Bucket created: $BUCKET_NAME${NC}"
    else
        echo -e "${RED}❌ Failed to create bucket${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}📦 Using existing bucket: $BUCKET_NAME${NC}"
fi

# 2. 버킷 버전 관리 활성화
echo -e "${BLUE}📝 Enabling versioning...${NC}"
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Versioning enabled${NC}"
else
    echo -e "${RED}❌ Failed to enable versioning${NC}"
fi

# 3. 서버 사이드 암호화 설정
echo -e "${BLUE}🔐 Enabling server-side encryption...${NC}"
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Server-side encryption enabled${NC}"
else
    echo -e "${RED}❌ Failed to enable encryption${NC}"
fi

# 4. 퍼블릭 액세스 차단
echo -e "${BLUE}🛡️  Blocking public access...${NC}"
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Public access blocked${NC}"
else
    echo -e "${RED}❌ Failed to block public access${NC}"
fi

# 5. 라이프사이클 정책 설정
echo -e "${BLUE}🗓️  Setting up lifecycle policy...${NC}"

# 임시 라이프사이클 정책 파일 생성
cat > /tmp/lifecycle-policy-$$.json << 'EOF'
{
    "Rules": [
        {
            "ID": "KubeBenchResultsLifecycle",
            "Status": "Enabled",
            "Filter": {
                "Prefix": "kube-bench-results/"
            },
            "Transitions": [
                {
                    "Days": 30,
                    "StorageClass": "STANDARD_IA"
                },
                {
                    "Days": 90,
                    "StorageClass": "GLACIER"
                },
                {
                    "Days": 365,
                    "StorageClass": "DEEP_ARCHIVE"
                }
            ],
            "Expiration": {
                "Days": 2555
            }
        },
        {
            "ID": "LatestResultsRetention",
            "Status": "Enabled",
            "Filter": {
                "Prefix": "kube-bench-results/latest/"
            },
            "Expiration": {
                "Days": 90
            }
        }
    ]
}
EOF

aws s3api put-bucket-lifecycle-configuration \
    --bucket "$BUCKET_NAME" \
    --lifecycle-configuration file:///tmp/lifecycle-policy-$$.json

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Lifecycle policy applied${NC}"
else
    echo -e "${RED}❌ Failed to apply lifecycle policy${NC}"
fi

# 임시 파일 정리
rm -f /tmp/lifecycle-policy-$$.json

# 6. 버킷 태그 설정
echo -e "${BLUE}🏷️  Setting bucket tags...${NC}"
aws s3api put-bucket-tagging \
    --bucket "$BUCKET_NAME" \
    --tagging '{
        "TagSet": [
            {
                "Key": "Name",
                "Value": "Kube-bench Results"
            },
            {
                "Key": "Purpose", 
                "Value": "Security Scan Results Storage"
            },
            {
                "Key": "Environment",
                "Value": "Production"
            },
            {
                "Key": "ManagedBy",
                "Value": "Script"
            },
            {
                "Key": "CreatedDate",
                "Value": "'$(date +%Y-%m-%d)'"
            }
        ]
    }'

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Bucket tags applied${NC}"
else
    echo -e "${YELLOW}⚠️  Failed to apply bucket tags (non-critical)${NC}"
fi

# 7. 버킷 설정 확인
echo ""
echo -e "${BLUE}🔍 Verifying bucket configuration...${NC}"

# 버킷 존재 확인
if aws s3 ls "s3://$BUCKET_NAME" &> /dev/null; then
    echo -e "${GREEN}✅ Bucket accessible${NC}"
else
    echo -e "${RED}❌ Bucket not accessible${NC}"
fi

# 버전 관리 확인
VERSIONING=$(aws s3api get-bucket-versioning --bucket "$BUCKET_NAME" --query 'Status' --output text 2>/dev/null)
if [ "$VERSIONING" = "Enabled" ]; then
    echo -e "${GREEN}✅ Versioning: Enabled${NC}"
else
    echo -e "${YELLOW}⚠️  Versioning: $VERSIONING${NC}"
fi

# 암호화 확인
ENCRYPTION=$(aws s3api get-bucket-encryption --bucket "$BUCKET_NAME" --query 'ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault.SSEAlgorithm' --output text 2>/dev/null)
if [ "$ENCRYPTION" = "AES256" ]; then
    echo -e "${GREEN}✅ Encryption: AES256${NC}"
else
    echo -e "${YELLOW}⚠️  Encryption: $ENCRYPTION${NC}"
fi

echo ""
echo -e "${GREEN}🎉 S3 bucket setup completed!${NC}"
echo ""
echo -e "${BLUE}📋 Summary:${NC}"
echo "  - Bucket Name: $BUCKET_NAME"
echo "  - Region: $REGION"
echo "  - Versioning: Enabled"
echo "  - Encryption: AES256"
echo "  - Lifecycle: 30d→IA, 90d→Glacier, 365d→Deep Archive, 7y→Delete"
echo "  - Public Access: Blocked"
echo "  - Tags: Applied"
echo ""
echo -e "${BLUE}🔧 Next Steps:${NC}"
echo "1. Add this bucket name to GitHub Secrets:"
echo -e "${YELLOW}   KUBE_BENCH_S3_BUCKET=$BUCKET_NAME${NC}"
echo ""
echo "2. Ensure your GitHub Actions have S3 permissions:"
echo "   - s3:GetObject"
echo "   - s3:PutObject" 
echo "   - s3:ListBucket"
echo ""
echo "3. Test the setup:"
echo -e "${YELLOW}   aws s3 ls s3://$BUCKET_NAME/${NC}"
echo ""
echo -e "${BLUE}🔗 S3 Console URL:${NC}"
echo "   https://s3.console.aws.amazon.com/s3/buckets/$BUCKET_NAME"
echo ""
echo -e "${BLUE}📁 Expected folder structure:${NC}"
echo "   s3://$BUCKET_NAME/"
echo "   └── kube-bench-results/"
echo "       ├── year=2024/"
echo "       │   └── month=08/"
echo "       │       └── day=23/"
echo "       │           └── kube-bench-20240823_065432-1234.json"
echo "       └── latest/"
echo "           └── kube-bench-latest.json"
