# Keycloak Harbor 클라이언트 설정

## 개요
Harbor 컨테이너 레지스트리와 Keycloak OIDC 연동을 위한 클라이언트 설정 가이드입니다.

## Keycloak 클라이언트 생성

### 1. 새 클라이언트 생성
1. Keycloak Admin Console에 로그인
2. 해당 Realm 선택
3. **Clients** → **Create client** 클릭

### 2. 기본 설정
```yaml
Client ID: harbor
Name: Harbor Container Registry
Description: Harbor 컨테이너 레지스트리 OIDC 클라이언트
```

### 3. Capability config
- **Client authentication**: ON
- **Authorization**: OFF
- **Standard flow**: ON
- **Direct access grants**: OFF
- **Implicit flow**: OFF
- **Service accounts roles**: OFF

### 4. Login settings
```yaml
Root URL: https://harbor.example.com
Home URL: https://harbor.example.com
Valid redirect URIs: 
  - https://harbor.example.com/c/oidc/callback
  - https://harbor.example.com/*
Valid post logout redirect URIs:
  - https://harbor.example.com/*
Web origins:
  - https://harbor.example.com
```

## 클라이언트 세부 설정

### Advanced Settings
```yaml
Access Token Lifespan: 1 Hours
Client Session Idle: 30 Minutes
Client Session Max: 10 Hours
```

### Client Scopes
기본 할당된 스코프:
- `openid`
- `profile` 
- `email`
- `roles`

## 사용자 그룹 및 역할 매핑

### 1. Harbor 관리자 그룹 생성
```yaml
Group Name: harbor-admins
Description: Harbor 관리자 그룹
```

### 2. Harbor 사용자 그룹 생성  
```yaml
Group Name: harbor-users
Description: Harbor 일반 사용자 그룹
```

### 3. 그룹 속성 설정
**harbor-admins 그룹 속성:**
```yaml
harbor_role: admin
```

**harbor-users 그룹 속성:**
```yaml
harbor_role: developer
```

## 클라이언트 매퍼 설정

### 1. 그룹 매퍼 생성
- **Name**: harbor-groups
- **Mapper Type**: Group Membership
- **Token Claim Name**: groups
- **Full group path**: OFF
- **Add to ID token**: ON
- **Add to access token**: ON
- **Add to userinfo**: ON

### 2. 역할 매퍼 생성
- **Name**: harbor-role
- **Mapper Type**: User Attribute
- **User Attribute**: harbor_role
- **Token Claim Name**: harbor_role
- **Claim JSON Type**: String
- **Add to ID token**: ON
- **Add to access token**: ON
- **Add to userinfo**: ON

## 클라이언트 시크릿 확인
1. **Credentials** 탭으로 이동
2. **Client secret** 값 복사 (Harbor 설정에서 사용)

## 테스트 사용자 생성

### 관리자 사용자
```yaml
Username: harbor-admin
Email: harbor-admin@example.com
First Name: Harbor
Last Name: Admin
Groups: harbor-admins
```

### 일반 사용자
```yaml
Username: harbor-user
Email: harbor-user@example.com  
First Name: Harbor
Last Name: User
Groups: harbor-users
```

## 다음 단계
Harbor 설정에서 OIDC 구성을 완료하세요:
- [Harbor OIDC 설정](./oidc-configuration.md)
- [문제 해결](./troubleshooting.md)