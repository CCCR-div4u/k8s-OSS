# 애플리케이션과 LGTM 스택 연동 가이드

⚠️ **중요**: 이 가이드는 최신 버전으로 업데이트되었습니다. 모든 구성 요소가 자동화되어 더 간단해졌습니다.

LGTM 스택을 구축한 후 기존 Java 샘플 애플리케이션과 연동하는 방법을 설명합니다.

## 📋 연동 구성 요소

### 메트릭 연동 (M - Mimir/Prometheus)
- **JMX Exporter**: 이미 설정됨 (7000 포트)
- **ServiceMonitor**: 메트릭 수집 설정 (자동 생성)
- **Prometheus Agent**: 메트릭 수집 및 전송 (Option 1)

### 로그 연동 (L - Loki)
- **Promtail**: 자동으로 모든 파드 로그 수집
- **로그 레이블링**: namespace, pod, container 자동 태깅

### 트레이싱 연동 (T - Tempo)
- **OpenTelemetry**: 애플리케이션 계측 필요
- **Jaeger 호환**: 기존 Jaeger 클라이언트 사용 가능

---

## Option 1: LGTM Only 스택과 연동

### 🚀 자동화된 배포 (권장)

#### 1. LGTM 스택 배포 (모든 구성 요소 자동 설치)
```bash
cd o11y/option1-lgtm-only/scripts
./deploy.sh
```

**자동 설치되는 구성 요소:**
- ✅ LGTM 스택 (Mimir, Loki, Tempo, Grafana)
- ✅ Prometheus Agent (메트릭 수집 및 Mimir 전송)
- ✅ Node Exporter (노드 메트릭)
- ✅ Kube State Metrics (Kubernetes 리소스 메트릭)
- ✅ ServiceMonitor (JMX 메트릭 수집 설정)
- ✅ Grafana 데이터 소스 (Mimir 연동 헤더 포함)
- ✅ Ingress (외부 접속)

#### 2. 샘플 앱 배포
```bash
cd ../sample-app
kubectl create -f manifests/jmx-configmap.yaml
kubectl create -f manifests/storage-test.yaml
```

### 📊 연동 확인

#### Grafana에서 메트릭 확인
1. **접속**: https://lgtm-grafana.bluesunnywings.com
2. **로그인**: admin / admin123!
3. **Explore** → **Mimir** 데이터 소스 선택
4. **메트릭 쿼리**:
   ```promql
   # 시스템 상태
   up
   
   # Java 애플리케이션 메트릭
   jvm_memory_pool_collection_used_bytes
   jvm_memory_pool_used_bytes
   process_cpu_seconds_total
   
   # 노드 메트릭
   node_cpu_seconds_total
   node_memory_MemAvailable_bytes
   
   # Kubernetes 메트릭
   kube_pod_info
   kube_node_info
   ```

#### API로 직접 확인
```bash
# 메트릭 수집 상태 확인
curl -s "https://lgtm-mimir.bluesunnywings.com/prometheus/api/v1/query?query=up"

# JMX 메트릭 확인
curl -s "https://lgtm-mimir.bluesunnywings.com/prometheus/api/v1/query?query=jvm_memory_pool_collection_used_bytes"

# 노드 메트릭 확인
curl -s "https://lgtm-mimir.bluesunnywings.com/prometheus/api/v1/query?query=node_cpu_seconds_total"

# 로그 확인
curl -s "https://lgtm-loki.bluesunnywings.com/loki/api/v1/query_range?query={namespace=\"default\"}"
```

---

## Option 2: Prometheus + LGTM 하이브리드와 연동

### 🚀 자동화된 배포 (권장)

#### 1. 기본 Prometheus 스택 설치
```bash
cd "Sample App with Monitoring/scripts"
./deploy-commands.sh
```

#### 2. LGTM 구성 요소 추가
```bash
cd ../../o11y/option2-prometheus-plus-lgtm/scripts
./deploy.sh
```

### 📊 연동 확인

#### Grafana에서 메트릭 확인
1. **접속**: https://grafana.bluesunnywings.com
2. **로그인**: admin / (kubectl 명령어로 패스워드 확인)
3. **데이터 소스**: Prometheus, Loki, Tempo 모두 사용 가능

#### API로 직접 확인
```bash
# Prometheus에서 JMX 메트릭 확인
curl -s "https://prometheus.bluesunnywings.com/api/v1/query?query=jvm_memory_used_bytes"

# Loki에서 로그 확인
curl -s "https://loki.bluesunnywings.com/loki/api/v1/query_range?query={namespace=\"default\"}"
```

---

## 🔍 상태 확인 명령어

### 전체 상태 확인
```bash
# Option 1
kubectl get pods -n lgtm-stack
kubectl get svc -n lgtm-stack
kubectl get servicemonitor -n lgtm-stack --show-labels

# Option 2
kubectl get pods -n monitoring
kubectl get svc -n monitoring
kubectl get servicemonitor -n monitoring
```

### 메트릭 수집 상태 확인
```bash
# ServiceMonitor 라벨 매칭 확인
kubectl describe servicemonitor java-app-jmx-monitor -n lgtm-stack  # Option 1
kubectl get svc java-sample-app-svc -n default --show-labels

# JMX 메트릭 직접 확인
kubectl port-forward -n default svc/java-sample-app-svc 7000:7000 &
curl http://localhost:7000/metrics | grep jvm_memory | head -5
```

