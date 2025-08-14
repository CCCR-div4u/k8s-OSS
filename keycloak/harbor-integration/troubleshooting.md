# Harbor-Keycloak 연동 문제 해결

## 일반적인 문제들

### 1. OIDC 로그인 버튼이 보이지 않음

**증상:**
- Harbor 로그인 페이지에 "LOGIN VIA OIDC PROVIDER" 버튼이 없음

**해결 방법:**
```bash
# Harbor 설정 확인
kubectl exec -n harbor deployment/harbor-core -- cat /etc/core/app.conf | grep oidc

# 예상 출력:
# auth_mode = oidc
# oidc_name = Keycloak
```

**설정 수정:**
```yaml
# values.yaml에서 확인
core:
  configureUserSettings: |
    auth_mode = oidc
```

### 2. 리다이렉트 URI 불일치 오류

**증상:**
```
Invalid redirect URI: https://harbor.example.com/c/oidc/callback
```

**해결 방법:**
Keycloak 클라이언트 설정에서 Valid redirect URIs 확인:
```yaml
Valid redirect URIs:
  - https://harbor.example.com/c/oidc/callback
  - https://harbor.example.com/*
```

### 3. 클라이언트 시크릿 오류

**증상:**
```
OIDC authentication failed: invalid client secret
```

**해결 방법:**
```bash
# Keycloak에서 클라이언트 시크릿 재생성
# Harbor 설정 업데이트
helm upgrade harbor harbor/harbor \
  --set core.secret=NEW_CLIENT_SECRET \
  -n harbor
```

### 4. 그룹 매핑 문제

**증상:**
- 사용자가 로그인되지만 권한이 없음
- 관리자 그룹 사용자가 관리자 권한을 받지 못함

**해결 방법:**
```bash
# Keycloak 토큰 확인
curl -X POST https://keycloak.example.com/realms/master/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "client_id=harbor" \
  -d "client_secret=YOUR_SECRET" \
  -d "code=AUTHORIZATION_CODE" \
  -d "redirect_uri=https://harbor.example.com/c/oidc/callback"

# 토큰 디코딩하여 groups 클레임 확인
```

**Keycloak 매퍼 확인:**
- Group Membership 매퍼가 올바르게 설정되었는지 확인
- Token Claim Name이 "groups"인지 확인

### 5. SSL/TLS 인증서 문제

**증상:**
```
x509: certificate signed by unknown authority
```

**해결 방법:**
```yaml
# 개발 환경에서 임시 해결
core:
  configureUserSettings: |
    oidc_verify_cert = false

# 프로덕션 환경에서는 올바른 인증서 사용
```

### 6. 사용자 자동 생성 실패

**증상:**
- OIDC 로그인 성공하지만 Harbor에 사용자가 생성되지 않음

**해결 방법:**
```yaml
core:
  configureUserSettings: |
    oidc_auto_onboard = true
    oidc_user_claim = preferred_username
```

## 로그 확인 방법

### Harbor Core 로그
```bash
kubectl logs -n harbor deployment/harbor-core -f
```

### Keycloak 로그
```bash
kubectl logs -n keycloak deployment/keycloak -f
```

### 네트워크 연결 테스트
```bash
# Harbor에서 Keycloak 연결 테스트
kubectl exec -n harbor deployment/harbor-core -- \
  curl -k https://keycloak.example.com/realms/master/.well-known/openid_configuration
```

## 디버깅 도구

### 1. OIDC 토큰 디코딩
```bash
# JWT 토큰 디코딩 (jwt.io 또는 명령줄 도구 사용)
echo "JWT_TOKEN" | base64 -d
```

### 2. Keycloak 이벤트 로그
Keycloak Admin Console → Events → Login Events에서 로그인 시도 확인

### 3. Harbor 데이터베이스 확인
```bash
# Harbor 데이터베이스 접속
kubectl exec -n harbor deployment/harbor-database -- \
  psql -U postgres -d registry -c "SELECT * FROM harbor_user WHERE username LIKE '%oidc%';"
```

## 성능 최적화

### 1. 토큰 캐싱
```yaml
core:
  configureUserSettings: |
    oidc_token_cache_size = 1000
    oidc_token_cache_ttl = 300
```

### 2. 연결 풀 설정
```yaml
database:
  internal:
    max_idle_conns: 50
    max_open_conns: 1000
```

## 보안 강화

### 1. 클라이언트 시크릿 보안
```bash
# Kubernetes Secret으로 관리
kubectl create secret generic harbor-oidc-secret \
  --from-literal=client-secret=YOUR_SECRET \
  -n harbor
```

### 2. 네트워크 정책
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: harbor-keycloak-policy
  namespace: harbor
spec:
  podSelector:
    matchLabels:
      app: harbor
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: keycloak
    ports:
    - protocol: TCP
      port: 8080
```

## 모니터링

### 1. 인증 메트릭
```bash
# Harbor 인증 성공/실패 메트릭 확인
curl http://harbor.example.com/api/v2.0/statistics
```

### 2. Keycloak 메트릭
```bash
# Keycloak 로그인 이벤트 모니터링
curl -H "Authorization: Bearer ADMIN_TOKEN" \
  http://keycloak.example.com/admin/realms/master/events
```

## 추가 리소스
- [Harbor 공식 문서](https://goharbor.io/docs/)
- [Keycloak OIDC 문서](https://www.keycloak.org/docs/latest/server_admin/#_oidc)
- [Harbor GitHub Issues](https://github.com/goharbor/harbor/issues)