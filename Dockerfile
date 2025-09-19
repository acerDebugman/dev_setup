FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

ENV cpuType=amd64
ENV TINI_VERSION=v0.19.0

ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini-${cpuType} /tini
RUN chmod +x /tini

RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    gdb \
    clang \
    curl \
    git \
    libssl-dev \
    pkg-config \
    zlib1g-dev \
    valgrind \
    net-tools \
    rsync \
    netcat \
    vim \
    && rm -rf /var/lib/apt/lists/*

# 安装工具
RUN apt-get update && \
    apt-get install -y \
      git \
      telnet \
      iproute2 \
      iputils-ping && \
rm -rf /var/lib/apt/lists/*

ENV RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"
ENV RUSTUP_DIST_SERVER="https://rsproxy.cn"
ENV RUST_VERSION=1.87.0
#ENV RUST_VERSION=nightly
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --verbose --profile minimal --component clippy,rustfmt --default-toolchain $RUST_VERSION
#RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
ENV PATH=/root/.cargo/bin:$PATH
RUN /root/.cargo/bin/rustup install 1.87.0 --component rustfmt --component clippy
RUN /root/.cargo/bin/cargo install cargo-make

# 安装最新版 Go
# 设置变量（可修改为其他版本）
ENV GO_VERSION=1.23.0
ENV GO_ARCH=linux-amd64

# 下载并安装 Go
RUN curl -O -L https://dl.google.com/go/go${GO_VERSION}.${GO_ARCH}.tar.gz \
    && tar -C /usr/local -xzf go${GO_VERSION}.${GO_ARCH}.tar.gz \
    && rm go${GO_VERSION}.${GO_ARCH}.tar.gz

# 设置 Go 环境变量
ENV PATH=$PATH:/usr/local/go/bin
ENV GOPATH=/go
ENV PATH=$PATH:$GOPATH/bin

# 验证安装
RUN go version

# npm && pnpm
# 安装基础工具
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    ca-certificates \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 安装 Node.js 和 npm
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# 安装 pnpm
RUN npm install -g pnpm

# 配置镜像加速（可选）
RUN pnpm config set registry https://registry.npmmirror.com

# 验证安装
RUN node -v && npm -v && pnpm -v

# 安装依赖
#RUN pnpm install --frozen-lockfile


# install jdk
# 安装必要工具
RUN apt-get update && apt-get install -y \
    wget \
    tar \
    gzip \
    && rm -rf /var/lib/apt/lists/*
# 下载 OpenJDK 24
#RUN wget https://download.java.net/java/GA/jdk24.0.1/24a58e0e276943138bf3e963e6291ac2/9/GPL/openjdk-24.0.1_linux-x64_bin.tar.gz
# amazon JDK 1.8
#COPY amazon-corretto-8-x64-linux-jdk.tar.gz /root/amazon-corretto-8-x64-linux-jdk.tar.gz
COPY amazon-corretto-8-x64-linux-jdk.tar.gz /root/

# 解压并安装到 /opt 目录
#RUN tar -xzf openjdk-24_linux-x64_bin.tar.gz -C /opt \
#    && rm openjdk-24_linux-x64_bin.tar.gz
RUN tar -xzf /root/amazon-corretto-8-x64-linux-jdk.tar.gz -C /opt \
    && rm /root/amazon-corretto-8-x64-linux-jdk.tar.gz

# 设置环境变量
ENV JAVA_HOME=/opt/amazon-corretto-8.452.09.1-linux-x64
ENV PATH="$JAVA_HOME/bin:$PATH"
# 验证安装
RUN java -version


RUN rm -f /etc/localtime
RUN ln -s /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

WORKDIR /app
RUN git config --global --add safe.directory /app
ADD ./cargo.toml /root/.cargo/config.toml

COPY ./bin/* /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh

# ENTRYPOINT ["/tini", "--"]
# CMD /usr/bin/entrypoint.sh
ENTRYPOINT ["/tini", "--", "/usr/bin/entrypoint.sh"]

