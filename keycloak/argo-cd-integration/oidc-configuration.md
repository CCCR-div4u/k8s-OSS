# Argo CD OIDC 설정 가이드

이 가이드는 Argo CD에서 Keycloak OIDC 인증을 설정하는 방법을 설명합니다.

## 📋 사전 요구사항

- Keycloak이 설치되고 실행 중
- Keycloak에 OIDC 클라이언트가 생성됨 ([client-setup.md](client-setup.md) 참조)
- Argo CD가 설치되고 실행 중

## ⚙️ Argo CD 설정

### 1. ConfigMap 수정

`argocd-cm` ConfigMap에 OIDC 설정을 추가합니다:

```bash
kubectl -n argo-cd edit configmap argocd-cm
```

다음 설정을 추가:

```yaml
data:
  url: https://argocd.your-domain.com
  oidc.config: |
    name: Keycloak
    issuer: https://keycloak.your-domain.com/realms/your-realm
    clientID: argocd
    enablePKCEAuthentication: false  # PKCE 비활성화 (문제 해결용)
    requestedScopes: ["openid", "profile", "email", "groups"]
```

### 2. Client Secret 설정

#### 방법 1: 직접 Secret 수정

```bash
# Client Secret을 base64로 인코딩
echo -n "your-client-secret" | base64

# Secret 수정
kubectl -n argo-cd patch secret argocd-secret -p '{"data":{"oidc.keycloak.clientSecret":"base64-encoded-secret"}}'
```

#### 방법 2: External Secrets 사용 (권장)

AWS Secrets Manager를 사용하는 경우:

```bash
# AWS Secrets Manager에 저장
aws secretsmanager put-secret-value \
  --secret-id "argocd/oidc/keycloak" \
  --secret-string '{"oidc.keycloak.clientSecret":"your-client-secret"}'
```

### 3. Argo CD 서버 재시작

```bash
kubectl -n argo-cd rollout restart deployment/argo-cd-argocd-server
kubectl -n argo-cd rollout status deployment/argo-cd-argocd-server
```

## 🔧 PKCE 설정

### PKCE 활성화 (권장)

보안을 위해 PKCE를 활성화하려면:

1. **Keycloak 클라이언트 설정**에서 추가 redirect URI 등록:
   ```
   https://argocd.your-domain.com/pkce/verify
   ```

2. **Argo CD 설정**에서 PKCE 활성화:
   ```yaml
   oidc.config: |
     name: Keycloak
     issuer: https://keycloak.your-domain.com/realms/your-realm
     clientID: argocd
     enablePKCEAuthentication: true
     requestedScopes: ["openid", "profile", "email", "groups"]
   ```

### PKCE 비활성화 (문제 해결용)

문제 해결을 위해 PKCE를 비활성화하려면:

```yaml
oidc.config: |
  name: Keycloak
  issuer: https://keycloak.your-domain.com/realms/your-realm
  clientID: argocd
  enablePKCEAuthentication: false
  requestedScopes: ["openid", "profile", "email", "groups"]
```

## 🛡️ RBAC 설정

### 1. 기본 RBAC 설정

`argocd-rbac-cm` ConfigMap을 수정하여 RBAC 정책을 설정:

```bash
kubectl -n argo-cd edit configmap argocd-rbac-cm
```

```yaml
data:
  policy.default: role:readonly
  policy.csv: |
    # 관리자 그룹
    g, argocd-admins, role:admin
    
    # 개발자 그룹
    g, argocd-developers, role:readonly
    
    # 커스텀 역할 정의
    p, role:developer, applications, *, */*, allow
    p, role:developer, repositories, *, *, allow
    g, argocd-developers, role:developer
```

### 2. 그룹 매핑 확인

Keycloak에서 사용자가 적절한 그룹에 속해 있는지 확인:

1. Keycloak 관리 콘솔 → Users
2. 사용자 선택 → Groups 탭
3. 필요한 그룹에 사용자 추가

## 🧪 테스트

### 1. 로그인 테스트

1. https://argocd.your-domain.com 접속
2. **LOG IN VIA KEYCLOAK** 버튼 클릭
3. Keycloak 로그인 페이지에서 인증
4. Argo CD 대시보드로 리다이렉트 확인

### 2. 로그 확인

```bash
# Argo CD 서버 로그 확인
kubectl -n argo-cd logs deployment/argo-cd-argocd-server --tail=50

# Keycloak 로그 확인
kubectl -n keycloak logs keycloak-0 --tail=50
```

## 📊 설정 예시

### 완전한 argocd-cm 설정 예시

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-cm
  namespace: argo-cd
data:
  url: https://argocd.bluesunnywings.com
  oidc.config: |
    name: Keycloak
    issuer: https://keycloak.bluesunnywings.com/realms/test1
    clientID: argocd
    enablePKCEAuthentication: false
    requestedScopes: ["openid", "profile", "email", "groups"]
  # 기타 설정들...
```

### External Secret 설정 예시

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: argocd-keycloak
  namespace: argo-cd
spec:
  refreshInterval: 1m
  secretStoreRef:
    kind: SecretStore
    name: aws-secretsmanager-argo-cd
  target:
    name: argocd-secret
    creationPolicy: Merge
  data:
  - secretKey: oidc.keycloak.clientSecret
    remoteRef:
      key: argocd/oidc/keycloak
      property: oidc.keycloak.clientSecret
```

## 🔍 문제 해결

일반적인 문제들은 [troubleshooting.md](troubleshooting.md)를 참조하세요.

## 📚 참고 자료

- [Argo CD OIDC 공식 문서](https://argo-cd.readthedocs.io/en/stable/operator-manual/user-management/#oidc)
- [Keycloak 공식 문서](https://www.keycloak.org/documentation)