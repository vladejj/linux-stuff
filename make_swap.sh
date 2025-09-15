# This method only works on UEFI for Fedora 42!
# To check that the system uses UEFI:
# bootctl

#!/bin/bash
SWAPSIZE=$(free | awk '/Mem/ {x=$2/1024/1024; printf "%.0fG", (x<2 ? 2*x : x<8 ? 1.5*x : x) }')
sudo btrfs subvolume create /var/swap
sudo chattr +C /var/swap
sudo restorecon /var/swap
sudo mkswap --file -L SWAPFILE --size $SWAPSIZE /var/swap/swapfile
sudo bash -c 'echo /var/swap/swapfile none swap defaults 0 0 >>/etc/fstab'
sudo swapon -av
sudo bash -c 'echo add_dracutmodules+=\" resume \" > /etc/dracut.conf.d/resume.conf'
sudo dracut -f
