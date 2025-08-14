# Harbor OIDC 설정

## 개요
Harbor에서 Keycloak OIDC 인증을 설정하는 방법을 설명합니다.

## Harbor 관리자 설정

### 1. Harbor 관리자 로그인
기본 관리자 계정으로 Harbor에 로그인합니다.
```
Username: admin
Password: Harbor12345 (기본값, 변경 권장)
```

### 2. OIDC 인증 설정
**Administration** → **Configuration** → **Authentication** 이동

#### 인증 모드 설정
```yaml
Auth Mode: OIDC
```

#### OIDC 설정 정보
```yaml
OIDC Provider Name: Keycloak
OIDC Provider Endpoint: https://keycloak.example.com/realms/master
OIDC Client ID: harbor
OIDC Client Secret: [Keycloak에서 생성한 클라이언트 시크릿]
Group Claim Name: groups
OIDC Admin Group: harbor-admins
OIDC Scope: openid,profile,email,groups
```

#### 고급 설정
```yaml
Verify Certificate: true (프로덕션 환경)
Auto Onboard: true
Username Claim: preferred_username
```

## Harbor Helm Values 설정

### values.yaml 예시
```yaml
expose:
  type: ingress
  tls:
    enabled: true
    certSource: secret
    secret:
      secretName: harbor-tls
  ingress:
    hosts:
      core: harbor.example.com
    className: nginx
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod

externalURL: https://harbor.example.com

# OIDC 설정
core:
  configureUserSettings: |
    auth_mode = oidc
    oidc_name = Keycloak
    oidc_endpoint = https://keycloak.example.com/realms/master
    oidc_client_id = harbor
    oidc_client_secret = YOUR_CLIENT_SECRET
    oidc_groups_claim = groups
    oidc_admin_group = harbor-admins
    oidc_scope = openid,profile,email,groups
    oidc_verify_cert = true
    oidc_auto_onboard = true
    oidc_user_claim = preferred_username

# 데이터베이스 설정
database:
  type: internal
  internal:
    password: "changeit"

# Redis 설정  
redis:
  type: internal
  internal:
    password: "changeit"

# 스토리지 설정
persistence:
  enabled: true
  resourcePolicy: "keep"
  persistentVolumeClaim:
    registry:
      size: 50Gi
      storageClass: "nfs-client"
    database:
      size: 10Gi
      storageClass: "nfs-client"
    redis:
      size: 1Gi
      storageClass: "nfs-client"
```

## 설정 적용

### 1. Helm으로 Harbor 업데이트
```bash
helm upgrade harbor harbor/harbor \
  -n harbor \
  -f values.yaml
```

### 2. 설정 확인
Harbor 재시작 후 로그인 페이지에서 "LOGIN VIA OIDC PROVIDER" 버튼 확인

## 사용자 로그인 테스트

### 1. OIDC 로그인
1. Harbor 로그인 페이지 접속
2. **LOGIN VIA OIDC PROVIDER** 클릭
3. Keycloak 로그인 페이지로 리다이렉트
4. Keycloak 계정으로 로그인
5. Harbor로 리다이렉트되어 로그인 완료

### 2. 권한 확인
- **harbor-admins** 그룹: 시스템 관리자 권한
- **harbor-users** 그룹: 프로젝트 개발자 권한

## 프로젝트 권한 설정

### 자동 프로젝트 할당
```yaml
# Harbor 프로젝트 생성 시 그룹별 권한 자동 할당
Project: my-project
Members:
  - harbor-admins (Project Admin)
  - harbor-users (Developer)
```

## Docker 클라이언트 설정

### OIDC 토큰으로 로그인
```bash
# Harbor CLI로 로그인
harbor login harbor.example.com

# 또는 Docker 로그인 (Harbor 2.2+)
docker login harbor.example.com
Username: [Keycloak username]
Password: [Harbor CLI token]
```

### Robot 계정 사용 (CI/CD)
```bash
# Robot 계정 생성 (Harbor UI에서)
# CI/CD에서 사용
docker login harbor.example.com -u robot$project+robot-name -p [robot-token]
```

## 다음 단계
- [문제 해결 가이드](./troubleshooting.md)
- [Harbor 프로젝트 관리](./project-management.md)