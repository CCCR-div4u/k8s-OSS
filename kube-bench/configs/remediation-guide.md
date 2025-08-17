# Kube-bench 수정 가이드

이 문서는 kube-bench 보안 검사에서 발견된 문제들을 수정하는 방법을 제공합니다.

## 🔧 일반적인 수정 방법

### 1. API Server 보안 설정

#### 1.2.1 - Anonymous Auth 비활성화
```yaml
# kube-apiserver 설정
spec:
  containers:
  - command:
    - kube-apiserver
    - --anonymous-auth=false
```

#### 1.2.2 - Basic Auth 비활성화
```yaml
# kube-apiserver 설정
spec:
  containers:
  - command:
    - kube-apiserver
    # --basic-auth-file 옵션 제거
```

#### 1.2.3 - Token Auth 비활성화
```yaml
# kube-apiserver 설정
spec:
  containers:
  - command:
    - kube-apiserver
    # --token-auth-file 옵션 제거
```

#### 1.2.4 - Kubelet HTTPS 활성화
```yaml
# kube-apiserver 설정
spec:
  containers:
  - command:
    - kube-apiserver
    - --kubelet-https=true
```

#### 1.2.5 - Kubelet 클라이언트 인증서 설정
```yaml
# kube-apiserver 설정
spec:
  containers:
  - command:
    - kube-apiserver
    - --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt
    - --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key
```

### 2. Controller Manager 보안 설정

#### 1.3.1 - 서비스 어카운트 개인 키 설정
```yaml
# kube-controller-manager 설정
spec:
  containers:
  - command:
    - kube-controller-manager
    - --service-account-private-key-file=/etc/kubernetes/pki/sa.key
```

#### 1.3.2 - Root CA 파일 설정
```yaml
# kube-controller-manager 설정
spec:
  containers:
  - command:
    - kube-controller-manager
    - --root-ca-file=/etc/kubernetes/pki/ca.crt
```

#### 1.3.3 - 서비스 어카운트 자격 증명 사용
```yaml
# kube-controller-manager 설정
spec:
  containers:
  - command:
    - kube-controller-manager
    - --use-service-account-credentials=true
```

### 3. Scheduler 보안 설정

#### 1.4.1 - 프로파일링 비활성화
```yaml
# kube-scheduler 설정
spec:
  containers:
  - command:
    - kube-scheduler
    - --profiling=false
```

#### 1.4.2 - 바인드 주소 설정
```yaml
# kube-scheduler 설정
spec:
  containers:
  - command:
    - kube-scheduler
    - --bind-address=127.0.0.1
```

### 4. etcd 보안 설정

#### 2.1 - 클라이언트 인증서 인증 활성화
```yaml
# etcd 설정
spec:
  containers:
  - command:
    - etcd
    - --client-cert-auth=true
```

#### 2.2 - 자동 TLS 비활성화
```yaml
# etcd 설정
spec:
  containers:
  - command:
    - etcd
    - --auto-tls=false
```

#### 2.3 - 피어 클라이언트 인증서 인증 활성화
```yaml
# etcd 설정
spec:
  containers:
  - command:
    - etcd
    - --peer-client-cert-auth=true
```

### 5. Kubelet 보안 설정

#### 4.2.1 - Anonymous Auth 비활성화
```yaml
# kubelet 설정 (/var/lib/kubelet/config.yaml)
authentication:
  anonymous:
    enabled: false
```

#### 4.2.2 - Authorization Mode 설정
```yaml
# kubelet 설정
authorization:
  mode: Webhook
```

#### 4.2.3 - 클라이언트 CA 파일 설정
```yaml
# kubelet 설정
authentication:
  x509:
    clientCAFile: /etc/kubernetes/pki/ca.crt
```

#### 4.2.4 - Read-only Port 비활성화
```yaml
# kubelet 설정
readOnlyPort: 0
```

