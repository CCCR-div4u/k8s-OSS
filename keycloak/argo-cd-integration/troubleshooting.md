# Keycloak + Argo CD 문제 해결 가이드

이 가이드는 Keycloak과 Argo CD OIDC 연동 시 발생할 수 있는 일반적인 문제들과 해결 방법을 다룹니다.

## 🚨 일반적인 오류들

### 1. "invalid_redirect_uri" 오류

**증상**: Keycloak 로그에 다음과 같은 오류가 나타남
```
type="LOGIN_ERROR", error="invalid_redirect_uri", redirect_uri="https://argocd.bluesunnywings.com/auth/callback"
```

**원인**: Keycloak 클라이언트에 등록된 redirect URI와 Argo CD가 보내는 redirect URI가 일치하지 않음

**해결 방법**:

1. **Argo CD가 보내는 실제 redirect_uri 확인**:
   ```bash
   curl -s "https://argocd.bluesunnywings.com/auth/login" | grep -o "redirect_uri=[^&]*"
   ```

2. **Keycloak 클라이언트 설정 확인**:
   - Keycloak 관리 콘솔 → Clients → argocd → Settings
   - **Valid redirect URIs**에 다음 추가:
     ```
     https://argocd.bluesunnywings.com/auth/callback
     https://argocd.bluesunnywings.com/pkce/verify  # PKCE 사용 시
     ```

3. **URL 정확성 체크**:
   - HTTPS/HTTP 스킴 일치
   - 포트 번호 일치 (443은 생략 가능)
   - 도메인명 정확성
   - 경로 정확성 (`/auth/callback`)

### 2. "unauthorized_client" 오류

**증상**: 로그인 후 다음 오류 발생
```
failed to get token: oauth2: "unauthorized_client" "Invalid client or Invalid client credentials"
```

**원인**: Client Secret 불일치 또는 클라이언트 설정 오류

**해결 방법**:

1. **Client Secret 확인**:
   ```bash
   # Argo CD에 설정된 secret 확인
   kubectl -n argo-cd get secret argocd-secret -o jsonpath='{.data.oidc\.keycloak\.clientSecret}' | base64 -d
   ```

2. **Keycloak에서 새 Client Secret 생성**:
   - Keycloak 관리 콘솔 → Clients → argocd → Credentials
   - **Regenerate** 버튼 클릭
   - 새 secret 복사

3. **Argo CD에 새 secret 적용**:
   ```bash
   # Secret을 base64로 인코딩
   echo -n "new-client-secret" | base64
   
   # Secret 업데이트
   kubectl -n argo-cd patch secret argocd-secret -p '{"data":{"oidc.keycloak.clientSecret":"base64-encoded-value"}}'
   
   # Argo CD 서버 재시작
   kubectl -n argo-cd rollout restart deployment/argo-cd-argocd-server
   ```

4. **클라이언트 설정 확인**:
   - **Client authentication**: `On`
   - **Standard Flow**: `On`
   - **Client ID**: `argocd` (정확히)

### 3. PKCE 관련 오류

**증상**: PKCE 활성화 시 redirect_uri 오류 발생

**해결 방법**:

1. **임시 해결**: PKCE 비활성화
   ```yaml
   oidc.config: |
     name: Keycloak
     issuer: https://keycloak.bluesunnywings.com/realms/test1
     clientID: argocd
     enablePKCEAuthentication: false
     requestedScopes: ["openid", "profile", "email", "groups"]
   ```

2. **근본 해결**: PKCE용 redirect URI 추가
   - Keycloak 클라이언트 설정에서 **Valid redirect URIs**에 추가:
     ```
     https://argocd.bluesunnywings.com/pkce/verify
     ```

### 4. External Secrets 동기화 문제

**증상**: Secret을 수동으로 업데이트해도 이전 값으로 되돌아감

**원인**: External Secrets Operator가 AWS Secrets Manager에서 값을 덮어씀

**해결 방법**:

1. **AWS Secrets Manager 업데이트**:
   ```bash
   aws secretsmanager put-secret-value \
     --secret-id "argocd/oidc/keycloak" \
     --secret-string '{"oidc.keycloak.clientSecret":"new-client-secret"}'
   ```

2. **External Secret 강제 동기화**:
   ```bash
   kubectl -n argo-cd annotate externalsecret argocd-keycloak force-sync=$(date +%s)
   ```

