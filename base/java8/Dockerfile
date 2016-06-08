FROM homeaccounting/base-baremetal

MAINTAINER Alexander Sidorenko <aleks.sidorenko@gmail.com>

# disable interactive functions
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get install -y software-properties-common && \
    add-apt-repository ppa:openjdk-r/ppa -y && \
    apt-get update && \
    apt-get install -y --no-install-recommends openjdk-8-jre && \
    rm -rf /var/lib/apt/lists/*

# set default java environment variable
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
