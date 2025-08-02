# 애플리케이션 연동 - 최종 가이드

LGTM 스택과 Sample App 스크립트 간의 충돌을 해결한 연동 가이드입니다.

## ⚠️ 중요: 실행 순서

### Option 1: LGTM Only 스택

#### 방법 A: 자동화된 배포 (추천)
```bash
# 1. LGTM 스택 배포 (모든 구성 요소 자동 설치)
cd o11y/option1-lgtm-only/scripts
./deploy.sh

# 2. 샘플 앱 배포
cd ../sample-app
kubectl create -f manifests/jmx-configmap.yaml
kubectl create -f manifests/storage-test.yaml
```

**자동 설치되는 구성 요소:**
- ✅ LGTM 스택 (Mimir, Loki, Tempo, Grafana)
- ✅ Prometheus Agent (메트릭 수집 및 Mimir 전송)
- ✅ Node Exporter (노드 메트릭)
- ✅ Kube State Metrics (Kubernetes 리소스 메트릭)
- ✅ ServiceMonitor (JMX 메트릭 수집 설정)
- ✅ Grafana 데이터 소스 (Mimir 연동 헤더 포함)
- ✅ Ingress (외부 접속)

### Option 2: Prometheus + LGTM 하이브리드

#### 자동화된 배포 (추천)
```bash
# 1. 기본 Prometheus 스택 설치 (Sample App 스크립트 사용)
cd "Sample App with Monitoring/scripts"
./deploy-commands.sh

# 2. LGTM 구성 요소 추가 (Grafana 데이터 소스 자동 설정)
cd ../../o11y/option2-prometheus-plus-lgtm/scripts
./deploy.sh
```

## 📊 연동 확인 방법

### Option 1 확인

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
curl -s "https://lgtm-mimir.bluesunnywings.com/prometheus/api/v1/query?query=jvm_memory_pool_used_bytes"

# 로그 확인
curl -s "https://lgtm-loki.bluesunnywings.com/loki/api/v1/query_range?query={namespace=\"default\"}"
```

### Option 2 확인

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

## 🔍 상태 확인 명령어

### 파드 및 서비스 상태
```bash
# Option 1
kubectl get pods -n lgtm-stack
kubectl get svc -n lgtm-stack
kubectl get servicemonitor -n lgtm-stack

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

### 로그 확인
```bash
# Option 1: Prometheus Agent 로그
kubectl logs -n lgtm-stack prom-agent-prometheus-agent-kube-prom-prometheus-0 -c prometheus | grep -E "(jvm_memory|401|org id)"

# Option 2: Prometheus 로그
kubectl logs -n monitoring prometheus-prometheus-kube-prometheus-prometheus-0 -c prometheus
```

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

## 🔧 트러블슈팅

### Option 1 문제 해결

#### "no org id" 에러 (Grafana)
```bash
# Grafana 데이터 소스 설정 확인
kubectl get configmap lgtm-grafana -n lgtm-stack -o yaml | grep -A10 datasources

# 해결: Grafana 재시작
kubectl rollout restart deployment lgtm-grafana -n lgtm-stack
```

#### JMX 메트릭 수집 안됨
```bash
# ServiceMonitor 라벨 매칭 확인
kubectl describe servicemonitor java-app-jmx-monitor -n lgtm-stack
kubectl get svc java-sample-app-svc -n default --show-labels

# 해결: ServiceMonitor에 release 라벨 확인
kubectl get servicemonitor java-app-jmx-monitor -n lgtm-stack --show-labels
```

#### Prometheus Agent 401 에러
```bash
# Remote write 헤더 확인
kubectl get prometheusagent prometheus-agent-kube-prom-prometheus -n lgtm-stack -o yaml | grep -A5 remoteWrite

# 해결: X-Scope-OrgID 헤더가 설정되어 있어야 함
```

### 공통 문제

#### 파드 리소스 부족
```bash
# 노드 리소스 확인
kubectl describe nodes
kubectl top nodes

# 해결: 노드 스케일링 또는 리소스 제한 조정
```

#### 스토리지 문제
```bash
# PVC 상태 확인
kubectl get pvc -n lgtm-stack  # Option 1
kubectl get pvc -n monitoring  # Option 2

# 해결: StorageClass 및 용량 확인
```

## 📋 권장 테스트 방법

### 단계별 테스트
**한 번에 하나씩 테스트:**
1. Option 1 완전 테스트 → 정리
2. Option 2 완전 테스트 → 정리

### 병렬 테스트
**별도 클러스터 사용:**
- 클러스터 A: Option 1
- 클러스터 B: Option 2

## 🎯 최종 결과

### Option 1 (LGTM Only)
- **접속 URL**: https://lgtm-grafana.bluesunnywings.com
- **데이터 소스**: Mimir, Loki, Tempo
- **파드 수**: 약 25개
- **네임스페이스**: lgtm-stack, default
- **특징**: 완전한 Grafana Labs 스택, Prometheus Agent 사용

### Option 2 (Prometheus + LGTM)
- **접속 URL**: https://grafana.bluesunnywings.com
- **데이터 소스**: Prometheus, Loki, Tempo
- **파드 수**: 약 30개
- **네임스페이스**: monitoring, default
- **특징**: 기존 Prometheus + LGTM 하이브리드

## 🚀 성공 지표

### 메트릭 수집 성공
- ✅ `up` 메트릭에서 모든 타겟이 `1` 상태
- ✅ JMX 메트릭 (`jvm_memory_pool_used_bytes` 등) 수집됨
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