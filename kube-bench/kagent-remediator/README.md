# 🔒 Kube-bench Remediator Agent

S3에서 kube-bench 검사 결과를 자동으로 읽어와 Kubernetes 클러스터의 보안 이슈를 자동으로 수정하는 kagent 에이전트입니다.

## 📋 개요

이 에이전트는 다음과 같은 기능을 제공합니다:

1. **자동 스캔**: S3에서 최신 kube-bench 결과 자동 다운로드
2. **지능형 분석**: 보안 이슈를 자동/수동 수정 가능 항목으로 분류
3. **안전한 자동 수정**: 승인 기반 자동 보안 설정 적용
4. **상세한 계획**: 수동 작업이 필요한 항목의 실행 가이드 제공

## 🏗️ 아키텍처

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   GitHub        │    │       S3         │    │   kagent        │
│   Actions       │───▶│     Bucket       │◀───│   Agent         │
│  (kube-bench)   │    │   (JSON 결과)    │    │ (remediator)    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                ▼                        ▼
                       ┌──────────────────┐    ┌─────────────────┐
                       │   S3 Structure   │    │   K8s Cluster   │
                       │ year/month/day/  │    │   Auto-fixes    │
                       │   latest/        │    │   Policies      │
                       └──────────────────┘    └─────────────────┘
```

## 📁 파일 구조

```
kube-bench-remediator/
├── kube-bench-remediator.yaml          # 메인 에이전트 정의
├── kube-bench-remediator-config.yaml   # 설정 및 RBAC
├── kube-bench-remediator-cronjob.yaml  # 자동 실행 Job
└── kube-bench-remediator-README.md     # 이 파일
```

## 🚀 설치 및 설정

### 1. 사전 요구사항

- kagent가 클러스터에 설치되어 있어야 함
- S3 버킷 `kube-bench-results-bluesunnywings`에 접근 권한
- AWS 자격 증명 설정 (IRSA 또는 Secret)

### 2. 설치

```bash
# 1. 설정 및 RBAC 적용
kubectl apply -f kube-bench-remediator-config.yaml

# 2. 에이전트 배포
kubectl apply -f kube-bench-remediator.yaml

# 3. 자동 실행 CronJob 설정 (선택사항)
kubectl apply -f kube-bench-remediator-cronjob.yaml
```

### 3. AWS 자격 증명 설정

#### Option A: IRSA 사용 (권장)
```bash
# ServiceAccount에 IAM Role ARN 추가
kubectl patch serviceaccount kube-bench-remediator -n kagent \
  -p '{"metadata":{"annotations":{"eks.amazonaws.com/role-arn":"arn:aws:iam::ACCOUNT:role/KubeBenchRemediatorRole"}}}'
```

#### Option B: Secret 사용
```bash
kubectl patch secret kube-bench-remediator-secrets -n kagent \
  --type='merge' -p='{
    "stringData": {
      "aws_access_key_id": "YOUR_ACCESS_KEY",
      "aws_secret_access_key": "YOUR_SECRET_KEY"
    }
  }'
```

### 4. Slack 알림 설정 (선택사항)

```bash
kubectl patch secret kube-bench-remediator-secrets -n kagent \
  --type='merge' -p='{
    "stringData": {
      "slack_webhook_url": "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
    }
  }'
```

## 🔧 사용법

### 기본 명령어

#### 1. 자동 스캔 (S3에서 최신 결과 읽기)
```
scan
```

#### 2. 특정 날짜 스캔
```
scan date=2024-08-23
```

#### 3. 수정 계획 생성
```
plan targets.namespaces=default,kube-system
```

#### 4. 자동 수정 적용 (승인 필요)
```
apply approve=true targets.namespaces=default
```

#### 5. 수동 JSON 입력
```
mode=plan targets.namespaces=default

{kube-bench JSON 결과 붙여넣기}
```

### 실행 방법

#### A. kagent UI/CLI 사용
```bash
# kagent CLI로 직접 호출
kagent invoke kube-bench-remediator "scan"
```

#### B. 수동 Job 실행
```bash
# Job 환경변수 설정 후 실행
kubectl set env job/kube-bench-manual-remediation -n kagent \
  REMEDIATION_MODE=plan \
  TARGET_NAMESPACES=default,kube-system \
  APPROVE=false

