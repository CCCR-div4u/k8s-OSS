# Keycloak 설치 및 설정 가이드

이 디렉터리는 Kubernetes 환경에서 Keycloak을 설치하고 Argo CD와 OIDC 연동하는 방법을 다룹니다.

> 🧪 **워크플로 테스트**: 이 파일은 Checkov 보안 스캔 워크플로의 스마트 변경 감지 기능을 테스트하기 위해 수정되었습니다. (2025-08-19)

## 📁 파일 구조

```
keycloak/
├── README.md                           # 이 파일
├── installation/
│   ├── helm-values.yaml               # Keycloak Helm 설치 값
│   └── installation-guide.md          # 설치 가이드
├── argo-cd-integration/
│   ├── oidc-configuration.md          # Argo CD OIDC 설정
│   ├── troubleshooting.md             # 문제 해결 가이드
│   └── client-setup.md                # Keycloak 클라이언트 설정
└── harbor-integration/
    ├── client-setup.md                # Harbor 클라이언트 설정
    ├── oidc-configuration.md          # Harbor OIDC 설정
    ├── project-management.md          # 프로젝트 관리
    ├── README.md                      # Harbor 연동 가이드
    └── troubleshooting.md             # 문제 해결
```

## 🚀 빠른 시작

1. **Keycloak 설치**: [installation/installation-guide.md](installation/installation-guide.md)
2. **Argo CD 연동**: [argo-cd-integration/oidc-configuration.md](argo-cd-integration/oidc-configuration.md)
3. **문제 해결**: [argo-cd-integration/troubleshooting.md](argo-cd-integration/troubleshooting.md)

## 🔧 주요 기능

- **AWS ALB Ingress** 를 통한 HTTPS 접근
- **PostgreSQL** 데이터베이스 연동
- **Argo CD OIDC** 인증 연동
- **Harbor OIDC** 인증 연동
- **보안 스캔** 자동화 (Checkov 통합)

## 📋 요구사항

- Kubernetes 클러스터
- AWS Load Balancer Controller
- Helm 3.x
- 보안 정책 준수 (Checkov 스캔 통과)

## 🌐 접근 URL

- **Keycloak 관리 콘솔**: https://keycloak.bluesunnywings.com/admin/
- **Argo CD**: https://argocd.bluesunnywings.com

## 🔒 보안 고려사항

- 정기적인 보안 스캔 실행
- HTTPS 강제 사용
- 강력한 패스워드 정책 적용
- 정기적인 보안 업데이트

## 📞 지원

문제가 발생하면 [troubleshooting.md](argo-cd-integration/troubleshooting.md)를 먼저 확인해주세요.

---

**📅 최종 업데이트**: 2025-08-19  
**🔧 워크플로 테스트**: 스마트 변경 감지 기능 검증용