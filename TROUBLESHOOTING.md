# GitHub Actions 보안 워크플로우 문제 해결 가이드

## 📋 개요

이 문서는 Checkov 보안 검사 워크플로우에서 발생한 문제들과 해결 과정을 정리한 것입니다.

## 🚨 발생한 문제들

### 1. OpenAI 분석 실패 - `'NoneType' object has no attribute 'upper'`

#### 문제 상황
```
❌ 분석 실패: 'NoneType' object has no attribute 'upper'
```

#### 원인
- Checkov JSON 결과에서 `severity` 필드가 `None`으로 반환됨
- Python 코드에서 `check.get('severity', 'UNKNOWN').upper()` 호출 시 `None.upper()` 오류 발생

#### 해결 방법
```python
# 기존 (오류 발생)
severity = check.get('severity', 'UNKNOWN').upper()

# 수정 (오류 해결)
severity = check.get('severity')
if severity:
    severity = severity.upper()
else:
    severity = 'UNKNOWN'
```

#### 파일 위치
`.github/workflows/checkov-security-scan.yml` 라인 164-169

---

### 2. JavaScript 구문 오류 - `SyntaxError: Unexpected identifier 'Image'`

#### 문제 상황
```
SyntaxError: Unexpected identifier 'Image'
    at new AsyncFunction (<anonymous>)
```