3. **동기화 확인**:
   ```bash
   kubectl -n argo-cd get secret argocd-secret -o jsonpath='{.data.oidc\.keycloak\.clientSecret}' | base64 -d
   ```

## 🔍 디버깅 방법

### 1. 로그 확인

**Argo CD 서버 로그**:
```bash
kubectl -n argo-cd logs deployment/argo-cd-argocd-server --tail=50 --follow
```

**Keycloak 로그**:
```bash
kubectl -n keycloak logs keycloak-0 --tail=50 --follow
```

**특정 오류 필터링**:
```bash
# OIDC 관련 로그만 확인
kubectl -n argo-cd logs deployment/argo-cd-argocd-server | grep -i "oidc\|oauth\|keycloak"

# Keycloak 오류 로그만 확인
kubectl -n keycloak logs keycloak-0 | grep -i "error\|warn"
```

### 2. 설정 확인

**Argo CD OIDC 설정 확인**:
```bash
kubectl -n argo-cd get configmap argocd-cm -o yaml | grep -A 10 "oidc.config"
```

**Client Secret 확인**:
```bash
kubectl -n argo-cd get secret argocd-secret -o jsonpath='{.data.oidc\.keycloak\.clientSecret}' | base64 -d
```

**External Secret 상태 확인**:
```bash
kubectl -n argo-cd get externalsecret argocd-keycloak -o yaml
```

### 3. 네트워크 연결 테스트

**Keycloak 접근성 테스트**:
```bash
# Keycloak 서버 응답 확인
curl -I https://keycloak.bluesunnywings.com

# OIDC 엔드포인트 확인
curl -k "https://keycloak.bluesunnywings.com/realms/test1"
```

**Argo CD에서 Keycloak 접근 테스트**:
```bash
# Argo CD Pod에서 테스트
kubectl -n argo-cd exec -it deployment/argo-cd-argocd-server -- curl -I https://keycloak.bluesunnywings.com
```

## 📋 체크리스트

### Keycloak 클라이언트 설정
- [ ] Client ID: `argocd`
- [ ] Client Type: `OpenID Connect`
- [ ] Client authentication: `On`
- [ ] Standard Flow: `On`
- [ ] Valid redirect URIs: 정확한 URL 등록
- [ ] Web origins: 적절히 설정

### Argo CD 설정
- [ ] `url` 설정: 정확한 외부 URL
- [ ] `issuer` 설정: 정확한 Keycloak realm URL
- [ ] `clientID` 설정: `argocd`
- [ ] Client Secret: Keycloak과 일치

### 네트워크 및 인프라
- [ ] DNS 해상도: 도메인이 올바르게 해석됨
- [ ] SSL 인증서: 유효하고 신뢰할 수 있음
- [ ] 방화벽: 필요한 포트가 열려 있음
- [ ] Load Balancer: 올바르게 구성됨

## 🆘 고급 문제 해결

### 1. 상세 로깅 활성화

**Argo CD 디버그 로깅**:
```bash
kubectl -n argo-cd patch configmap argocd-cmd-params-cm -p '{"data":{"server.log.level":"debug"}}'
kubectl -n argo-cd rollout restart deployment/argo-cd-argocd-server
```

**Keycloak 디버그 로깅**:
```bash
kubectl -n keycloak exec -it keycloak-0 -- /opt/bitnami/keycloak/bin/kc.sh config set log-level=DEBUG
```

### 2. 브라우저 개발자 도구 활용

1. 브라우저에서 F12 키를 눌러 개발자 도구 열기
2. **Network** 탭에서 로그인 과정 모니터링
3. 실패한 요청의 상세 정보 확인
4. `redirect_uri` 파라미터 값 확인

### 3. 임시 우회 방법

**관리자 계정으로 로그인**:
```bash
# 관리자 비밀번호 확인
kubectl -n argo-cd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# 관리자 계정으로 로그인: admin / 위에서 확인한 비밀번호
```

## 📞 추가 지원

문제가 지속되면 다음 정보를 수집하여 지원을 요청하세요:

1. **환경 정보**:
   - Kubernetes 버전
   - Argo CD 버전
   - Keycloak 버전

2. **설정 파일**:
   - `argocd-cm` ConfigMap
   - Keycloak 클라이언트 설정 스크린샷

3. **로그 파일**:
   - Argo CD 서버 로그
   - Keycloak 로그
   - 브라우저 네트워크 로그