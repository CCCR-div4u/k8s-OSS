# 사전 준비: Prometheus + Grafana 설치

옵션 2는 기존 Prometheus/Grafana가 설치되어 있다는 전제하에 진행됩니다.
만약 아무것도 설치되어 있지 않다면, 먼저 다음 명령어로 기본 모니터링 스택을 설치해주세요.

## 🚀 기본 Prometheus 스택 설치

### 1. Helm 리포지토리 추가
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

### 2. 네임스페이스 생성
```bash
kubectl create namespace monitoring
```

### 3. Prometheus Stack 설치
```bash
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName=gp3 \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi \
  --set grafana.persistence.enabled=true \
  --set grafana.persistence.storageClassName=gp3 \
  --set grafana.persistence.size=5Gi \
  --set grafana.adminPassword=admin123! \
  --timeout 10m \
  --wait
```

### 4. Ingress 생성 (기본 모니터링용)
```bash
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus-grafana-ingress
  namespace: monitoring
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80,"HTTPS":443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:ap-northeast-2:219967435143:certificate/5d011410-cf0a-4412-94fd-9482bed70ef8
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/backend-protocol: HTTP
spec:
  ingressClassName: alb
  rules:
    - host: prometheus.bluesunnywings.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: prometheus-kube-prometheus-prometheus
                port:
                  number: 9090
    - host: grafana.bluesunnywings.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: prometheus-grafana
                port:
                  number: 80
EOF
```

### 5. 설치 확인
```bash
# 파드 상태 확인
kubectl get pods -n monitoring

# 서비스 확인
kubectl get svc -n monitoring

# Ingress 확인
kubectl get ingress -n monitoring
```

### 6. 접속 정보
- **Prometheus**: https://prometheus.bluesunnywings.com
- **Grafana**: https://grafana.bluesunnywings.com
  - Username: `admin`
  - Password: `admin123!`

## ✅ 설치 완료 후

기본 Prometheus 스택이 정상적으로 설치되면, 이제 옵션 2의 `deploy.sh` 스크립트를 실행하여 Loki와 Tempo를 추가할 수 있습니다.

```bash
cd ../scripts
./deploy.sh
```

## 🧹 전체 정리 시 (Terraform destroy 전)

기본 Prometheus 스택까지 모두 정리하려면:

```bash
# 1. LGTM 구성 요소 정리
./cleanup.sh

# 2. 기본 Prometheus 스택 정리
kubectl delete ingress prometheus-grafana-ingress -n monitoring
helm uninstall prometheus -n monitoring
kubectl delete namespace monitoring
```