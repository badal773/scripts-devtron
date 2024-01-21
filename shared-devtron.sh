echo "============Starting migration==================="

cat << 'EOF' > devtron-migration.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: postgresql-migrate-devtron-$RANDOM
  namespace: devtroncd
spec:
  activeDeadlineSeconds: 1500
  backoffLimit: 20
  suspend: false
  template:
    spec:
      imagePullSecrets:
         - name: devtron-image-pull
      containers:
      - command:
        - /bin/sh
        - -c
        - 'if [ "$MIGRATE_TO_VERSION" -eq 0 ]; then migrate -path "$SCRIPT_LOCATION"
               -database postgres://"$DB_USER_NAME":"$DB_PASSWORD"@"$DB_HOST":"$DB_PORT"/"$DB_NAME"?sslmode=disable
               up;  else   echo "$MIGRATE_TO_VERSION"; migrate -path "$SCRIPT_LOCATION"  -database
               postgres://"$DB_USER_NAME":"$DB_PASSWORD"@"$DB_HOST":"$DB_PORT"/"$DB_NAME"?sslmode=disable
               goto "$MIGRATE_TO_VERSION";    fi '
        env:
        - name: SCRIPT_LOCATION
          value: /shared/sql/
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
        envFrom:
        - secretRef:
            name: postgresql-migrator
        image: $migrator
        imagePullPolicy: IfNotPresent
        name: postgresql-migrate-devtron
        resources: {}
        securityContext:
          allowPrivilegeEscalation: false
          runAsNonRoot: true
          runAsUser: 1000
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /shared
          name: shared-volume
      dnsPolicy: ClusterFirst
      initContainers:
      - command:
        - /bin/sh
        - -c
        - cp -r /scripts/. /shared/
        image: $devtron
        imagePullPolicy: IfNotPresent
        name: init-devtron
        resources: {}
        securityContext:
          allowPrivilegeEscalation: false
          runAsNonRoot: true
          runAsUser: 1000
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /shared
          name: shared-volume
      restartPolicy: OnFailure
      schedulerName: default-scheduler
      securityContext:
        fsGroup: 1000
        runAsGroup: 1000
        runAsUser: 1000
      terminationGracePeriodSeconds: 30
      volumes:
      - emptyDir: {}
        name: shared-volume
EOF
cat << 'EOF' > casbin-migration.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: postgresql-migrate-casbin-$RANDOM
  namespace: devtroncd
spec:
  activeDeadlineSeconds: 1500
  backoffLimit: 20
  template:
    spec:
      imagePullSecrets:
         - name: devtron-image-pull
      containers:
      - command:
        - sh
        - -c
        - kubectl rollout restart deployment/devtron -n devtroncd && kubectl rollout
          restart deployment/kubelink -n devtroncd
        image: quay.io/devtron/kubectl:latest
        imagePullPolicy: Always
        name: devtron-rollout
        resources: {}
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
      dnsPolicy: ClusterFirst
      initContainers:
      - command:
        - /bin/sh
        - -c
        - cp -r /scripts/. /shared/
        image: $devtron
        imagePullPolicy: IfNotPresent
        name: init-devtron
        resources: {}
        securityContext:
          allowPrivilegeEscalation: false
          runAsNonRoot: true
          runAsUser: 1000
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /shared
          name: shared-volume
      - command:
        - /bin/sh
        - -c
        - 'if [ $(MIGRATE_TO_VERSION) -eq "0" ]; then migrate -path $(SCRIPT_LOCATION)
          -database postgres://$(DB_USER_NAME):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=disable
          up;  else   echo $(MIGRATE_TO_VERSION); migrate -path $(SCRIPT_LOCATION)  -database
          postgres://$(DB_USER_NAME):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=disable
          goto $(MIGRATE_TO_VERSION);    fi '
        env:
        - name: SCRIPT_LOCATION
          value: /shared/casbin/
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
        envFrom:
        - secretRef:
            name: postgresql-migrator
        image: $migrator
        imagePullPolicy: IfNotPresent
        name: postgresql-migrate-casbin
        resources: {}
        securityContext:
          allowPrivilegeEscalation: false
          runAsNonRoot: true
          runAsUser: 1000
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /shared
          name: shared-volume
      restartPolicy: OnFailure
      schedulerName: default-scheduler
      securityContext:
        fsGroup: 1000
        runAsGroup: 1000
        runAsUser: 1000
      serviceAccount: devtron
      serviceAccountName: devtron
      terminationGracePeriodSeconds: 30
      volumes:
      - emptyDir: {}
        name: shared-volume
EOF
cat << 'EOF' > git-sensor-migration.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: postgresql-migrate-gitsensor-$RANDOM
  namespace: devtroncd