#### 원인
- OpenAI 분석 결과에 백틱(`)이나 특수 문자가 포함됨
- JavaScript 템플릿 리터럴에서 구문 충돌 발생

#### 해결 방법
```yaml
# 기존 (오류 발생)
script: |
  const analysis = `${{ steps.openai-analysis.outputs.analysis_result }}`;

# 수정 (오류 해결)
env:
  ANALYSIS_RESULT: ${{ steps.openai-analysis.outputs.analysis_result }}
script: |
  const analysis = process.env.ANALYSIS_RESULT;
```

#### 파일 위치
`.github/workflows/checkov-security-scan.yml` 라인 325, 348

---

### 3. JSON 파싱 오류 - `Bad control character in string literal`

#### 문제 상황
```
SyntaxError: Bad control character in string literal in JSON at position 23
    at JSON.parse (<anonymous>)
```

#### 원인
- OpenAI 분석 결과에 JSON에서 허용되지 않는 제어 문자(줄바꿈, 탭 등) 포함
- `JSON.parse()` 함수가 제어 문자를 처리하지 못함

#### 해결 방법
```yaml
# 기존 (오류 발생)
script: |
  const analysis = JSON.parse('${{ toJSON(steps.openai-analysis.outputs.analysis_result) }}');

# 수정 (오류 해결)
env:
  ANALYSIS_RESULT: ${{ steps.openai-analysis.outputs.analysis_result }}
script: |
  const analysis = process.env.ANALYSIS_RESULT;
```

---

### 4. GitHub Issue 생성 안됨

#### 문제 상황
- OpenAI 분석은 성공하지만 GitHub Issues에 보안 이슈가 생성되지 않음

#### 원인
- Issue 생성 조건이 Critical/High 이슈만으로 제한됨
- Keycloak 등의 경우 모든 이슈가 `severity: None`으로 분류되어 조건에 맞지 않음

#### 해결 방법
```javascript
// 기존 (Critical/High만 생성)
if (hasCriticalHigh) {
  // Issue 생성
}

// 수정 (모든 보안 이슈에 대해 생성)
if (issueCount && issueCount !== '0') {
  // 심각도별 라벨링과 함께 Issue 생성
}
```

---

### 5. GitHub 토큰 권한 부족

#### 문제 상황
```
refusing to allow an OAuth App to create or update workflow without `workflow` scope
```

#### 원인
- 기존 GitHub 토큰에 `workflow` 스코프가 없음
- 워크플로우 파일 수정 권한 부족

#### 해결 방법
1. GitHub에서 새 Personal Access Token 생성
2. 필요한 스코프 포함:
   - `repo` (저장소 접근)
   - `workflow` (워크플로우 수정)
   - `read:org` (조직 정보)
3. GitHub CLI 재인증: `gh auth login --web`

---

## 🔧 최종 해결된 워크플로우 구조

### 1. 권한 설정
```yaml
permissions:
  contents: read
  security-events: write
  issues: write
  pull-requests: write
```

### 2. OpenAI 분석 단계
- JSON 결과 파일 생성
- Python 스크립트로 안전한 severity 처리
- OpenAI API 호출 또는 기본 보고서 생성

### 3. 알림 단계
- **PR 댓글**: Pull Request 이벤트 시 자동 댓글
- **GitHub Issue**: 모든 보안 이슈에 대해 심각도별 라벨링과 함께 생성
- **Slack 알림**: 웹훅 URL 설정 시 구조화된 메시지 전송

## 📊 테스트 결과

### 성공한 기능들
- ✅ Helm 템플릿 렌더링
- ✅ Checkov 보안 검사 (JSON + SARIF 출력)
- ✅ OpenAI 분석 (severity 처리 개선)
- ✅ GitHub Issue 생성 (모든 컴포넌트)
- ✅ 아티팩트 업로드

### 조건부 기능들
- ⚠️ PR 댓글: Pull Request 이벤트에서만 작동
- ⚠️ Slack 알림: `SLACK_WEBHOOK_URL` 설정 시에만 작동

## 🛠 필요한 GitHub Secrets

### 필수
```
OPENAI_API_KEY=sk-proj-xxxxx...
```

### 선택사항
```
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
```

## 📝 학습된 교훈

1. **데이터 전달 시 안전성**: 템플릿 리터럴보다 환경변수가 더 안전
2. **Null 체크의 중요성**: API 응답에서 null 값 처리 필수
3. **권한 관리**: GitHub 토큰 스코프 사전 확인 필요
4. **조건부 로직**: 비즈니스 요구사항에 맞는 조건 설정
5. **오류 처리**: 각 단계별 적절한 fallback 메커니즘 구현

## 🔍 디버깅 팁

### 워크플로우 로그 확인
```bash
gh run view <run-id> --log-failed --repo CCCR-div4u/k8s-OSS
```

### 아티팩트 다운로드
```bash
gh run download <run-id> --repo CCCR-div4u/k8s-OSS
```

### 로컬 테스트
```bash
# OpenAI 분석 스크립트 테스트
OPENAI_API_KEY=your_key python3 test_openai_analysis.py results/component.json
```

---

### 6. GitHub Actions JSON 매트릭스 형식 오류 ⭐ **최신 추가 (2025-08-19)**

#### 문제 상황
```
Error: Unable to process file command 'output' successfully.
Error: Invalid format '  "include": ['
```

#### 원인
- GitHub Actions에서 멀티라인 JSON을 `echo "matrix=$JSON"` 방식으로 출력할 때 형식이 깨짐
- 줄바꿈과 공백이 포함된 JSON이 GitHub Actions output으로 올바르게 파싱되지 않음
- 특히 복잡한 매트릭스 JSON에서 자주 발생

#### 해결 방법

**기존 방식 (문제 발생)**
```yaml
- name: Set matrix
  run: |
    MATRIX='{
      "include": [
        {
          "name": "component",
          "value": "test"
        }
      ]
    }'
    echo "matrix=$MATRIX" >> $GITHUB_OUTPUT  # ❌ 실패
```

**개선된 방식 (해결)**
```yaml
- name: Set matrix
  run: |
    # 임시 파일을 사용한 안전한 JSON 생성
    cat > /tmp/matrix.json << 'EOF'
    {
      "include": [
        {
          "name": "component",
          "value": "test"
        }
      ]
    }
    EOF
    
    # jq를 사용한 JSON 압축 및 검증
    MATRIX=$(cat /tmp/matrix.json | jq -c .)
    
    # heredoc 방식으로 안전한 output 설정
    {
      echo "matrix<<EOF"
      echo "$MATRIX"
      echo "EOF"
    } >> $GITHUB_OUTPUT  # ✅ 성공
