#!/bin/bash

# Kube-bench 결과 수집 및 분석 스크립트
# 이 스크립트는 kube-bench 실행 결과를 수집하고 분석합니다.

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
    echo "  -d, --directory  Results directory [default: ../results]"
    echo "  -f, --format     Output format (json|csv|html) [default: json]"
    echo "  -o, --output     Output file name [default: auto-generated]"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                           # Collect all results in JSON format"
    echo "  $0 -f csv -o summary.csv     # Generate CSV summary"
    echo "  $0 -d /path/to/results       # Use custom results directory"
}

# 기본값 설정
RESULTS_DIR="../results"
OUTPUT_FORMAT="json"
OUTPUT_FILE=""

# 명령행 인수 파싱
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--directory)
            RESULTS_DIR="$2"
            shift 2
            ;;
        -f|--format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
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

# 결과 디렉터리 확인
if [[ ! -d "$RESULTS_DIR" ]]; then
    log_error "Results directory not found: $RESULTS_DIR"
    exit 1
fi

# 결과 파일 확인
result_files=($(find "$RESULTS_DIR" -name "kube-bench-*.log" -type f))
if [[ ${#result_files[@]} -eq 0 ]]; then
    log_error "No kube-bench result files found in $RESULTS_DIR"
    exit 1
fi

log_info "Found ${#result_files[@]} result files"

# 출력 파일명 생성
if [[ -z "$OUTPUT_FILE" ]]; then
    timestamp=$(date +"%Y%m%d_%H%M%S")
    OUTPUT_FILE="${RESULTS_DIR}/kube-bench-summary-${timestamp}.${OUTPUT_FORMAT}"
fi

# JSON 형식으로 결과 수집
collect_json_results() {
    local output_file="$1"
    
    log_info "Collecting results in JSON format..."
    
    echo "{" > "$output_file"
    echo "  \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"," >> "$output_file"
    echo "  \"summary\": {" >> "$output_file"
    
    local total_pass=0
    local total_fail=0
    local total_warn=0
    local total_info=0
    
    echo "    \"by_target\": {" >> "$output_file"
    
    local first=true
    for file in "${result_files[@]}"; do
        local basename=$(basename "$file" .log)
        local target=$(echo "$basename" | sed 's/kube-bench-\([^-]*\)-.*/\1/')
        
        local pass_count=$(grep -c "\[PASS\]" "$file" 2>/dev/null || echo "0")
        local fail_count=$(grep -c "\[FAIL\]" "$file" 2>/dev/null || echo "0")
        local warn_count=$(grep -c "\[WARN\]" "$file" 2>/dev/null || echo "0")
        local info_count=$(grep -c "\[INFO\]" "$file" 2>/dev/null || echo "0")
        
        total_pass=$((total_pass + pass_count))
        total_fail=$((total_fail + fail_count))
        total_warn=$((total_warn + warn_count))
        total_info=$((total_info + info_count))
        
        if [[ "$first" == "false" ]]; then
            echo "," >> "$output_file"
        fi
        first=false
        
        echo "      \"$target\": {" >> "$output_file"
        echo "        \"file\": \"$file\"," >> "$output_file"
        echo "        \"pass\": $pass_count," >> "$output_file"
        echo "        \"fail\": $fail_count," >> "$output_file"
        echo "        \"warn\": $warn_count," >> "$output_file"
        echo "        \"info\": $info_count" >> "$output_file"
        echo -n "      }" >> "$output_file"
    done
    
    echo "" >> "$output_file"
    echo "    }," >> "$output_file"
    echo "    \"total\": {" >> "$output_file"
    echo "      \"pass\": $total_pass," >> "$output_file"
    echo "      \"fail\": $total_fail," >> "$output_file"
    echo "      \"warn\": $total_warn," >> "$output_file"
    echo "      \"info\": $total_info" >> "$output_file"
    echo "    }" >> "$output_file"
    echo "  }," >> "$output_file"
    
    # 실패한 검사 항목들 수집
    echo "  \"failed_checks\": [" >> "$output_file"
    
    local first_fail=true
    for file in "${result_files[@]}"; do
        local target=$(basename "$file" .log | sed 's/kube-bench-\([^-]*\)-.*/\1/')
        
        while IFS= read -r line; do
            if [[ "$line" =~ ^\[FAIL\] ]]; then
                if [[ "$first_fail" == "false" ]]; then
                    echo "," >> "$output_file"
                fi
                first_fail=false
                
                local check_id=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
                local description=$(echo "$line" | sed 's/^\[FAIL\] [0-9]\+\.[0-9]\+\.[0-9]\+ //')
                
                echo "    {" >> "$output_file"
                echo "      \"target\": \"$target\"," >> "$output_file"
                echo "      \"check_id\": \"$check_id\"," >> "$output_file"
                echo "      \"description\": \"$description\"," >> "$output_file"
                echo "      \"severity\": \"FAIL\"" >> "$output_file"
                echo -n "    }" >> "$output_file"
            fi
        done < "$file"
    done
    
    echo "" >> "$output_file"
    echo "  ]" >> "$output_file"
    echo "}" >> "$output_file"
    
    log_success "JSON results saved to: $output_file"
}

# CSV 형식으로 결과 수집
collect_csv_results() {
    local output_file="$1"
    
    log_info "Collecting results in CSV format..."
    
    echo "Target,File,Pass,Fail,Warn,Info,Total" > "$output_file"
    
    for file in "${result_files[@]}"; do
        local basename=$(basename "$file" .log)
        local target=$(echo "$basename" | sed 's/kube-bench-\([^-]*\)-.*/\1/')
        
        local pass_count=$(grep -c "\[PASS\]" "$file" 2>/dev/null || echo "0")
        local fail_count=$(grep -c "\[FAIL\]" "$file" 2>/dev/null || echo "0")
        local warn_count=$(grep -c "\[WARN\]" "$file" 2>/dev/null || echo "0")
        local info_count=$(grep -c "\[INFO\]" "$file" 2>/dev/null || echo "0")
        local total=$((pass_count + fail_count + warn_count + info_count))
        
        echo "$target,$file,$pass_count,$fail_count,$warn_count,$info_count,$total" >> "$output_file"
    done
    
    log_success "CSV results saved to: $output_file"
}

# HTML 형식으로 결과 수집
collect_html_results() {
    local output_file="$1"
    
    log_info "Collecting results in HTML format..."
    
    cat > "$output_file" << 'EOF'
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Kube-bench Security Benchmark Results</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f8f9fa; padding: 20px; border-radius: 5px; margin-bottom: 20px; }
        .summary { display: flex; gap: 20px; margin-bottom: 20px; }
        .card { background-color: #fff; border: 1px solid #dee2e6; border-radius: 5px; padding: 15px; flex: 1; }
        .pass { color: #28a745; }
        .fail { color: #dc3545; }
        .warn { color: #ffc107; }
        .info { color: #17a2b8; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #dee2e6; padding: 8px; text-align: left; }
        th { background-color: #f8f9fa; }
        .failed-checks { margin-top: 30px; }
        .check-item { background-color: #f8d7da; border: 1px solid #f5c6cb; border-radius: 3px; padding: 10px; margin: 5px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🛡️ Kube-bench Security Benchmark Results</h1>
        <p><strong>Generated:</strong> $(date)</p>
    </div>
EOF

    # 요약 통계 계산
    local total_pass=0
    local total_fail=0
    local total_warn=0
    local total_info=0
    
    for file in "${result_files[@]}"; do
        local pass_count=$(grep -c "\[PASS\]" "$file" 2>/dev/null || echo "0")
        local fail_count=$(grep -c "\[FAIL\]" "$file" 2>/dev/null || echo "0")
        local warn_count=$(grep -c "\[WARN\]" "$file" 2>/dev/null || echo "0")
        local info_count=$(grep -c "\[INFO\]" "$file" 2>/dev/null || echo "0")
        
        total_pass=$((total_pass + pass_count))
        total_fail=$((total_fail + fail_count))
        total_warn=$((total_warn + warn_count))
        total_info=$((total_info + info_count))
    done
    
    cat >> "$output_file" << EOF
    <div class="summary">
        <div class="card">
            <h3 class="pass">✅ PASS</h3>
            <h2>$total_pass</h2>
        </div>
        <div class="card">
            <h3 class="fail">❌ FAIL</h3>
            <h2>$total_fail</h2>
        </div>
        <div class="card">
            <h3 class="warn">⚠️ WARN</h3>
            <h2>$total_warn</h2>
        </div>
        <div class="card">
            <h3 class="info">ℹ️ INFO</h3>
            <h2>$total_info</h2>
        </div>
    </div>

    <h2>📊 Detailed Results by Target</h2>
    <table>
        <thead>
            <tr>
                <th>Target</th>
                <th>File</th>
                <th class="pass">Pass</th>
                <th class="fail">Fail</th>
                <th class="warn">Warn</th>
                <th class="info">Info</th>
                <th>Total</th>
            </tr>
        </thead>
        <tbody>
EOF

    for file in "${result_files[@]}"; do
        local basename=$(basename "$file" .log)
        local target=$(echo "$basename" | sed 's/kube-bench-\([^-]*\)-.*/\1/')
        
        local pass_count=$(grep -c "\[PASS\]" "$file" 2>/dev/null || echo "0")
        local fail_count=$(grep -c "\[FAIL\]" "$file" 2>/dev/null || echo "0")
        local warn_count=$(grep -c "\[WARN\]" "$file" 2>/dev/null || echo "0")
        local info_count=$(grep -c "\[INFO\]" "$file" 2>/dev/null || echo "0")
        local total=$((pass_count + fail_count + warn_count + info_count))
        
        cat >> "$output_file" << EOF
            <tr>
                <td><strong>$target</strong></td>
                <td>$basename</td>
                <td class="pass">$pass_count</td>
                <td class="fail">$fail_count</td>
                <td class="warn">$warn_count</td>
                <td class="info">$info_count</td>
                <td>$total</td>
            </tr>
EOF
    done
    
    cat >> "$output_file" << 'EOF'
        </tbody>
    </table>

    <div class="failed-checks">
        <h2>❌ Failed Checks</h2>
EOF

    # 실패한 검사 항목들 추가
    for file in "${result_files[@]}"; do
        local target=$(basename "$file" .log | sed 's/kube-bench-\([^-]*\)-.*/\1/')
        
        while IFS= read -r line; do
            if [[ "$line" =~ ^\[FAIL\] ]]; then
                local check_id=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
                local description=$(echo "$line" | sed 's/^\[FAIL\] [0-9]\+\.[0-9]\+\.[0-9]\+ //')
                
                cat >> "$output_file" << EOF
        <div class="check-item">
            <strong>[$target] $check_id:</strong> $description
        </div>
EOF
            fi
        done < "$file"
    done
    
    cat >> "$output_file" << 'EOF'
    </div>
</body>
</html>
EOF
    
    log_success "HTML results saved to: $output_file"
}

# 메인 실행 로직
main() {
    log_info "Starting kube-bench results collection"
    log_info "Results directory: $RESULTS_DIR"
    log_info "Output format: $OUTPUT_FORMAT"
    log_info "Output file: $OUTPUT_FILE"
    
    case $OUTPUT_FORMAT in
        json)
            collect_json_results "$OUTPUT_FILE"
            ;;
        csv)
            collect_csv_results "$OUTPUT_FILE"
            ;;
        html)
            collect_html_results "$OUTPUT_FILE"
            ;;
        *)
            log_error "Invalid output format: $OUTPUT_FORMAT. Valid options: json, csv, html"
            exit 1
            ;;
    esac
    
    log_success "Results collection completed successfully!"
    log_info "Output saved to: $OUTPUT_FILE"
}

# 스크립트 실행
main