#### 4.2.5 - 스트리밍 연결 유휴 시간 초과 설정
```yaml
# kubelet 설정
streamingConnectionIdleTimeout: 4h0m0s
```

#### 4.2.6 - 보호 커널 기본값 설정
```yaml
# kubelet 설정
protectKernelDefaults: true
```

#### 4.2.7 - Make iptables util chains 설정
```yaml
# kubelet 설정
makeIPTablesUtilChains: true
```

#### 4.2.8 - Hostname Override 비활성화
```yaml
# kubelet 설정에서 --hostname-override 제거
```

#### 4.2.9 - Event QPS 설정
```yaml
# kubelet 설정
eventRecordQPS: 0
```

#### 4.2.10 - TLS 인증서 파일 설정
```yaml
# kubelet 설정
tlsCertFile: /var/lib/kubelet/pki/kubelet.crt
tlsPrivateKeyFile: /var/lib/kubelet/pki/kubelet.key
```

#### 4.2.11 - 인증서 회전 활성화
```yaml
# kubelet 설정
rotateCertificates: true
```

#### 4.2.12 - RotateKubeletServerCertificate 활성화
```yaml
# kubelet 설정
serverTLSBootstrap: true
```

## 🛡️ EKS 특화 수정 방법

### 1. EKS 클러스터 로깅 활성화
```bash
# AWS CLI를 통한 로깅 활성화
aws eks update-cluster-config \
  --region us-west-2 \
  --name my-cluster \
  --logging '{"enable":[{"types":["api","audit","authenticator","controllerManager","scheduler"]}]}'
```

### 2. EKS 클러스터 엔드포인트 접근 제한
```bash
# 프라이빗 엔드포인트만 활성화
aws eks update-cluster-config \
  --region us-west-2 \
  --name my-cluster \
  --resources-vpc-config endpointConfigPrivateAccess=true,endpointConfigPublicAccess=false
```

### 3. EKS 노드 그룹 보안 설정
```yaml
# EKS 노드 그룹 설정
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig
metadata:
  name: my-cluster
  region: us-west-2

nodeGroups:
  - name: worker-nodes
    instanceType: m5.large
    desiredCapacity: 2
    ssh:
      allow: false  # SSH 접근 비활성화
    iam:
      withAddonPolicies:
        imageBuilder: false
        autoScaler: true
        externalDNS: true
        certManager: true
        appMesh: false
        ebs: true
        fsx: false
        efs: true
```

## 📋 네트워크 정책 설정

### 1. 기본 거부 정책
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

### 2. DNS 허용 정책
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-access
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to: []
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
```

## 🔒 Pod Security Standards

### 1. Pod Security Policy (PSP) - Deprecated
```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
```

### 2. Pod Security Standards (PSS) - Recommended
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: secure-namespace
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

## 🔧 자동화된 수정 스크립트

### 1. Kubelet 설정 자동 수정
```bash
#!/bin/bash
# kubelet-security-fix.sh

KUBELET_CONFIG="/var/lib/kubelet/config.yaml"

# 백업 생성
cp $KUBELET_CONFIG ${KUBELET_CONFIG}.backup

# 보안 설정 적용
cat >> $KUBELET_CONFIG << EOF
authentication:
  anonymous:
    enabled: false
  webhook:
    enabled: true
authorization:
  mode: Webhook
readOnlyPort: 0
protectKernelDefaults: true
makeIPTablesUtilChains: true
streamingConnectionIdleTimeout: 4h0m0s
eventRecordQPS: 0
rotateCertificates: true
serverTLSBootstrap: true
EOF

# kubelet 재시작
systemctl restart kubelet
```

### 2. 네트워크 정책 자동 적용
```bash
#!/bin/bash
# apply-network-policies.sh

kubectl apply -f - << EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-access
  namespace: default
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to: []
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
EOF
```

## 📚 참고 자료

- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [AWS EKS Security Best Practices](https://aws.github.io/aws-eks-best-practices/security/docs/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)