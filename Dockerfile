# Version 1.0
FROM ubuntu:14.04
MAINTAINER Florian GAUVIN "florian.gauvin@nl.thalesgroup.com"

ENV DEBIAN_FRONTEND noninteractive

#Download all the packages needed 

RUN apt-get update && apt-get install -y \
	curl \
	git \
	wget \
        && apt-get clean 

#Download and install the latest version of Docker (You need to be the same version to use this Dockerfile)

RUN wget -qO- https://get.docker.com/ | sh

#Prepare the usr directory by downloading in it : the base image, Openjdk8 and Apache Felix

WORKDIR /usr

RUN	git clone https://github.com/florian-gauvin/rootfs.tar-felix.git && \ 
	wget http://www.eu.apache.org/dist/felix/org.apache.felix.main.distribution-5.0.1.tar.gz  && \
	tar -xf org.apache.felix.main.distribution-5.0.1.tar.gz

#Decompress the base image

WORKDIR /usr/rootfs.tar-felix

RUN tar -xf rootfs.tar &&\
	rm rootfs.tar

#Install etcd

RUN cd /tmp \
	&& export ETCDVERSION=v2.0.13 \
	&& curl -k -L https://github.com/coreos/etcd/releases/download/$ETCDVERSION/etcd-$ETCDVERSION-linux-amd64.tar.gz | gunzip | tar xf - \
	&& cp etcd-$ETCDVERSION-linux-amd64/etcdctl /usr/rootfs.tar-felix/bin/

#Add the resources

ADD resources /usr/rootfs.tar-felix/tmp

#Download and add openjdk8 to the base image, then add felix to the base image, finally the base image is complete so we can recompress it

WORKDIR /usr/

RUN	git clone https://github.com/florian-gauvin/openjdk8-compact2.git && \
	cp -r openjdk8-compact2/j2re-compact2-image/ rootfs.tar-felix/usr/ &&\
	cp -r /usr/felix-framework-5.0.1 /usr/rootfs.tar-felix/usr/ && \
	cd /usr/rootfs.tar-felix/ &&\
	tar -cf rootfs.tar * && \
	mkdir /usr/image && \
	cp rootfs.tar /usr/image && \ 
	cd /usr && \
	rm -fr rootfs.tar-felix org.apache.felix.main.distribution-5.0.1.tar.gz felix-framework-5.0.1 openjdk8-compact2

#When the builder image is launch, it creates the openjdk8 and felix docker image that you will be able to see by running the command : docker images

ENTRYPOINT for i in `seq 0 100`; do sudo mknod -m0660 /dev/loop$i b 7 $i; done && \
	service docker start && \
	docker import - inaetics/felix-agent < /usr/image/rootfs.tar &&\
	/bin/bash

