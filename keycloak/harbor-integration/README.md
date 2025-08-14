# Keycloak-Harbor 연동 가이드

## 개요
이 디렉터리는 Keycloak과 Harbor 컨테이너 레지스트리 간의 OIDC 연동 설정 및 관리에 대한 종합적인 가이드를 제공합니다.

## 문서 구성

### 📋 [클라이언트 설정](./client-setup.md)
- Keycloak에서 Harbor용 OIDC 클라이언트 생성
- 사용자 그룹 및 역할 매핑 설정
- 클라이언트 매퍼 구성

### ⚙️ [OIDC 설정](./oidc-configuration.md)
- Harbor에서 Keycloak OIDC 인증 설정
- Helm values.yaml 구성
- 사용자 로그인 테스트

### 🔧 [문제 해결](./troubleshooting.md)
- 일반적인 연동 문제 및 해결 방법
- 로그 확인 및 디버깅 도구
- 성능 최적화 및 보안 강화

### 📁 [프로젝트 관리](./project-management.md)
- Harbor 프로젝트 생성 및 권한 설정
- Robot 계정 관리
- CI/CD 파이프라인 연동

## 빠른 시작

### 1. 사전 요구사항
- Keycloak 서버가 실행 중이어야 함
- Harbor가 Kubernetes에 배포되어 있어야 함
- 적절한 DNS 설정 및 TLS 인증서

### 2. 설정 순서
1. [Keycloak 클라이언트 설정](./client-setup.md)
2. [Harbor OIDC 구성](./oidc-configuration.md)
3. [사용자 그룹 및 권한 설정](./project-management.md)
4. [테스트 및 문제 해결](./troubleshooting.md)

## 주요 기능

### 🔐 Single Sign-On (SSO)
- Keycloak 계정으로 Harbor 로그인
- 중앙화된 사용자 관리
- 그룹 기반 권한 관리

### 👥 사용자 관리
- 자동 사용자 온보딩
- 그룹 기반 역할 할당
- 세밀한 권한 제어

### 🏗️ 프로젝트 관리
- 자동화된 프로젝트 생성
- 그룹별 프로젝트 접근 권한
- Robot 계정을 통한 CI/CD 연동

## 아키텍처 다이어그램

```
┌─────────────┐    OIDC     ┌─────────────┐
│   사용자     │ ◄─────────► │  Keycloak   │
└─────────────┘             └─────────────┘
       │                           │
       │ 로그인                     │ 인증/인가
       ▼                           ▼
┌─────────────┐    API      ┌─────────────┐
│   Harbor    │ ◄─────────► │ Kubernetes  │
└─────────────┘             └─────────────┘
```

## 보안 고려사항

### 🔒 인증 보안
- HTTPS 필수 사용
- 클라이언트 시크릿 보안 관리
- 토큰 만료 시간 설정

### 🛡️ 권한 관리
- 최소 권한 원칙 적용
- 정기적인 권한 검토
- 감사 로그 모니터링

## 모니터링 및 유지보수

### 📊 메트릭 수집
- 로그인 성공/실패 통계
- 프로젝트별 사용량 모니터링
- 성능 메트릭 추적

### 🔄 정기 작업
- 인증서 갱신
- 사용자 권한 검토
- 백업 및 복구 테스트

## 지원되는 버전

| 구성 요소 | 최소 버전 | 권장 버전 |
|----------|----------|----------|
| Keycloak | 15.0+ | 22.0+ |
| Harbor | 2.2+ | 2.8+ |
| Kubernetes | 1.20+ | 1.27+ |

## 추가 리소스

### 공식 문서
- [Harbor 공식 문서](https://goharbor.io/docs/)
- [Keycloak 문서](https://www.keycloak.org/documentation)
- [OIDC 표준](https://openid.net/connect/)

### 커뮤니티
- [Harbor GitHub](https://github.com/goharbor/harbor)
- [Keycloak GitHub](https://github.com/keycloak/keycloak)
- [Harbor Slack](https://cloud-native.slack.com/channels/harbor)

## 기여하기
이 문서에 대한 개선 사항이나 추가 내용이 있다면 Pull Request를 통해 기여해 주세요.

## 라이선스
이 문서는 MIT 라이선스 하에 제공됩니다.