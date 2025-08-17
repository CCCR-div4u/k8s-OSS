# 보안 검사 워크플로우 설정 가이드

이 문서는 Checkov 보안 검사 워크플로우에서 OpenAI 분석과 알림 기능을 사용하기 위한 설정 방법을 설명합니다.

## 필요한 GitHub Secrets

### 1. OpenAI API Key (필수)
```
OPENAI_API_KEY
```
- OpenAI API 키를 설정하세요
- 없으면 기본 보고서가 생성됩니다

### 2. Slack Webhook URL (선택사항)
```
SLACK_WEBHOOK_URL
```
- Slack 알림을 받으려면 Incoming Webhook URL을 설정하세요
- 설정하지 않으면 Slack 알림은 건너뜁니다

## 기능 설명

### 1. 보안 검사 결과 분석
- Checkov가 JSON 형식으로 결과를 출력합니다
- OpenAI API를 통해 결과를 분석하여 한국어 보고서를 생성합니다
- 심각도별로 이슈를 분류하고 우선순위를 제시합니다

### 2. 알림 방법

#### PR 댓글
- Pull Request에서 보안 이슈가 발견되면 자동으로 댓글을 추가합니다
- 분석된 보고서 내용이 포함됩니다

#### GitHub Issue 생성
- Critical 또는 High 심각도 이슈가 발견되면 자동으로 Issue를 생성합니다
- 체크리스트와 함께 해결 가이드를 제공합니다
- `security`, `checkov`, `컴포넌트명` 라벨이 자동으로 추가됩니다

#### Slack 알림
- `SLACK_WEBHOOK_URL`이 설정된 경우 Slack으로 알림을 전송합니다
- 보안 검사 결과 요약과 워크플로우 링크를 포함합니다

### 3. 아티팩트
- SARIF 파일: GitHub Security 탭에서 확인 가능
- JSON 파일: 상세한 검사 결과 확인 가능

## Slack Webhook 설정 방법

1. Slack 워크스페이스에서 앱 설정으로 이동
2. "Incoming Webhooks" 앱을 추가
3. 알림을 받을 채널을 선택
4. 생성된 Webhook URL을 GitHub Secrets에 `SLACK_WEBHOOK_URL`로 추가

## OpenAI API Key 설정 방법

1. OpenAI 플랫폼(https://platform.openai.com)에 로그인
2. API Keys 섹션에서 새 키를 생성
3. 생성된 키를 GitHub Secrets에 `OPENAI_API_KEY`로 추가

## 워크플로우 트리거

- Pull Request: 지정된 디렉터리에 변경사항이 있을 때
- Push to main: 메인 브랜치에 변경사항이 푸시될 때
- 워크플로우 파일 자체가 수정될 때

## 지원하는 컴포넌트

- argo-cd
- harbor  
- keycloak
- sonarqube
- thanos

각 컴포넌트별로 독립적으로 검사가 수행되며, 결과도 개별적으로 처리됩니다.
