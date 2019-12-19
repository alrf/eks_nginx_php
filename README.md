# Nginx + PHP deployment based on EKS

## How to deploy

eksctl and kubectl tools should be pre-installed.

Docker image can be rebuilt by:

```
docker build --no-cache . -t alrf/php:7.4-fpm-alpine
```

Run `bash deploy.sh`

## How to remove deployment

Run `bash undeploy.sh`
