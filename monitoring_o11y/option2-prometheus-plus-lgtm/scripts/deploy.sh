#!/bin/bash

echo "🚀 Prometheus + LGTM 하이브리드 스택 배포 시작..."

# 기존 모니터링 스택 확인
echo "🔍 기존 모니터링 스택 확인 중..."
if ! kubectl get namespace monitoring >/dev/null 2>&1; then
    echo "❌ monitoring 네임스페이스가 존재하지 않습니다."
    echo "먼저 기존 Prometheus 스택을 배포해주세요."
    exit 1
fi

if ! kubectl get deployment -n monitoring prometheus-grafana >/dev/null 2>&1; then
    echo "❌ 기존 Grafana가 실행 중이지 않습니다."
    echo "먼저 기존 Prometheus 스택을 배포해주세요."
    exit 1
fi

echo "✅ 기존 모니터링 스택 확인 완료"

# Helm 리포지토리 추가
echo "📦 Helm 리포지토리 추가 중..."
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Loki 설치
echo "📊 Loki 설치 중..."
helm upgrade --install loki grafana/loki \
  --namespace monitoring \
  --values ../manifests/loki-values.yaml \
  --timeout 10m \
  --wait

# Tempo 설치
echo "🔍 Tempo 설치 중..."
helm upgrade --install tempo grafana/tempo \
  --namespace monitoring \
  --values ../manifests/tempo-values.yaml \
  --timeout 10m \
  --wait

# Promtail 설치
echo "📝 Promtail 설치 중..."
helm upgrade --install promtail grafana/promtail \
  --namespace monitoring \
  --values ../manifests/promtail-values.yaml \
  --timeout 10m \
  --wait

# 설치 상태 확인
echo "🔍 설치 상태 확인 중..."
kubectl get pods -n monitoring | grep -E "(loki|tempo|promtail)"

# Ingress 생성
echo "🌐 Ingress 생성 중..."
kubectl apply -f ../manifests/ingress.yaml

# Grafana 데이터 소스 추가 (ConfigMap 업데이트)
echo "📊 Grafana 데이터 소스 추가 중..."
kubectl apply -f ../manifests/grafana-datasource-patch.yaml

# Grafana 재시작 (데이터 소스 적용)
echo "🔄 Grafana 재시작 중..."
kubectl rollout restart deployment/prometheus-grafana -n monitoring

# 서비스 상태 확인
echo "📊 서비스 상태 확인 중..."
kubectl get svc -n monitoring | grep -E "(loki|tempo|promtail)"

# Ingress 상태 확인
echo "🔗 Ingress 상태 확인 중..."
kubectl get ingress -n monitoring

# 완료 메시지
echo ""
echo "✅ Prometheus + LGTM 하이브리드 스택 배포 완료!"
echo ""
echo "🌐 접속 URL:"
echo "- Grafana (기존): https://grafana.bluesunnywings.com"
echo "- Prometheus (기존): https://prometheus.bluesunnywings.com"
echo "- Loki API (신규): https://loki.bluesunnywings.com"
echo "- Tempo API (신규): https://tempo.bluesunnywings.com"
echo ""
echo "🔐 Grafana 로그인 정보 (기존과 동일):"
echo "- Username: admin"
echo "- Password: \$(kubectl get secret --namespace monitoring prometheus-grafana -o jsonpath=\"{.data.admin-password}\" | base64 --decode)"
echo ""
echo "📊 새로 추가된 데이터 소스:"
echo "- Loki: http://loki:3100"
echo "- Tempo: http://tempo:3100"
echo ""
echo "📝 참고사항:"
echo "- 기존 Prometheus/Grafana는 그대로 유지됩니다"
echo "- Grafana에서 새로운 데이터 소스를 확인해보세요"
echo "- ALB 생성까지 2-3분 소요될 수 있습니다"
echo ""
echo "🔍 상태 확인 명령어:"
echo "kubectl get pods -n monitoring | grep -E \"(loki|tempo|promtail)\""
echo "kubectl get ingress -n monitoring"