#!/bin/bash
# sed -i 's/kubectl/microk8s kubectl/g' test.sh
app_sync_job=khjcghcjhgkgiyvjhvh
git_sensor=
kubelink=
kubewatch=
lens=
dashboard=
devtron=
image_scanner=
ci_runner=
argocd_dex=

echo "========RUNNING MIGRATION==================="

echo "DO YOU WANT TO RUN MIGRATION  -:"

echo "1.FROM MAIN BRANCH"
echo "2.NO-MIGRATION-ONLY-IMAGE-CHNAGE"



echo "NOTE-:for custom branch your git repo and branch and hash required "
echo  -e "\n\n"

while true; do
    echo "PLEASE ENTER 1 or 2-: "
    read input

    if [ "$input" = "1" ] || [ "$input" = "2" ] || [ "$input" = "3" ] ; then
        break
    else
        echo -e "Invalid input. Please enter 1 or 2 or 3. \U0001F620"
    fi
done

echo "You entered: $input"



if [[ $input == 1 ]]; then

    echo "running migration form main"
    echo "now getting the latest hash from git"
    custom_gitrepo="https://github.com/devtron-labs/devtron.git"
    custom_branch="main"
    sudo snap install jq
    main_hash=$(curl -s https://api.github.com/repos/devtron-labs/devtron/commits/main | jq -r '.sha')
    custom_hash=$main_hash
    echo $input
elif [[$input ==2 ]]; then 
    echo "please enter your custom git repo-:"
    read custom_gitrepo
    echo "please enter your branch-:"
    read custom_branch
    echo "please enter your hash-:"
    read custom_hash
else 
    echo "SKIPPING MIGRATION ONLY WILL BE CHANGE THE IMAGE OF MICROSERVICES"
fi
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



echo "============================================\n"
devtron_image=""
while [ -z "$devtron_image" ]
do
    echo "=====Please enter the devtron Image-:====="
    read devtron_image
done
kubectl set image deploy/devtron -n devtroncd devtron=$devtron_image 


echo "==========================================\n"
dashboard_image=""
while [ -z "$dashboard_image" ]
do
    echo "=====Please enter the enterprise-dashboard Image-:====="
    read dashboard_image

done

kubectl set image deploy/dashboard -n devtroncd dashboard=$dashboard_image 



echo -e "\e[32m=====================  \U0001F64F\U0001F604  YOU ARE SUCESSFULLY SYNC with MAIN    \U0001F604\U0001F64F  =================\e[0m"
