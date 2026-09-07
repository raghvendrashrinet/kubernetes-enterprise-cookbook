### Create a new chart
```
 ## create a template chart
  helm create mmysql-chart
```

#### modify the values yaml file for the mysql  
`values.yaml'
```
  image nginx
  tag latest

  port: 3306

  env:
    mysqrootpwd: admin
    mysqldb: mydb
    mysqluser: admin
    mysqlpassword: admin 
 
```
`templates/deployment.yaml`
```
### add env variables which are mandatory for mysql
env:
- name=MYSQL_ROOT_PASSWORD
  value: {{  .Values.env.mysqlrootpwd }}
- name=MYSQL_DATABASE
  value:  {{  .Values.env.mysqldb }}
- name=MYSQL_USER
  value:  {{  .Values.env.mysqluser }}
- name=MYSQL_PASSWORD
  value:  {{  .Values.env.mysqlpassword }}
```
Now create a mysql deployment : `helm install mysql-1 mysql-chart`
>[!NOTE]
>COMMENT THE PROBES IN VALUES FILE, OR IT WILL FAIL


#### Packaging the chart
```
 helm package mysql-chart

 ## creates a zip file
```
---
Login into DB
```
# Exec into the pod and open the MySQL client
kubectl exec -it <pod-name> -- mysql -u root -p
# enter the password you set in MYSQL_ROOT_PASSWORD
```
---
SQL Query
```
-- List databases
SHOW DATABASES;

-- List tables in your DB
USE myapp;
SHOW TABLES;

-- Check version
SELECT VERSION();

-- Check status
SHOW STATUS LIKE 'Uptime';
```
