#!/bin/bash

echo "🚀 Thanos 간단 배포 시작..."

# 1. S3 버킷 생성
echo "1/4 🪣 S3 버킷 생성..."
BUCKET_NAME="thanos-metrics-$(date +%s)"
aws s3 mb s3://$BUCKET_NAME --region ap-northeast-2
echo "S3 버킷 생성됨: $BUCKET_NAME"

# 2. S3 설정 Secret 생성
echo "2/4 🔐 S3 설정 생성..."
kubectl create secret generic thanos-objstore-config -n monitoring --from-literal=objstore.yml="
type: s3
config:
  bucket: $BUCKET_NAME
  region: ap-northeast-2
  endpoint: s3.ap-northeast-2.amazonaws.com
" --dry-run=client -o yaml | kubectl apply -f -

# 3. Prometheus에 Thanos Sidecar 추가 (YAML 파일 사용)
echo "3/4 🔗 Prometheus에 Thanos Sidecar 추가..."
kubectl apply -f ../manifests/prometheus-with-thanos.yaml

# 4. Thanos Query 배포
echo "4/4 🎯 Thanos Query 배포..."
kubectl apply -f ../manifests/thanos-query-simple.yaml

# 설정 저장
echo "THANOS_BUCKET=$BUCKET_NAME" > ../thanos-config.env

echo "✅ 배포 완료!"
echo ""
echo "📋 다음 단계:"
echo "1. Grafana 데이터 소스를 http://thanos-query:9090 으로 변경"
echo "2. Grafana에서 장기 데이터 쿼리 테스트"
echo ""
echo "🔍 확인: kubectl get pods -n monitoring | grep thanos"