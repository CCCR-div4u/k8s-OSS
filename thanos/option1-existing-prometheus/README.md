# Option 1: 기존 Prometheus에 Thanos 추가

이미 배포된 Sample App + Prometheus + Grafana 환경에 Thanos를 추가합니다.

## 🎯 목표
- 기존 환경을 건드리지 않고 Thanos만 추가
- 장기 메트릭 저장을 위한 S3 연동
- Grafana에서 통합 쿼리 제공

## 🚀 배포 방법
```bash
cd scripts
./deploy.sh
```

## 📊 확인 방법
```bash
# Thanos 파드 확인
kubectl get pods -n monitoring | grep thanos

# Grafana에서 장기 데이터 쿼리
up[30d]  # 30일 전 데이터
```

## 🧹 정리 방법
```bash
./cleanup.sh
```

## ⚠️ 주의사항
- 기존 Prometheus 설정이 변경됩니다
- Grafana 데이터 소스 URL이 변경됩니다
- 정리 시 원본 설정으로 복원됩니다