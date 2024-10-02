FROM ros:noetic-perception


# ROS dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ros-noetic-cv-bridge \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl

# Add the Git PPA and install Git
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common && \
    add-apt-repository ppa:git-core/ppa && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        git 


RUN apt-get install -y --no-install-recommends python2 gmodule-2.0 libgtk-3-dev libglib2.0-dev pulseaudio libasound2-dev libpulse-dev ros-noetic-image-transport ninja-build stow

RUN apt-get install -y --no-install-recommends libjpeg-turbo8 libjpeg-turbo8-dev

RUN update-alternatives --install /usr/bin/python python /usr/bin/python2 1

RUN apt-get update && \
    apt-get remove -y gcc g++ gcc-aarch64-linux-gnu g++-aarch64-linux-gnu && \
    apt-get purge -y gcc g++ gcc-aarch64-linux-gnu g++-aarch64-linux-gnu && \
    apt-get autoremove -y && \
    apt-get clean

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        libgmp3-dev \
        libmpfr-dev \
        libmpc-dev \
        wget \
        zlib1g-dev \
        texinfo && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN wget https://ftp.gnu.org/gnu/gcc/gcc-14.1.0/gcc-14.1.0.tar.gz && \
    tar -xf gcc-14.1.0.tar.gz && \
    cd gcc-14.1.0 && \
    ./contrib/download_prerequisites && \
    mkdir build && \
    cd build && \
    ../configure --enable-languages=c,c++ --disable-multilib --disable-bootstrap && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    mkdir build-aarch64 && \
    cd build-aarch64 && \
    ../configure --target=aarch64-linux-gnu --enable-languages=c,c++ --disable-multilib --disable-bootstrap && \
    make -j$(nproc) && \
    make install && \
    cd ../.. && \
    rm -rf gcc-14.1.0 gcc-14.1.0.tar.gz


RUN echo "/usr/local/lib64" >> /etc/ld.so.conf.d/gcc.conf && \
    echo "/usr/local/lib" >> /etc/ld.so.conf.d/gcc.conf && \
    ldconfig

# Set LD_LIBRARY_PATH to prioritize the new libstdc++ location
ENV LD_LIBRARY_PATH="/usr/local/lib64:/usr/local/lib:$LD_LIBRARY_PATH"

WORKDIR /home/3rdparty/jsoncpp/
RUN git clone https://github.com/open-source-parsers/jsoncpp.git . && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_STATIC_LIBS=ON -DBUILD_SHARED_LIBS=OFF -DARCHIVE_INSTALL_DIR=. -G "Unix Makefiles" .. &&  \
    make && \
    make install

ENV LD_LIBRARY_PATH /usr/local/lib/:$LD_LIBRARY_PATH

WORKDIR /home/webrtc_ws
COPY . /home/webrtc_ws/src/
RUN rm -rf /home/webrtc_ws/src/webrtc_ros

RUN git clone https://github.com/GT-RAIL/async_web_server_cpp.git /home/webrtc_ws/src/async_web_server_cpp/

RUN /ros_entrypoint.sh catkin_make_isolated --install --install-space "/usr/local/webrtc/" \
    && sed -i '$isource "/usr/local/webrtc/setup.bash"' /ros_entrypoint.sh \
    && rm -rf /home/webrtc_ws/
ENTRYPOINT ["/ros_entrypoint.sh"]
