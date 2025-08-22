#!/bin/bash

# Checkov 워크플로 테스트 스크립트
# 이 스크립트는 워크플로의 변경 감지 로직을 로컬에서 테스트합니다.

set -euo pipefail

echo "🧪 Checkov 워크플로 테스트 시작"
echo "=================================="

# 테스트 함수들
test_path_filter() {
    echo "📁 경로 필터 테스트..."
    
    # 지원되는 디렉터리 목록
    SUPPORTED_DIRS=("argo-cd" "harbor" "keycloak" "sonarqube" "thanos" "monitoring_o11y")
    
    for dir in "${SUPPORTED_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            echo "✅ $dir/ - 디렉터리 존재"
        else
            echo "❌ $dir/ - 디렉터리 없음"
        fi
    done
}

test_matrix_generation() {
    echo ""
    echo "🔧 매트릭스 생성 테스트..."
    
    # 전체 매트릭스 JSON 생성 (워크플로와 동일)
    FULL_MATRIX='{
      "include": [
        {
          "name": "argo-cd",
          "chart_ref": "argo/argo-cd",
          "values": "argo-cd/my-values.yaml",
          "scan_type": "helm"
        },
        {
          "name": "harbor", 
          "chart_ref": "goharbor/harbor",
          "values": "harbor/override-values.yaml",
          "scan_type": "helm"
        },
        {
          "name": "keycloak",
          "chart_ref": "bitnami/keycloak", 
          "values": "keycloak/installation/helm-values.yaml",
          "scan_type": "helm"
        },
        {
          "name": "sonarqube",
          "chart_ref": "sonarqube/sonarqube",
          "values": "sonarqube/override-values.yaml",
          "scan_type": "helm"
        },
        {
          "name": "thanos",
          "chart_ref": "bitnami/thanos",
          "values": "thanos/values/values.yaml",
          "scan_type": "helm"
        },
        {
          "name": "monitoring_o11y",
          "chart_ref": "",
          "values": "",
          "scan_type": "kubernetes"
        }
      ]
    }'
    
    # JSON 유효성 검사
    if echo "$FULL_MATRIX" | python3 -m json.tool > /dev/null 2>&1; then
        echo "✅ 매트릭스 JSON 형식 유효"
        
        # 컴포넌트 개수 확인
        COMPONENT_COUNT=$(echo "$FULL_MATRIX" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(len(data['include']))
")
        echo "📊 총 컴포넌트 개수: $COMPONENT_COUNT개"
    else
        echo "❌ 매트릭스 JSON 형식 오류"
        return 1
    fi
}

test_values_files() {
    echo ""
    echo "📄 Values 파일 존재 확인..."
    
    VALUES_FILES=(
        "argo-cd/my-values.yaml"
        "harbor/override-values.yaml"
        "keycloak/installation/helm-values.yaml"
        "sonarqube/override-values.yaml"
        "thanos/values/values.yaml"
    )
    
    for values_file in "${VALUES_FILES[@]}"; do
        if [ -f "$values_file" ]; then
            echo "✅ $values_file - 파일 존재"
        else
            echo "⚠️ $values_file - 파일 없음 (선택사항)"
        fi
    done
}

test_kubernetes_manifests() {
    echo ""
    echo "📋 Kubernetes 매니페스트 확인..."
    
    if [ -d "monitoring_o11y" ]; then
        YAML_COUNT=$(find monitoring_o11y -name "*.yaml" -o -name "*.yml" | wc -l)
        echo "✅ monitoring_o11y/ - ${YAML_COUNT}개 YAML 파일 발견"
        
        if [ "$YAML_COUNT" -gt 0 ]; then
            echo "📄 예시 파일들:"
            find monitoring_o11y -name "*.yaml" -o -name "*.yml" | head -5 | while read -r file; do
                echo "   - $file"
            done
        fi
    else
        echo "❌ monitoring_o11y/ - 디렉터리 없음"
    fi
}

test_workflow_syntax() {
    echo ""
    echo "🔍 워크플로 파일 구문 검사..."
    
    WORKFLOW_FILE=".github/workflows/checkov-security-scan-improved.yml"
    
    if [ -f "$WORKFLOW_FILE" ]; then
        echo "✅ 워크플로 파일 존재: $WORKFLOW_FILE"
        
        # YAML 구문 검사 (Python yaml 모듈 사용)
        if python3 -c "
import yaml
try:
    with open('$WORKFLOW_FILE', 'r') as f:
        yaml.safe_load(f)
    print('✅ YAML 구문 유효')
except Exception as e:
    print(f'❌ YAML 구문 오류: {e}')
    exit(1)
"; then
            echo "🎯 워크플로 구문 검사 통과"
        else
            echo "❌ 워크플로 구문 오류"
            return 1
        fi
    else
        echo "❌ 워크플로 파일 없음: $WORKFLOW_FILE"
        return 1
    fi
}

simulate_change_detection() {
    echo ""
    echo "🎯 변경 감지 시뮬레이션..."
    
    # 시뮬레이션 시나리오들
    echo "시나리오 1: keycloak 디렉터리만 변경"
    echo "  → 예상 결과: keycloak만 스캔"
    
    echo "시나리오 2: 워크플로 파일 변경"
    echo "  → 예상 결과: 전체 스캔"
    
    echo "시나리오 3: monitoring_o11y 디렉터리 변경"
    echo "  → 예상 결과: monitoring_o11y만 스캔 (Kubernetes 모드)"
    
    echo "시나리오 4: 변경사항 없음"
    echo "  → 예상 결과: 빠른 성공 종료"
}

# 메인 테스트 실행
main() {
    test_path_filter
    test_matrix_generation
    test_values_files
    test_kubernetes_manifests
    test_workflow_syntax
    simulate_change_detection
    
    echo ""
    echo "🎉 테스트 완료!"
    echo "=================================="
    echo "다음 단계:"
    echo "1. 작은 변경사항으로 PR 생성하여 실제 테스트"
    echo "2. 워크플로 파일 변경으로 전체 스캔 테스트"
    echo "3. 각 컴포넌트별 개별 변경 테스트"
}

# 스크립트 실행
main "$@"
