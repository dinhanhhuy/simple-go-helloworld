#
# MAKEFILE for simple-go-helloworld

#
# binary output name
BINARY=simple-go-helloworld

#
# Values Version and Commit
VERSION=`cat version`
COMMIT=`git rev-parse HEAD || echo "unknown"`

#
# Setup the -ldflags option for go build here, interpolate the variable values
LDFLAGS=-ldflags "-X simple-go-helloworld/release.Version=${VERSION} -X simple-go-helloworld/release.Commit=${COMMIT}"

#
# dafault target
.DEFAULT_GOAL: all

# define phony targets
.PHONY: clean install build docker-container docker-container-clear docker-image test

#
# build the binary and deploy a container with it
all: build docker

#
# build a clean image an container
docker: docker-image-clean docker-image docker-container

#
# BINARY TARGETS
# 

#
# build the binary
#
# "...We’re disabling cgo which gives us a static binary. 
# We’re also setting the OS to Linux (in case someone builds this on a Mac or Windows) 
# and the -a flag means to rebuild all the packages we’re using, 
# which means all the imports will be rebuilt with cgo disabled..."
#
# reference: https://blog.codeship.com/building-minimal-docker-containers-for-go-applications/
#
build: clean
	CGO_ENABLED=0 GOOS=linux go build ${LDFLAGS}  -a -o ${BINARY} main.go

#
# install compiled dependencies in $GOPATH/pkg and put the binary in $GOPATH/bin
install: clean
	go install ${LDFLAGS} ./...

#
# execute all tests
test:
	go test ./...

#
# clear binaries generated by install or build targets
clean:
	if [ -f ${BINARY} ] ; then rm -f ${BINARY} ; rm -f $$GOPATH/bin/${BINARY} ; fi


#
# DOCKER TARGETS
# 

#
# create a docker image to run the binary
docker-image:
	docker build --tag ${BINARY} --tag ${BINARY}:${VERSION} .

#
# create a container to run the binary.
docker-container:
	docker run -d --name ${BINARY} -p 80:80 ${BINARY}

#
# clean the containers
docker-container-clean:
	docker ps -a | grep ${BINARY} | tr -s ' ' | cut -d " " -f1 | while read c; do docker stop $$c; docker rm -v $$c; done

#
# clear docker images
docker-image-clean: docker-container-clean
	docker images | grep simple-go-helloworld | tr -s ' ' | cut -d " " -f2 | while read t; do docker rmi ${BINARY}:$$t; done
