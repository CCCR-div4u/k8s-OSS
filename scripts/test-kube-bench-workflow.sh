#!/bin/bash

# 🔒 Kube-bench 워크플로우 테스트 스크립트
# 이 스크립트는 로컬에서 kube-bench 워크플로우를 테스트하기 위한 도구입니다.

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
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

# 도움말 표시
show_help() {
    cat << EOF
🔒 Kube-bench 워크플로우 테스트 스크립트

사용법: $0 [옵션]

옵션:
    -c, --cluster CLUSTER_NAME    테스트할 EKS 클러스터 이름 (기본값: default-cluster)
    -r, --region REGION          AWS 리전 (기본값: ap-northeast-2)
    -d, --dry-run               실제 실행 없이 설정만 확인
    -h, --help                  이 도움말 표시

예시:
    $0 -c my-eks-cluster -r us-west-2
    $0 --dry-run
    $0 --help

EOF
}

# 기본값 설정
CLUSTER_NAME="default-cluster"
AWS_REGION="ap-northeast-2"
DRY_RUN=false

# 명령행 인수 파싱
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--cluster)
            CLUSTER_NAME="$2"
            shift 2
            ;;
        -r|--region)
            AWS_REGION="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "알 수 없는 옵션: $1"
            show_help
            exit 1
            ;;
    esac
done

log_info "🔒 Kube-bench 워크플로우 테스트 시작"
log_info "클러스터: $CLUSTER_NAME"
log_info "리전: $AWS_REGION"
log_info "드라이런: $DRY_RUN"

# 필수 도구 확인
check_prerequisites() {
    log_info "📋 필수 도구 확인 중..."
    
    local missing_tools=()
    
    if ! command -v aws &> /dev/null; then
        missing_tools+=("aws-cli")
    fi
    
    if ! command -v kubectl &> /dev/null; then
        missing_tools+=("kubectl")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_tools+=("jq")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "다음 도구들이 설치되어 있지 않습니다: ${missing_tools[*]}"
        log_error "필수 도구를 설치한 후 다시 시도해주세요."
        exit 1
    fi
    
    log_success "모든 필수 도구가 설치되어 있습니다."
}

# AWS 인증 확인
check_aws_auth() {
    log_info "🔐 AWS 인증 확인 중..."
    
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS 인증에 실패했습니다."
        log_error "AWS credentials를 설정해주세요."
        exit 1
    fi
    
    local caller_identity=$(aws sts get-caller-identity)
    local account_id=$(echo "$caller_identity" | jq -r '.Account')
    local user_arn=$(echo "$caller_identity" | jq -r '.Arn')
    
    log_success "AWS 인증 성공"
    log_info "계정 ID: $account_id"
    log_info "사용자 ARN: $user_arn"
}

# EKS 클러스터 확인
check_eks_cluster() {
    log_info "🏗️ EKS 클러스터 확인 중..."
    
    if ! aws eks describe-cluster --region "$AWS_REGION" --name "$CLUSTER_NAME" &> /dev/null; then
        log_error "EKS 클러스터 '$CLUSTER_NAME'을 찾을 수 없습니다."
        log_error "클러스터 이름과 리전을 확인해주세요."
        
        log_info "사용 가능한 클러스터 목록:"
        aws eks list-clusters --region "$AWS_REGION" --query 'clusters[]' --output table
        exit 1
    fi
    
    log_success "EKS 클러스터 '$CLUSTER_NAME' 확인됨"
    
    # kubeconfig 업데이트
    log_info "kubeconfig 업데이트 중..."
    aws eks update-kubeconfig --region "$AWS_REGION" --name "$CLUSTER_NAME"
    
    # 클러스터 연결 테스트
    if kubectl cluster-info &> /dev/null; then
        log_success "클러스터 연결 성공"
    else
        log_error "클러스터 연결에 실패했습니다."
        exit 1
    fi
}

