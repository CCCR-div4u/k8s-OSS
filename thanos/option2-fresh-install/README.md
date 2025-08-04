# Option 2: 처음부터 Thanos 포함 설치

새로운 EKS 클러스터에 Sample App + Prometheus + Grafana + Thanos를 통합 설치합니다.

## 🎯 목표
- 처음부터 Thanos가 통합된 환경 구축
- Sample App + 모니터링 스택 일괄 설치
- 장기 메트릭 저장 및 통합 쿼리 제공

## 📋 설치되는 구성 요소
- **Sample App**: Java 애플리케이션 + JMX
- **Prometheus**: Thanos Sidecar 내장
- **Grafana**: Thanos Query 연동
- **Thanos Query**: 통합 쿼리 인터페이스
- **S3 Bucket**: 장기 메트릭 저장소

## 🚀 배포 방법
```bash
cd scripts
./deploy.sh
```

## 📊 확인 방법
```bash
# 전체 파드 확인
kubectl get pods -n monitoring
kubectl get pods -n default

# Grafana 접속
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
# 브라우저: http://localhost:3000
# 로그인: admin / admin123!
```

## 🧹 정리 방법
```bash
./cleanup.sh
```

## ✅ 장점
- 처음부터 통합 설계
- 설정 충돌 없음
- 깔끔한 환경 구성

## 🔧 주요 설정 변경사항

### Grafana 데이터소스 설정
- 기본 Prometheus 데이터소스 비활성화
- Thanos Query를 기본 데이터소스로 설정
- URL: `http://thanos-query:9090`

### Thanos Query 연결
- Prometheus Operated 서비스 연결
- Headless 서비스를 통한 자동 발견
- Store: `prometheus-operated.monitoring.svc.cluster.local:10901`

### S3 설정
- 동적 버킷 생성: `thanos-metrics-[timestamp]`
- 리전: `ap-northeast-2`
- Thanos Sidecar 자동 업로드

## 📈 모니터링 대시보드

### 접속 방법
1. **웹 브라우저 (권장)**:
   - Grafana: `https://grafana.bluesunnywings.com`
   - Prometheus: `https://prometheus.bluesunnywings.com`
   - Sample App: `https://www.bluesunnywings.com`

2. **Port Forward (로컬 테스트)**:
   ```bash
   kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
   ```

### Thanos 전용 대시보드
Grafana → Import → Dashboard ID 입력:
- **Thanos Overview**: `12937`

## 🔍 연동 확인 방법

### 1. 구성 요소 상태 확인
```bash
# Thanos 관련 파드
kubectl get pods -n monitoring | grep thanos

# 서비스 확인
kubectl get svc -n monitoring | grep thanos

# Prometheus Sidecar 로그
kubectl logs -n monitoring prometheus-monitoring-kube-prometheus-prometheus-0 -c thanos-sidecar
```

### 2. Grafana에서 연결 테스트
1. Grafana 접속 → Configuration → Data Sources
2. Thanos-Query 선택 → Test 버튼
3. "Data source is working" 메시지 확인

### 3. 메트릭 쿼리 테스트
Grafana Query 탭에서:
```promql
# 기본 연결 확인
up

# Prometheus 정보
prometheus_build_info

# Thanos 상태
thanos_query_concurrent_selects
```

### 4. S3 저장 확인
```bash
# 생성된 버킷 확인
aws s3 ls | grep thanos-metrics

# 업로드된 데이터 확인 (시간 경과 후)
aws s3 ls s3://thanos-metrics-[timestamp]/ --recursive
```

## 🚨 문제 해결

### Grafana 데이터소스 오류
**증상**: "Only one datasource per organization can be marked as default"
**해결**: prometheus-values.yaml에서 기본 데이터소스 비활성화 설정 확인

### Thanos Query 연결 실패
**증상**: "no such host" 오류
**해결**: thanos-query.yaml에서 올바른 서비스 이름 사용
```yaml
--store=prometheus-operated.monitoring.svc.cluster.local:10901
```

### 메트릭이 보이지 않음
**원인**: 
- Thanos Query 시작 직후 일시적 현상
- 브라우저 캐시 문제
**해결**: 페이지 새로고침 또는 다른 브라우저 사용