spec:
  activeDeadlineSeconds: 1500
  backoffLimit: 20
  completionMode: NonIndexed
  completions: 1
  suspend: false
  template:
    spec:
      imagePullSecrets:
         - name: devtron-image-pull
      containers:
      - command:
        - /bin/sh
        - -c
        - 'if [ $(MIGRATE_TO_VERSION) -eq "0" ]; then migrate -path $(SCRIPT_LOCATION)
          -database postgres://$(DB_USER_NAME):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=disable
          up;  else   echo $(MIGRATE_TO_VERSION); migrate -path $(SCRIPT_LOCATION)  -database
          postgres://$(DB_USER_NAME):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=disable
          goto $(MIGRATE_TO_VERSION);    fi '
        env:
        - name: SCRIPT_LOCATION
          value: /shared/sql/
        - name: DB_TYPE
          value: postgres
        - name: DB_USER_NAME
          value: postgres
        - name: DB_HOST
          value: postgresql-postgresql.devtroncd
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          value: git_sensor
        - name: MIGRATE_TO_VERSION
          value: "0"
        envFrom:
        - secretRef:
            name: postgresql-migrator
        image: $migrator
        imagePullPolicy: IfNotPresent
        name: postgresql-migrate-git-sensor
        resources: {}
        securityContext:
          allowPrivilegeEscalation: false
          runAsNonRoot: true
          runAsUser: 1000
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /shared
          name: shared-volume
      dnsPolicy: ClusterFirst
      initContainers:
      - command:
        - /bin/sh
        - -c
        - cp -r sql /shared/
        image: $git_sensor
        imagePullPolicy: IfNotPresent
        name: init-git-sensor
        resources: {}
        securityContext:
          allowPrivilegeEscalation: false
          runAsNonRoot: true
          runAsUser: 1000
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /shared
          name: shared-volume
      restartPolicy: OnFailure
      schedulerName: default-scheduler
      securityContext:
        fsGroup: 1000
        runAsGroup: 1000
        runAsUser: 1000
      terminationGracePeriodSeconds: 30
      volumes:
      - emptyDir: {}
        name: shared-volume
EOF
cat << 'EOF' > lens-migration.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: postgresql-migrate-lens-$RANDOM
  namespace: devtroncd
spec:
  activeDeadlineSeconds: 1500
  backoffLimit: 20
  suspend: false
  template:
    spec:
      containers:
      - command:
        - /bin/sh
        - -c
        - 'echo \$(MIGRATE_TO_VERSION); 
          if [ \$(MIGRATE_TO_VERSION) -eq "0" ]; 
          then 
            migrate -path \$(SCRIPT_LOCATION) -database postgres://$(DB_USER_NAME):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=disable up;  
          else   
             migrate -path \$(SCRIPT_LOCATION)  -database postgres://$(DB_USER_NAME):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=disable goto $(MIGRATE_TO_VERSION);    
          fi '
        env:
        - name: SCRIPT_LOCATION
          value: /shared/sql/
        - name: DB_TYPE
          value: postgres
        - name: DB_USER_NAME
          value: postgres
        - name: DB_HOST
          value: postgresql-postgresql.devtroncd
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          value: lens
        - name: MIGRATE_TO_VERSION
          value: "0"
        envFrom:
        - secretRef:
            name: postgresql-migrator
        image: $migrator
        imagePullPolicy: IfNotPresent
        name: postgresql-migrate-lens
        resources: {}
        securityContext:
          allowPrivilegeEscalation: false
          runAsNonRoot: true
          runAsUser: 1000
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /shared
          name: shared-volume
      dnsPolicy: ClusterFirst
      initContainers:
      - command:
        - /bin/sh
        - -c
        - cp -r sql /shared/
        image: $lens
        imagePullPolicy: IfNotPresent
        name: init-lens
        resources: {}
        securityContext:
          allowPrivilegeEscalation: false
          runAsNonRoot: true
          runAsUser: 1000
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /shared
          name: shared-volume
      restartPolicy: OnFailure
      schedulerName: default-scheduler
      securityContext:
        fsGroup: 1000
        runAsGroup: 1000
        runAsUser: 1000
      terminationGracePeriodSeconds: 30
      volumes:
      - emptyDir: {}
        name: shared-volume

EOF
sed -i "s|\$migrator|$migrator|g" devtron-migration.yaml
sed -i "s|\$devtron|$devtron|g" devtron-migration.yaml
sed -i "s|\$RANDOM|$RANDOM|g" devtron-migration.yaml

sed -i "s|\$migrator|$migrator|g" casbin-migration.yaml
sed -i "s|\$devtron|$devtron|g" casbin-migration.yaml
sed -i "s|\$RANDOM|$RANDOM|g" casbin-migration.yaml

sed -i "s|\$migrator|$migrator|g" git-sensor-migration.yaml
sed -i "s|\$git_sensor|$git_sensor|g" git-sensor-migration.yaml
sed -i "s|\$RANDOM|$RANDOM|g" git-sensor-migration.yaml

sed -i "s|\$migrator|$migrator|g" lens-migration.yaml
sed -i "s|\$lens|$lens|g" lens-migration.yaml
sed -i "s|\$RANDOM|$RANDOM|g" lens-migration.yaml



kubectl set image deploy/devtron -n $DEVTRON_NAMESPACE devtron=
kubectl set image deploy/dashboard -n $DEVTRON_NAMESPACE dashboard=
kubectl set image deploy/kubewatch -n $DEVTRON_NAMESPACE kubewatch=
kubectl set image deploy/kubelink -n $DEVTRON_NAMESPACE kubelink=
kubectl set image deploy/lens -n $DEVTRON_NAMESPACE lens=
kubectl set image sts/git-sensor -n $DEVTRON_NAMESPACE git-sensor=$git_sensor
kubectl set image deploy/image-scanner -n devtroncd image-scanner=$image_scanner 
