#!/bin/bash

echo "🧹 Thanos 정리 시작..."

# 설정 로드
if [ -f "../thanos-config.env" ]; then
    source ../thanos-config.env
fi

# 1. Thanos Query 삭제
echo "1/3 🎯 Thanos Query 삭제..."
kubectl delete -f ../manifests/thanos-query-simple.yaml --ignore-not-found

# 2. Prometheus 원본 설정 복원 (YAML 파일 사용)
echo "2/3 🔗 Prometheus 원본 설정 복원..."
kubectl apply -f ../manifests/prometheus-original.yaml

# 3. Secret 삭제
echo "3/3 🔐 Secret 삭제..."
kubectl delete secret thanos-objstore-config -n monitoring --ignore-not-found

# S3 버킷 정리 (선택)
if [ -n "$THANOS_BUCKET" ]; then
    echo ""
    read -p "S3 버킷($THANOS_BUCKET)을 삭제하시겠습니까? (y/N): " choice
    if [[ $choice =~ ^[Yy]$ ]]; then
        aws s3 rm s3://$THANOS_BUCKET --recursive
        aws s3 rb s3://$THANOS_BUCKET
        echo "S3 버킷 삭제됨"
    fi
fi

# 설정 파일 삭제
rm -f ../thanos-config.env

echo "✅ 정리 완료!"
echo ""
echo "📋 Grafana 데이터 소스를 원래대로 변경하세요:"
echo "http://prometheus-kube-prometheus-prometheus:9090"