# Keycloak 설치 가이드

이 가이드는 Kubernetes 환경에서 Helm을 사용하여 Keycloak을 설치하는 방법을 설명합니다.

## 📋 사전 요구사항

- Kubernetes 클러스터
- Helm 3.x
- AWS Load Balancer Controller (ALB 사용 시)
- 도메인 및 SSL 인증서 (HTTPS 사용 시)

## 🚀 설치 단계

### 1. Helm Repository 추가

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

### 2. Namespace 생성

```bash
kubectl create namespace keycloak
```

### 3. Helm Values 파일 준비

[helm-values.yaml](helm-values.yaml) 파일을 참조하여 환경에 맞게 수정합니다.

주요 설정 항목:
- **도메인**: `hostname: keycloak.your-domain.com`
- **SSL 인증서**: `alb.ingress.kubernetes.io/certificate-arn`
- **관리자 계정**: `auth.adminUser`, `auth.adminPassword`

### 4. Keycloak 설치

```bash
helm install keycloak bitnami/keycloak \
  --namespace keycloak \
  --values helm-values.yaml
```

### 5. 설치 확인

```bash
# Pod 상태 확인
kubectl -n keycloak get pods

# Ingress 확인
kubectl -n keycloak get ingress

# 서비스 확인
kubectl -n keycloak get svc
```

## 🔧 설치 후 설정

### 1. 관리자 콘솔 접속

- URL: https://keycloak.your-domain.com/admin/
- 사용자명: admin (기본값)
- 비밀번호: helm-values.yaml에서 설정한 값

### 2. Realm 생성

1. 관리자 콘솔 로그인
2. 좌측 상단 드롭다운에서 "Create Realm" 클릭
3. Realm 이름 입력 (예: `test1`)
4. "Create" 버튼 클릭

### 3. 기본 설정 확인

- **SSL Required**: External requests (기본값)
- **User Registration**: Off (보안상 권장)
- **Email as Username**: Off (기본값)

## 🔍 문제 해결

### Pod가 시작되지 않는 경우

```bash
# Pod 로그 확인
kubectl -n keycloak logs keycloak-0

# Pod 상세 정보 확인
kubectl -n keycloak describe pod keycloak-0
```

### Ingress 접근 불가

```bash
# Ingress 상태 확인
kubectl -n keycloak describe ingress keycloak

# ALB 생성 확인 (AWS 콘솔에서)
```

### 데이터베이스 연결 오류

```bash
# PostgreSQL Pod 확인
kubectl -n keycloak get pods | grep postgresql

# PostgreSQL 로그 확인
kubectl -n keycloak logs keycloak-postgresql-0
```

## 📚 다음 단계

설치가 완료되면 다음 문서를 참조하세요:
- [Argo CD OIDC 연동](../argo-cd-integration/oidc-configuration.md)
- [클라이언트 설정](../argo-cd-integration/client-setup.md)