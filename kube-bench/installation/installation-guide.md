# Kube-bench 설치 및 실행 가이드

이 가이드는 Kubernetes 클러스터에서 kube-bench를 사용하여 CIS 벤치마크 보안 검사를 수행하는 방법을 설명합니다.

## 📋 사전 요구사항

- Kubernetes 클러스터 (v1.15+)
- kubectl 명령어 도구
- 클러스터 관리자 권한
- 노드에 대한 호스트 레벨 접근 권한

## 🚀 설치 방법

### 1. Job을 통한 실행 (권장)

#### EKS 클러스터
```bash
# EKS 전용 벤치마크 실행
kubectl apply -f job-eks.yaml

# 실행 상태 확인
kubectl get jobs
kubectl get pods

# 결과 확인
kubectl logs job/kube-bench-eks
```

#### 일반 Kubernetes 클러스터
```bash
# 마스터 노드 벤치마크
kubectl apply -f job-master.yaml

# 워커 노드 벤치마크
kubectl apply -f job-node.yaml

# 결과 확인
kubectl logs job/kube-bench-master
kubectl logs job/kube-bench-node
```

### 2. DaemonSet을 통한 실행

모든 노드에서 동시에 실행하려면 DaemonSet을 사용할 수 있습니다:

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: kube-bench
  namespace: default
spec:
  selector:
    matchLabels:
      app: kube-bench
  template:
    metadata:
      labels:
        app: kube-bench
    spec:
      hostPID: true
      containers:
      - name: kube-bench
        image: aquasec/kube-bench:latest
        command: ["kube-bench"]
        args: ["--targets", "node"]
        volumeMounts:
        - name: var-lib-kubelet
          mountPath: /var/lib/kubelet
          readOnly: true
        - name: etc-systemd
          mountPath: /etc/systemd
          readOnly: true
        - name: etc-kubernetes
          mountPath: /etc/kubernetes
          readOnly: true
        - name: usr-bin
          mountPath: /usr/local/mount-from-host/bin
          readOnly: true
      volumes:
      - name: var-lib-kubelet
        hostPath:
          path: "/var/lib/kubelet"
      - name: etc-systemd
        hostPath:
          path: "/etc/systemd"
      - name: etc-kubernetes
        hostPath:
          path: "/etc/kubernetes"
      - name: usr-bin
        hostPath:
          path: "/usr/bin"
      tolerations:
      - operator: Exists
```

### 3. 스크립트를 통한 실행

```bash
# 실행 권한 부여
chmod +x ../scripts/run-benchmark.sh

# EKS 벤치마크 실행
../scripts/run-benchmark.sh -t eks

# 모든 벤치마크 실행 및 정리
../scripts/run-benchmark.sh -t all -c

# 결과 수집
../scripts/collect-results.sh -f html
```

## 🔧 설정 옵션

### 벤치마크 타겟

- `eks`: AWS EKS 전용 벤치마크
- `master`: 마스터/컨트롤 플레인 노드
- `node`: 워커 노드
- `etcd`: etcd 클러스터
- `policies`: 네트워크 정책 및 PSP

### 출력 형식

```bash
# JSON 형식
kube-bench --json

# JUnit XML 형식
kube-bench --junit

# 특정 섹션만 실행
kube-bench --targets master,node

# 특정 검사만 실행
kube-bench --check 1.1.1,1.1.2
```

## 📊 결과 해석

### 검사 결과 상태

- **[PASS]**: 검사 통과 - 권장사항을 준수함
- **[FAIL]**: 검사 실패 - 권장사항을 준수하지 않음
- **[WARN]**: 경고 - 수동 확인이 필요함
- **[INFO]**: 정보 - 참고용 정보

### 예시 출력

```
[INFO] 1 Master Node Security Configuration
[INFO] 1.1 Master Node Configuration Files
[PASS] 1.1.1 Ensure that the API server pod specification file permissions are set to 644 or more restrictive (Automated)
[FAIL] 1.1.2 Ensure that the API server pod specification file ownership is set to root:root (Automated)
[WARN] 1.1.3 Ensure that the controller manager pod specification file permissions are set to 644 or more restrictive (Manual)
```

## 🔒 보안 고려사항

### 권한 요구사항

kube-bench는 다음 권한이 필요합니다:

- 호스트 파일 시스템 읽기 권한
- 프로세스 정보 접근 권한
- Kubernetes API 접근 권한

### 네트워크 정책

kube-bench Pod가 필요한 리소스에 접근할 수 있도록 네트워크 정책을 설정해야 할 수 있습니다.

### 보안 컨텍스트

```yaml
securityContext:
  runAsUser: 0
  runAsGroup: 0
  fsGroup: 0
  privileged: true
```

## 🛠️ 문제 해결

### 일반적인 문제

#### 1. 권한 부족 오류
```bash
# 서비스 어카운트에 필요한 권한 부여
kubectl create clusterrolebinding kube-bench --clusterrole=cluster-admin --serviceaccount=default:default
```

#### 2. 호스트 경로 접근 불가
```bash
# 노드 선택자 확인
kubectl get nodes --show-labels

# 볼륨 마운트 경로 확인
kubectl describe node <node-name>
```

#### 3. Job이 완료되지 않음
```bash
# Job 상태 확인
kubectl describe job kube-bench-eks

# Pod 로그 확인
kubectl logs -l job-name=kube-bench-eks
```

### EKS 특화 문제

#### 1. 관리형 서비스 제한
EKS에서는 일부 마스터 노드 검사가 적용되지 않을 수 있습니다.

#### 2. Fargate 제한
Fargate에서는 호스트 레벨 접근이 제한되므로 일부 검사가 실행되지 않을 수 있습니다.

## 📈 결과 활용

### 1. CI/CD 통합
```yaml
# GitHub Actions 예시
- name: Run Kube-bench
  run: |
    kubectl apply -f kube-bench/installation/job-eks.yaml
    kubectl wait --for=condition=complete job/kube-bench-eks --timeout=300s
    kubectl logs job/kube-bench-eks > kube-bench-results.log
```

### 2. 모니터링 통합
```bash
# Prometheus 메트릭으로 변환
kube-bench --json | jq '.Totals' > metrics.json
```

### 3. 정기 실행
```yaml
# CronJob으로 정기 실행
apiVersion: batch/v1
kind: CronJob
metadata:
  name: kube-bench-scheduled
spec:
  schedule: "0 2 * * 0"  # 매주 일요일 2시
  jobTemplate:
    spec:
      template:
        spec:
          # ... kube-bench job 설정
```

## 📚 참고 자료

- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [Kube-bench GitHub Repository](https://github.com/aquasecurity/kube-bench)
- [AWS EKS Security Best Practices](https://aws.github.io/aws-eks-best-practices/security/docs/)
- [Kubernetes Security Documentation](https://kubernetes.io/docs/concepts/security/)