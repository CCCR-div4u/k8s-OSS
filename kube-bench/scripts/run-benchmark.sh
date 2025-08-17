#!/bin/bash

# Kube-bench 벤치마크 실행 스크립트
# 이 스크립트는 EKS 클러스터에서 CIS 벤치마크를 실행합니다.

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로깅 함수
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

# 사용법 출력
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -t, --target    Target to benchmark (eks|master|node|all) [default: eks]"
    echo "  -n, --namespace Kubernetes namespace [default: default]"
    echo "  -o, --output    Output directory [default: ../results]"
    echo "  -c, --cleanup   Cleanup jobs after completion [default: false]"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -t eks                    # Run EKS benchmark"
    echo "  $0 -t all -c                # Run all benchmarks and cleanup"
    echo "  $0 -t master -n kube-system # Run master benchmark in kube-system namespace"
}

# 기본값 설정
TARGET="eks"
NAMESPACE="default"
OUTPUT_DIR="../results"
CLEANUP=false

# 명령행 인수 파싱
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--target)
            TARGET="$2"
            shift 2
            ;;
        -n|--namespace)
            NAMESPACE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -c|--cleanup)
            CLEANUP=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# 출력 디렉터리 생성
mkdir -p "$OUTPUT_DIR"

# kubectl 명령어 확인
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl command not found. Please install kubectl."
    exit 1
fi

# 클러스터 연결 확인
if ! kubectl cluster-info &> /dev/null; then
    log_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

# Job 실행 함수
run_job() {
    local job_type=$1
    local job_file="../installation/job-${job_type}.yaml"
    local job_name="kube-bench-${job_type}"
    
    log_info "Running ${job_type} benchmark..."
    
    # 기존 Job 정리
    kubectl delete job "$job_name" -n "$NAMESPACE" --ignore-not-found=true
    
    # Job 실행
    if [[ -f "$job_file" ]]; then
        # 네임스페이스 설정
        sed "s/namespace: default/namespace: $NAMESPACE/g" "$job_file" | kubectl apply -f -
        
        # Job 완료 대기
        log_info "Waiting for ${job_type} benchmark to complete..."
        kubectl wait --for=condition=complete job/"$job_name" -n "$NAMESPACE" --timeout=300s
        
        # 결과 수집
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        local output_file="${OUTPUT_DIR}/kube-bench-${job_type}-${timestamp}.log"
        
        kubectl logs job/"$job_name" -n "$NAMESPACE" > "$output_file"
        log_success "${job_type} benchmark completed. Results saved to: $output_file"
        
        # JSON 형식으로도 저장
        local json_output="${OUTPUT_DIR}/kube-bench-${job_type}-${timestamp}.json"
        kubectl logs job/"$job_name" -n "$NAMESPACE" | grep -E '^\{.*\}$' > "$json_output" 2>/dev/null || true
        
        if [[ -s "$json_output" ]]; then
            log_success "JSON results saved to: $json_output"
        else
            rm -f "$json_output"
        fi
        
        # 정리
        if [[ "$CLEANUP" == "true" ]]; then
            kubectl delete job "$job_name" -n "$NAMESPACE"
            log_info "Cleaned up ${job_type} job"
        fi
        
    else
        log_error "Job file not found: $job_file"
        return 1
    fi
}

# 메인 실행 로직
main() {
    log_info "Starting Kube-bench security benchmark"
    log_info "Target: $TARGET"
    log_info "Namespace: $NAMESPACE"
    log_info "Output Directory: $OUTPUT_DIR"
    
    case $TARGET in
        eks)
            run_job "eks"
            ;;
        master)
            run_job "master"
            ;;
        node)
            run_job "node"
            ;;
        all)
            log_info "Running all benchmarks..."
            run_job "eks"
            run_job "master" 
            run_job "node"
            ;;
        *)
            log_error "Invalid target: $TARGET. Valid options: eks, master, node, all"
            exit 1
            ;;
    esac
    
    log_success "Kube-bench benchmark completed successfully!"
    log_info "Results are available in: $OUTPUT_DIR"
    
    # 결과 요약 출력
    echo ""
    log_info "=== BENCHMARK SUMMARY ==="
    for file in "$OUTPUT_DIR"/kube-bench-*.log; do
        if [[ -f "$file" ]]; then
            local basename=$(basename "$file")
            local pass_count=$(grep -c "\[PASS\]" "$file" 2>/dev/null || echo "0")
            local fail_count=$(grep -c "\[FAIL\]" "$file" 2>/dev/null || echo "0")
            local warn_count=$(grep -c "\[WARN\]" "$file" 2>/dev/null || echo "0")
            
            echo "📄 $basename:"
            echo "  ✅ PASS: $pass_count"
            echo "  ❌ FAIL: $fail_count"
            echo "  ⚠️  WARN: $warn_count"
        fi
    done
}

# 스크립트 실행
main