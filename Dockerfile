#   Copyright 2020 NephoSolutions SRL, Sebastian Trebitz
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

ARG ALPINE_VERSION
ARG RUBY_VERSION

FROM alpine:${ALPINE_VERSION} as downloader

WORKDIR /tmp

ARG GCLOUD_SDK_VERSION
ENV GCLOUD_SDK_VERSION ${GCLOUD_SDK_VERSION}

ADD https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz
RUN tar -xzf google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz

FROM ruby:${RUBY_VERSION}-alpine${ALPINE_VERSION}
LABEL maintainer="sebastian@nephosolutions.com"
LABEL name="nephosolutions/terraform"
LABEL version="${TERRAFORM_VERSION}"

RUN apk add --no-cache --update \
  bash \
  build-base \
  ca-certificates \
  git \
  groff \
  libc6-compat \
  libsodium-dev \
  make \
  openssh-client \
  openssl \
  python3

RUN ln -s /lib /lib64

ARG GIT_CRYPT_VERSION
ENV GIT_CRYPT_VERSION ${GIT_CRYPT_VERSION}

ADD https://raw.githubusercontent.com/sgerrand/alpine-pkg-git-crypt/master/sgerrand.rsa.pub /etc/apk/keys/sgerrand.rsa.pub
ADD https://github.com/sgerrand/alpine-pkg-git-crypt/releases/download/${GIT_CRYPT_VERSION}/git-crypt-${GIT_CRYPT_VERSION}.apk /var/cache/apk/
RUN apk add /var/cache/apk/git-crypt-${GIT_CRYPT_VERSION}.apk

COPY --from=downloader /tmp/google-cloud-sdk /opt/google/cloud-sdk

RUN git config --system credential.'https://source.developers.google.com'.helper gcloud.sh

RUN addgroup alpine && \
    adduser -G alpine -D alpine

USER alpine
ENV USER alpine

ENV PATH $PATH:/opt/google/cloud-sdk/bin

RUN gcloud config set core/disable_usage_reporting true && \
    gcloud config set component_manager/disable_update_check true && \
    gcloud config set metrics/environment github_docker_image
