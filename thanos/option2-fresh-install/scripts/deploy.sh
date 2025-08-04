#!/bin/bash

echo "🚀 Option 2: 처음부터 Thanos 포함 설치 시작..."

# 1. S3 버킷 생성
echo "1/6 🪣 S3 버킷 생성..."
BUCKET_NAME="thanos-metrics-$(date +%s)"
aws s3 mb s3://$BUCKET_NAME --region ap-northeast-2
echo "S3 버킷 생성됨: $BUCKET_NAME"

# 2. 네임스페이스 생성
echo "2/6 🏗️ 네임스페이스 생성..."
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# 3. Prometheus Operator 설치 (Thanos 지원)
echo "3/6 📦 Prometheus Operator 설치..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# S3 설정 Secret 생성
kubectl create secret generic thanos-objstore-config -n monitoring --from-literal=objstore.yml="
type: s3
config:
  bucket: $BUCKET_NAME
  region: ap-northeast-2
  endpoint: s3.ap-northeast-2.amazonaws.com
" --dry-run=client -o yaml | kubectl apply -f -

# Prometheus + Grafana + Thanos 통합 설치
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values ../manifests/prometheus-values.yaml \
  --timeout 15m \
  --wait

kubectl apply -f ../manifests/monitoring-ingress-single.yaml

echo "✅ Prometheus + Grafana + Thanos Sidecar 설치 완료"

# 4. Thanos Query 설치
echo "4/6 🎯 Thanos Query 설치..."
kubectl apply -f ../manifests/thanos-query.yaml

# 5. Sample App 배포
echo "5/6 ☕ Sample App 배포..."
kubectl apply -f ../sample-app/jmx-configmap.yaml
kubectl apply -f ../sample-app/storage-test.yaml
kubectl apply -f ../sample-app/servicemonitor.yaml

# 6. Grafana 데이터 소스 설정 적용
echo "6/6 📊 Grafana 데이터 소스 설정..."
sleep 30  # Grafana 시작 대기

# Grafana 데이터 소스 ConfigMap 직접 적용
#kubectl apply -f ../manifests/grafana-datasource.yaml

# Grafana 재시작
#kubectl rollout restart deployment monitoring-grafana -n monitoring

# 설정 저장
echo "THANOS_BUCKET=$BUCKET_NAME" > ../thanos-config.env

echo "✅ 전체 설치 완료!"
echo ""
echo "📋 설치된 구성 요소:"
echo "- Sample App (Java + JMX)"
echo "- Prometheus (Thanos Sidecar 포함)"
echo "- Grafana (Thanos Query 연동)"
echo "- Thanos Query"
echo "- S3 장기 저장소: $BUCKET_NAME"
echo ""
echo "🌐 접속 정보:"
echo "1. 웹 브라우저 (권장):"
echo "   - Grafana: https://grafana.bluesunnywings.com"
echo "   - Prometheus: https://prometheus.bluesunnywings.com"
echo "   - Sample App: https://www.bluesunnywings.com"
echo ""
echo "2. 로컬 테스트:"
echo "   - kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80"
echo "   - 로그인: admin / admin123!"
echo ""
echo "📈 Thanos 대시보드 추가:"
echo "- Grafana → Import → Dashboard ID: 12937 (Thanos Overview)"
echo "- Dashboard ID: 12936 (Thanos Query), 12938 (Thanos Compact)"
echo ""
echo "🔍 연동 확인:"
echo "1. 구성 요소: kubectl get pods -n monitoring | grep thanos"
echo "2. 서비스: kubectl get svc -n monitoring | grep thanos"
echo "3. Grafana에서 'up' 메트릭 쿼리 테스트"
echo "4. S3 버킷: aws s3 ls | grep thanos-metrics"
echo ""
echo "⚠️ 참고사항:"
echo "- Thanos의 장기 저장 효과는 며칠 후부터 확인 가능"
echo "- 15일 후부터 기존 Prometheus와 차이 명확해짐"