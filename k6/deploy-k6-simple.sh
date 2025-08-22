#!/bin/bash

# k6 Operator 간소화된 배포 스크립트
# ACM 인증서와 external-dns를 사용하는 환경용

set -e

# =============================================================================
# 설정 변수 (사용자 수정 필요)
# =============================================================================
CLUSTER_NAME="your-eks-cluster"                    # EKS 클러스터 이름
REGION="ap-northeast-2"                            # AWS 리전
DOMAIN="k6-operator.your-domain.com"               # 도메인 (external-dns가 관리)
ACM_CERT_ARN="arn:aws:acm:ap-northeast-2:YOUR_ACCOUNT_ID:certificate/YOUR_CERTIFICATE_ID"  # ACM 인증서 ARN
NAMESPACE="k6-operator-system"                     # 네임스페이스

# =============================================================================
# 색상 정의
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# 함수 정의
# =============================================================================
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "사전 요구사항 확인 중..."
    
    # kubectl 확인
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl이 설치되지 않았습니다."
        exit 1
    fi
    
    # helm 확인
    if ! command -v helm &> /dev/null; then
        log_error "helm이 설치되지 않았습니다."
        exit 1
    fi
    
    # AWS CLI 확인
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI가 설치되지 않았습니다."
        exit 1
    fi
    
    # 클러스터 연결 확인
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Kubernetes 클러스터에 연결할 수 없습니다."
        exit 1
    fi
    
    log_success "모든 사전 요구사항이 충족되었습니다."
}

update_values_file() {
    log_info "values 파일 업데이트 중..."
    
    # values 파일에서 도메인과 ACM ARN 업데이트
    sed -i.bak "s|k6-operator.your-domain.com|${DOMAIN}|g" k6-operator-values-simple.yaml
    sed -i.bak "s|arn:aws:acm:ap-northeast-2:YOUR_ACCOUNT_ID:certificate/YOUR_CERTIFICATE_ID|${ACM_CERT_ARN}|g" k6-operator-values-simple.yaml
    
    log_success "values 파일이 업데이트되었습니다."
}

deploy_k6_operator() {
    log_info "k6 operator 배포 시작..."
    
    # 네임스페이스 생성
    kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    
    # Helm 저장소 추가
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo update
    
    # k6 operator 설치/업그레이드
    helm upgrade --install k6-operator grafana/k6-operator \
        --namespace ${NAMESPACE} \
        --values k6-operator-values-simple.yaml \
        --wait \
        --timeout 10m
    
    log_success "k6 operator가 성공적으로 배포되었습니다."
}

verify_deployment() {
    log_info "배포 상태 확인 중..."
    
    # Pod 상태 확인
    kubectl get pods -n ${NAMESPACE}
    
    # 서비스 상태 확인
    kubectl get svc -n ${NAMESPACE}
    
    # Ingress 상태 확인
    kubectl get ingress -n ${NAMESPACE}
    
    # ALB 생성 확인
    log_info "ALB 생성 대기 중... (최대 5분)"
    for i in {1..30}; do
        ALB_ADDRESS=$(kubectl get ingress -n ${NAMESPACE} -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
        if [[ -n "$ALB_ADDRESS" ]]; then
            log_success "ALB가 생성되었습니다: ${ALB_ADDRESS}"
            break
        fi
        echo -n "."
        sleep 10
    done
    
    if [[ -z "$ALB_ADDRESS" ]]; then
        log_warning "ALB 생성이 완료되지 않았습니다. 수동으로 확인해주세요."
    fi
}

show_access_info() {
    log_info "접속 정보:"
    echo "=================================="
    echo "도메인: https://${DOMAIN}"
    echo "네임스페이스: ${NAMESPACE}"
    echo "=================================="
    
    log_info "DNS 전파 확인 방법:"
    echo "nslookup ${DOMAIN}"
    echo "curl -I https://${DOMAIN}"
}

# =============================================================================
# 메인 실행
# =============================================================================
main() {
    log_info "k6 Operator 간소화된 배포 시작"
    echo "=================================="
    echo "클러스터: ${CLUSTER_NAME}"
    echo "리전: ${REGION}"
    echo "도메인: ${DOMAIN}"
    echo "네임스페이스: ${NAMESPACE}"
    echo "=================================="
    
    check_prerequisites
    update_values_file
    deploy_k6_operator
    verify_deployment
    show_access_info
    
    log_success "k6 Operator 배포가 완료되었습니다!"
}

# 스크립트 실행
main "$@"
