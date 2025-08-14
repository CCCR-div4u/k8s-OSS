# Harbor 프로젝트 관리 (Keycloak 연동)

## 개요
Keycloak과 연동된 Harbor에서 프로젝트 관리 및 권한 설정 방법을 설명합니다.

## 프로젝트 생성 및 설정

### 1. 프로젝트 생성
Harbor UI에서 프로젝트 생성:
```yaml
Project Name: my-application
Access Level: Private
Storage Quota: 10GB
```

### 2. 멤버 추가
**Projects** → **my-application** → **Members** → **+USER**

#### 개별 사용자 추가
```yaml
Username: john.doe (Keycloak 사용자명)
Role: Developer
```

#### 그룹 추가
```yaml
Group Name: harbor-users
Role: Developer
```

```yaml
Group Name: harbor-admins  
Role: Project Admin
```

## 역할별 권한

### Project Admin
- 프로젝트 설정 변경
- 멤버 관리
- 이미지 푸시/풀
- 이미지 삭제
- 취약점 스캔 설정

### Maintainer
- 이미지 푸시/풀
- 이미지 삭제
- 태그 관리
- 취약점 스캔 실행

### Developer
- 이미지 푸시/풀
- 이미지 조회

### Guest
- 이미지 풀 (읽기 전용)
- 이미지 조회

## 자동화된 프로젝트 설정

### Helm Chart로 프로젝트 생성
```yaml
# harbor-project-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: harbor-project-config
  namespace: harbor
data:
  projects.json: |
    [
      {
        "name": "frontend",
        "public": false,
        "storage_limit": 10737418240,
        "members": [
          {"entity_name": "harbor-users", "entity_type": "g", "role_id": 2},
          {"entity_name": "harbor-admins", "entity_type": "g", "role_id": 1}
        ]
      },
      {
        "name": "backend", 
        "public": false,
        "storage_limit": 21474836480,
        "members": [
          {"entity_name": "harbor-users", "entity_type": "g", "role_id": 2},
          {"entity_name": "harbor-admins", "entity_type": "g", "role_id": 1}
        ]
      }
    ]
```

### 프로젝트 생성 스크립트
```bash
#!/bin/bash
# create-harbor-projects.sh

HARBOR_URL="https://harbor.example.com"
HARBOR_USERNAME="admin"
HARBOR_PASSWORD="Harbor12345"

# 프로젝트 목록
PROJECTS=(
  "frontend:10GB:harbor-users,harbor-admins"
  "backend:20GB:harbor-users,harbor-admins"
  "database:5GB:harbor-admins"
)

for project_info in "${PROJECTS[@]}"; do
  IFS=':' read -r project_name storage_limit groups <<< "$project_info"
  
  # 프로젝트 생성
  curl -X POST "${HARBOR_URL}/api/v2.0/projects" \
    -H "Content-Type: application/json" \
    -u "${HARBOR_USERNAME}:${HARBOR_PASSWORD}" \
    -d "{
      \"project_name\": \"${project_name}\",
      \"public\": false,
      \"storage_limit\": $(echo ${storage_limit} | sed 's/GB//' | awk '{print $1*1024*1024*1024}')
    }"
  
  # 그룹 멤버 추가
  IFS=',' read -ra GROUP_ARRAY <<< "$groups"
  for group in "${GROUP_ARRAY[@]}"; do
    role_id=2  # Developer
    if [[ "$group" == "harbor-admins" ]]; then
      role_id=1  # Project Admin
    fi
    
    curl -X POST "${HARBOR_URL}/api/v2.0/projects/${project_name}/members" \
      -H "Content-Type: application/json" \
      -u "${HARBOR_USERNAME}:${HARBOR_PASSWORD}" \
      -d "{
        \"member_group\": {
          \"group_name\": \"${group}\",
          \"group_type\": 1
        },
        \"role_id\": ${role_id}
      }"
  done
done
```

## 이미지 푸시/풀 가이드

### Docker 로그인
```bash
# OIDC 사용자로 로그인
docker login harbor.example.com
Username: [Keycloak username]
Password: [Harbor CLI token 또는 패스워드]
```

### 이미지 태깅 및 푸시
```bash
# 이미지 태깅
docker tag my-app:latest harbor.example.com/frontend/my-app:v1.0.0

# 이미지 푸시
docker push harbor.example.com/frontend/my-app:v1.0.0
```

### 이미지 풀
```bash
# 이미지 풀
docker pull harbor.example.com/frontend/my-app:v1.0.0
```

## Robot 계정 관리

### 프로젝트 Robot 계정 생성
1. **Projects** → **my-application** → **Robot Accounts** → **+ROBOT ACCOUNT**

```yaml
Name: ci-cd-robot
Description: CI/CD 파이프라인용 Robot 계정
Expiration: 90 days
Permissions:
  - Push and pull repository
  - Pull repository
```

### CI/CD에서 Robot 계정 사용
```yaml
# GitLab CI/CD 예시
variables:
  HARBOR_REGISTRY: harbor.example.com
  HARBOR_PROJECT: frontend
  HARBOR_ROBOT_USER: robot$frontend+ci-cd-robot
  HARBOR_ROBOT_TOKEN: [Robot Token]

before_script:
  - docker login $HARBOR_REGISTRY -u $HARBOR_ROBOT_USER -p $HARBOR_ROBOT_TOKEN

build:
  script:
    - docker build -t $HARBOR_REGISTRY/$HARBOR_PROJECT/my-app:$CI_COMMIT_SHA .
    - docker push $HARBOR_REGISTRY/$HARBOR_PROJECT/my-app:$CI_COMMIT_SHA
```

## 보안 정책 설정

### 1. 취약점 스캔 정책
```yaml
# 프로젝트별 스캔 정책
Scan Policy:
  - Scan on push: Enabled
  - Prevent vulnerable images from running: Enabled
  - Severity threshold: High
```

### 2. 이미지 서명 정책
```yaml
Content Trust:
  - Enable content trust: true
  - Prevent unsigned images: true
```

### 3. 이미지 보존 정책
```yaml
Tag Retention Policy:
  - Keep last 10 tags
  - Keep tags matching: v*
  - Exclude tags matching: latest, dev-*
```

## 모니터링 및 감사

### 프로젝트 사용량 모니터링
```bash
# API를 통한 프로젝트 통계 조회
curl -X GET "${HARBOR_URL}/api/v2.0/projects/${PROJECT_NAME}/summary" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"
```

### 감사 로그 확인
Harbor UI → **Administration** → **Audit Log**에서 프로젝트별 활동 확인

## 백업 및 복구

### 프로젝트 메타데이터 백업
```bash
#!/bin/bash
# backup-harbor-projects.sh

HARBOR_URL="https://harbor.example.com"
BACKUP_DIR="/backup/harbor/$(date +%Y%m%d)"

mkdir -p $BACKUP_DIR

# 모든 프로젝트 목록 백업
curl -X GET "${HARBOR_URL}/api/v2.0/projects" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  > "${BACKUP_DIR}/projects.json"

# 각 프로젝트의 멤버 정보 백업
for project in $(jq -r '.[].name' "${BACKUP_DIR}/projects.json"); do
  curl -X GET "${HARBOR_URL}/api/v2.0/projects/${project}/members" \
    -H "Authorization: Bearer ${ACCESS_TOKEN}" \
    > "${BACKUP_DIR}/${project}-members.json"
done
```

## 다음 단계
- [Harbor 고급 설정](./advanced-configuration.md)
- [CI/CD 파이프라인 연동](./cicd-integration.md)
- [모니터링 및 알림 설정](./monitoring.md)