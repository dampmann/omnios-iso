#!/usr/bin/bash
#svcadm disable sendmail
#svcadm disable sendmail-client
#dladm show-phys
#ifconfig <your_nic> plumb
#ifconfig <your_nic> dhcp
#echo “nameserver 8.8.8.8” > /etc/resolv.conf
#cp /etc/nsswitch.dns /etc/nsswitch.conf
echo "Running pkg update"
pkg update
echo "Installing gcc51"
pkg install developer/gcc51
echo "Installing gnu-make"
pkg install developer/build/gnu-make
echo "Installing rmformat"
pkg install service/storage/media-volume-manager
echo "Installing cdrtools"
pkg install media/cdrtools
if [ -f /root.zfs.bz2 ]; then
    echo "root.zfs.bz2 exists."
    echo -n "Want to keep and use it (y/n)? "
    read response
    if [ $response == "n" ]; then
        echo "We need to take a snapshot."
        echo -n "Please type a snapshot name: "
        read snap
        zfs snapshot rpool/ROOT/omnios@${snap}
        zfs send rpool/ROOT/omnios@${snap} | bzip2 -9 > /root.zfs.bz2 
    fi
else
    zfs snapshot rpool/ROOT/omnios@template
    zfs send rpool/ROOT/omnios@template | bzip2 -9 > /root.zfs.bz2 
fi
cdrom=$(rmformat | grep "/dev/rdsk" | awk '{print $4}' | sed 's#rdsk#dsk#')
echo "Creating /media/cdrom"
mkdir -p /media/cdrom
echo "Mounting cdrom ..."
mount -F hsfs $cdrom /media/cdrom
if [ "$?" != 0 ]; then
    echo "Cannot mount cdrom ... exiting."
    exit 127
fi
echo "Creating /iso"
mkdir -p /iso
cd /media/cdrom
echo "Running cpio to copy cdrom contents to /iso"
find . -print -depth | cpio -pdmu /iso
echo "Creating /minirootold"
mkdir -p /minirootold
echo "Creating /miniroot"
mkdir -p /miniroot
echo "Copy cdrom boot_archive to /tmp"
cp -f /iso/platform/i86pc/amd64/boot_archive /tmp
lofiadm -a /tmp/boot_archive
mount /dev/lofi/1 /minirootold
echo "mounted cdrom boot_archive to /minirootold"
mkfile -n 256M /tmp/miniroot
lofiadm -a /tmp/miniroot
echo 'y' | newfs /dev/rlofi/2 > /dev/zero 2>&1
tunefs -m 0 /dev/lofi/2
mount /dev/lofi/2 /miniroot
echo "mounted new file system on /miniroot"
cd /minirootold
find . -print -depth | egrep -v kayak_r151023.zfs.bz2 | cpio -pdmu /miniroot
echo "Copied over the old miniroot to new miniroot"
printf '/kayak-menu/\ni\n\tmkdir -p /media/cdrom\n\tcdrom=$(/usr/bin/rmformat | /usr/bin/grep "/dev/rdsk" | /usr/bin/awk "{print $4}" | /usr/bin/sed "s#rdsk#dsk#")\n\t/usr/sbin/mount -F hsfs $cdrom /media/cdrom\n\tln -s /media/cdrom/root.zfs.bz2 /root/root.zfs.bz2\n.\n\nw\nq\n' | ed /miniroot/.initialboot
printf '/kayak-menu/\ni\n\tmkdir -p /media/cdrom\n\tcdrom=$(/usr/bin/rmformat | /usr/bin/grep "/dev/rdsk" | /usr/bin/awk "{print $4}" | /usr/bin/sed "s#rdsk#dsk#")\n\t/usr/sbin/mount -F hsfs $cdrom /media/cdrom\n\tln -s /media/cdrom/root.zfs.bz2 /root/root.zfs.bz2\n.\n\nw\nq\n' | ed /iso/.initialboot
echo "Patched .initialboot in /miniroot and /iso"
cd /miniroot
#find /miniroot -type d -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'
cp `which rmformat` usr/bin/
for i in $(ldd `which rmformat` | awk '{print $3}') 
do 
	j=$(echo $i | sed 's#^/##') 
	ls $j > /dev/zero 2>&1
	if [ "$?" != 0 ]; then 
        echo "Copy $i $j for rmformat ..."
		cp $i $j 
	fi 
done
cp -rf /usr/lib/smedia /miniroot/usr/lib
echo "Copied rmformat to miniroot and resolved dependencies."
echo "Copying /root.zfs.bz2 to /iso"
cp /root.zfs.bz2 /iso
echo "Cleaning up"
cd /
umount /miniroot
lofiadm -d /dev/lofi/2
echo "Copy new boot_archive to /iso ..."
cp /tmp/miniroot /iso/platform/i86pc/amd64/boot_archive
echo "Creating digest file ..."
digest -a sha1 /iso/platform/i86pc/amd64/boot_archive > /iso/platform/i86pc/amd64/boot_archive.hash
umount /minirootold
lofiadm -d /dev/lofi/1
echo "Creating iso"
mkisofs -o omni_new.iso -b boot/cdboot -c .catalog -no-emul-boot -boot-load-size 4 -boot-info-table -N -l -R -U -allow-multidot -no-iso-translate -cache-inodes -d -D -V OmniOS /iso
rm -rf /miniroot /minirootold /iso /tmp/boot_archive
echo "done"
