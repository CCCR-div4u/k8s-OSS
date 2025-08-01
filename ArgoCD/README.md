# ArgoCD Deploy via Helm on EKS
---
## **1. ArgoCD 설치**

---

**1) argocd 네임스페이스 생성**

```bash
kubectl create ns argocd
```

**2) Helm Repo 추가 및 다운로드**

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```

- Helm chart 저장소(argo)를 추가하는 명령어.
- Helm이 해당 URL에서 chart 목록을 가져올 수 있게 등록

```bash
helm pull argo/argo-cd --version 7.7.17
```

- Helm chart를 다운로드(pull)하는 명령어.
- `argo` 저장소에서 `argo-cd` chart를 7.7.17 버전으로 받아옴.
- 압축된 `.tgz` 파일로 저장

```bash
tar xvzf argo-cd-7.7.17.tgz
```

- 압축(`.tgz`) 풀기 명령어
- 풀면 chart 디렉토리(`argo-cd/`) 생긴다.

```bash
cd argo-cd
```
**3) ACM 인증서 ARN 확인**

```basg
aws acm list-certificates --query "CertificateSummaryList[?DomainName=='bluesunnywings.com'].CertificateArn" --output text
```

- 출력 결과는 도메인 주소의 ARN

**4) Values 파일 작성**

```bash
vi my-values.yaml
```

- 이전 단계에서 ACM 인증서

**5) Helm으로 ArgoCD 설치**

```bash
helm install argocd --namespace argocd -f new-values.yaml .
```

**6) 설치 확인**

```bash
kubectl get pods -n argocd
kubectl get svc -n argocd
```

**7) 도메인 주소 접속**
<img width="910" height="743" alt="image" src="https://github.com/user-attachments/assets/48517fad-0402-4401-9f5f-0ad4e56833f3" />


**8) 초기 비밀번호 확인**
```bash
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d; echo
```

**9) 로그인**
- username: admin
- password: 8에서 확인한 초기 비밀번호
<img width="910" height="743" alt="image" src="https://github.com/user-attachments/assets/1138a394-c4c3-4b4d-ad70-05fac023ef57" />
