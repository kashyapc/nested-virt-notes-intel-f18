#!/bin/bash

#Let's create a minimal kickstart file with serial console enabled
#NOTE for F16 serial console login w/o any line-breaks, disable plymouth service and reboot the vm -- $ ln -s /dev/null /etc/systemd/system/plymouth-start.service

cat << EOF > fed.ks
install
text
reboot
lang en_US.UTF-8
keyboard us
network --bootproto dhcp
rootpw testpwd
firewall --enabled --ssh
selinux --enforcing
timezone --utc America/New_York
bootloader --location=mbr --append="console=tty0 console=ttyS0,115200 rd_NO_PLYMOUTH serial text"
zerombr
clearpart --all --initlabel
autopart

%packages
@core
%end
EOF


#Disk Image location
diskimage=/export/vmimgs/nested-guest-f18.qcow2

#Create the qcow2 disk image with preallocation and 'facllocate'(which pre-allocates all the blocks to a file) it for max. performance
echo "Creating qcow2 disk image.."
qemu-img create -f qcow2 -o preallocation=metadata $diskimage 6G
#fallocate -l `ls -al $diskimage | awk '{print $5}'` $diskimage
echo `ls -lash $diskimage`


#Create the nested-guest
virt-install --connect=qemu:///system \
    --network=bridge:virbr0 \
    --initrd-inject=./fed.ks \
    --extra-args="ks=file:/fed.ks console=tty0 console=ttyS0,115200 serial rd_NO_PLYMOUTH" \
    --name=nested-guest-f18 \
    --disk path=$diskimage,format=qcow2,cache=none \
    --ram 2048 \
    --vcpus=2 \
    --check-cpu \
    --accelerate \
    --os-type linux \
    --os-variant fedora18 \
    --cpuset auto \
    --hvm \
    --location=http://foo.bar.com/pub/fedora/linux/releases/18/Fedora/x86_64/os/ \
    --nographics 

