# Run MARUS on docker
Currently available only for Nvidia GPU.

1. Make sure you have Nvidia drivers installed. That can be validated using nvidia-smi command.
2. Install Nvidia-container-toolkit (>= 1.12.1)

https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html.

Test with `nvidia/cuda:11.6.2-base-ubuntu20.04` image as described in the installation guide.

3. Run `xhost +`

4. Build docker image with

`docker build -t marus_docker . --build-arg ssh_prv_key="$(cat ~/.ssh/id_rsa)" --build-arg ssh_pub_key="$(cat ~/.ssh/id_rsa.pub)"`

Make sure you have git ssh configured.


5. Run docker container with

`docker run --rm -v /tmp/.X11-unix:/tmp/.X11-unix --gpus all --runtime nvidia -e DISPLAY=$DISPLAY --privileged -it marus_docker /bin/bash`

## Testing
1. In docker container run command:

`run ros2 launch grpc_ros_adapter ros2_server_launch.py`

2. In other terminal attach to that container with:

`docker exec -it <container_id> /bin/bash`

You can find you docker id using command `docker ps`

3. When attached to container run Unity Hub with:

`unityhub`

and add marus_example project (/home/marus_user/marus_example).


