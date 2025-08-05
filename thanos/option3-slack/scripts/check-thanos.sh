#!/bin/bash

echo "🔍 Thanos 연동 상태 확인..."
echo ""

# 설정 로드
if [ -f "../thanos-config.env" ]; then
    source ../thanos-config.env
    echo "📋 S3 버킷: $THANOS_BUCKET"
else
    echo "⚠️ 설정 파일을 찾을 수 없습니다."
fi

echo ""

# 1. 파드 상태 확인
echo "1. 📦 파드 상태 확인"
echo "Thanos 관련 파드:"
kubectl get pods -n monitoring | grep -E "(thanos|prometheus)" || echo "파드를 찾을 수 없습니다."

echo ""

# 2. Thanos Sidecar 로그 확인
echo "2. 📝 Thanos Sidecar 로그 확인 (최근 10줄)"
kubectl logs -n monitoring prometheus-prometheus-kube-prometheus-prometheus-0 -c thanos-sidecar --tail=10 2>/dev/null || echo "Sidecar 로그를 가져올 수 없습니다."

echo ""

# 3. S3 업로드 확인
echo "3. 🪣 S3 버킷 확인"
if [ -n "$THANOS_BUCKET" ]; then
    BLOCK_COUNT=$(aws s3 ls s3://$THANOS_BUCKET/ --recursive | wc -l)
    if [ $BLOCK_COUNT -gt 0 ]; then
        echo "✅ S3에 $BLOCK_COUNT 개의 파일이 업로드됨"
        echo "최근 업로드된 파일:"
        aws s3 ls s3://$THANOS_BUCKET/ --recursive | tail -3
    else
        echo "⚠️ S3 버킷이 비어있습니다. (업로드 대기 중일 수 있음)"
    fi
else
    echo "⚠️ S3 버킷 정보가 없습니다."
fi

echo ""

# 4. Thanos Query 상태 확인
echo "4. 🎯 Thanos Query 상태 확인"
QUERY_POD=$(kubectl get pods -n monitoring -l app=thanos-query -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -n "$QUERY_POD" ]; then
    echo "✅ Thanos Query 파드: $QUERY_POD"
    kubectl get pod -n monitoring $QUERY_POD | grep -v NAME
else
    echo "❌ Thanos Query 파드를 찾을 수 없습니다."
fi

echo ""

# 5. 서비스 상태 확인
echo "5. 🌐 서비스 상태 확인"
kubectl get svc -n monitoring | grep -E "(thanos|prometheus|grafana)" || echo "서비스를 찾을 수 없습니다."

echo ""

# 6. 간단한 연결 테스트
echo "6. 🔗 연결 테스트"
echo "Thanos Query API 테스트 중..."
kubectl port-forward -n monitoring svc/thanos-query 9090:9090 >/dev/null 2>&1 &
PF_PID=$!
sleep 3

if curl -s "http://localhost:9090/api/v1/query?query=up" | grep -q "success"; then
    echo "✅ Thanos Query API 정상 응답"
else
    echo "❌ Thanos Query API 응답 없음"
fi

kill $PF_PID 2>/dev/null

echo ""
echo "🎯 종합 결과:"
echo "- 파드가 Running 상태이고"
echo "- Sidecar 로그에 'upload' 메시지가 있고"
echo "- S3에 파일이 업로드되고"
echo "- Thanos Query가 응답하면"
echo "✅ Thanos 연동이 성공적으로 완료된 것입니다!"
echo ""
echo "📊 Grafana 접속: kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"