# Kube-bench - Kubernetes CIS 벤치마크 보안 검사

이 디렉터리는 Kubernetes 클러스터의 CIS (Center for Internet Security) 벤치마크 준수 여부를 검사하는 kube-bench 도구의 설치 및 실행 가이드를 제공합니다.

## 📋 개요

Kube-bench는 Kubernetes 클러스터가 CIS Kubernetes Benchmark에서 정의한 보안 권장사항을 준수하는지 확인하는 도구입니다. 이 도구는 마스터 노드, 워커 노드, etcd, 그리고 관리형 서비스에 대한 보안 검사를 수행합니다.

## 📁 디렉터리 구조

```
kube-bench/
├── README.md                    # 이 파일
├── AUTOMATED_SCAN_SETUP.md     # 🆕 자동화 스캔 설정 가이드
├── installation/
│   ├── job-eks.yaml            # EKS용 kube-bench Job
│   ├── job-master.yaml         # 마스터 노드용 Job
│   ├── job-node.yaml           # 워커 노드용 Job
│   ├── cronjob-scheduled.yaml  # 스케줄된 CronJob
│   ├── daemonset-monitor.yaml  # 지속적 모니터링용 DaemonSet
│   └── installation-guide.md   # 설치 가이드
├── configs/
│   ├── config-eks.yaml         # EKS 전용 설정
│   ├── config-custom.yaml      # 커스텀 설정
│   └── remediation-guide.md    # 수정 가이드
├── scripts/
│   ├── run-benchmark.sh        # 벤치마크 실행 스크립트
│   ├── collect-results.sh      # 결과 수집 스크립트
│   └── generate-report.sh      # 보고서 생성 스크립트
└── results/
    └── .gitkeep                # 결과 파일 저장 디렉터리
```

## 🚀 빠른 시작

### 🤖 자동화된 보안 검사 (권장)

**GitHub Actions를 통한 완전 자동화된 보안 검사**

```bash
# 1. 설정 가이드 확인
cat AUTOMATED_SCAN_SETUP.md

# 2. 워크플로우 테스트
../scripts/test-kube-bench-workflow.sh -c your-cluster-name

# 3. GitHub Actions에서 자동 실행 (매일 오전 9시)
# 또는 수동으로 워크플로우 실행
```

**주요 기능:**
- ⏰ 매일 자동 실행 (스케줄 조정 가능)
- 📊 상세 보안 보고서 자동 생성
- 🚨 GitHub Issues로 결과 보고
- 📱 Slack 알림 지원
- 📁 결과 아티팩트 장기 보관

### 🔧 수동 실행

#### 1. EKS 클러스터에서 실행
```bash
# EKS용 kube-bench Job 실행
kubectl apply -f installation/job-eks.yaml

# 결과 확인
kubectl logs job/kube-bench-eks
```

#### 2. 일반 Kubernetes 클러스터에서 실행
```bash
# 마스터 노드 검사
kubectl apply -f installation/job-master.yaml

# 워커 노드 검사  
kubectl apply -f installation/job-node.yaml
```

#### 3. 스크립트를 통한 실행
```bash
# 전체 벤치마크 실행
./scripts/run-benchmark.sh

# 결과 수집
./scripts/collect-results.sh

# 보고서 생성
./scripts/generate-report.sh
```

## 🔍 주요 검사 항목

### **마스터 노드 검사**
- API 서버 보안 설정
- Controller Manager 설정
- Scheduler 설정
- etcd 보안 설정

### **워커 노드 검사**
- Kubelet 보안 설정
- 컨테이너 런타임 설정
- 네트워크 정책
- 파일 권한 및 소유권

### **EKS 특화 검사**
- 관리형 서비스 보안 설정
- IAM 역할 및 정책
- 네트워크 보안 그룹
- 로깅 및 모니터링

## 📊 결과 해석

### **검사 결과 등급**
- **PASS**: 권장사항을 준수함
- **FAIL**: 권장사항을 준수하지 않음
- **WARN**: 수동 확인이 필요함
- **INFO**: 정보성 메시지

### **우선순위**
1. **FAIL** 항목 우선 수정
2. **WARN** 항목 검토 및 필요시 수정
3. **INFO** 항목 참고

## 🔧 수정 가이드

각 실패 항목에 대한 수정 방법은 다음 문서를 참조하세요:
- [수정 가이드](configs/remediation-guide.md)
- [EKS 특화 설정](configs/config-eks.yaml)

## 📋 요구사항

- Kubernetes 클러스터 (v1.15+)
- kubectl 명령어 도구
- 클러스터 관리자 권한

## 🌐 참고 자료

- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [Kube-bench GitHub](https://github.com/aquasecurity/kube-bench)
- [Kubernetes 보안 가이드](https://kubernetes.io/docs/concepts/security/)

## 📞 지원

문제가 발생하면 다음을 확인해주세요:
1. 클러스터 권한 확인
2. kube-bench 버전 호환성
3. 네트워크 정책 설정
4. 로그 메시지 분석