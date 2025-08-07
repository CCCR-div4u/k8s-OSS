# Harbor 설치 및 테스트 가이드

## 1. Harbor 설치

### Helm Repository 추가
```bash
helm repo add harbor https://helm.goharbor.io
helm repo update
```

### Harbor 네임스페이스 생성
```bash
kubectl create namespace harbor
```

### Harbor 설치
```bash
helm install harbor harbor/harbor -n harbor -f harbor/override-values.yaml
```

## 2. Harbor 설정 파일 (override-values.yaml)

```yaml
---
expose:
  type: ingress
  tls:
    enabled: true
  ingress:
    hosts:
      core: harbor.bluesunnywings.com
    controller: "alb"
    className: "alb"
    annotations:
      alb.ingress.kubernetes.io/target-type: ip
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/group.name: common-ingress
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}, {"HTTPS":443}]'
      alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:ap-northeast-2:219967435143:certificate/5d011410-cf0a-4412-94fd-9482bed70ef8"
      external-dns.alpha.kubernetes.io/hostname: "harbor.bluesunnywings.com"

externalURL: https://harbor.bluesunnywings.com
harborAdminPassword: "Cccrcabta04!"
```

## 3. Docker 이미지 Push & Pull 테스트

### Docker 로그인
```bash
docker login harbor.bluesunnywings.com
# Username: admin
# Password: Cccrcabta04!
```

### 테스트 이미지 태그 및 Push
```bash
# 기존 이미지 태그
docker tag nginx:latest harbor.bluesunnywings.com/library/nginx:latest

# Harbor에 Push
docker push harbor.bluesunnywings.com/library/nginx:latest
```

### 이미지 Pull 테스트
```bash
# 로컬 이미지 삭제
docker rmi harbor.bluesunnywings.com/library/nginx:latest

# Harbor에서 Pull
docker pull harbor.bluesunnywings.com/library/nginx:latest
```

## 4. Kubernetes에서 Harbor 이미지 사용

### Docker Registry Secret 생성
```bash
kubectl create secret docker-registry harbor-secret \
  --docker-server=harbor.bluesunnywings.com \
  --docker-username=admin \
  --docker-password=Cccrcabta04! \
  --docker-email=admin@example.com \
  -n default
```

### nginx-harbor 애플리케이션 배포

#### Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-harbor
  namespace: harbor
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-harbor
  template:
    metadata:
      labels:
        app: nginx-harbor
    spec:
      containers:
      - name: nginx
        image: harbor.bluesunnywings.com/library/nginx:latest
        ports:
        - containerPort: 80
      imagePullSecrets:
      - name: harbor-secret
```

#### Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-harbor-service
  namespace: harbor
spec:
  selector:
    app: nginx-harbor
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
```

#### Ingress
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-harbor-ingress
  namespace: harbor
  annotations:
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/group.name: common-ingress
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}, {"HTTPS":443}]'
    alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:ap-northeast-2:219967435143:certificate/5d011410-cf0a-4412-94fd-9482bed70ef8"
    external-dns.alpha.kubernetes.io/hostname: "nginx-harbor.bluesunnywings.com"
spec:
  ingressClassName: alb
  rules:
    - host: nginx-harbor.bluesunnywings.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nginx-harbor-service
                port:
                  number: 80
```

## 5. 배포 및 확인

### 애플리케이션 배포
```bash
kubectl apply -f nginx-harbor/
```

### 상태 확인
```bash
kubectl get pods -n harbor
kubectl get svc -n harbor
kubectl get ingress -n harbor
```

## 6. 접속 확인

- **Harbor UI**: https://harbor.bluesunnywings.com
- **nginx-harbor 앱**: https://nginx-harbor.bluesunnywings.com

## 7. 리소스 정리

### Harbor 애플리케이션 삭제
```bash
kubectl delete -f nginx-harbor/
```

### Harbor Helm 릴리스 삭제
```bash
helm uninstall harbor -n harbor
```

### PVC 삭제
```bash
kubectl delete pvc --all -n harbor
```

### 네임스페이스 삭제
```bash
kubectl delete namespace harbor
```

## 주요 특징

- **AWS ALB Ingress Controller** 사용
- **External DNS**로 자동 DNS 레코드 생성
- **ACM 인증서**로 HTTPS 지원
- **Harbor Private Registry**에서 이미지 관리
- **ImagePullSecrets**로 Private Registry 인증
