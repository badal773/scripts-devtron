echo "============Starting migration==================="

cat << 'EOF' > devtron-migration.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: postgresql-migrate-devtron-$RANDOM
  namespace: $DEVTRON_NAMESPACE
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
          value: $DB_HOST
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          value: $DB_NAME_DEVTRON
        - name: MIGRATE_TO_VERSION
          value: "0"
        envFrom:
        - secretRef:
            name: postgresql-migrator
        image: quay.io/devtron/migrator:v4.16.2
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
  namespace: $DEVTRON_NAMESPACE
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
          value: $DB_HOST
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          value: $DB_NAME_CASBIN
        - name: MIGRATE_TO_VERSION
          value: "0"
        envFrom:
        - secretRef:
            name: postgresql-migrator
        image: quay.io/devtron/migrator:v4.16.2
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
  namespace: $DEVTRON_NAMESPACE
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
          value: $DB_HOST
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          value: DB_NAME_GIT_SENSOR
        - name: MIGRATE_TO_VERSION
          value: "0"
        envFrom:
        - secretRef:
            name: postgresql-migrator
        image: quay.io/devtron/migrator:v4.16.2
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
  namespace: $DEVTRON_NAMESPACE
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
          value: $DB_HOST
        - name: DB_PORT
          value: "5432"
        - name: DB_NAME
          value: $DB_NAME_LENS
        - name: MIGRATE_TO_VERSION
          value: "0"
        envFrom:
        - secretRef:
            name: postgresql-migrator
        image: quay.io/devtron/migrator:v4.16.2
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
sed -i "s|\$devtron|$devtron|g" devtron-migration.yaml
sed -i "s|\$RANDOM|$RANDOM|g" devtron-migration.yaml
sed -i "s|\$DB_NAME_DEVTRON|$DB_NAME_DEVTRON|g" devtron-migration.yaml

sed -i "s|\$devtron|$devtron|g" casbin-migration.yaml
sed -i "s|\$RANDOM|$RANDOM|g" casbin-migration.yaml
sed -i "s|\$DB_NAME_CASBIN|$DB_NAME_CASBIN|g" casbin-migration.yaml

sed -i "s|\$git_sensor|$git_sensor|g" git-sensor-migration.yaml
sed -i "s|\$RANDOM|$RANDOM|g" git-sensor-migration.yaml
sed -i "s|\$DB_NAME_GIT_SENSOR|$DB_NAME_GIT_SENSOR|g" git-sensor-migration.yaml


sed -i "s|\$lens|$lens|g" lens-migration.yaml
sed -i "s|\$RANDOM|$RANDOM|g" lens-migration.yaml
sed -i "s|\$DB_NAME_LENS|$DB_NAME_LENS|g" lens-migration.yaml

sed -i "s|\$DB_HOST|$DB_HOST|g" lens-migration.yaml
sed -i "s|\$DB_HOST|$DB_HOST|g" git-sensor-migration.yaml
sed -i "s|\$DB_HOST|$DB_HOST|g" casbin-migration.yaml
sed -i "s|\$DB_HOST|$DB_HOST|g" devtron-migration.yaml

sed -i "s|\$DEVTRON_NAMESPACE|$DEVTRON_NAMESPACE|g" lens-migration.yaml
sed -i "s|\$DEVTRON_NAMESPACE|$DEVTRON_NAMESPACE|g" git-sensor-migration.yaml
sed -i "s|\$DEVTRON_NAMESPACE|$DEVTRON_NAMESPACE|g" casbin-migration.yaml
sed -i "s|\$DEVTRON_NAMESPACE|$DEVTRON_NAMESPACE|g" devtron-migration.yaml
