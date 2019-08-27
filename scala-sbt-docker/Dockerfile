#
# Scala, sbt and docker Dockerfile
#
# https://github.com/homeaccounting/docker/scala-sbt-docker
#

# Pull base image
ARG BASE_IMAGE_TAG
FROM hseeberger/scala-sbt:${BASE_IMAGE_TAG:-8u212_1.2.8_2.12.8}

RUN curl -fsSL https://get.docker.com -o get-docker.sh
RUN sh get-docker.sh
RUN usermod -aG docker sbtuser
