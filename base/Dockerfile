FROM alpine:3.10

LABEL maintainer="Alexander Sidorenko <aleks.sidorenko@gmail.com>" 

RUN apk update && \
    apk upgrade && \
    apk add git

ENV LANG en_US.UTF-8 
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Define default command.
CMD ["bash"]