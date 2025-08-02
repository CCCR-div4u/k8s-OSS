#!/bin/bash

echo "🚀 LGTM Stack 배포 시작..."

# Helm 리포지토리 추가
echo "📦 Helm 리포지토리 추가 중..."
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# 네임스페이스 생성
echo "🏗️ 네임스페이스 생성 중..."
kubectl create namespace lgtm-stack --dry-run=client -o yaml | kubectl apply -f -

# LGTM 스택 설치
echo "⚙️ LGTM 스택 설치 중..."
helm upgrade --install lgtm grafana/lgtm-distributed \
  --namespace lgtm-stack \
  --values ../manifests/lgtm-values.yaml \
  --timeout 10m \
  --wait

# 설치 상태 확인
echo "🔍 설치 상태 확인 중..."
kubectl get pods -n lgtm-stack

# Ingress 생성
echo "🌐 Ingress 생성 중..."
kubectl apply -f ../manifests/ingress.yaml

# Prometheus Operator CRDs 설치
echo "🔧 Prometheus Operator CRDs 설치 중..."
kubectl apply --server-side -f https://raw.githubusercontent.com/prometheus-operator/prometheus-operator/v0.68.0/example/prometheus-operator-crd/monitoring.coreos.com_servicemonitors.yaml

# Node Exporter 설치 (노드 메트릭)
echo "📊 Node Exporter 설치 중..."
helm upgrade --install node-exporter prometheus-community/prometheus-node-exporter \
  --namespace lgtm-stack \
  --timeout 5m

# Kube State Metrics 설치 (Kubernetes 리소스 메트릭)
echo "📊 Kube State Metrics 설치 중..."
helm upgrade --install kube-state-metrics prometheus-community/kube-state-metrics \
  --namespace lgtm-stack \
  --timeout 5m

# 시스템 ServiceMonitor 생성 (노드, Kubernetes 메트릭)
echo "📊 시스템 ServiceMonitor 생성 중..."
kubectl apply -f ../manifests/system-servicemonitors.yaml

# Prometheus Agent 설치 (메트릭 수집용)
echo "🔍 Prometheus Agent 설치 중..."
helm upgrade --install prometheus-agent prometheus-community/kube-prometheus-stack \
  --namespace lgtm-stack \
  --values ../manifests/prometheus-agent-values.yaml \
  --timeout 10m \
  --wait

# 애플리케이션 ServiceMonitor 생성 (JMX 메트릭)
echo "📊 애플리케이션 ServiceMonitor 생성 중..."
kubectl apply -f ../manifests/servicemonitor.yaml

# Grafana 데이터 소스 설정 (Mimir 헤더 포함)
echo "📊 Grafana 데이터 소스 설정 중..."
kubectl apply -f ../manifests/grafana-datasource.yaml
kubectl rollout restart deployment lgtm-grafana -n lgtm-stack

# 서비스 상태 확인
echo "📊 서비스 상태 확인 중..."
kubectl get svc -n lgtm-stack

# Ingress 상태 확인
echo "🔗 Ingress 상태 확인 중..."
kubectl get ingress -n lgtm-stack

# 완료 메시지
echo ""
echo "✅ LGTM Stack 배포 완료!"
echo ""
echo "🌐 접속 URL:"
echo "- Grafana: https://lgtm-grafana.bluesunnywings.com"
echo "- Mimir API: https://lgtm-mimir.bluesunnywings.com"
echo "- Loki API: https://lgtm-loki.bluesunnywings.com"
echo "- Tempo API: https://lgtm-tempo.bluesunnywings.com"
echo ""
echo "🔐 Grafana 로그인 정보:"
echo "- Username: admin"
echo "- Password: admin123!"
echo ""
echo "📝 참고사항:"
echo "- ALB 생성까지 2-3분 소요될 수 있습니다"
echo "- 모든 파드가 Running 상태가 될 때까지 기다려주세요"
echo ""
echo "🔍 상태 확인 명령어:"
echo "kubectl get pods -n lgtm-stack"
echo "kubectl get ingress -n lgtm-stack"