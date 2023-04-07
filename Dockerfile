# syntax=docker/dockerfile:1.2
FROM nvidia/vulkan:1.3-470

ARG USERNAME=marus_user
ARG UNITY_VERSION=2021.3.3f1
ARG ROS_DISTRO=galactic
ARG ssh_prv_key
ARG ssh_pub_key

ENV HOME /home/$USERNAME

SHELL ["/bin/bash", "-c"]

#issue https://github.com/NVIDIA/nvidia-docker/issues/1632
RUN rm /etc/apt/sources.list.d/cuda.list

RUN apt -y update
RUN apt install -y sudo

RUN useradd -ms /bin/bash ${USERNAME} && adduser ${USERNAME} sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN usermod -a -G sudo,dialout ${USERNAME}

#Basic dependencies
RUN apt -y update && apt -y install firefox && apt -y install git-lfs && apt -y install wget &&  apt -y install git && apt -y install blender && apt -y install pip

#Install Unity hub
RUN sh -c 'echo "deb https://hub.unity3d.com/linux/repos/deb stable main" > /etc/apt/sources.list.d/unityhub.list' \
&& wget -qO - https://hub.unity3d.com/linux/keys/public | apt-key add \
&& apt -y update
USER ${USERNAME}
RUN sudo DEBIAN_FRONTEND=noninteractive apt install -y unityhub

### Install ROS
RUN sudo apt -y update && sudo apt install -y locales \
 && sudo locale-gen en_US en_US.UTF-8 \
 && sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 \
 && export LANG=en_US.UTF-8
RUN sudo apt install -y software-properties-common \
 && sudo add-apt-repository -y universe
RUN sudo apt install -y software-properties-common && sudo add-apt-repository -y universe \
    && sudo apt update && sudo apt install -y curl \
    && sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && sudo echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
RUN sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt install -y ros-galactic-desktop && sudo apt install -y ros-dev-tools

RUN mkdir ${HOME}/.ssh -m 0700
RUN ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts
# Add the keys and set permissions
RUN echo "$ssh_prv_key" > ${HOME}/.ssh/id_rsa \
    && echo "$ssh_pub_key" > ${HOME}/.ssh/id_rsa.pub \
   && chmod 600 ${HOME}/.ssh/id_rsa \
   && chmod 600 ${HOME}/.ssh/id_rsa.pub

##CLONE MARUS_EXAMPLE
WORKDIR ${HOME}
RUN git clone git@github.com:MARUSimulator/marus-example.git
WORKDIR ./marus-example
RUN git submodule update --init --recursive

RUN source /opt/ros/galactic/setup.bash \
    && mkdir -p ${HOME}/ros2_ws/src
WORKDIR ${HOME}/ros2_ws/src
RUN git clone git@github.com:MARUSimulator/grpc_ros_adapter.git
WORKDIR ${HOME}/ros2_ws/src/grpc_ros_adapter
RUN git checkout galactic && pip install -r requirements.txt && git submodule update --init --recursive
WORKDIR ${HOME}/ros2_ws
RUN colcon build

COPY ./files ${HOME}/files

# install Unity
WORKDIR ${HOME}
RUN sudo chmod 777 ./files/UnitySetup-2021.3.3f1
RUN while sleep 3; do echo -e '\nPlease wait, this might take a few minutes'; done & yes | ./files/UnitySetup-2021.3.3f1 --unattended -l ${HOME}/Unity/Hub/Editor/2021.3.3f1
RUN echo -e "if [ \$(whoami) != ${USERNAME} ]; then\n su ${USERNAME}\nfi\nsource /opt/ros/galactic/setup.bash\nsource ${HOME}/ros2_ws/install/setup.bash" >> ${HOME}/.bashrc

USER root