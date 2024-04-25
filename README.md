# Report
## Alexander Buchnev, B21-CS-01

## The reasoning behind the solution
I wrote several helper bash functions, e.g. `build_docker_image`, `setup_disk_and_run`. Then there is 
a main wrapper which has neat interface and help messages for the functions. All the necessary documentation
is also present

## Example runs

### NB: you must run this with sudo rights, since there are a lot of kernel calls

### Run main.sh `rootfs` to prepare the rootfs file from the docker image
```sh
sudo ./main.sh rootfs ./Dockerfile ./ virt-test-img virt-test.tar
```

### Run main.sh `disk` on previously set up block file to run the "container"
```sh
sudo ./main.sh disk virt-test.tar 10240 /mnt block-dev-test
```
