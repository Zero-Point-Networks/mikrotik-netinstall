# Mikrotik Netinstall in a Container

## Overview
This container is designed to run on alternate platforms (eg. ARM/ARM64) and to facilitate a simple netinstall experience

## Enviroment Variables
| Name | Default | Description |
|------|---------|-------------|
| NETINSTALL_ADDR | `192.168.88.1` | Client IP Address for Netinstall to assign |
| NETINSTALL_ARGS | `<null>` | Allows specifying additional arguments such as '-r' to reset config (https://help.mikrotik.com/docs/display/ROS/Netinstall#Netinstall-InstructionsforLinux)
| NETINSTALL_ARCH | `arm64` | CPU Architecture to use when selecting npk |
| NETINSTALL_VER | `7.14.1` | RouterOS version to use when selecting npk |
| NETINSTALL_PKGS | `routeros` | Packages to install seperated by space (eg. routeros container) Do NOT include anything but the package name |

## Usage on RouterOS v7
With the implementation of containers in ROSv7, we can now enjoy a netinstall experience from another Mikrotik

Testing has been completed with a RB4011 (v7.6b8) running the container to flash a RB2011

### Steps
The below steps will create a container linking to `ether5`, and set netinstall to perform a full reset/recovery of RouterOS v7.14.1 for arm64 with the container package 

1. Enable containers and install package (refer wiki)
2. Create folder `images` under `disk1`
3. Upload npk files to images folder
4. Create veth interface 
    ```
    /interface veth add address=192.168.88.6/24 gateway=192.168.88.1 name=veth1
    ```
5. Create bridge
    ```
    /interface bridge add name=dockers
    ```
6. Add veth and physical port to bridge
    ```
    /interface bridge port add bridge=dockers interface=veth1
    /interface bridge port add bridge=dockers interface=ether5
    ```
7. Create mount to contain npk files
    ```
    /container mounts add dst=/app/images name=images src=/disk1/images
    ```
8. Create enviroment set, and specify npk file to use
    ```
    /container envs add key=NETINSTALL_ARCH name=NETINSTALL value=arm64
    /container envs add key=NETINSTALL_VER name=NETINSTALL value=7.14.1
    /container envs add key=NETINSTALL_PKGS name=NETINSTALL value="routeros container"
    /container envs add key=NETINSTALL_ARGS name=NETINSTALL value="-r -b"
    ```
9. Create container
    ```
    /container add remote-image=semaja2/mikrotik-netinstall:latest envlist=NETINSTALL interface=veth1 logging=yes mounts=images workdir=/app
    ```

## Usage with Podman
>TODO
#### Allow containers to bind to lower ports
```bash
sudo sh -c "echo 0 > /proc/sys/net/ipv4/ip_unprivileged_port_start"
```


## Usage with Docker
Due to limitations with Docker, the container can only work via the `--network=host` network parameter, as such this is only useful on Linux as this driver is not available for Windows/MacOS
 > The host networking driver only works on Linux hosts, and is not supported on Docker Desktop for Mac, Docker Desktop for Windows, or Docker EE for Windows Server.

>TODO