# kube-bench 테스트 실행
run_kube_bench_test() {
    if [ "$DRY_RUN" = true ]; then
        log_info "🧪 드라이런 모드: 실제 kube-bench는 실행하지 않습니다."
        return 0
    fi
    
    log_info "🔍 kube-bench 테스트 실행 중..."
    
    # 임시 Job 매니페스트 생성
    local job_manifest="/tmp/kube-bench-test-job.yaml"
    
    cat > "$job_manifest" << 'EOF'
apiVersion: batch/v1
kind: Job
metadata:
  name: kube-bench-test
  namespace: default
spec:
  template:
    spec:
      hostPID: true
      nodeSelector:
        kubernetes.io/os: linux
      tolerations:
      - key: node-role.kubernetes.io/master
        operator: Exists
        effect: NoSchedule
      containers:
      - name: kube-bench
        image: aquasec/kube-bench:latest
        command: ["kube-bench"]
        args: ["--benchmark", "eks-1.0.1", "--json"]
        volumeMounts:
        - name: var-lib-etcd
          mountPath: /var/lib/etcd
          readOnly: true
        - name: var-lib-kubelet
          mountPath: /var/lib/kubelet
          readOnly: true
        - name: etc-kubernetes
          mountPath: /etc/kubernetes
          readOnly: true
        - name: usr-bin
          mountPath: /usr/local/mount-from-host/bin
          readOnly: true
      restartPolicy: Never
      volumes:
      - name: var-lib-etcd
        hostPath:
          path: "/var/lib/etcd"
      - name: var-lib-kubelet
        hostPath:
          path: "/var/lib/kubelet"
      - name: etc-kubernetes
        hostPath:
          path: "/etc/kubernetes"
      - name: usr-bin
        hostPath:
          path: "/usr/bin"
  backoffLimit: 2
EOF
    
    # 기존 테스트 Job 정리
    kubectl delete job kube-bench-test --ignore-not-found=true
    
    # Job 실행
    kubectl apply -f "$job_manifest"
    
    # Job 완료 대기
    log_info "⏳ kube-bench 실행 완료 대기 중... (최대 5분)"
    if kubectl wait --for=condition=complete --timeout=300s job/kube-bench-test; then
        log_success "kube-bench 실행 완료"
        
        # 결과 출력
        log_info "📊 검사 결과:"
        kubectl logs job/kube-bench-test | head -20
        
        # 결과를 파일로 저장
        local results_file="/tmp/kube-bench-test-results.json"
        kubectl logs job/kube-bench-test > "$results_file"
        log_info "결과가 $results_file에 저장되었습니다."
        
    else
        log_error "kube-bench 실행이 시간 초과되었습니다."
        kubectl logs job/kube-bench-test
    fi
    
    # 정리
    kubectl delete job kube-bench-test
    rm -f "$job_manifest"
}

# GitHub Actions 시뮬레이션
simulate_github_actions() {
    log_info "🤖 GitHub Actions 워크플로우 시뮬레이션"
    
    # 환경 변수 설정
    export CLUSTER_NAME="$CLUSTER_NAME"
    export AWS_REGION="$AWS_REGION"
    export GITHUB_REPOSITORY="test/k8s-OSS"
    export GITHUB_RUN_NUMBER="123"
    
    log_info "환경 변수:"
    log_info "  CLUSTER_NAME=$CLUSTER_NAME"
    log_info "  AWS_REGION=$AWS_REGION"
    log_info "  GITHUB_REPOSITORY=$GITHUB_REPOSITORY"
    
    if [ "$DRY_RUN" = true ]; then
        log_info "드라이런 모드: GitHub Actions 시뮬레이션을 건너뜁니다."
        return 0
    fi
    
    # 결과 분석 시뮬레이션
    log_info "📊 결과 분석 시뮬레이션..."
    
    python3 << 'EOF'
import json
import os
from datetime import datetime

# 시뮬레이션 데이터 생성
simulation_data = {
    "summary": {
        "timestamp": datetime.now().strftime("%Y%m%d_%H%M%S"),
        "cluster_name": os.environ.get('CLUSTER_NAME', 'test-cluster'),
        "total_tests": 50,
        "passed_tests": 35,
        "failed_tests": 10,
        "warnings": 5,
        "pass_rate": 70.0,
        "critical_count": 2,
        "high_count": 3,
        "medium_count": 3,
        "low_count": 2
    },
    "critical_issues": [
        {
            "test_desc": "Ensure that the API server pod specification file permissions are set to 644 or more restrictive",
            "test_number": "1.1.1",
            "test_result": "FAIL",
            "remediation": "Run the below command (based on the file location on your system) on the master node. chmod 644 /etc/kubernetes/manifests/kube-apiserver.yaml"
        }
    ]
}

# 시뮬레이션 결과 저장
with open('/tmp/kube-bench-simulation.json', 'w') as f:
    json.dump(simulation_data, f, indent=2)

print("✅ 시뮬레이션 데이터 생성 완료")
print(f"총 테스트: {simulation_data['summary']['total_tests']}")
print(f"통과율: {simulation_data['summary']['pass_rate']}%")
print(f"Critical 이슈: {simulation_data['summary']['critical_count']}")
EOF
    
    log_success "GitHub Actions 시뮬레이션 완료"
}

# 메인 실행 함수
main() {
    check_prerequisites
    check_aws_auth
    check_eks_cluster
    run_kube_bench_test
    simulate_github_actions
    
    log_success "🎉 모든 테스트가 완료되었습니다!"
    
    if [ "$DRY_RUN" = false ]; then
        log_info "📋 다음 단계:"
        log_info "1. GitHub Secrets 설정 확인"
        log_info "2. Slack 웹훅 URL 설정 (선택사항)"
        log_info "3. GitHub Actions 워크플로우 활성화"
        log_info "4. 수동으로 워크플로우 실행하여 테스트"
    fi
}

# 스크립트 실행
main "$@"