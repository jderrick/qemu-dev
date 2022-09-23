#!/bin/bash
if [ "$EUID" -ne 0 ]
	then echo "Get root noob"
 	exit
fi

screen -Sdm qemu-nvme ./run.sh
