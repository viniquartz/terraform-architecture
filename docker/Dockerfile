# Jenkins Agent - Terraform Azure (Optimized)
# Minimal image with Azure CLI, Trivy, Infracost: ~500-550MB

FROM alpine:3.19 AS builder

ARG TERRAFORM_VERSION=1.5.7
ARG TRIVY_VERSION=0.48.0
ARG INFRACOST_VERSION=0.10.32

WORKDIR /tmp

RUN apk add --no-cache wget unzip tar

# Download Terraform
RUN wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    chmod +x terraform

# Download Trivy
RUN wget -q https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz && \
    tar -xzf trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz && \
    chmod +x trivy

# Download Infracost
RUN wget -q https://github.com/infracost/infracost/releases/download/v${INFRACOST_VERSION}/infracost-linux-amd64.tar.gz && \
    tar -xzf infracost-linux-amd64.tar.gz && \
    chmod +x infracost-linux-amd64 && \
    mv infracost-linux-amd64 infracost

# ------------------------------------------------------------------------------
# Final Image
# ------------------------------------------------------------------------------
FROM alpine:3.19

LABEL maintainer="platform-team"
LABEL version="2.0-optimized"

# Install essentials + Azure CLI dependencies
RUN apk add --no-cache \
    bash \
    git \
    curl \
    ca-certificates \
    openssh-client \
    openjdk17-jre-headless \
    python3 \
    py3-pip \
    && rm -rf /var/cache/apk/*

# Install Azure CLI (minimal)
RUN pip3 install --no-cache-dir azure-cli --break-system-packages

# Copy binaries
COPY --from=builder /tmp/terraform /usr/local/bin/terraform
COPY --from=builder /tmp/trivy /usr/local/bin/trivy
COPY --from=builder /tmp/infracost /usr/local/bin/infracost

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
