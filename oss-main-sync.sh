#!/bin/bash
# sed -i 's/kubectl/microk8s kubectl/g' test.sh
app_sync_job=quay.io/devtron/chart-sync:65186dca-373-20979
git_sensor=quay.io/devtron/test:602eaeab-536-21035
kubelink=quay.io/devtron/kubelink:2dbe99a8-538-18986
kubewatch=quay.io/devtron/kubewatch:8d517c0d-539-20644
lens=quay.io/devtron/lens:70577aaa-540-20989
dashboard=quay.io/devtron/dashboard:2c0c6b21-537-21060
devtron=quay.io/devtron/devtron:cb60db06-534-21063
image_scanner=quay.io/devtron/image-scanner:3bc0c200-559-20980
ci_runner=quay.io/devtron/ci-runner:4de9e75c-541-20975

# Print the values
echo "app-sync-job: $app_sync_job"
echo "git-sensor: $git_sensor"
echo "kubelink: $kubelink"
echo "kubewatch: $kubewatch"
echo "lens: $lens"
echo "dashboard: $dashboard"
echo "devtron: $devtron"
echo "image_scanner: $image_scanner"
echo "ci-runner: $ci_runner"

echo "========RUNNING MIGRATION==================="

echo "running migration form main"
echo "now getting the latest hash from git"
custom_gitrepo="https://github.com/devtron-labs/devtron.git"
custom_branch="main"
sudo snap install jq
main_hash=$(curl -s https://api.github.com/repos/devtron-labs/devtron/commits/main | jq -r '.sha')
custom_hash=$main_hash


echo $custom_hash
echo $custom_branch
echo $custom_gitrepo

cat << EOF > migrator.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: postgresql-migrate-enterprise-devtron-$RANDOM
spec:
  template:
    spec:
      securityContext:
        fsGroup: 1000
        runAsGroup: 1000
        runAsUser: 1000
      containers:
      - name: postgresql-migrate-devtron
        image: quay.io/devtron/migrator:ec1dcab8-149-13278
        securityContext:
          allowPrivilegeEscalation: false
          runAsUser: 1000
          runAsNonRoot: true
        env:
        - name: GIT_BRANCH
          value: $custom_branch
        - name: SCRIPT_LOCATION
          value: scripts/sql/
        - name: GIT_REPO_URL
          value: $custom_gitrepo
        - name: DB_TYPE
          value: postgres
        - name: DB_USER_NAME
          value: postgres
        - name: DB_HOST
          value: postgresql-postgresql.devtroncd
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          value: orchestrator                      
        - name: MIGRATE_TO_VERSION
          value: "0"
        - name: GIT_HASH
          value: $custom_hash
        envFrom:
          - secretRef:
              name: postgresql-migrator
      restartPolicy: OnFailure
  backoffLimit: 20
  activeDeadlineSeconds: 1500
---
apiVersion: batch/v1
kind: Job
metadata:
  name: postgresql-migrate-enterprise-casbin-$RANDOM
spec:
  template:
    spec:
      securityContext:
        fsGroup: 1000
        runAsGroup: 1000
        runAsUser: 1000
      serviceAccountName: devtron
      containers:
      - name: devtron-rollout
        image: "quay.io/devtron/kubectl:latest"
        command: ['sh', '-c', 'kubectl rollout restart deployment/devtron -n devtroncd && kubectl rollout restart deployment/kubelink -n devtroncd']
      initContainers:
      - name: postgresql-migrate-casbin
        image: quay.io/devtron/migrator:ec1dcab8-149-13278
        securityContext:
          allowPrivilegeEscalation: false
          runAsUser: 1000
          runAsNonRoot: true
        env:
        - name: SCRIPT_LOCATION
          value: scripts/casbin/
        - name: GIT_REPO_URL
          value: $custom_gitrepo
        - name: DB_TYPE
          value: postgres
        - name: DB_USER_NAME
          value: postgres
        - name: DB_HOST
          value: postgresql-postgresql.devtroncd
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          value: casbin
        - name: MIGRATE_TO_VERSION
          value: "0"
        - name: GIT_HASH
          value: $custom_hash
        - name: GIT_BRANCH
          value: $custom_branch
        envFrom:
          - secretRef:
              name: postgresql-migrator
        resources:
          requests:
            cpu: 0.5
            memory: 500Mi
      restartPolicy: OnFailure
  backoffLimit: 20
  activeDeadlineSeconds: 1500
EOF

kubectl apply -f migrator.yaml -n devtroncd


kubectl patch configmap devtron-custom-cm -n devtroncd --patch "{\"data\": {\"DEFAULT_CI_IMAGE\": \"$ci_runner\"}}"
kubectl patch configmap devtron-custom-cm -n devtroncd --patch "{\"data\": {\"APP_SYNC_IMAGE\": \"$app_sync_job\"}}"

kubectl set image deploy/devtron -n devtroncd devtron=quay.io/devtron/devtron:cb60db06-534-21063
kubectl set image deploy/dashboard -n devtroncd dashboard=quay.io/devtron/dashboard:2c0c6b21-537-21060

kubectl set image deploy/kubewatch -n devtroncd kubewatch=quay.io/devtron/kubewatch:8d517c0d-539-20644
kubectl set image deploy/kubelink -n devtroncd kubelink=quay.io/devtron/kubelink:2dbe99a8-538-18986
kubectl set image deploy/lens -n devtroncd lens=quay.io/devtron/lens:70577aaa-540-20989
kubectl set image sts/git-sensor -n devtroncd git-sensor=$git_sensor
kubectl set image sts/git-sensor -n devtroncd chown-git-base=$git_sensor
kubectl delete po -n devtroncd git-sensor-0
kubectl set image deploy/image-scanner -n devtroncd image-scanner=$image_scanner

kubectl set image cronjob/app-sync-cronjob -n devtroncd chart-sync=$app_sync_job


echo -e "\e[32m=====================  \U0001F64F\U0001F604  YOU ARE SUCESSFULLY SYNC WITH MAIN    \U0001F604\U0001F64F  =================\e[0m"
