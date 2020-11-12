# Note
Currently, this tool only support pulling image from AWS ECR and public image repositories.

# Build docker image
```
docker build -t <image_tag>
```

# How to use
## Prerequisites
An AWS IAM role which will be associated with a K8s service account. This role must have permissions to pull image from all of the ECR repository you store your images.
For more information: https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html
## K8s RBAC resources
K8s RBAC so that the container can get all of the images name from all of the K8s deployments
```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: k8s-prepull-image-clusterrole
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "watch", "list"]

---
apiVersion: v1
kind: ServiceAccount
metadata:
  namespace: kube-system
  name: k8s-prepull-image-serviceaccount
  annotations:
    eks.amazonaws.com/role-arn: <AWS_IAM_Role_ARN>

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: k8s-prepull-image-clusterrolebinding
subjects:
- kind: ServiceAccount
  name: k8s-prepull-image-serviceaccount
  namespace: kube-system
roleRef:
  kind: ClusterRole
  name: k8s-prepull-image-clusterrole
  apiGroup: rbac.authorization.k8s.io
```
## K8s daemonset
The container must be used in a daemonset, so that all nodes can perform image pre-pulling
```
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: prepull-image
  namespace: kube-system
  labels:
    k8s-app: prepull-image
spec:
  selector:
    matchLabels:
      name: prepull-image
  template:
    metadata:
      labels:
        name: prepull-image
    spec:
      serviceAccountName: k8s-prepull-image-serviceaccount
      securityContext:
        fsGroup: 1000
      containers:
      - name: prepull-image
        image: onlysea212/k8s-prepull-image:latest
        env:
          - name: AWS_REGION
            value: ap-southeast-1
          - name: SLEEP_SECONDS
            value: 10
        securityContext:
          privileged: true
        resources:
          limits:
            memory: 500Mi
          requests:
            cpu: 100m
            memory: 500Mi
        volumeMounts:
        - name: varlibdocker
          mountPath: /var/lib/docker
        - name: varrundocker
          mountPath: /var/run/docker.sock
          subPath: docker.sock
      terminationGracePeriodSeconds: 30
      volumes:
      - name: varlibdocker
        hostPath:
          path: /var/lib/docker
      - name: varrundocker
        hostPath:
          path: /var/run/
```
You should adjust AWS_REGION and SLEEP_SECONDS according to your need.
Currently, the script will check and pull image periodically with a period of SLEEP_SECONDS seconds (not event-based). AWS_REGION is the region of the ECR repos.
You can also add nodeSelector so that the pod only run on the nodes you choose.
