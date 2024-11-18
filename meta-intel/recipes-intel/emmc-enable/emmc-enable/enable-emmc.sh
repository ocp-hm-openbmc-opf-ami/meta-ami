#!/bin/bash

#
# Enable EMMC storage so that it can be used by BMC
#

mountdevicemmc=mmcblk0

deleteAllPartition () {

        if [ -e /dev/"$1" ]
        then
        (
        echo o # create a new empty DOS partition table
        echo w # write table to disk and exit
        ) | fdisk /dev/"$1" > /dev/null
        else
                echo "No Such $1 in device tree"
                return 0
        fi
        return 1
}

createAllPartitions () {
        # Partition 1 - 512MB
        local -r firstSectorOfPartition1=16
        local -r lastSectorOfPartition1=1048592
        local -r firstSectorOfPartition2=1048593
        local -r lastSectorOfPartition2=2097185


         if [ -e /dev/"$1" ]
        then

        (
        echo n # add a new partition
        echo p # primary partition
        echo 1 # partition number
        echo $firstSectorOfPartition1
        echo $lastSectorOfPartition1
        echo w # write table to disk and exit
        ) | fdisk /dev/"$1" > /dev/null
        sleep 1

                mkfs.vfat /dev/"$1"p1 > /dev/null

                (
        echo n # add a new partition
        echo p # primary partition
        echo 2 # partition number
        echo $firstSectorOfPartition2
        echo $lastSectorOfPartition2
        echo w # write table to disk and exit
        ) | fdisk /dev/"$1" > /dev/null
        sleep 1

                mkfs.vfat /dev/"$1"p2 > /dev/null
        else
                return 1
        fi
        return 0
}

printAllPartitionInfo () {
       fdisk -l /dev/"$1"
}

mountPartition () {
        local partIdx=$1
        local mountPath=$2
        local devicemmc=$3

        # create directory if not exist
        if [ ! -d "$mountPath" ]; then
                mkdir -p $mountPath
        fi

        if [ "$mountPath" == "/tmp/images/" ]; then
                mount -o nosuid,noexec /dev/$devicemmc"p"$partIdx $mountPath > /dev/null
        else
                mount /dev/$devicemmc"p"$partIdx $mountPath > /dev/null
        fi
}

get_validation_hook_jumper() {
    if dbg_gpio=$(gpiofind "FM_BMC_VAL_EN"); then
        jum_val=$(gpioget $dbg_gpio);
        if [[ "$jum_val" -eq 1 ]]; then
            return 0
        fi
    fi

    return 1
}

is_partitions_present() {
        if [ -e /dev/"$1"p1 ] && [ -e /dev/"$1"p2 ]
        then
            return 0
        else
            return 1
        fi

}


main () {

        # As of now, eMMC is needed only for firmware updatee, that too
        # for large files such as BMC/BIOS full flash. These features
        # are enabled only for validation purpose. So create & mount
        # eMMC partitions only if validation hook jumper is set.
        #if ! get_validation_hook_jumper; then
        #        echo "Validation hook jumper is unset - eMMC support disabled"
        #        return
        #fi

        echo "Enabling the eMMC/SD card support..."

      if [ -e /dev/$mountdevicemmc ]
      then
        echo "found $mountdevicemmc in devices list"
        if ! is_partitions_present $mountdevicemmc; then
              echo "Creating  p1 p2 patitions on device $mountdevicemmc"
                deleteAllPartition "$mountdevicemmc"
                # As of now, Create single partition for image uploads
                createAllPartitions $mountdevicemmc
        fi

        # Mount partition 1 to "/tmp/images"
        mountPartition 1 "/tmp/images/" $mountdevicemmc

        # Mount partition 2 to "/etc/sensor-reader"
        cp /etc/sensor-reader/configuredsensors /tmp/
        mountPartition 2 "/etc/sensor-reader" $mountdevicemmc
        cp  /tmp/configuredsensors /etc/sensor-reader/

        # For debug, lets print all partitions info
        printAllPartitionInfo $mountdevicemmc

     else

        echo "No such device $mountdevicemmc present"
        # create directory if not exist
        if [ ! -d "/tmp/images" ]; then
                mkdir -p "/tmp/images"
        fi
        mount -t tmpfs -o nosuid,noexec tmpfs /tmp/images/

     fi


}

main
