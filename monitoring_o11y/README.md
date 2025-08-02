# LGTM Stack for EKS Observability

이 디렉터리는 EKS 클러스터에 LGTM (Loki, Grafana, Tempo, Mimir) 스택을 도입하는 두 가지 옵션을 제공합니다.

## 📋 LGTM 스택 구성 요소

- **L**oki: 로그 수집 및 저장
- **G**rafana: 통합 시각화 대시보드
- **T**empo: 분산 트레이싱
- **M**imir: 메트릭 장기 저장 (Prometheus 대체)

## 🎯 옵션 비교

| 구분 | Option 1: LGTM Only | Option 2: Prometheus + LGTM |
|------|---------------------|------------------------------|
| **메트릭** | Mimir | Prometheus (기존) |
| **로그** | Loki | Loki |
| **트레이싱** | Tempo | Tempo |
| **시각화** | Grafana | Grafana (기존) |
| **복잡도** | 낮음 | 중간 |
| **리소스** | 적음 | 많음 |
| **호환성** | 완전 통합 | 혼합 환경 |

## 📁 디렉터리 구조

```
o11y/
├── README.md                           # 이 파일
├── option1-lgtm-only/                  # 완전한 LGTM 스택
│   ├── README.md                       # 옵션 1 가이드
│   ├── manifests/                      # Kubernetes 매니페스트
│   │   ├── lgtm-values.yaml           # LGTM 통합 설정
│   │   ├── storage-config.yaml        # 스토리지 설정
│   │   └── ingress.yaml               # 접속용 Ingress
│   └── scripts/                       # 배포/정리 스크립트
│       ├── deploy.sh                  # 배포 스크립트
│       └── cleanup.sh                 # 정리 스크립트
└── option2-prometheus-plus-lgtm/       # Prometheus + LGTM 혼합
    ├── README.md                       # 옵션 2 가이드
    ├── manifests/                      # Kubernetes 매니페스트
    │   ├── loki-values.yaml           # Loki 설정
    │   ├── tempo-values.yaml          # Tempo 설정
    │   ├── promtail-values.yaml       # 로그 수집기 설정
    │   ├── ingress.yaml               # 접속용 Ingress
    │   └── grafana-datasource-patch.yaml # Grafana 데이터 소스 설정
    └── scripts/                       # 배포/정리 스크립트
        ├── deploy.sh                  # 배포 스크립트
        └── cleanup.sh                 # 정리 스크립트
```

## 🚀 사용 방법

### 사전 요구사항
- EKS 클러스터가 실행 중이어야 함
- kubectl이 클러스터에 연결되어 있어야 함
- Helm 3.x 설치됨

### 옵션 선택
1. **Option 1**: 완전히 새로운 LGTM 스택 (기존 모니터링 대체)
2. **Option 2**: 기존 Prometheus와 LGTM 병행 사용

**⚠️ Option 2 주의사항**: 기존 Prometheus/Grafana가 설치되어 있어야 합니다. 만약 아무것도 없다면 `option2-prometheus-plus-lgtm/setup-prometheus-first.md`를 먼저 따라하세요.

각 옵션의 상세한 가이드는 해당 디렉터리의 README.md를 참조하세요.

## ⚠️ 주의사항

1. **리소스 사용량**: LGTM 스택은 상당한 CPU/메모리를 사용합니다
2. **스토리지**: 로그와 트레이스 데이터를 위한 충분한 스토리지 필요
3. **네트워크**: 각 구성 요소 간 통신을 위한 네트워크 정책 고려
4. **정리**: Terraform destroy 전에 반드시 cleanup 스크립트 실행

## 🔗 참고 문서

- [Grafana LGTM Stack](https://grafana.com/docs/lgtm-stack/)
- [Loki Documentation](https://grafana.com/docs/loki/)
- [Tempo Documentation](https://grafana.com/docs/tempo/)
- [Mimir Documentation](https://grafana.com/docs/mimir/)