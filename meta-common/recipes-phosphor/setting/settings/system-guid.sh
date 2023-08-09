#!/bin/bash

uid="/etc/machine-id"
service="xyz.openbmc_project.Settings"
objPath="/xyz/openbmc_project/control/host0/systemGUID"
uuidInterface="xyz.openbmc_project.Common.UUID"
uuidProperty="UUID"

line=`awk '{ print }' $uid`
echo $line
uuid="${line:0:8}-${line:8:4}-${line:12:4}-${line:16:4}-${line:20:12}"
busctl set-property $service $objPath $uuidInterface $uuidProperty s $uuid
