#!/bin/sh
set -e

os_file="example-os/os.sh"
img_file="$(tempfile --suffix=".img")"
vbox_dir="vbox_$(date +%s)-$$"
vmname="automatic-os-test-$(date +%s)-$$"

ln -sf "$(readlink -f "$os_file")" "$img_file"
VBoxManage createvm --name "$vmname" --register --basefolder "/tmp/$vbox_dir"
VBoxManage modifyvm "$vmname" --hwvirtex off
VBoxManage modifyvm "$vmname" --nestedpaging off
VBoxManage modifyvm "$vmname" --pae off
VBoxManage storagectl "$vmname" --name 'floppy disk drive' --add floppy --bootable on
VBoxManage storageattach "$vmname" --storagectl 'floppy disk drive' --port 0 --device 0 --type fdd --medium "$img_file"
VBoxManage modifyvm "$vmname" --boot1 floppy
VBoxManage startvm "$vmname" --type sdl &
pid=$!
runsikulix -r test/check-gradient.sikuli
VBoxManage controlvm "$vmname" poweroff
wait $pid
# TODO: should ensure that the cleanup phase is always done even if the test fails.
for i in `seq 10`; do
    if VBoxManage unregistervm "$vmname" --delete; then
        break
    fi
    sleep 0.1
done
rm "$img_file"
rm "/tmp/$vbox_dir" -fr
