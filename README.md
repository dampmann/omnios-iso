# omnios-iso from live root file system
Create an installable OmniOS iso from a root file system snapshot 
of your running system

## How to do this

* [Download](http://omnios.omniti.com/media/r151023-20170515.iso) and install OmniOS (for example using VirtualBox)
* Configure networking
  * dladm show-phys
  * ifconfig NIC plumb
  * ifconfig NIC dhcp 
  * echo "nameserver 8.8.8.8" > /etc/resolv.conf
  * cp /etc/nsswitch.dns /etc/nsswitch.conf
* Run pkg update
* pkg install git
* git clone https://github.com/dampmann/omnios-iso.git
* cd omnios-iso
* chmod 755 *.sh
* Execute the script

- Replace or comment the lines in the script where I install gcc and gnu-make if you don't need it
