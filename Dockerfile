FROM ubuntu:18.04

# Setting up for SSH/Remote compiling
# Taken from https://austinmorlan.com/posts/docker_clion_development/
RUN apt update \
	&& apt upgrade -y \
	&& apt install -y \
	apt-utils \
	build-essential \
	clang \
	cmake \
	gdb \
	gdbserver \
	openssh-server \
	rsync \
	bzip2 \
    g++ \
    gcc \
    gfortran \
    git \
    gsl-bin \
    libblas-dev \
    libbz2-dev \
    libgsl-dev \
    liblapack-dev \
    libnetcdf-c++4-dev \
    libnetcdf-cxx-legacy-dev \
    libnetcdf-dev \
    ninja-build \
    numdiff \
    unzip \
    wget \
    zlib1g-dev \
    qt5-default

# Taken from - https://docs.docker.com/engine/examples/running_ssh_service/#environment-variables
RUN mkdir /var/run/sshd && \
    echo 'root:root' | chpasswd && \
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# 22 for ssh server. 7777 for gdb server.
EXPOSE 22 7777

# Create dev user with password 'dev'
RUN useradd -ms /bin/bash dev && \
    echo 'dev:dev' | chpasswd

# Upon start, run ssh daemon
CMD ["/usr/sbin/sshd", "-D"]


# Install deal.ii
# from https://github.com/dealii/docker-files/blob/master/dealii/fulldepscandi/Dockerfile
# get deal.ii repo
ARG VER=master
ARG BUILD_TYPE=DebugRelease

ARG USER=dev

WORKDIR "/home/dev"

RUN git clone https://github.com/dealii/dealii.git dealii-$VER-src

RUN cd dealii-$VER-src && \
    git checkout $VER && \
    mkdir build && cd build && \
    cmake -DDEAL_II_WITH_MPI=OFF \
          -DDEAL_II_COMPONENT_EXAMPLES=OFF \
          -DCMAKE_INSTALL_PREFIX=/home/dev/deal.ii \
          -DCMAKE_BUILD_TYPE=$BUILD_TYPE \
          ../
RUN cd dealii-$VER-src && \
    cd build && \
    make install -j16 && \
    make test && \
    cd .. && rm -rf build .git

ENV DEAL_II_DIR /home/dev/dealii
