# Option 2: Prometheus + LGTM Hybrid

기존 Prometheus 모니터링을 유지하면서 Loki와 Tempo를 추가하는 하이브리드 옵션입니다.

## 📋 구성 요소

- **Prometheus**: 메트릭 수집 및 저장 (기존 유지)
- **Grafana**: 통합 시각화 (기존 유지)
- **Loki**: 로그 수집 및 저장 (신규 추가)
- **Tempo**: 분산 트레이싱 (신규 추가)
- **Promtail**: 로그 수집 에이전트 (신규 추가)

## 🏗️ 아키텍처

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Grafana   │◄───┤ Prometheus  │    │    Loki     │
│ (기존 유지)   │    │  (기존 유지)  │    │  (신규 추가) │
└─────────────┘    └─────────────┘    └─────────────┘
       ▲                                      ▲
       │                                      │
       │              ┌─────────────┐         │
       └──────────────┤    Tempo    │◄────────┘
                      │  (신규 추가) │
                      └─────────────┘
```

## 🚀 배포 방법

### 0. 사전 요구사항
**⚠️ 중요**: 이 옵션은 기존 Prometheus/Grafana가 설치되어 있어야 합니다.

만약 아무것도 설치되어 있지 않다면, 먼저 [`setup-prometheus-first.md`](./setup-prometheus-first.md) 가이드를 따라 기본 모니터링 스택을 설치해주세요.

### 1. 사전 준비
```bash
cd option2-prometheus-plus-lgtm

