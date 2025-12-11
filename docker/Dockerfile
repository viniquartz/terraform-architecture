# Jenkins Agent - Terraform Azure (Otimizado)
# Imagem minimalista: ~600MB

FROM alpine:3.19 AS builder

ARG TERRAFORM_VERSION=1.5.7
ARG TFSEC_VERSION=1.28.4

WORKDIR /tmp

RUN apk add --no-cache wget unzip

# Download Terraform
RUN wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    chmod +x terraform

# Download TFSec
RUN wget -q https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-amd64 && \
    chmod +x tfsec-linux-amd64 && \
    mv tfsec-linux-amd64 tfsec

# ------------------------------------------------------------------------------
# Imagem Final
# ------------------------------------------------------------------------------
FROM alpine:3.19

LABEL maintainer="platform-team"
LABEL version="2.0-optimized"

# Instalar apenas o essencial
RUN apk add --no-cache \
    bash \
    git \
    curl \
    ca-certificates \
    openssh-client \
    openjdk17-jre-headless && \
    rm -rf /var/cache/apk/*

# Copiar binarios
COPY --from=builder /tmp/terraform /usr/local/bin/terraform
COPY --from=builder /tmp/tfsec /usr/local/bin/tfsec

# Java environment
ENV JAVA_HOME=/usr/lib/jvm/default-jvm
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Jenkins user
ARG JENKINS_USER=jenkins
ARG JENKINS_UID=1000
ARG JENKINS_GID=1000

RUN addgroup -g ${JENKINS_GID} ${JENKINS_USER} && \
    adduser -D -u ${JENKINS_UID} -G ${JENKINS_USER} -s /bin/bash ${JENKINS_USER} && \
    mkdir -p /home/${JENKINS_USER}/{workspace,.terraform.d,.azure} && \
    chown -R ${JENKINS_USER}:${JENKINS_USER} /home/${JENKINS_USER}

# Git config
RUN git config --global user.email "jenkins@ci.local" && \
    git config --global user.name "Jenkins Agent" && \
    git config --global init.defaultBranch main

USER ${JENKINS_USER}
WORKDIR /home/${JENKINS_USER}

CMD ["/bin/bash"]
