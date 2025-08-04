# Thanos 통합 모니터링 시스템

## 📋 개요
Prometheus + Grafana + Thanos를 통합한 장기 메트릭 저장 및 고가용성 모니터링 시스템

## 🔄 Thanos 사용 전후 차이점

### **기존 Prometheus 환경**
- **데이터 보존**: 로컬 스토리지만 (15일)
- **가용성**: 단일 장애점 (Single Point of Failure)
- **확장성**: 수직 확장만 가능
- **비용**: 고성능 스토리지 필요
- **쿼리 범위**: 단일 Prometheus 인스턴스만

### **Thanos 적용 후**
- **데이터 보존**: 로컬 15일 + S3 무제한 장기 저장
- **가용성**: 분산 아키텍처로 고가용성 확보
- **확장성**: 수평 확장 가능 (여러 Prometheus 통합)
- **비용**: S3 저비용 장기 저장 + 다운샘플링
- **쿼리 범위**: 여러 클러스터 통합 쿼리 가능

## 🏗️ 아키텍처 구성

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Prometheus    │    │  Thanos Query   │    │    Grafana      │
│   + Sidecar     │◄───┤   (9090)        │◄───┤   (3000)        │
│   (9090/10901)  │    └─────────────────┘    └─────────────────┘
└─────────┬───────┘              │
          │                      │
          ▼                      ▼
┌─────────────────┐    ┌─────────────────┐
│   S3 Bucket     │    │  Sample App     │
│ (Long-term)     │    │   + JMX         │
└─────────────────┘    └─────────────────┘
```

## 📊 주요 기능

### 1. **장기 데이터 저장**
- Prometheus: 15일 로컬 저장
- Thanos: S3에 무제한 저장
- 자동 다운샘플링으로 비용 최적화

### 2. **통합 쿼리**
- 여러 Prometheus 인스턴스 통합
- 글로벌 뷰 제공
- 중복 제거 (Deduplication)

### 3. **고가용성**
- Sidecar 패턴으로 장애 격리
- 분산 쿼리 엔진
- 자동 복구 기능

## 🚀 설치 옵션

### Option 1: 기존 Prometheus에 Thanos 추가
```bash
cd option1-add-to-existing/scripts
./deploy.sh
```

### Option 2: 처음부터 Thanos 포함 설치 (권장)
```bash
cd option2-fresh-install/scripts
./deploy.sh
```

## 📈 모니터링 대시보드

### Grafana 대시보드 ID
- **Thanos Overview**: 12937
- **Thanos Query**: 12936
- **Thanos Compact**: 12938

### 접속 정보
- **Grafana**: `https://grafana.bluesunnywings.com`
- **Prometheus**: `https://prometheus.bluesunnywings.com`
- **Sample App**: `https://www.bluesunnywings.com`

## 🔍 효과 확인 방법

### 1. **즉시 확인 가능**
```bash
# Thanos 구성 요소 상태
kubectl get pods -n monitoring | grep thanos

# S3 버킷 생성 확인
aws s3 ls | grep thanos-metrics
```

### 2. **시간 경과 후 확인 (며칠 후)**
- Grafana에서 Time Range를 1개월로 설정
- 15일 이전 데이터도 조회 가능
- S3 버킷에 압축된 메트릭 데이터 확인

### 3. **비용 효과 (1개월 후)**
- 다운샘플링된 데이터 확인
- 스토리지 비용 절감 효과
- 쿼리 성능 향상

## 🛠️ 문제 해결

### 일반적인 문제
1. **Grafana 데이터소스 연결 실패**
   - Thanos Query 서비스 상태 확인
   - 네트워크 정책 확인

2. **메트릭이 보이지 않음**
   - Prometheus Sidecar 로그 확인
   - S3 권한 설정 확인

3. **S3 업로드 실패**
   - AWS 자격증명 확인
   - 버킷 권한 설정 확인

## 📚 참고 자료
- [Thanos 공식 문서](https://thanos.io/)
- [Prometheus Operator](https://prometheus-operator.dev/)
- [Grafana 대시보드](https://grafana.com/grafana/dashboards/)