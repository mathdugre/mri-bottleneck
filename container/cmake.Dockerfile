FROM ubuntu:focal-20221019

ENV DEBIAN_FRONTEND="noninteractive"
RUN : \
    && apt update \
    && apt install -y --no-install-recommends \
      apt-utils \
      apt-transport-https \
      ca-certificates \
      gnupg \
      wget \
    && :

# Add GPG key for CMAKE
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null \
      | gpg --dearmor - \
      | tee /usr/share/keyrings/kitware-archive-keyring.gpg >/dev/null \
    && echo 'deb [signed-by=/usr/share/keyrings/kitware-archive-keyring.gpg] https://apt.kitware.com/ubuntu/ focal main' \
      | tee /etc/apt/sources.list.d/kitware.list >/dev/null 

# Install CMAKE
ARG CMAKE_VERSION="3.24.1-0kitware1ubuntu20.04.1"
RUN : \
    && apt update \
    && apt install -y --no-install-recommends \
      cmake=${CMAKE_VERSION} \
      cmake-data=${CMAKE_VERSION} \
    && :
