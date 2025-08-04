#!/bin/bash

echo "🧹 Option 2: 전체 환경 정리 시작..."

# 설정 로드
if [ -f "../thanos-config.env" ]; then
    source ../thanos-config.env
fi

# 1. Sample App 삭제
echo "1/5 ☕ Sample App 삭제..."
kubectl delete -f ../sample-app/storage-test.yaml --ignore-not-found
kubectl delete -f ../sample-app/jmx-configmap.yaml --ignore-not-found

# 2. Thanos Query 삭제
echo "2/5 🎯 Thanos Query 삭제..."
kubectl delete -f ../manifests/thanos-query.yaml --ignore-not-found

# 3. Prometheus + Grafana 삭제
echo "3/5 📦 Prometheus + Grafana 삭제..."
helm uninstall monitoring -n monitoring --ignore-not-found

# 4. Secret 및 네임스페이스 삭제
echo "4/5 🔐 Secret 및 네임스페이스 삭제..."
kubectl delete secret thanos-objstore-config -n monitoring --ignore-not-found
kubectl delete namespace monitoring --ignore-not-found

# 5. S3 버킷 정리
echo "5/5 🪣 S3 버킷 정리..."
if [ -n "$THANOS_BUCKET" ]; then
    echo "발견된 S3 버킷: $THANOS_BUCKET"
    echo "선택 옵션:"
    echo "1) 삭제 (개발/테스트 환경 권장)"
    echo "2) 보존 (운영 환경 권장 - 장기 데이터 유지)"
    read -p "S3 버킷을 삭제하시겠습니까? (1=삭제/2=보존): " choice
    if [[ $choice == "1" ]]; then
        aws s3 rm s3://$THANOS_BUCKET --recursive
        aws s3 rb s3://$THANOS_BUCKET
        echo "✅ S3 버킷 삭제됨"
        rm -f ../thanos-config.env
    else
        echo "✅ S3 버킷 보존됨 - 재배포 시 수동으로 버킷명 설정 필요"
        echo "보존된 버킷: $THANOS_BUCKET"
    fi
else
    echo "S3 버킷 정보를 찾을 수 없습니다."
fi

# 설정 파일 삭제 (버킷 보존 시 제외)
if [[ $choice == "1" ]] || [ -z "$THANOS_BUCKET" ]; then
    rm -f ../thanos-config.env
fi

echo "✅ 전체 정리 완료!"
echo ""
echo "📋 삭제된 구성 요소:"
echo "- Sample App (Java + JMX)"
echo "- Prometheus + Thanos Sidecar"
echo "- Grafana"
echo "- Thanos Query"
echo "- monitoring 네임스페이스"
echo "- Thanos 설정 Secret"
if [ -n "$THANOS_BUCKET" ]; then
    echo "- S3 버킷: $THANOS_BUCKET (사용자 선택에 따라)"
fi
echo ""
echo "🔍 정리 확인:"
echo "1. 남은 파드: kubectl get pods -A"
echo "2. 남은 서비스: kubectl get svc -A"
echo "3. PVC 확인: kubectl get pvc -A"
echo "4. S3 버킷: aws s3 ls | grep thanos-metrics"
echo ""
echo "⚠️ 참고사항:"
echo "- PVC는 자동 삭제되지 않으므로 필요시 수동 삭제"
echo "- S3 버킷은 사용자 선택에 따라 보존될 수 있음"