

`values.yaml`
```
image:
  repository: raghvendrashrinet/projects
  # This sets the pull policy for images.
  pullPolicy: Always
  # Overrides the image tag whose default is the chart appVersion.
  tag: "helm3tier"
env:
  mysqlhost: mysql-mysql-chart # mysql service name
  mysqlpwd: admin
  mysqluser: admin
  mysqldb: mydb


service:

  type: NodePort
  # This sets the ports more information can be found here: https://kubernetes.io/docs/concepts/services-networking/service/#field-spec-ports
  port: 80
  targetPort: 5000
  nodePort: 30080
```

`service.yaml`
```
ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
      nodePort: {{ .Values.service.nodePort }}
```

`deployment.yaml
```
 env:
          - name: MYSQL_HOST
            value: {{ .Values.env.mysqlhost }}
          - name: MYSQL_PASSWORD
            value: {{ .Values.env.mysqlpwd }}
          - name: MYSQL_USER
            value: {{ .Values.env.mysqluser }}
          - name: MYSQL_DB
            value: {{ .Values.env.mysqldb }}
```
