# 🔒 Kube-bench 자동화된 보안 검사 설정 가이드

이 문서는 EKS 클러스터에서 kube-bench를 사용한 자동화된 보안 검사를 설정하는 방법을 설명합니다.

## 📋 개요

GitHub Actions를 통해 매일 자동으로 kube-bench 보안 검사를 실행하고, 결과를 분석하여 GitHub Issues로 보고서를 생성하며, Slack으로 알림을 전송하는 완전 자동화된 시스템입니다.

## 🚀 주요 기능

- **자동 스케줄링**: 매일 오전 9시 (KST) 자동 실행
- **수동 실행**: 필요시 수동으로 워크플로우 실행 가능
- **결과 분석**: 심각도별 이슈 분류 및 분석
- **자동 보고서**: GitHub Issues로 상세 보고서 생성
- **Slack 알림**: 검사 완료 및 중요 이슈 알림
- **아티팩트 저장**: 검사 결과의 장기 보관

## 🔧 설정 요구사항

### 1. GitHub Secrets 설정

다음 secrets을 GitHub 저장소에 설정해야 합니다:

```bash
# AWS 인증 정보
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
AWS_REGION=ap-northeast-2  # 또는 사용하는 리전

# Slack 웹훅 URL (선택사항)
SLACK_WEBHOOK_URL_SCAN=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
```

### 2. AWS IAM 권한

GitHub Actions에서 사용할 IAM 사용자 또는 역할에 다음 권한이 필요합니다:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:DescribeCluster",
                "eks:ListClusters"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "sts:GetCallerIdentity"
            ],
            "Resource": "*"
        }
    ]
}
```

### 3. EKS 클러스터 접근 권한

GitHub Actions에서 사용하는 IAM 사용자/역할이 EKS 클러스터에 접근할 수 있도록 `aws-auth` ConfigMap을 업데이트해야 합니다:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapUsers: |
    - userarn: arn:aws:iam::ACCOUNT-ID:user/github-actions-user
      username: github-actions-user
      groups:
        - system:masters
```

## 📊 워크플로우 구성

### 자동 실행 스케줄

```yaml
schedule:
  # 매일 오전 9시 (KST 기준 오전 6시 UTC)에 실행
  - cron: '0 6 * * *'
```

### 수동 실행 옵션

워크플로우는 다음 매개변수로 수동 실행할 수 있습니다:

- **cluster_name**: 검사할 EKS 클러스터 이름
- **severity_threshold**: 알림 임계값 (CRITICAL, HIGH, MEDIUM, LOW)

## 🔍 검사 프로세스

### 1. 환경 설정
- AWS 인증 정보 구성
- kubectl 설정
- EKS 클러스터 연결

### 2. Kube-bench 실행
- EKS 전용 kube-bench Job 생성
- CIS Kubernetes Benchmark 검사 실행
- 결과 수집 및 정리

### 3. 결과 분석
- JSON 결과 파싱
- 심각도별 이슈 분류
- 통계 정보 생성

### 4. 보고서 생성
- 마크다운 형식의 상세 보고서 생성
- 요약 정보 및 권장 조치사항 포함

### 5. 알림 및 이슈 생성
- GitHub Issues로 보고서 게시
- Slack으로 요약 알림 전송

## 📋 보고서 구성

생성되는 보고서에는 다음 정보가 포함됩니다:

### 검사 요약
- 전체 테스트 수
- 통과/실패/경고 수
- 통과율

### 심각도별 이슈
- 🔴 Critical: 즉시 조치 필요
- 🟠 High: 우선 조치 필요  
- 🟡 Medium: 검토 필요
- 🟢 Low: 참고사항

### 권장 조치사항
- 즉시 조치 항목
- 단기/장기 조치 계획
- 모니터링 권장사항

## 📱 Slack 알림 설정

### Slack 웹훅 생성

1. Slack 워크스페이스에서 앱 생성
2. Incoming Webhooks 활성화
3. 웹훅 URL을 GitHub Secrets에 `SLACK_WEBHOOK_URL_SCAN`로 저장

### 알림 내용

Slack 알림에는 다음 정보가 포함됩니다:

- 검사 상태 (색상 코딩)
- 클러스터 이름 및 검사 시간
- 전체 테스트 수 및 통과율
- Critical/High 이슈 수
- GitHub Issues 링크

## 🔧 커스터마이징

### 검사 주기 변경

`.github/workflows/kube-bench-security-scan.yml` 파일의 cron 표현식을 수정:

```yaml
schedule:
  # 매주 월요일 오전 9시
  - cron: '0 6 * * 1'
  
  # 매시간
  - cron: '0 * * * *'
```

### 심각도 임계값 조정

워크플로우 파일에서 `SEVERITY_THRESHOLD` 환경 변수를 수정하여 알림 임계값을 조정할 수 있습니다.

### 추가 클러스터 지원

여러 클러스터를 검사하려면 워크플로우를 matrix 전략으로 수정:

```yaml
strategy:
  matrix:
    cluster: ['cluster-1', 'cluster-2', 'cluster-3']
```

## 📊 결과 아티팩트

각 검사 실행 후 다음 아티팩트가 저장됩니다:

- `kube-bench-results-{timestamp}.json`: 원본 검사 결과
- `kube-bench-analysis-{timestamp}.json`: 분석된 결과
- `security-report-{timestamp}.md`: 마크다운 보고서

아티팩트는 30일간 보관되며, 장기 추세 분석에 활용할 수 있습니다.

## 🔍 문제 해결

### 일반적인 문제

1. **AWS 인증 실패**
   - AWS credentials 확인
   - IAM 권한 검토

2. **EKS 클러스터 접근 실패**
   - aws-auth ConfigMap 설정 확인
   - 클러스터 이름 확인

3. **kube-bench Job 실패**
   - 노드 리소스 확인
   - 보안 정책 검토

4. **Slack 알림 실패**
   - 웹훅 URL 확인
   - 네트워크 연결 확인

### 로그 확인

GitHub Actions의 워크플로우 실행 로그에서 상세한 오류 정보를 확인할 수 있습니다.

## 📞 지원

문제가 발생하면 다음을 확인해주세요:

1. GitHub Actions 워크플로우 로그
2. AWS CloudTrail 로그
3. EKS 클러스터 상태
4. kube-bench 공식 문서

## 🔄 업데이트

이 자동화 시스템은 다음과 같이 지속적으로 개선됩니다:

- kube-bench 최신 버전 적용
- 새로운 CIS 벤치마크 지원
- 추가 보안 도구 통합
- 대시보드 및 메트릭 개선

---

> 이 가이드는 EKS 환경에서의 자동화된 보안 검사를 위한 완전한 솔루션을 제공합니다.
> 추가 질문이나 개선 사항이 있으면 GitHub Issues를 통해 문의해주세요.