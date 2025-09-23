# Task 03 — Parent Container Image (Alpine) and Child (nginx)

## Images
- Parent: `manuelherreram/alpine-parent:1.0` (FROM alpine:3.20; apk update/upgrade)
- Child:  `manuelherreram/nebo-container:v1` (FROM alpine_parent:1.0; installs nginx; serves index.html)

## Build
```
docker build -f Dockerfile.parent   -t alpine_parent:1.0 .
docker build -f Dockerfile.newimage -t nebo_container:v1 .
``` 
## Run
```
docker run -d --name nebo-web -p 8080:80 nebo_container:v1
```

Open http://localhost:8080

## Push
```
docker tag alpine_parent:1.0           manuelherreram/alpine-parent:1.0
docker tag nebo_container:v1           manuelherreram/nebo-container:v1
docker push manuelherreram/alpine-parent:1.0
docker push manuelherreram/nebo-container:v1
```