```

#### 핵심 개선사항
1. **임시 파일 사용**: 복잡한 JSON을 안전하게 생성
2. **jq 압축**: JSON 유효성 검사 및 한 줄로 압축  
3. **heredoc output**: 특수문자와 줄바꿈 안전 처리

#### 적용된 커밋
- 커밋 해시: `bb3c0fb`
- 제목: "🔧 fix: GitHub Actions JSON 매트릭스 형식 오류 수정"

---

### 7. 워크플로 파일 구조 및 관리 문제 ⭐ **최신 추가 (2025-08-19)**

#### 문제 상황
- 개발/테스트용 파일들이 OSS 프로젝트 루트에 혼재
- 문서화 파일들이 실제 Kubernetes 배포 파일들과 섞여있음
- 백업 파일들의 체계적 관리 필요

#### 해결 방법

**디렉터리 구조 정리**
```
k8s-OSS/
├── .github/workflows/
│   └── checkov-security-scan.yml          # 활성 워크플로
├── docs/                                  # 📁 새로 생성
│   ├── README.md
│   └── workflow-improvements/
│       ├── README.md
│       ├── CHECKOV_WORKFLOW_IMPROVEMENTS.md
│       ├── IMPLEMENTATION_COMPLETE.md
│       ├── test-workflow.sh
│       └── checkov-security-scan-old.yml  # 백업
├── argo-cd/                               # OSS 컴포넌트들
├── harbor/
└── ...
```

**파일 분류 원칙**
- **OSS 프로젝트 파일**: 루트 디렉터리에 유지
- **문서화/개발 도구**: `docs/` 디렉터리로 이동  
- **백업 파일**: `docs/workflow-improvements/`에 보관

#### 적용된 커밋
- 커밋 해시: `7080feb`, `2f9281f`
- 제목: "feat: 개선된 Checkov 보안 스캔 워크플로 구현"

---

## 🧪 추가 디버깅 도구 ⭐ **최신 추가**

### 1. 로컬 테스트 스크립트
```bash
cd docs/workflow-improvements
chmod +x test-workflow.sh
./test-workflow.sh
```

### 2. JSON 검증 도구
```bash
# 매트릭스 JSON 검증
echo '{"include":[...]}' | jq .

# 파일에서 JSON 검증  
jq . < matrix.json
```

### 3. 워크플로 구문 검사
```bash
# Python yaml 모듈로 YAML 구문 검사
python3 -c "
import yaml
with open('.github/workflows/checkov-security-scan.yml', 'r') as f:
    yaml.safe_load(f)
print('YAML 구문 유효')
"
```

## 📚 추가 참고 자료

### GitHub Actions 문서
- [Using outputs with jobs](https://docs.github.com/en/actions/using-jobs/defining-outputs-for-jobs)
- [Using a matrix strategy](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs)
- [Workflow syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)

### 관련 도구
- [dorny/paths-filter](https://github.com/dorny/paths-filter)
- [bridgecrewio/checkov-action](https://github.com/bridgecrewio/checkov-action)
- [jq Manual](https://stedolan.github.io/jq/manual/)

## 🔄 버전 히스토리

| 버전 | 커밋 | 날짜 | 주요 변경사항 |
|------|------|------|---------------|
| v1.0 | 초기 | 2025-08-17 | 기본 트러블슈팅 문서 |
| v1.1 | `7080feb` | 2025-08-19 | 워크플로 개선 구현 |
| v1.2 | `2f9281f` | 2025-08-19 | 워크플로 활성화 |
| v1.3 | `bb3c0fb` | 2025-08-19 | JSON 매트릭스 오류 수정 |

---

*이 문서는 2025-08-17에 작성되었으며, 2025-08-19에 최신 트러블슈팅 내용이 추가되었습니다. 향후 유사한 문제 발생 시 참고용으로 활용할 수 있습니다.*
