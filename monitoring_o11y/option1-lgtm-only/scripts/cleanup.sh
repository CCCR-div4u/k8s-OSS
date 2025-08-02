#!/bin/bash

echo "🧹 LGTM Stack 정리 시작..."
echo ""
echo "📋 정리 순서:"
echo "1. Ingress 삭제 (ALB 정리)"
echo "2. ServiceMonitor 삭제 (메트릭 수집 설정)"
echo "3. Grafana 데이터 소스 설정 삭제"
echo "4. Prometheus Agent 삭제 (메트릭 수집기)"
echo "5. 시스템 메트릭 삭제 (Node Exporter, Kube State Metrics)"
echo "6. LGTM Stack 삭제 (Mimir, Loki, Tempo, Grafana)"
echo "7. PVC 삭제 (데이터 완전 삭제)"
echo "8. 네임스페이스 삭제"
echo ""

# Ingress 삭제
echo "1/8 🔗 Ingress 삭제 중..."
kubectl delete -f ../manifests/ingress.yaml --ignore-not-found=true

# ServiceMonitor 삭제
echo "2/8 📊 ServiceMonitor 삭제 중..."
kubectl delete -f ../manifests/servicemonitor.yaml --ignore-not-found=true
kubectl delete -f ../manifests/system-servicemonitors.yaml --ignore-not-found=true

# Grafana 데이터 소스 설정 삭제
echo "3/8 📊 Grafana 데이터 소스 설정 삭제 중..."
kubectl delete -f ../manifests/grafana-datasource.yaml --ignore-not-found=true

# Prometheus Agent 삭제
echo "4/8 📦 Prometheus Agent 삭제 중..."
helm uninstall prometheus-agent -n lgtm-stack --ignore-not-found

# 시스템 메트릭 Helm 릴리스 삭제
echo "5/8 📦 시스템 메트릭 삭제 중..."
helm uninstall node-exporter -n lgtm-stack --ignore-not-found
helm uninstall kube-state-metrics -n lgtm-stack --ignore-not-found

# LGTM Stack Helm 릴리스 삭제
echo "6/8 📦 LGTM Stack 삭제 중..."
helm uninstall lgtm -n lgtm-stack --ignore-not-found

# PVC 삭제 (데이터 완전 삭제)
echo "7/8 💾 PVC 삭제 중 (데이터 완전 삭제)..."
kubectl delete pvc -n lgtm-stack --all --ignore-not-found=true

# 네임스페이스 삭제
echo "8/8 🏗️ 네임스페이스 삭제 중..."
kubectl delete namespace lgtm-stack --ignore-not-found=true

# 정리 완료 확인
echo ""
echo "🔍 정리 상태 확인 중..."
echo ""

# 네임스페이스 확인
if kubectl get namespace lgtm-stack >/dev/null 2>&1; then
    echo "⚠️ 네임스페이스가 아직 삭제 중입니다..."
    echo "완전 삭제까지 1-2분 소요될 수 있습니다."
else
    echo "✅ 네임스페이스 삭제 완료"
fi

# Helm 릴리스 확인
if helm list -A | grep -q lgtm; then
    echo "⚠️ Helm 릴리스가 아직 남아있습니다"
    echo "남은 릴리스:"
    helm list -A | grep lgtm
else
    echo "✅ 모든 Helm 릴리스 삭제 완료"
fi

# Prometheus Operator CRD 확인
echo ""
echo "📋 Prometheus Operator CRD 상태:"
if kubectl get crd servicemonitors.monitoring.coreos.com >/dev/null 2>&1; then
    echo "ℹ️ ServiceMonitor CRD가 남아있습니다 (다른 Prometheus 설치에서 사용 중일 수 있음)"
else
    echo "✅ ServiceMonitor CRD 없음"
fi

# ALB 확인 (수동 확인 필요)
echo ""
echo "📋 수동 확인 필요:"
echo "1. AWS 콘솔에서 ALB가 삭제되었는지 확인"
echo "2. Route53에서 DNS 레코드가 정리되었는지 확인"
echo "3. EBS 볼륨이 삭제되었는지 확인"
echo ""

echo "✅ LGTM Stack 정리 완료!"
echo ""
echo "📝 참고사항:"
echo "- ALB 삭제까지 2-3분 소요될 수 있습니다"
echo "- PVC 삭제로 모든 메트릭/로그 데이터가 영구 삭제됩니다"
echo "- Terraform destroy 전에 이 스크립트를 실행해야 합니다"
echo "- ServiceMonitor CRD는 다른 Prometheus 설치에서 사용할 수 있어 보존됩니다"
echo ""
echo "🔍 최종 확인 명령어:"
echo "kubectl get namespace lgtm-stack"
echo "helm list -A | grep lgtm"
echo "kubectl get pods -A | grep -E '(prometheus|grafana|loki|tempo|mimir)'"