# Sample Java Application for LGTM Stack

LGTM 스택과 연동하기 위한 샘플 Java 애플리케이션입니다.

## 📋 구성 요소

### 애플리케이션
- **Java Spring Boot**: 기본 웹 애플리케이션
- **JMX Exporter**: Prometheus 메트릭 수집 (포트 7000)
- **PersistentVolume**: 데이터 저장용 스토리지

### 메트릭 수집
- **JMX 메트릭**: JVM 메모리, GC, 스레드 등
- **애플리케이션 메트릭**: 커스텀 비즈니스 메트릭
- **자동 수집**: ServiceMonitor를 통한 Prometheus 연동

## 🚀 배포 방법

### 1. JMX ConfigMap 생성
```bash
kubectl create -f manifests/jmx-configmap.yaml
```

### 2. 애플리케이션 배포
```bash
kubectl create -f manifests/storage-test.yaml
```

### 3. 배포 확인
```bash
# 파드 상태 확인
kubectl get pods -n default | grep java-sample-app

# 서비스 확인
kubectl get svc java-sample-app-svc -n default

# JMX 메트릭 확인
kubectl port-forward -n default svc/java-sample-app-svc 7000:7000 &
curl http://localhost:7000/metrics | grep jvm_memory
```

## 📊 메트릭 확인

### JMX 메트릭 예시
```
jvm_memory_used_bytes{area="heap"} 74183104
jvm_memory_used_bytes{area="nonheap"} 125175720
jvm_memory_pool_used_bytes{pool="G1 Eden Space"} 32505856
jvm_memory_pool_used_bytes{pool="G1 Old Gen"} 40395776
process_cpu_seconds_total 12.34
```

### Grafana에서 확인
1. **접속**: https://lgtm-grafana.bluesunnywings.com
2. **Explore** → **Mimir** 선택
3. **쿼리**: `jvm_memory_pool_collection_used_bytes`

## 🔧 설정 정보

### 포트 설정
- **8080**: 애플리케이션 HTTP 포트
- **7000**: JMX Exporter 메트릭 포트

### 볼륨 마운트
- **/app/data**: 애플리케이션 데이터 저장
- **/opt/jmx_exporter**: JMX Exporter JAR 및 설정

### 환경 변수
- **DATA_PATH**: `/app/data` (데이터 저장 경로)

## 🧹 정리 방법

```bash
# 애플리케이션 삭제
kubectl delete -f manifests/storage-test.yaml

# ConfigMap 삭제
kubectl delete -f manifests/jmx-configmap.yaml
```

## 🔗 LGTM 스택 연동

이 샘플 앱은 다음과 자동으로 연동됩니다:

- **Mimir**: JMX 메트릭 자동 수집
- **Loki**: 애플리케이션 로그 자동 수집
- **Tempo**: OpenTelemetry 설정 시 트레이스 수집
- **Grafana**: 통합 대시보드에서 모든 데이터 시각화

자세한 연동 방법은 상위 디렉터리의 `app-integration-guide.md`를 참조하세요.