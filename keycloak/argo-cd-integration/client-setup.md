# Keycloak 클라이언트 설정 가이드

이 가이드는 Argo CD와 OIDC 연동을 위한 Keycloak 클라이언트 설정 방법을 설명합니다.

## 🎯 클라이언트 생성

### 1. 관리자 콘솔 접속

1. https://keycloak.bluesunnywings.com/admin/ 접속
2. 관리자 계정으로 로그인
3. 적절한 Realm 선택 (예: `test1`)

### 2. 클라이언트 생성

1. 좌측 메뉴에서 **Clients** 클릭
2. **Create client** 버튼 클릭
3. 다음 정보 입력:
   - **Client type**: `OpenID Connect`
   - **Client ID**: `argocd`
   - **Name**: `Argo CD` (선택사항)
4. **Next** 클릭

### 3. Capability config

1. **Client authentication**: `On` ✅
2. **Authorization**: `Off`
3. **Standard flow**: `On` ✅
4. **Direct access grants**: `Off` (보안상 권장)
5. **Implicit flow**: `Off` (보안상 권장)
6. **Service accounts roles**: `Off`
7. **Next** 클릭

### 4. Login settings

다음 URL들을 정확히 입력합니다:

- **Root URL**: `https://argocd.bluesunnywings.com`
- **Home URL**: `https://argocd.bluesunnywings.com`
- **Valid redirect URIs**: 
  ```
  https://argocd.bluesunnywings.com/auth/callback
  ```
- **Valid post logout redirect URIs**:
  ```
  https://argocd.bluesunnywings.com/auth/logout
  ```
- **Web origins**: 
  ```
  https://argocd.bluesunnywings.com
  ```
  또는 `+` (자동 설정)

5. **Save** 버튼 클릭

## 🔑 Client Secret 확인

### 1. Credentials 탭

1. 생성된 클라이언트에서 **Credentials** 탭 클릭
2. **Client secret** 값 확인
3. **Show** 버튼을 클릭하여 실제 값 복사

### 2. Secret 재생성 (필요시)

1. **Regenerate** 버튼 클릭
2. 새로 생성된 secret 값 복사
3. Argo CD 설정에 반영

## ⚙️ 고급 설정

### 1. Advanced Settings (선택사항)

- **Access Token Lifespan**: `5 minutes` (기본값)
- **Client Session Idle**: `30 minutes` (기본값)
- **Client Session Max**: `12 hours` (기본값)

### 2. Mappers 설정 (그룹 정보 필요시)

1. **Client scopes** 탭 클릭
2. **argocd-dedicated** 스코프 선택
3. **Add mapper** → **By configuration** → **Group Membership**
4. 다음 설정:
   - **Name**: `groups`
   - **Token Claim Name**: `groups`
   - **Full group path**: `Off`
   - **Add to ID token**: `On`
   - **Add to access token**: `On`
   - **Add to userinfo**: `On`

## ✅ 설정 검증 체크리스트

### 기본 설정
- [ ] **Client ID**: `argocd`
- [ ] **Client Type**: `OpenID Connect`
- [ ] **Client authentication**: `On`

### 인증 플로우
- [ ] **Standard Flow**: `On`
- [ ] **Direct Access Grants**: `Off`
- [ ] **Implicit Flow**: `Off`

### URL 설정
- [ ] **Root URL**: `https://argocd.bluesunnywings.com`
- [ ] **Valid redirect URIs**: `https://argocd.bluesunnywings.com/auth/callback`
- [ ] **Web origins**: `https://argocd.bluesunnywings.com` 또는 `+`

### 보안 설정
- [ ] **Client Secret** 확인 및 복사 완료
- [ ] **SSL Required**: `External requests` (Realm 설정)

## 🔍 문제 해결

### "invalid_redirect_uri" 오류
- Valid redirect URIs에 정확한 URL이 등록되어 있는지 확인
- HTTPS/HTTP, 포트, 경로가 정확한지 확인
- PKCE 사용 시 `/pkce/verify` 경로도 추가 필요

### "unauthorized_client" 오류
- Client authentication이 `On`으로 설정되어 있는지 확인
- Client Secret이 Argo CD 설정과 일치하는지 확인
- Client ID가 정확한지 확인 (`argocd`)

### 로그인 후 권한 없음
- 사용자가 적절한 그룹에 속해 있는지 확인
- Argo CD RBAC 설정 확인
- Group Mapper가 올바르게 설정되어 있는지 확인

## 📚 다음 단계

클라이언트 설정이 완료되면:
1. [Argo CD OIDC 설정](oidc-configuration.md)
2. [문제 해결 가이드](troubleshooting.md)