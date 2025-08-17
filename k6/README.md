# k6 Operator 간소화된 배포 가이드

ACM 인증서와 external-dns를 사용하여 k6 operator를 EKS에 배포하는 간소화된 가이드입니다.

## 📋 사전 요구사항

### 필수 도구
- `kubectl` - Kubernetes CLI
- `helm` - Kubernetes 패키지 매니저  
- `aws` - AWS CLI

### AWS 리소스 (이미 준비됨)
- ✅ EKS 클러스터 (실행 중)
- ✅ ACM SSL 인증서 (생성됨)
- ✅ external-dns (설치됨)
- ✅ AWS Load Balancer Controller (설치됨)

## 🚀 빠른 배포

### 1. 설정 파일 수정

`deploy-k6-simple.sh` 파일의 변수들을 수정하세요:

```bash
# 필수 수정 항목
CLUSTER_NAME="your-eks-cluster"                    # EKS 클러스터 이름
REGION="ap-northeast-2"                            # AWS 리전
DOMAIN="k6-operator.your-domain.com"               # 도메인
ACM_CERT_ARN="arn:aws:acm:ap-northeast-2:YOUR_ACCOUNT_ID:certificate/YOUR_CERTIFICATE_ID"  # ACM 인증서 ARN
```

### 2. 배포 실행

```bash
# 배포 실행
./deploy-k6-simple.sh
```

## 📁 파일 구조

```
k6/
├── k6-operator-values-simple.yaml  # 간소화된 Helm values 파일
├── deploy-k6-simple.sh            # 간소화된 배포 스크립트
├── example-k6-test.yaml           # k6 테스트 예제
└── README-simple.md               # 이 파일
```

## ⚙️ 주요 설정

### Helm Values 핵심 설정

```yaml
# Ingress 설정 (ALB + ACM + External DNS)
ingress:
  enabled: true
  className: alb
  annotations:
    # ACM 인증서 (수정 필요)
    alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:..."
    # External DNS (수정 필요)
    external-dns.alpha.kubernetes.io/hostname: "k6-operator.your-domain.com"
  hosts:
    - host: k6-operator.your-domain.com  # 수정 필요
```

## 🔧 배포 후 확인

### 상태 확인
```bash
# Pod 상태
kubectl get pods -n k6-operator-system

# Ingress 상태  
kubectl get ingress -n k6-operator-system

# ALB 주소 확인
kubectl get ingress -n k6-operator-system -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'
```

### 접속 테스트
```bash
# DNS 확인
nslookup k6-operator.your-domain.com

# HTTPS 접속 테스트
curl -I https://k6-operator.your-domain.com
```

## 📊 k6 테스트 실행

### 테스트 생성
```bash
# ConfigMap으로 테스트 스크립트 생성
kubectl create configmap k6-test-script \
  --from-file=test.js=example-test.js \
  -n k6-operator-system
```

### 테스트 실행
```yaml
apiVersion: k6.io/v1alpha1
kind: K6
metadata:
  name: simple-test
  namespace: k6-operator-system
spec:
  parallelism: 2
  script:
    configMap:
      name: k6-test-script
      file: test.js
  arguments: --vus=10 --duration=30s
```

```bash
# 테스트 실행
kubectl apply -f k6-test.yaml

# 테스트 상태 확인
kubectl get k6 -n k6-operator-system

# 테스트 로그 확인
kubectl logs -l k6_cr=simple-test -n k6-operator-system
```

## 🔍 트러블슈팅

### ALB 생성 안됨
```bash
# AWS Load Balancer Controller 로그 확인
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Ingress 이벤트 확인
kubectl describe ingress -n k6-operator-system
```

### DNS 해석 안됨
```bash
# external-dns 로그 확인
kubectl logs -n kube-system -l app.kubernetes.io/name=external-dns

# Route53 레코드 확인
aws route53 list-resource-record-sets --hosted-zone-id YOUR_ZONE_ID
```

### SSL 인증서 문제
```bash
# ACM 인증서 상태 확인
aws acm describe-certificate --certificate-arn YOUR_CERT_ARN --region YOUR_REGION
```

## 🗑️ 정리

```bash
# k6 operator 제거
helm uninstall k6-operator -n k6-operator-system

# 네임스페이스 제거
kubectl delete namespace k6-operator-system
```

## 📝 참고사항

- external-dns가 자동으로 Route53 레코드를 생성합니다
- ACM 인증서는 미리 생성되어 있어야 합니다
- ALB 생성까지 5-10분 정도 소요될 수 있습니다
- DNS 전파는 최대 5분 정도 소요됩니다
