# Keycloak 설치 및 설정 가이드

이 디렉터리는 Kubernetes 환경에서 Keycloak을 설치하고 Argo CD와 OIDC 연동하는 방법을 다룹니다.

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
└── external-secrets/
    ├── external-secret.yaml           # External Secret 설정
    └── aws-secrets-manager.md         # AWS Secrets Manager 연동
```

## 🚀 빠른 시작

1. **Keycloak 설치**: [installation/installation-guide.md](installation/installation-guide.md)
2. **Argo CD 연동**: [argo-cd-integration/oidc-configuration.md](argo-cd-integration/oidc-configuration.md)
3. **문제 해결**: [argo-cd-integration/troubleshooting.md](argo-cd-integration/troubleshooting.md)

## 🔧 주요 기능

- **AWS ALB Ingress** 를 통한 HTTPS 접근
- **PostgreSQL** 데이터베이스 연동
- **Argo CD OIDC** 인증 연동
- **External Secrets** 를 통한 시크릿 관리

## 📋 요구사항

- Kubernetes 클러스터
- AWS Load Balancer Controller
- External Secrets Operator (선택사항)
- Helm 3.x

## 🌐 접근 URL

- **Keycloak 관리 콘솔**: https://keycloak.bluesunnywings.com/admin/
- **Argo CD**: https://argocd.bluesunnywings.com

## 📞 지원

문제가 발생하면 [troubleshooting.md](argo-cd-integration/troubleshooting.md)를 먼저 확인해주세요.