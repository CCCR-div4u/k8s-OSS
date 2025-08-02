#!/bin/bash

echo "🧹 Prometheus + LGTM 하이브리드 스택 정리 시작..."

# Ingress 삭제
echo "🔗 Ingress 삭제 중..."
kubectl delete -f ../manifests/ingress.yaml --ignore-not-found=true

# Promtail 삭제
echo "📝 Promtail 삭제 중..."
helm uninstall promtail -n monitoring --ignore-not-found

# Tempo 삭제
echo "🔍 Tempo 삭제 중..."
helm uninstall tempo -n monitoring --ignore-not-found

# Loki 삭제
echo "📊 Loki 삭제 중..."
helm uninstall loki -n monitoring --ignore-not-found

# 새로 생성된 PVC 삭제
echo "💾 새로 생성된 PVC 삭제 중..."
kubectl delete pvc -n monitoring -l app.kubernetes.io/part-of=lgtm-hybrid --ignore-not-found=true
kubectl delete pvc -n monitoring storage-loki-0 --ignore-not-found=true
kubectl delete pvc -n monitoring storage-tempo-0 --ignore-not-found=true

# Grafana 데이터 소스 원복 (기존 Prometheus만 남김)
echo "📊 Grafana 데이터 소스 원복 중..."
kubectl patch configmap prometheus-grafana -n monitoring --type merge -p '{
  "data": {
    "datasources.yaml": "apiVersion: 1\ndatasources:\n- name: Prometheus\n  type: prometheus\n  url: http://prometheus-kube-prometheus-prometheus:9090\n  isDefault: true"
  }
}' --ignore-not-found=true

# Grafana 재시작 (데이터 소스 적용)
echo "🔄 Grafana 재시작 중..."
kubectl rollout restart deployment/prometheus-grafana -n monitoring --ignore-not-found=true

# 정리 완료 확인
echo "🔍 정리 상태 확인 중..."
echo ""

# Helm 릴리스 확인
echo "📦 삭제된 Helm 릴리스 확인:"
if helm list -n monitoring | grep -E "(loki|tempo|promtail)"; then
    echo "⚠️ 일부 Helm 릴리스가 아직 남아있습니다"
else
    echo "✅ 모든 LGTM 관련 Helm 릴리스 삭제 완료"
fi

# 파드 확인
echo ""
echo "🔍 남은 파드 확인:"
remaining_pods=$(kubectl get pods -n monitoring | grep -E "(loki|tempo|promtail)" | wc -l)
if [ "$remaining_pods" -gt 0 ]; then
    echo "⚠️ LGTM 관련 파드가 아직 $remaining_pods 개 남아있습니다"
    kubectl get pods -n monitoring | grep -E "(loki|tempo|promtail)"
else
    echo "✅ 모든 LGTM 관련 파드 삭제 완료"
fi

# 기존 모니터링 스택 확인
echo ""
echo "🔍 기존 모니터링 스택 상태:"
if kubectl get deployment -n monitoring prometheus-grafana >/dev/null 2>&1; then
    echo "✅ 기존 Grafana 정상 유지"
else
    echo "⚠️ 기존 Grafana 상태 확인 필요"
fi

if kubectl get deployment -n monitoring prometheus-kube-prometheus-prometheus >/dev/null 2>&1; then
    echo "✅ 기존 Prometheus 정상 유지"
else
    echo "⚠️ 기존 Prometheus 상태 확인 필요"
fi

echo ""
echo "✅ Prometheus + LGTM 하이브리드 스택 정리 완료!"
echo ""
echo "📝 참고사항:"
echo "- 기존 Prometheus/Grafana는 그대로 유지됩니다"
echo "- 새로 추가된 LGTM 구성 요소만 삭제되었습니다"
echo "- ALB 삭제까지 2-3분 소요될 수 있습니다"
echo "- Terraform destroy 전에 이 스크립트를 실행해야 합니다"
echo ""
echo "🔍 최종 확인 명령어:"
echo "kubectl get pods -n monitoring"
echo "helm list -n monitoring"
echo "kubectl get pvc -n monitoring"