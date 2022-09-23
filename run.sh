#!/bin/bash
set -x
#qemu=/opt/qemu/build/qemu-system-x86_64
qemu=/opt/qemu-nvme/build/qemu-system-x86_64
#image=${image:-RHEL-8.4.0-20210503.1-x86_64-dvd1.iso}
#image=${image:-gparted-live-1.3.1-1-amd64.iso}
disk="rhel8p4.img"

ram_opts="-m $((4*1024))"
#qemu="qemu-system-x86_64"
qemu_opts="-D ./qemu.log"
#trace_opts="--trace events=trace_events"
cpu_opts="-cpu qemu64,+ssse3,+sse4.1,+sse4.2"
smp_opts="-smp 8"
net_opts="-net nic,model=virtio -net user,hostfwd=tcp::13084-:22"
drive="-drive file=${disk},index=0,media=disk,format=raw"
cd_opts="-cdrom ${image}"

rp_opts="${rp_opts} -device pcie-root-port,id=rp.1,chassis=0"
slot_opts="${slot_opts} -device x3130-upstream,bus=rp.1,id=up.1 \
			-device xio3130-downstream,bus=up.1,slot=1,id=down.1 \
			-device xio3130-downstream,bus=up.1,slot=2,id=down.2 \
			-device xio3130-downstream,bus=up.1,slot=3,id=down.3 \
			-device xio3130-downstream,bus=up.1,slot=4,id=down.4"

#Mpath
nvme_subsys_opts="${nvme_subsys_opts} -device nvme-subsys,id=nvme-mpath-subsys-0"
nvme_opts="${nvme_opts} -device nvme,subsys=nvme-mpath-subsys-0,serial=c0def00d,id=nvme0c0"
nvme_opts="${nvme_opts} -device nvme,subsys=nvme-mpath-subsys-0,serial=c0def00d,id=nvme0c1"
ns_opts="${ns_opts} -drive file=mpath_nsid1.qcow2,if=none,id=mpath_nsid1 -device nvme-ns,drive=mpath_nsid1,bus=nvme0c0,nsid=11,shared=off"
ns_opts="${ns_opts} -drive file=mpath_nsid2.qcow2,if=none,id=mpath_nsid2 -device nvme-ns,drive=mpath_nsid2,bus=nvme0c1,nsid=12,shared=off"

nvme_subsys_opts="${nvme_subsys_opts} -device nvme-subsys,id=nvme-subsys-1"
nvme_opts="${nvme_opts} -device nvme,subsys=nvme-subsys-1,serial=coffee12,id=nvme1c0"
ns_opts="${ns_opts} -drive file=mpath_nsid3.qcow2,if=none,id=mpath_nsid3 -device nvme-ns,drive=mpath_nsid3,bus=nvme1c0,nsid=13"
ns_opts="${ns_opts} -drive file=mpath_nsid4.qcow2,if=none,id=mpath_nsid4 -device nvme-ns,drive=mpath_nsid4,bus=nvme1c0,nsid=14"


#ZNS
nvme_subsys_opts="${nvme_subsys_opts} -device nvme-subsys,id=nvme-zns-subsys-0"
nvme_opts="${nvme_opts} -device nvme,subsys=nvme-zns-subsys-0,serial=coffee34,id=nvme-zns-0"
#Solidigm/Intel 144M zone size/cap
ns_opts="${ns_opts} -drive file=zns_nsid1.qcow2,if=none,id=zns_nsid1 \
          -device nvme-ns,drive=zns_nsid1,bus=nvme-zns-0,nsid=1,zoned=true,zoned.zone_size=144M,zoned.zone_capacity=144M,uuid=cf0f1289-692e-4ec4-bfbd-f3497e2f7647"
#128M zone size/cap
ns_opts="${ns_opts} -drive file=zns_nsid2.qcow2,if=none,id=zns_nsid2 \
          -device nvme-ns,drive=zns_nsid2,bus=nvme-zns-0,nsid=2,zoned=true,zoned.zone_size=128M,zoned.zone_capacity=128M,uuid=5d7f52c9-a08b-4ec4-a97d-469900b3b7cd"
#128M zone size, 144M zone cap
ns_opts="${ns_opts} -drive file=zns_nsid3.qcow2,if=none,id=zns_nsid3 \
          -device nvme-ns,drive=zns_nsid3,bus=nvme-zns-0,nsid=3,zoned=true,zoned.zone_size=256M,zoned.zone_capacity=144M,uuid=908d167c-1eec-497d-9398-97c552be49fb"


#Regular
nvme_opts="${nvme_opts} -device nvme,serial=c0def00d1,id=nvme0,bus=down.1"
ns_opts="${ns_opts} -drive file=nsid1.qcow2,if=none,id=nsid1 -device nvme-ns,drive=nsid1,bus=nvme0,nsid=1"

nvme_opts="${nvme_opts} -device nvme,serial=c0def00d2,id=nvme1,bus=down.2"
ns_opts="${ns_opts} -drive file=nsid2.qcow2,if=none,id=nsid2 -device nvme-ns,drive=nsid2,bus=nvme1,nsid=2"

nvme_opts="${nvme_opts} -device nvme,serial=c0def00d3,id=nvme2,bus=down.3"
ns_opts="${ns_opts} -drive file=nsid3.qcow2,if=none,id=nsid3 -device nvme-ns,drive=nsid3,bus=nvme2,nsid=3"

nvme_opts="${nvme_opts} -device nvme,serial=c0def00d4,id=nvme3,bus=down.4"
ns_opts="${ns_opts} -drive file=nsid4.qcow2,if=none,id=nsid4 -device nvme-ns,drive=nsid4,bus=nvme3,nsid=4"



cmd="${qemu} ${qemu_opts} ${trace_opts} ${drive} ${net_opts} ${smp_opts} ${ram_opts} \
	${rp_opts} ${slot_opts} ${nvme_subsys_opts} ${nvme_opts} ${ns_opts} -enable-kvm ${cpu_opts}"

rm -f trace-*
if [ "$1" == cdboot ]; then
        ${cmd} -boot d ${cd_opts}
#-display vnc:1
elif [ "$1" == cd ]; then
        ${cmd} ${cd_opts} -nographic
elif [ "$1" == gfx ]; then
#        ${cmd} -display vnc:1
        ${cmd}
else
        ${cmd} -nographic
fi

