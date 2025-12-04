# ==============================================================================
# Jenkins Agent - Terraform Azure Pipeline
# Multi-stage build for optimized image size
# ==============================================================================

# ------------------------------------------------------------------------------
# Stage 1: Builder - Download and install tools
# ------------------------------------------------------------------------------
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Build arguments for tool versions
ARG TERRAFORM_VERSION=1.5.7
ARG TFSEC_VERSION=1.28.4
ARG TERRAFORM_DOCS_VERSION=0.17.0

WORKDIR /tmp

# Install download tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    unzip \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Download Terraform
RUN wget -q https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
    chmod +x terraform

# Download TFSec
RUN wget -q https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-amd64 && \
    chmod +x tfsec-linux-amd64 && \
    mv tfsec-linux-amd64 tfsec

# Download terraform-docs
RUN wget -q https://github.com/terraform-docs/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz && \
    tar -xzf terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-amd64.tar.gz && \
    chmod +x terraform-docs

# ------------------------------------------------------------------------------
# Stage 2: Final image - Minimal runtime
# ------------------------------------------------------------------------------
FROM ubuntu:22.04

LABEL maintainer="DevOps Team"
LABEL description="Jenkins agent for Terraform Azure deployments"
LABEL version="1.0"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install only runtime dependencies (no build tools)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    gnupg \
    ca-certificates \
    apt-transport-https \
    lsb-release \
    jq \
    python3 \
    python3-pip \
    openjdk-17-jre-headless \
    openssh-client \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Set Java environment
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Install Azure CLI (smallest method)
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash \
    && rm -rf /var/lib/apt/lists/* \
# Copy binaries from builder stage
COPY --from=builder /tmp/terraform /usr/local/bin/terraform
COPY --from=builder /tmp/tfsec /usr/local/bin/tfsec
COPY --from=builder /tmp/terraform-docs /usr/local/bin/terraform-docs

# Install Checkov (only tool that needs pip)
RUN pip3 install --no-cache-dir --break-system-packages \
    checkov \
    requests \
    pyyaml \
    jinja2 \
    azure-storage-blob \
    azure-identity

# Create Jenkins user
ARG JENKINS_USER=jenkins
ARG JENKINS_UID=1000
ARG JENKINS_GID=1000

RUN groupadd -g ${JENKINS_GID} ${JENKINS_USER} && \
    useradd -m -u ${JENKINS_UID} -g ${JENKINS_GID} -s /bin/bash ${JENKINS_USER} && \
    mkdir -p /home/${JENKINS_USER}/{workspace,.terraform.d,.azure} && \
    chown -R ${JENKINS_USER}:${JENKINS_USER} /home/${JENKINS_USER}

# Configure Git
RUN git config --global user.email "jenkins@ci.local" && \
    git config --global user.name "Jenkins Agent" && \
    git config --global init.defaultBranch main

# ==============================================================================
# VALIDATION SECTION - DELETE AFTER TESTING
# This section verifies all tools are installed correctly.
# Once you confirm the image works in your Jenkins environment, you can remove
# everything from here to the comment "END VALIDATION SECTION" to reduce image size.
# ==============================================================================
RUN echo "=== Verifying installations ===" && \
    echo "Git: $(git --version)" && \
    echo "Azure CLI: $(az version --output tsv | head -n1)" && \
    echo "Terraform: $(terraform version | head -n1)" && \
    echo "TFSec: $(tfsec --version)" && \
    echo "Checkov: $(checkov --version)" && \
    echo "terraform-docs: $(terraform-docs --version)" && \
    echo "Python3: $(python3 --version)" && \
    echo "Java: $(java -version 2>&1 | head -n1)" && \
    echo "=== All tools installed successfully ==="
# ==============================================================================
# END VALIDATION SECTION
# ==============================================================================

# Switch to Jenkins user
USER ${JENKINS_USER}
WORKDIR /home/${JENKINS_USER}

# Default command
CMD ["/bin/bash"]
WORKDIR /home/${JENKINS_USER}

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD terraform version || exit 1

# Default command
CMD ["/bin/bash"]
