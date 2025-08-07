# SonarQube 실습

## 📋 실습 개요
- **목표**: EKS 클러스터에 SonarQube 설치 및 코드 품질 분석 실습
- **환경**: AWS EKS, Helm, PostgreSQL
- **도메인**: sonarqube.bluesunnywings.com

## 🛠️ 실습 1: SonarQube 설치

### 1-1. Helm Repository 추가
```bash
helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
helm repo update
```

### 1-2. 네임스페이스 생성
```bash
kubectl create namespace sonarqube
```

### 1-3. SonarQube 설정 파일 생성
`sonarqube/override-values.yaml` 파일 생성:
```yaml
---
ingress:
  enabled: true
  ingressClassName: alb
  hosts:
    - name: sonarqube.bluesunnywings.com
      path: /
  annotations:
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/group.name: common-ingress
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}, {"HTTPS":443}]'
    alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:ap-northeast-2:219967435143:certificate/5d011410-cf0a-4412-94fd-9482bed70ef8"
    external-dns.alpha.kubernetes.io/hostname: "sonarqube.bluesunnywings.com"

postgresql:
  enabled: true
  auth:
    postgresPassword: "sonarqube123"
    database: "sonarqube"
  primary:
    persistence:
      enabled: true
      size: 8Gi

persistence:
  enabled: true
  size: 10Gi

resources:
  requests:
    memory: "2Gi"
    cpu: "1000m"
  limits:
    memory: "4Gi"
    cpu: "2000m"
```

### 1-4. SonarQube 설치
```bash
helm install sonarqube sonarqube/sonarqube -n sonarqube -f sonarqube/override-values.yaml
```

### 1-5. 설치 상태 확인
```bash
kubectl get pods -n sonarqube
kubectl get svc -n sonarqube
kubectl get ingress -n sonarqube
```

## 🔍 실습 2: SonarQube 접속 및 초기 설정

### 2-1. SonarQube 웹 UI 접속
- **URL**: https://sonarqube.bluesunnywings.com
- **초기 계정**: admin / admin

### 2-2. 관리자 비밀번호 변경
1. 로그인 후 비밀번호 변경 프롬프트 확인
2. 새 비밀번호 설정: `Cccrcabta04!`

### 2-3. 프로젝트 생성
1. **Create Project** 클릭
2. **Project Key**: `spring-petclinic`
3. **Display Name**: `spring-petclinic`
4. **Create** 클릭

## 📊 실습 3: 코드 분석 실습

### 3-1. 분석 토큰 생성
1. **My Account** → **Security** 탭
2. **Generate Tokens**
3. **Token Name**: `spring-petclinic`
4. **Generate** 클릭 후 토큰 복사

### 3-2. 샘플 프로젝트 기존 petclinic 사용
```bash
저장소: https://github.com/Jiwon-sim/spring-petclinic.git
```

### 3-3. 분석 결과 확인
1. SonarQube 웹 UI에서 프로젝트 확인
2. **Issues**, **Security Hotspots**, **Coverage** 탭 확인
3. **Code Smells**, **Bugs**, **Vulnerabilities** 분석

![image.png](attachment:0c7ee48d-3940-4721-8778-6f54beed2c3b:image.png)


## 🚀 CI/CD 통합 (GitHub Actions 연동)

### GitHub Repository Secrets 설정
1. GitHub Repository → **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret** 클릭
3. **SONAR_TOKEN**: SonarQube에서 생성한 토큰 값
4. **SONAR_HOST_URL**: `https://sonarqube.bluesunnywings.com`

### GitHub Actions Workflow 생성
`.github/workflows/build.yml` 파일 생성:
```yaml
name: Build

on:
  push:
    branches:
      - main


jobs:
  build:
    name: Build and analyze
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Shallow clones should be disabled for a better relevancy of analysis
      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: 17
          distribution: 'zulu' # Alternative distribution options are available.
      - name: Cache SonarQube packages
        uses: actions/cache@v4
        with:
          path: ~/.sonar/cache
          key: ${{ runner.os }}-sonar
          restore-keys: ${{ runner.os }}-sonar
      - name: Cache Gradle packages
        uses: actions/cache@v4
        with:
          path: ~/.gradle/caches
          key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle') }}
          restore-keys: ${{ runner.os }}-gradle
      - name: Build and analyze
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
        run: ./gradlew build sonar --info
```

```

## 📈 분석 결과 해석

### 주요 메트릭 이해
- **Bugs**: 실제 버그로 이어질 수 있는 코드 이슈
- **Vulnerabilities**: 보안 취약점
- **Code Smells**: 코드 품질 이슈
- **Coverage**: 테스트 커버리지
- **Duplications**: 중복 코드 비율

### 이슈 분류 및 우선순위
1. **Blocker**: 즉시 수정 필요
2. **Critical**: 높은 우선순위
3. **Major**: 중간 우선순위
4. **Minor**: 낮은 우선순위
5. **Info**: 정보성

### 기술 부채 관리
- **Technical Debt**: 수정에 필요한 예상 시간
- **Debt Ratio**: 전체 코드 대비 기술 부채 비율
- **SQALE Rating**: 유지보수성 등급

## 🧹 리소스 정리

### SonarQube 삭제
```bash
helm uninstall sonarqube -n sonarqube
```

### PVC 삭제
```bash
kubectl delete pvc --all -n sonarqube
```

### 네임스페이스 삭제
```bash
kubectl delete namespace sonarqube
```

## 📝 실습 정리

### 학습한 내용
- ✅ SonarQube 설치 및 설정
- ✅ 코드 품질 분석 실행
- ✅ Quality Gate 설정
- ✅ CI/CD 파이프라인 통합
- ✅ 분석 결과 해석 및 활용

### 주요 명령어
```bash
# SonarQube 설치
helm install sonarqube sonarqube/sonarqube -n sonarqube -f override-values.yaml

# 상태 확인
kubectl get all -n sonarqube

# Maven 분석
mvn sonar:sonar -Dsonar.projectKey=project -Dsonar.host.url=URL -Dsonar.login=TOKEN

# 리소스 정리
helm uninstall sonarqube -n sonarqube
kubectl delete pvc --all -n sonarqube
kubectl delete namespace sonarqube
```

### 다음 단계
- 실제 프로젝트에 SonarQube 적용
- 팀 내 코드 품질 기준 수립
- 지속적인 코드 품질 모니터링 체계 구축
