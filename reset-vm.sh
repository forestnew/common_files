#!/bin/bash
set -e

MACHINE=$1 #virtual machine name
SNAPSHOT=$2 #snapshot name

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
	echo -e "\nСкрипт для возврата указанной машины к указаному снапшоту\n"
	echo "Запуск: ./reset-vm.sh MACHINE_NAME SNAPSHOT_NAME"
	echo "MACHINE_NAME - наименование виртуальной машины"
	echo "SNAPSHOT_NAME - наименование снимка, для возврата"
	
elif [ ! -n "$MACHINE" ]; then
	echo -e "\nНеобходимо указать название машины"
	echo "Подробнее: ./reset-vm.sh"
	echo -e "\n\nСписок всех машин:\n"
	virsh -c qemu:///system list --all
	
elif [ ! -n "$SNAPSHOT" ]; then
	echo -e "\nНе указан снапшот для возврата, укажите из списка:\n"
	virsh -c qemu:///system snapshot-list $MACHINE
else
	if [[  $(virsh -c qemu:///system  list --all) == *" $MACHINE "* ]]; then
		if [[ $(virsh -c qemu:///system snapshot-list $MACHINE) == *" $SNAPSHOT "* ]]; then
			virsh -c qemu:///system snapshot-revert $MACHINE $SNAPSHOT
			echo "Успешно!"
		else
			echo -e "\nСнимок $SNAPSHOT не найден для $MACHINE"
			echo -e "Укажите из списка:\n"
			virsh -c qemu:///system snapshot-list $MACHINE
		fi
	else
		echo -e "\nУказанная машина не найдена"
		echo -e "\nСписок всех машин:\n"
		virsh -c qemu:///system list --all
	fi
fi


