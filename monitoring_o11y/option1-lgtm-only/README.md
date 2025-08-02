# Option 1: LGTM Only Stack

완전한 LGTM 스택으로 기존 Prometheus를 대체하는 옵션입니다.

## 📋 구성 요소

- **Mimir**: 메트릭 저장 (Prometheus 대체)
- **Loki**: 로그 수집 및 저장
- **Grafana**: 통합 시각화
- **Tempo**: 분산 트레이싱
- **Prometheus Agent**: 메트릭 수집 및 전송
- **Node Exporter**: 노드 메트릭
- **Kube State Metrics**: Kubernetes 리소스 메트릭

## 🏗️ 아키텍처

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Grafana   │◄───┤    Mimir    │    │    Loki     │
│ (시각화)     │    │  (메트릭)    │    │   (로그)     │
└─────────────┘    └─────────────┘    └─────────────┘
       ▲                   ▲                   ▲
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
                    ┌─────────────┐
                    │    Tempo    │
                    │  (트레이싱)   │
                    └─────────────┘
                           ▲
                           │
                ┌─────────────────────┐
                │ Prometheus Agent    │
                │   (메트릭 수집)      │
                └─────────────────────┘
```

## 🚀 배포 방법

### 1. 사전 준비
```bash
cd option1-lgtm-only
```

### 2. 배포 실행
```bash
chmod +x scripts/*.sh
./scripts/deploy.sh
```

### 3. 배포 과정
1. **네임스페이스 생성**: `lgtm-stack` 네임스페이스
2. **Prometheus Operator CRD 설치**: ServiceMonitor 지원
3. **LGTM 스택 설치**: Grafana Labs 통합 차트 사용
4. **Prometheus Agent 설치**: 메트릭 수집 및 Mimir 전송
5. **Node Exporter 설치**: 노드 메트릭 수집
6. **Kube State Metrics 설치**: Kubernetes 리소스 메트릭
7. **ServiceMonitor 생성**: 메트릭 수집 대상 정의
8. **Grafana 데이터 소스 설정**: Mimir 연동 헤더 설정
9. **Ingress 생성**: 외부 접속을 위한 ALB 설정

## 🌐 접속 정보

배포 완료 후 다음 URL로 접속 가능:

### 웹 UI 접속
- **Grafana**: https://lgtm-grafana.bluesunnywings.com (웹 대시보드)

### API 엔드포인트
- **Mimir**: https://lgtm-mimir.bluesunnywings.com/prometheus (메트릭 API)
- **Loki**: https://lgtm-loki.bluesunnywings.com (로그 API)
- **Tempo**: https://lgtm-tempo.bluesunnywings.com (트레이스 API)

**API 용도:**
- **Mimir**: Grafana에서 메트릭 쿼리
- **Loki**: Grafana에서 로그 검색
- **Tempo**: Grafana에서 트레이스 조회

**참고**: API 엔드포인트는 브라우저 직접 접속용이 아닌 Grafana나 애플리케이션에서 사용하는 백엔드 API입니다.

### Grafana 로그인
- **Username**: admin
- **Password**: admin123!

## 📊 데이터 소스 설정

Grafana에서 자동으로 다음 데이터 소스가 구성됩니다:

1. **Mimir**: http://lgtm-mimir-nginx:80/prometheus (X-Scope-OrgID: anonymous)
2. **Loki**: http://lgtm-loki-query-frontend:3100
3. **Tempo**: http://lgtm-tempo-query-frontend:3100

## 🔧 메트릭 수집 구성

### 자동 수집 메트릭
- **Kubernetes API Server**: 클러스터 상태
- **Kubelet**: 노드 및 컨테이너 메트릭
- **cAdvisor**: 컨테이너 리소스 사용량
- **Kube Proxy**: 네트워크 메트릭
- **CoreDNS**: DNS 메트릭
- **Node Exporter**: 노드 시스템 메트릭
- **Kube State Metrics**: Kubernetes 리소스 상태

### 애플리케이션 메트릭
- **JMX Exporter**: Java 애플리케이션 메트릭 (ServiceMonitor 통해 자동 수집)

## 📈 Grafana 데이터 테스트 방법

### 1. Grafana 접속
```
URL: https://lgtm-grafana.bluesunnywings.com
Username: admin
Password: admin123!
```

### 2. Mimir (메트릭) 테스트
**경로**: 왼쪽 메뉴 → **Explore** → 데이터 소스 **Mimir** 선택

**테스트 쿼리:**
```promql
# 시스템 상태 확인
up

# Java 애플리케이션 메트릭
jvm_memory_pool_collection_used_bytes

# 노드 CPU 사용률
rate(node_cpu_seconds_total[5m])

# 메모리 사용률
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes

# Kubernetes 파드 상태
kube_pod_info
```

### 3. Loki (로그) 테스트
**경로**: **Explore** → 데이터 소스 **Loki** 선택

**테스트 쿼리:**
```logql
# 기본 네임스페이스 로그
{namespace="default"}

# Java 애플리케이션 로그
{namespace="default", app="java-sample-app"}

# 에러 로그 필터링
{namespace="default"} |= "ERROR"

# LGTM 스택 로그
{namespace="lgtm-stack"}
```

### 4. Tempo (트레이스) 테스트
**경로**: **Explore** → 데이터 소스 **Tempo** 선택

**테스트 방법:**
- Service Name: `java-sample-app`
- Time Range: Last 1 hour
- 참고: OpenTelemetry 설정 후에만 트레이스 데이터 표시

### 5. 통합 대시보드 생성
**경로**: **+ → Dashboard → Add visualization**

**추천 패널:**
- **JVM Memory**: `jvm_memory_pool_collection_used_bytes{pool="G1 Old Gen"}`
- **Node CPU**: `100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)`
- **Application Logs**: `{namespace="default", app="java-sample-app"}`

### 6. 데이터 소스 연결 확인
**경로**: **Configuration → Data Sources**

각 데이터 소스에서 **"Save & Test"** 버튼으로 연결 상태 확인

### API로 직접 확인
```bash
# 메트릭 수집 상태 확인
curl -s "https://lgtm-mimir.bluesunnywings.com/prometheus/api/v1/query?query=up"

# JMX 메트릭 확인
curl -s "https://lgtm-mimir.bluesunnywings.com/prometheus/api/v1/query?query=jvm_memory_pool_used_bytes"

# 노드 메트릭 확인
curl -s "https://lgtm-mimir.bluesunnywings.com/prometheus/api/v1/query?query=node_cpu_seconds_total"
```

## 🔍 상태 확인 명령어

### 전체 상태 확인
```bash
# 모든 파드 상태
kubectl get pods -n lgtm-stack

# 서비스 상태
kubectl get svc -n lgtm-stack

# ServiceMonitor 상태
kubectl get servicemonitor -n lgtm-stack

# Ingress 상태
kubectl get ingress -n lgtm-stack
```

### 메트릭 수집 확인
```bash
# Prometheus Agent 타겟 확인
kubectl port-forward -n lgtm-stack prom-agent-prometheus-agent-kube-prom-prometheus-0 9090:9090 &
# 브라우저에서 http://localhost:9090/targets 접속

# ServiceMonitor 라벨 확인
kubectl get servicemonitor -n lgtm-stack --show-labels

# JMX 메트릭 직접 확인
kubectl port-forward -n default svc/java-sample-app-svc 7000:7000 &
curl http://localhost:7000/metrics | grep jvm_memory
```

### 로그 확인
```bash
# Prometheus Agent 로그
kubectl logs -n lgtm-stack prom-agent-prometheus-agent-kube-prom-prometheus-0 -c prometheus

# Grafana 로그
kubectl logs -n lgtm-stack deployment/lgtm-grafana

# Mimir 로그
kubectl logs -n lgtm-stack deployment/lgtm-mimir-distributor
```

## 🗂️ 스토리지 요구사항

| 구성 요소 | 스토리지 | 용량 | 타입 |
|-----------|----------|------|------|
| Mimir | PVC | 50Gi | GP3 |
| Loki | PVC | 30Gi | GP3 |
| Tempo | PVC | 20Gi | GP3 |
| Grafana | PVC | 5Gi | GP3 |
| Prometheus Agent | PVC | 5Gi | GP3 |

## 🔍 트러블슈팅

### 메트릭 수집 문제
```bash
# ServiceMonitor 라벨 매칭 확인
kubectl describe servicemonitor java-app-jmx-monitor -n lgtm-stack
kubectl get svc java-sample-app-svc -n default --show-labels

# Prometheus Agent 401 에러 확인
kubectl logs -n lgtm-stack prom-agent-prometheus-agent-kube-prom-prometheus-0 -c prometheus | grep "401\|org id"
```

### Grafana "no org id" 에러
```bash
# 데이터 소스 설정 확인
kubectl get configmap lgtm-grafana -n lgtm-stack -o yaml | grep -A20 datasources

# Grafana 재시작
kubectl rollout restart deployment lgtm-grafana -n lgtm-stack
```

### 파드 리소스 부족
```bash
# 노드 리소스 확인
kubectl describe nodes
kubectl top nodes
kubectl top pods -A
```

## 🧹 정리 방법

### 리소스 정리
```bash
./scripts/cleanup.sh
```

### 정리 과정
1. **Ingress 삭제**: ALB 리소스 정리
2. **ServiceMonitor 삭제**: 메트릭 수집 설정 제거
3. **Prometheus Agent 삭제**: 메트릭 수집기 제거
4. **시스템 메트릭 삭제**: Node Exporter, Kube State Metrics 제거
5. **LGTM Stack 삭제**: Helm 릴리스 제거
6. **PVC 삭제**: 스토리지 볼륨 정리
7. **네임스페이스 삭제**: 관련 리소스 완전 제거

## 📝 성능 최적화

### 리소스 할당
- **Mimir**: CPU 2코어, 메모리 4Gi
- **Loki**: CPU 1코어, 메모리 2Gi
- **Tempo**: CPU 1코어, 메모리 2Gi
- **Grafana**: CPU 0.5코어, 메모리 1Gi
- **Prometheus Agent**: CPU 0.5코어, 메모리 1Gi

### 데이터 보존 정책
- **메트릭**: 30일 보존
- **로그**: 7일 보존
- **트레이스**: 3일 보존

## 🔗 참고 자료

- [LGTM Stack 공식 문서](https://grafana.com/docs/lgtm-stack/)
- [Mimir 설정 가이드](https://grafana.com/docs/mimir/latest/configure/)
- [Prometheus Agent 가이드](https://prometheus.io/docs/prometheus/latest/feature_flags/#prometheus-agent)