# 기존 Prometheus 스택이 실행 중인지 확인
kubectl get pods -n monitoring
```

### 2. 배포 실행
```bash
chmod +x scripts/*.sh
./scripts/deploy.sh
```

### 3. 배포 과정
1. **기존 모니터링 확인**: Prometheus/Grafana 상태 점검
2. **Loki 설치**: 로그 수집 및 저장 시스템
3. **Tempo 설치**: 분산 트레이싱 시스템
4. **Promtail 설치**: 로그 수집 에이전트
5. **Grafana 데이터 소스 추가**: Loki, Tempo 연결
6. **Ingress 업데이트**: 새로운 서비스 접속 경로

## 🌐 접속 정보

기존 접속 URL 유지 + 새로운 서비스 추가:

### 기존 서비스 (유지)
- **Grafana**: https://grafana.bluesunnywings.com
- **Prometheus**: https://prometheus.bluesunnywings.com

### 새로운 서비스 (추가)
- **Loki**: https://loki.bluesunnywings.com (API 접속)
- **Tempo**: https://tempo.bluesunnywings.com (API 접속)

### Grafana 로그인 (기존과 동일)
- **Username**: admin
- **Password**: 기존 패스워드 유지

## 📊 데이터 소스 설정

Grafana에 다음 데이터 소스가 추가됩니다:

### 기존 데이터 소스 (유지)
1. **Prometheus**: http://prometheus-kube-prometheus-prometheus:9090

### 새로운 데이터 소스 (추가)
2. **Loki**: http://loki:3100
3. **Tempo**: http://tempo:3100

## 🔧 주요 설정

### 메트릭 수집 (기존 유지)
- **Prometheus**: 기존 설정 그대로 유지
- **ServiceMonitor**: 기존 메트릭 수집 규칙 유지
- **AlertManager**: 기존 알림 규칙 유지

### 로그 수집 (신규 추가)
- **Promtail**: DaemonSet으로 모든 노드에 배포
- **로그 파싱**: JSON, 멀티라인 로그 지원
- **레이블링**: namespace, pod, container 자동 태깅

### 트레이싱 (신규 추가)
- **OpenTelemetry**: OTLP 프로토콜 지원
- **Jaeger 호환**: 기존 Jaeger 클라이언트 지원
- **샘플링**: 1% 샘플링 비율 (성능 최적화)

## 📈 대시보드

### 기존 대시보드 (유지)
- **Kubernetes Cluster Overview**
- **Node Exporter Full**
- **Prometheus Stats**

### 새로운 대시보드 (추가)
- **Loki Logs Dashboard**
- **Tempo Tracing Dashboard**
- **Log Analysis Dashboard**
- **Distributed Tracing Overview**

## 🗂️ 스토리지 요구사항

| 구성 요소 | 스토리지 | 용량 | 타입 | 상태 |
|-----------|----------|------|------|------|
| Prometheus | PVC | 50Gi | GP3 | 기존 |
| Grafana | PVC | 5Gi | GP3 | 기존 |
| Loki | PVC | 30Gi | GP3 | 신규 |
| Tempo | PVC | 20Gi | GP3 | 신규 |

## 🔄 기존 시스템과의 통합

### Grafana 설정 업데이트
```yaml
# 자동으로 추가되는 데이터 소스
datasources:
  - name: Loki
    type: loki
    url: http://loki:3100
  - name: Tempo
    type: tempo
    url: http://tempo:3100
```

### 로그-메트릭 상관관계
- **Grafana Explore**: 로그와 메트릭을 함께 조회
- **Trace to Logs**: 트레이스에서 관련 로그로 바로 이동
- **Logs to Metrics**: 로그에서 관련 메트릭으로 바로 이동

## 🔍 트러블슈팅

### 일반적인 문제

**1. Loki 파드가 시작되지 않음**
```bash
kubectl describe pod -n monitoring -l app=loki
kubectl logs -n monitoring -l app=loki
```

**2. Promtail이 로그를 수집하지 않음**
```bash
kubectl logs -n monitoring daemonset/promtail
kubectl get configmap -n monitoring promtail -o yaml
```

**3. Tempo 트레이스가 보이지 않음**
```bash
kubectl logs -n monitoring deployment/tempo
kubectl port-forward -n monitoring svc/tempo 3100:3100
```

### 상태 확인 명령어
```bash
# 전체 모니터링 스택 상태
kubectl get pods -n monitoring

# 새로 추가된 서비스 확인
kubectl get svc -n monitoring | grep -E "(loki|tempo)"

# 데이터 소스 연결 테스트
kubectl port-forward -n monitoring svc/loki 3100:3100
curl http://localhost:3100/ready
```

## 🧹 정리 방법

### 리소스 정리
```bash
./scripts/cleanup.sh
```

### 정리 과정
1. **새로운 Helm 릴리스 삭제**: Loki, Tempo 제거
2. **Promtail DaemonSet 삭제**: 로그 수집 에이전트 제거
3. **PVC 삭제**: 새로 생성된 스토리지 볼륨 정리
4. **Grafana 데이터 소스 정리**: 추가된 데이터 소스 제거
5. **기존 모니터링 유지**: Prometheus/Grafana는 그대로 유지

**⚠️ 중요**: 
- 기존 Prometheus/Grafana는 영향받지 않음
- 새로 추가된 구성 요소만 정리됨

## 📊 리소스 사용량 비교

| 구분 | 기존 (Prometheus만) | 추가 후 (Hybrid) | 증가량 |
|------|-------------------|------------------|--------|
| **CPU** | 2 코어 | 4 코어 | +2 코어 |
| **메모리** | 4Gi | 8Gi | +4Gi |
| **스토리지** | 55Gi | 105Gi | +50Gi |
| **파드 수** | ~15개 | ~25개 | +10개 |

## 📝 성능 최적화

### Loki 최적화
- **청크 압축**: gzip 압축으로 스토리지 절약
- **인덱스 최적화**: 레이블 카디널리티 제한
- **보존 정책**: 7일 후 자동 삭제

### Tempo 최적화
- **샘플링**: 1% 샘플링으로 오버헤드 최소화
- **압축**: 트레이스 데이터 압축 저장
- **보존 정책**: 3일 후 자동 삭제

## 🔗 참고 자료

- [Loki + Prometheus 통합 가이드](https://grafana.com/docs/loki/latest/getting-started/grafana/)
- [Tempo + Prometheus 통합](https://grafana.com/docs/tempo/latest/getting-started/grafana/)
- [Promtail 설정 가이드](https://grafana.com/docs/loki/latest/clients/promtail/)
- [OpenTelemetry + Tempo](https://grafana.com/docs/tempo/latest/getting-started/instrumentation/)