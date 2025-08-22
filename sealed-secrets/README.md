# 🔐 Sealed Secrets 설치 가이드

쿠버네티스 Secret을 안전하게 관리하기 위해 **Sealed Secrets**를 설치하는 방법을 정리했습니다.  
본 문서는 **Helm + values.yaml**을 활용하여 운영 환경에 적합한 설정을 적용하는 핸즈온 가이드입니다.  

---

## 1. Helm Repo 추가

```bash
helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
helm repo update
```

---

## 2. sealed-secrets-values.yaml

sealed-secrets-values.yaml 파일을 작성합니다.
운영환경을 고려한 예시 파일이 작성되어 있습니다.

---

## 3. 설치 / 업그레이드

```bash
helm upgrade --install sealed-secrets sealed-secrets/sealed-secrets \
  --namespace kube-system \
  --create-namespace \
  -f sealed-secrets-values.yaml
```
- --install : 최초 설치 시 사용
- upgrade : 이미 설치되어 있으면 업데이트
- -f sealed-secrets-values.yaml : values 파일 적용

---

## 4. 설치 확인

```bash
kubectl -n kube-system get pods | grep sealed-secrets
```
출력 예시:
```csharp
sealed-secrets-controller-7b9c8c4d9f-xxxxx   1/1   Running   0   30s
```

---

## 5. RSA 키 백업 (중요 ⚠️)

컨트롤러에서 사용하는 RSA 키는 반드시 백업해야 합니다.
키가 손실되면 기존 SealedSecret을 복호화할 수 없습니다.

```bash
kubectl get secret -n kube-system | grep sealed-secrets-key
```

시크릿 이름은 Helm 정책상 sealed-secrets-key 뒤에 랜덤 문자열이 붙어 있는 이름으로 생성되므로 secret 이름을 확인하고 다음 명령어를 실행하세요.

```bash
kubectl -n kube-system get secret sealed-secrets-key{랜덤문자열} -o yaml > sealed-secrets-key-backup.yaml
```
👉 백업 파일은 안전한 스토리지(S3, Vault, 암호화된 Git 리포 등)에 보관하세요.

---

✅ 이제 클러스터에 Sealed Secrets 컨트롤러가 준비되었습니다.
다음 단계에서는 kubeseal CLI를 사용하여 Secret을 SealedSecret으로 변환해 GitOps 워크플로우에 적용할 수 있습니다.

---

# 🔐 SealedSecret 사용 예시
## 1. 일반 Secret 작성

먼저 쿠버네티스 Secret YAML을 작성합니다. (아직 적용하지 마세요)

```yaml
# mysecret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
  namespace: default
type: Opaque
data:
  username: YWRtaW4=   # base64 인코딩된 값
  password: MWYyZDFlMmU2N2Rm
```

---

## 2. SealedSecret 생성

작성한 mysecret.yaml을 kubeseal CLI를 이용해 SealedSecret으로 변환합니다.
```bash
kubeseal \
  --controller-name=sealed-secrets \
  --controller-namespace=kube-system \
  -o yaml < mysecret.yaml > mysealedsecret.yaml
```
생성된 mysealedsecret.yaml에는 민감정보가 암호화되어 들어갑니다.

---

## 3. 생성된 SealedSecret 예시

```yaml
# mysealedsecret.yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: mysecret
  namespace: default
spec:
  encryptedData:
    username: AgByz...EncryptedString...==
    password: AgCFc...EncryptedString...==
```

👉 여기서 encryptedData 값은 컨트롤러의 RSA 공개키로 암호화된 값입니다.
Git 리포지토리에 안전하게 커밋할 수 있습니다.

---

## 4. 클러스터에 적용

```bash
kubectl apply -f mysealedsecret.yaml
```

적용하면 컨트롤러가 자동으로 일반 Secret(mysecret)을 복호화하여 생성합니다.

---

## 5. Secret 확인

```bash
kubectl get secret mysecret -n default
kubectl get secret mysecret -n default -o yaml
```

출력 예시:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
  namespace: default
type: Opaque
data:
  username: YWRtaW4=
  password: MWYyZDFlMmU2N2Rm
```

---

✅ 정리

Secret → kubeseal → SealedSecret

GitOps 저장소에는 SealedSecret만 저장

컨트롤러가 자동으로 원본 Secret 생성

