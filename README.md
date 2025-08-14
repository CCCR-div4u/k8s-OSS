# k8s-OSS (Kubernetes Open Source Software)

Kubernetes 환경에서 운영할 수 있는 오픈소스 소프트웨어들의 설치 및 설정 가이드 모음입니다.

## 📋 프로젝트 개요

이 저장소는 EKS(Elastic Kubernetes Service) 클러스터에서 다양한 오픈소스 도구들을 배포하고 운영하기 위한 완전한 가이드를 제공합니다. 각 도구는 AWS ALB Ingress Controller, External DNS, ACM 인증서를 활용하여 프로덕션 환경에 적합하게 구성되어 있습니다.

## 🛠️ 포함된 OSS 도구들

### 🚀 CI/CD & GitOps
- **[Argo CD](./argo-cd/)**: GitOps 기반 지속적 배포 도구
  - Helm을 통한 설치 및 설정
  - GitHub Actions 워크플로우 자동화
  - HTTPS 접속 및 초기 설정 가이드

### 🐳 컨테이너 레지스트리
- **[Harbor](./harbor/)**: 엔터프라이즈급 컨테이너 레지스트리
  - Docker 이미지 Push/Pull 테스트
  - Kubernetes에서 Private Registry 사용
  - 보안 스캔 및 정책 관리

### 🔐 인증 및 권한 관리
- **[Keycloak](./keycloak/)**: 오픈소스 Identity and Access Management
  - OIDC 기반 Single Sign-On
  - Argo CD와 Harbor 연동
  - External Secrets를 통한 시크릿 관리
  - AWS Secrets Manager 통합

### 📊 모니터링 및 관찰성
- **[Monitoring & Observability](./monitoring_o11y/)**: LGTM 스택 기반 통합 모니터링
  - **Option 1**: 완전한 LGTM 스택 (Loki, Grafana, Tempo, Mimir)
  - **Option 2**: 기존 Prometheus + LGTM 혼합 환경
  - 애플리케이션 통합 가이드 및 샘플 앱

- **[Thanos](./thanos/)**: Prometheus 장기 저장 및 고가용성 솔루션
  - S3 기반 무제한 메트릭 저장
  - 다중 클러스터 통합 쿼리
  - 자동 다운샘플링으로 비용 최적화
  - 3가지 설치 옵션 제공

### 🔍 코드 품질 관리
- **[SonarQube](./sonarqube/)**: 정적 코드 분석 도구
  - PostgreSQL 데이터베이스 연동
  - GitHub Actions CI/CD 통합
  - 코드 품질 메트릭 및 기술 부채 관리

## 🏗️ 아키텍처 특징

### 공통 인프라 구성
- **AWS EKS**: 관리형 Kubernetes 서비스
- **AWS ALB Ingress Controller**: 로드 밸런서 자동 관리
- **External DNS**: 자동 DNS 레코드 생성
- **ACM 인증서**: HTTPS 통신 보안
- **도메인**: `*.bluesunnywings.com`

### 네트워킹
- 모든 서비스는 HTTPS로 접근 가능
- 공통 ALB 그룹을 통한 비용 최적화
- 자동 DNS 관리로 운영 부담 최소화

### 보안
- TLS/SSL 인증서 자동 관리
- OIDC 기반 통합 인증
- Private Registry를 통한 이미지 보안
- External Secrets를 통한 시크릿 관리

## 🚀 빠른 시작

### 사전 요구사항
- AWS EKS 클러스터
- kubectl 설정 완료
- Helm 3.x 설치
- AWS Load Balancer Controller 설치
- External DNS 설정

### 설치 순서 (권장)
1. **Keycloak** - 인증 시스템 기반 구축
2. **Harbor** - 컨테이너 이미지 저장소
3. **Argo CD** - GitOps 배포 파이프라인
4. **Monitoring** - 관찰성 스택 구축
5. **SonarQube** - 코드 품질 관리

각 도구의 상세한 설치 가이드는 해당 디렉터리의 README.md를 참조하세요.

## 📁 디렉터리 구조

```
k8s-OSS/
├── README.md                    # 이 파일
├── .github/workflows/           # GitHub Actions 워크플로우
├── argo-cd/                     # GitOps 지속적 배포
│   ├── README.md
│   └── my-values.yaml
├── harbor/                      # 컨테이너 레지스트리
│   ├── README.md
│   ├── override-values.yaml
│   └── nginx-harbor/           # 테스트 애플리케이션
├── keycloak/                    # 인증 및 권한 관리
│   ├── README.md
│   ├── installation/           # 설치 가이드
│   ├── argo-cd-integration/    # Argo CD 연동
│   ├── harbor-integration/     # Harbor 연동
│   └── external-secrets/       # 시크릿 관리
├── monitoring_o11y/             # LGTM 스택 모니터링
│   ├── README.md
│   ├── option1-lgtm-only/      # 완전한 LGTM 스택
│   ├── option2-prometheus-plus-lgtm/  # 혼합 환경
│   └── sample-app/             # 샘플 애플리케이션
├── sonarqube/                   # 코드 품질 분석
│   ├── README.md
│   └── override-values.yaml
└── thanos/                      # 장기 메트릭 저장
    ├── README.md
    ├── option1-existing-prometheus/
    ├── option2-fresh-install/
    ├── option3-slack/
    ├── terraform/              # S3 버킷 생성
    └── values/                 # Helm 설정값
```

## 🌐 접속 URL

배포 완료 후 다음 URL들로 각 서비스에 접근할 수 있습니다:

- **Argo CD**: https://argocd.bluesunnywings.com
- **Harbor**: https://harbor.bluesunnywings.com
- **Keycloak**: https://keycloak.bluesunnywings.com
- **Grafana**: https://grafana.bluesunnywings.com
- **Prometheus**: https://prometheus.bluesunnywings.com
- **SonarQube**: https://sonarqube.bluesunnywings.com

## 🔧 운영 가이드

### 모니터링
- Grafana 대시보드를 통한 통합 모니터링
- Thanos를 통한 장기 메트릭 저장
- LGTM 스택으로 로그, 메트릭, 트레이싱 통합

### 보안
- Keycloak을 통한 중앙 집중식 인증
- Harbor를 통한 컨테이너 이미지 보안 스캔
- External Secrets를 통한 시크릿 자동 관리

### CI/CD
- Argo CD를 통한 GitOps 기반 배포
- GitHub Actions를 통한 자동화
- SonarQube를 통한 코드 품질 게이트

## 🧹 리소스 정리

각 도구를 제거할 때는 다음 순서를 권장합니다:

```bash
# 1. 애플리케이션 정리
kubectl delete -f <app-manifests>

# 2. Helm 릴리스 삭제
helm uninstall <release-name> -n <namespace>

# 3. PVC 정리 (데이터 손실 주의!)
kubectl delete pvc --all -n <namespace>

# 4. 네임스페이스 삭제
kubectl delete namespace <namespace>
```

## 📞 지원 및 문제 해결

각 도구별 문제 해결 가이드는 해당 디렉터리의 README.md 또는 troubleshooting.md 파일을 참조하세요.

## 🤝 기여하기

이 프로젝트에 기여하고 싶으시다면:
1. Fork 후 브랜치 생성
2. 변경사항 커밋
3. Pull Request 생성

## 📄 라이선스

이 프로젝트는 각 오픈소스 도구들의 라이선스를 따릅니다.
