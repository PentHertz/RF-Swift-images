#!/bin/bash 

sudo docker pull tonistiigi/binfmt:latest
sudo docker run --privileged --rm tonistiigi/binfmt --uninstall "qemu-*"
sudo docker run --privileged --rm tonistiigi/binfmt --install all