kubectl create job --from=job/kube-bench-manual-remediation manual-scan-$(date +%s) -n kagent
```

#### C. 자동 실행 (CronJob)
- 매일 오전 10시 (KST)에 자동으로 `scan` 실행
- 결과는 ConfigMap과 Slack으로 전송

## 🛡️ 자동 수정 범위

### ✅ 자동 적용 가능 (A그룹)

1. **Pod Security Standards**
   ```yaml
   pod-security.kubernetes.io/enforce: restricted
   pod-security.kubernetes.io/audit: restricted
   pod-security.kubernetes.io/warn: restricted
   ```

2. **ServiceAccount 보안**
   ```yaml
   automountServiceAccountToken: false
   ```

3. **워크로드 보안 설정**
   - `hostNetwork: false`
   - `hostPID: false`
   - `hostIPC: false`
   - `securityContext.allowPrivilegeEscalation: false`
   - `securityContext.capabilities.drop: ["ALL"]`
   - `securityContext.runAsNonRoot: true`

4. **NetworkPolicy 생성**
   - 기본 deny-all 정책
   - DNS 허용 정책
   - 필요한 통신만 허용

### ⚠️ 계획만 제공 (B그룹)

- API Server 설정
- Controller Manager 설정
- Scheduler 설정
- etcd 암호화
- 감사 로깅
- 노드/OS 레벨 설정

## 📊 결과 저장

모든 실행 결과는 다음 위치에 저장됩니다:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: kb-remediation-{timestamp}
  namespace: kagent
data:
  scan_id: "20240823-073124"
  input_hash: "abc123..."
  failed_checks: "..."
  remediation_plan: "..."
  applied_fixes: "..."
  rollback_guide: "..."
```

## 🔍 모니터링

### 로그 확인
```bash
# 에이전트 로그
kubectl logs -n kagent -l app=kagent -f

# CronJob 로그
kubectl logs -n kagent -l app=kube-bench-remediator -f

# 최근 실행 결과
kubectl get configmaps -n kagent | grep kb-remediation
```

### 상태 확인
```bash
# 에이전트 상태
kubectl get agents -n kagent kube-bench-remediator

# CronJob 상태
kubectl get cronjobs -n kagent kube-bench-auto-remediation

# 최근 Job 실행 이력
kubectl get jobs -n kagent | grep kube-bench
```

## 🚨 안전 기능

1. **승인 기반 실행**: `approve=true` 명시적 승인 필요
2. **네임스페이스 제한**: 지정된 네임스페이스에만 적용
3. **Dry-run 모드**: 실제 적용 전 시뮬레이션
4. **롤백 가이드**: 모든 변경사항에 대한 롤백 방법 제공
5. **상세 로깅**: 모든 작업 내역 기록

## 🔧 설정 커스터마이징

### ConfigMap 수정
```bash
kubectl edit configmap kube-bench-remediator-config -n kagent
```

### 주요 설정 항목
- `remediation.auto_fix_enabled`: 자동 수정 활성화 여부
- `remediation.severity_threshold`: 수정 대상 심각도 임계값
- `targets.default_namespaces`: 기본 대상 네임스페이스
- `policies.*`: 각종 보안 정책 활성화 여부

## 🐛 문제 해결

### 일반적인 문제

1. **S3 접근 오류**
   ```bash
   # AWS 자격 증명 확인
   kubectl describe serviceaccount kube-bench-remediator -n kagent
   ```

2. **권한 오류**
   ```bash
   # RBAC 권한 확인
   kubectl auth can-i patch namespaces --as=system:serviceaccount:kagent:kube-bench-remediator
   ```

3. **에이전트 응답 없음**
   ```bash
   # kagent 상태 확인
   kubectl get pods -n kagent
   kubectl logs -n kagent -l app=kagent
   ```

### 디버깅 모드

```bash
# 상세 로깅 활성화
kubectl patch configmap kube-bench-remediator-config -n kagent \
  --type='merge' -p='{"data":{"config.yaml":"logging:\n  level: DEBUG"}}'
```

## 📚 참고 자료

- [kagent 공식 문서](https://kagent.dev/docs/)
- [kube-bench GitHub](https://github.com/aquasecurity/kube-bench)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

## 🤝 기여하기

이슈나 개선사항이 있으시면 GitHub 저장소에 이슈를 생성해 주세요.

## 📄 라이선스

이 프로젝트는 각 오픈소스 도구들의 라이선스를 따릅니다.
