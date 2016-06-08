FROM ubuntu:16.04

# Base utilities
RUN apt-get update && apt-get -y -qq install curl