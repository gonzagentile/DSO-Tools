# Use a base image to build (and download) the tools on

FROM ubuntu:latest as build

LABEL maintainer="support@go-forward.net"
LABEL vendor="Go Forward"

WORKDIR /
COPY requirements.txt .

ENV DEBIAN_FRONTEND=noninteractive
ARG SCANNER=4.7.0.2747

# Install necessary binaries
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    python3-dev \
    python3-pip \
    python3-setuptools \
    python3-venv \
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install the latest version of wheel first, as that is not installed by default
RUN python3 -m pip install wheel --no-cache-dir
# Install packages as specified in the requirements.txt file
RUN python3 -m pip install -r requirements.txt --no-cache-dir

# Download and unzip sonar-scanner-cli
RUN curl -sL https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SCANNER}-linux.zip -o /tmp/scanner.zip && \
    unzip /tmp/scanner.zip -d /tmp/sonarscanner && \
    mv /tmp/sonarscanner/sonar-scanner-${SCANNER}-linux /usr/lib/sonar-scanner

FROM ubuntu:latest as release
# Default entry point
WORKDIR /workdir

COPY --chown=999:999 --from=build /opt/venv /opt/venv
COPY --from=build /usr/lib/sonar-scanner/ /usr/lib/sonar-scanner/
RUN ln -s /usr/lib/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner 

# Install necessary binaries
RUN apt-get update
RUN apt-get install -y --no-install-recommends \
    bsdmainutils \
    curl \
    dnsutils \
    git \
    jq \
    libnet-ssleay-perl \
    make \
    nmap \
    procps \
    python3 \
    python3-venv 
Run apt-get clean 
RUN rm -rf /var/lib/apt/lists/*

ENV ANCHORE_CLI_PASS=foobar \
    ANCHORE_CLI_URL=http://anchore-engine_api_1:8228/v1 \
    ANCHORE_CLI_USER=admin \
    LC_ALL=C.UTF-8 \
    NODE_PATH=/usr/local/lib/node_modules \
    PATH="/opt/venv/bin:$PATH" \
    SONAR_RUNNER_HOME=/usr/lib/sonar-scanner \
    SONAR_USER_HOME=/tmp

RUN groupadd -r tool && \
    useradd --create-home --no-log-init --shell /bin/bash --system --gid tool --groups tool devsecops

USER tool

