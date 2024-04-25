#!/bin/sh

# First we need to setup disk (new mountpoint, etc)
if [[ $EUID -ne 0 ]]; then
    echo "You must be root"
    exit 1
fi

# Function to build docker image from the dockerfile and then export it to the tar archive
# $1 - Dockerfile path
# $2 - Build context
# $3 - Image name
# $4 - Rootfs output path
build_docker_image () {
    docker build -t $3 -f $1 $2

    # Get image
    local image_id=$(docker images --format="{{.Repository}} {{.ID}}" | grep $3 | awk '{print $2}')

    # Export rootfs to tar archive
    local container_id=$(docker create $3)
    docker export $container_id -o $4

    # Remove image and container
    docker container rm $container_id
    docker image rm $image_id
}


# Function to allocate corresponding disk space for the loop device and then extract tar archive with rootfs image there
# $1 rootfs input path
# $2 vm disk size (in Mib)
# $3 mountpoint path
# $4 block device output path
setup_disk_and_run () {

    # create an empty block device
    fallocate -l $2 $4
    dd if=/dev/zero of=$4 bs=1M count=$2

    loop_device=$(losetup -f $4 --show)

    # format to ext4
    mkfs.ext4 $loop_device &> /dev/null

    # Mount loop device
    mkdir -p $3
    mount -t ext4 $loop_device $3

    # Copy rootfs contents to mountpoint
    tar -xf $1 -C $3

    unshare --net --fork --mount --pid --ipc --mount-proc \
            chroot $3 /bin/bash
}

print_help () {
    echo -e \
"Usage: COMMAND ARGS

COMMANDS:
    rootfs <dockerfile path> <context> <image name> <rootfs output path>                    -- create rootfs .tar archive from given Dockerfile 
    run <rootfs input path> <vm disk size> <mountpoint path> <block device output path>    -- prepares corresponding disk space for the \"vm\" and runs interactive shell inside
    help                                                                                    -- print this help message
"
}

case $1 in
    "rootfs"    ) build_docker_image $2 $3 $4 $5 ;;
    "run"       ) setup_disk_and_run $2 $3 $4 $5 ;;
    "help" | *  ) print_help ;;
esac