### Prometheus Agent 타겟 확인 (Option 1)
```bash
# Prometheus Agent UI 접속
kubectl port-forward -n lgtm-stack prom-agent-prometheus-agent-kube-prom-prometheus-0 9090:9090 &
# 브라우저에서 http://localhost:9090/targets 접속

# 또는 API로 확인
curl http://localhost:9090/api/v1/targets | grep java-sample-app
```

---

## 🔍 트레이싱 연동 (고급)

### Java 애플리케이션에 OpenTelemetry 추가

#### 1. OpenTelemetry Agent 다운로드
```bash
# 애플리케이션 이미지에 추가하거나 initContainer 사용
wget https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar
```

#### 2. 애플리케이션 Deployment 수정
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: java-sample-app
spec:
  template:
    spec:
      initContainers:
      - name: download-otel-agent
        image: busybox:1.28
        command: ['wget', '-O', '/opt/otel/opentelemetry-javaagent.jar', 'https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar']
        volumeMounts:
        - name: otel-agent
          mountPath: /opt/otel
      containers:
      - name: java-sample
        args:
          - "-javaagent:/opt/jmx_exporter/jmx_prometheus_javaagent-0.19.0.jar=7000:/opt/jmx_exporter/config.yaml"
          - "-javaagent:/opt/otel/opentelemetry-javaagent.jar"
          - "-jar"
          - "/app/app.jar"
        env:
        - name: OTEL_SERVICE_NAME
          value: "java-sample-app"
        - name: OTEL_TRACES_EXPORTER
          value: "otlp"
        - name: OTEL_EXPORTER_OTLP_TRACES_ENDPOINT
          value: "http://tempo:4318/v1/traces"  # Option 2
          # value: "http://lgtm-tempo-distributor:4318/v1/traces"  # Option 1
        - name: OTEL_RESOURCE_ATTRIBUTES
          value: "service.name=java-sample-app,service.version=1.0.0"
        volumeMounts:
        - name: otel-agent
          mountPath: /opt/otel
      volumes:
      - name: otel-agent
        emptyDir: {}
```

---

## 📊 Grafana 대시보드 설정

### 1. 데이터 소스 확인
Grafana에 접속하여 다음 데이터 소스가 설정되어 있는지 확인:

**Option 1:**
- Mimir: `http://lgtm-mimir-nginx:80/prometheus` (X-Scope-OrgID: anonymous)
- Loki: `http://lgtm-loki-query-frontend:3100`
- Tempo: `http://lgtm-tempo-query-frontend:3100`

**Option 2:**
- Prometheus: `http://prometheus-kube-prometheus-prometheus:9090`
- Loki: `http://loki:3100`
- Tempo: `http://tempo:3100`

### 2. 통합 대시보드 생성
```json
{
  "dashboard": {
    "title": "Java Application Observability",
    "panels": [
      {
        "title": "JVM Memory Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "jvm_memory_pool_collection_used_bytes{job=\"java-sample-app-svc\"}",
            "datasource": "Mimir"  // Option 1 또는 "Prometheus" Option 2
          }
        ]
      },
      {
        "title": "Application Logs",
        "type": "logs",
        "targets": [
          {
            "expr": "{namespace=\"default\", app=\"java-sample-app\"}",
            "datasource": "Loki"
          }
        ]
      },
      {
        "title": "Distributed Traces",
        "type": "traces",
        "datasource": "Tempo"
      }
    ]
  }
}
```

---

## 🧹 정리 순서

### Option 1 정리
```bash
# 1. 샘플 앱 정리
kubectl delete -f "sample-app/manifests/storage-test.yaml" --ignore-not-found=true
kubectl delete -f "sample-app/manifests/jmx-configmap.yaml" --ignore-not-found=true

# 2. LGTM 스택 정리 (모든 구성 요소 포함)
cd o11y/option1-lgtm-only/scripts
./cleanup.sh
```

### Option 2 정리
```bash
# 1. LGTM 구성 요소 정리 (Grafana 데이터 소스 원복)
cd o11y/option2-prometheus-plus-lgtm/scripts
./cleanup.sh

# 2. 기본 모니터링 스택 정리
cd "../../../Sample App with Monitoring/scripts"
./cleanup-commands.sh
```

---

## 🎯 성공 지표

### 메트릭 수집 성공
- ✅ `up` 메트릭에서 모든 타겟이 `1` 상태
- ✅ JMX 메트릭 (`jvm_memory_pool_collection_used_bytes` 등) 수집됨
- ✅ 노드 메트릭 (`node_cpu_seconds_total` 등) 수집됨
- ✅ Kubernetes 메트릭 (`kube_pod_info` 등) 수집됨

### 로그 수집 성공
- ✅ 애플리케이션 로그가 Loki에서 조회됨
- ✅ 네임스페이스, 파드별 필터링 가능

### 시각화 성공
- ✅ Grafana에서 모든 데이터 소스 정상 작동
- ✅ 메트릭 쿼리 및 그래프 표시 정상
- ✅ 로그 검색 및 필터링 정상

두 옵션 모두 완전한 관찰 가능성(Observability) 환경을 제공합니다!