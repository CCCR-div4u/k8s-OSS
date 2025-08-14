# AWS Secrets Manager 연동 가이드

이 가이드는 External Secrets Operator를 사용하여 AWS Secrets Manager와 Keycloak Client Secret을 연동하는 방법을 설명합니다.

## 📋 사전 요구사항

- External Secrets Operator 설치
- AWS Secrets Manager 접근 권한
- IAM Role 또는 Access Key 설정

## 🔧 AWS Secrets Manager 설정

### 1. Secret 생성

```bash
# AWS CLI를 사용하여 Secret 생성
aws secretsmanager create-secret \
  --name "argocd/oidc/keycloak" \
  --description "Argo CD Keycloak OIDC Client Secret" \
  --secret-string '{"oidc.keycloak.clientSecret":"your-client-secret-here"}'
```

### 2. Secret 값 업데이트

```bash
# 기존 Secret 값 업데이트
aws secretsmanager put-secret-value \
  --secret-id "argocd/oidc/keycloak" \
  --secret-string '{"oidc.keycloak.clientSecret":"new-client-secret"}'
```

### 3. Secret 값 확인

```bash
# Secret 값 조회
aws secretsmanager get-secret-value \
  --secret-id "argocd/oidc/keycloak" \
  --query SecretString \
  --output text
```

## 🔐 IAM 권한 설정

### 1. IAM Policy 생성

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": [
        "arn:aws:secretsmanager:ap-northeast-2:*:secret:argocd/oidc/keycloak*"
      ]
    }
  ]
}
```

### 2. IAM Role 생성 (IRSA 사용)

```bash
# OIDC Provider 확인
aws eks describe-cluster --name your-cluster-name --query "cluster.identity.oidc.issuer" --output text

# IAM Role 생성
aws iam create-role \
  --role-name ExternalSecretsRole \
  --assume-role-policy-document file://trust-policy.json

# Policy 연결
aws iam attach-role-policy \
  --role-name ExternalSecretsRole \
  --policy-arn arn:aws:iam::your-account:policy/ExternalSecretsPolicy
```

**trust-policy.json**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR-ACCOUNT-ID:oidc-provider/oidc.eks.ap-northeast-2.amazonaws.com/id/YOUR-OIDC-ID"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.ap-northeast-2.amazonaws.com/id/YOUR-OIDC-ID:sub": "system:serviceaccount:argo-cd:external-secrets-sa",
          "oidc.eks.ap-northeast-2.amazonaws.com/id/YOUR-OIDC-ID:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
```

## 🚀 External Secrets 설정

### 1. ServiceAccount 생성

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-secrets-sa
  namespace: argo-cd
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::YOUR-ACCOUNT-ID:role/ExternalSecretsRole
```

### 2. SecretStore 생성

[external-secret.yaml](external-secret.yaml) 파일을 참조하여 SecretStore를 생성합니다.

```bash
kubectl apply -f external-secret.yaml
```

### 3. ExternalSecret 생성

동일한 파일에 포함된 ExternalSecret을 적용합니다.

## 🔍 동기화 확인

### 1. ExternalSecret 상태 확인

```bash
# ExternalSecret 상태 확인
kubectl -n argo-cd get externalsecret argocd-keycloak

# 상세 상태 확인
kubectl -n argo-cd describe externalsecret argocd-keycloak
```

### 2. Secret 동기화 확인

```bash
# 생성된 Secret 확인
kubectl -n argo-cd get secret argocd-secret -o yaml

# Client Secret 값 확인
kubectl -n argo-cd get secret argocd-secret -o jsonpath='{.data.oidc\.keycloak\.clientSecret}' | base64 -d
```

### 3. 강제 동기화

```bash
# 강제 동기화 트리거
kubectl -n argo-cd annotate externalsecret argocd-keycloak force-sync=$(date +%s)
```

## 🔄 자동 갱신 설정

### 1. 갱신 주기 설정

```yaml
spec:
  refreshInterval: 1m  # 1분마다 동기화
```

### 2. Secret 회전 설정

AWS Secrets Manager에서 자동 회전을 설정할 수 있습니다:

```bash
aws secretsmanager rotate-secret \
  --secret-id "argocd/oidc/keycloak" \
  --rotation-lambda-arn "arn:aws:lambda:region:account:function:rotation-function"
```

## 🛠️ 문제 해결

### 1. 권한 오류

**증상**: `AccessDenied` 오류 발생

**해결**:
- IAM Role의 권한 확인
- ServiceAccount 어노테이션 확인
- OIDC Provider 설정 확인

### 2. 동기화 실패

**증상**: ExternalSecret이 `SecretSyncError` 상태

**해결**:
```bash
# ExternalSecret 로그 확인
kubectl -n argo-cd logs -l app.kubernetes.io/name=external-secrets

# SecretStore 연결 테스트
kubectl -n argo-cd get secretstore aws-secretsmanager-argo-cd -o yaml
```

### 3. Secret 형식 오류

**증상**: JSON 파싱 오류

**해결**:
```bash
# AWS Secrets Manager의 Secret 형식 확인
aws secretsmanager get-secret-value --secret-id "argocd/oidc/keycloak"

# 올바른 JSON 형식으로 업데이트
aws secretsmanager put-secret-value \
  --secret-id "argocd/oidc/keycloak" \
  --secret-string '{"oidc.keycloak.clientSecret":"correct-value"}'
```

## 📊 모니터링

### 1. CloudWatch 메트릭

AWS Secrets Manager 사용량을 모니터링:
- `NumberOfSecrets`
- `NumberOfVersions`
- `SuccessfulRequestLatency`

### 2. Kubernetes 이벤트

```bash
# External Secrets 관련 이벤트 확인
kubectl -n argo-cd get events --field-selector involvedObject.kind=ExternalSecret
```

## 🔒 보안 고려사항

1. **최소 권한 원칙**: IAM Role에 필요한 최소한의 권한만 부여
2. **Secret 암호화**: AWS KMS를 사용한 Secret 암호화
3. **접근 로깅**: CloudTrail을 통한 Secret 접근 로깅
4. **정기 회전**: Client Secret 정기적 회전
5. **네트워크 보안**: VPC Endpoint 사용 고려

## 📚 참고 자료

- [External Secrets Operator 공식 문서](https://external-secrets.io/)
- [AWS Secrets Manager 공식 문서](https://docs.aws.amazon.com/secretsmanager/)
- [EKS IRSA 가이드](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)