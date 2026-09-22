#! /bin/bash
# Copyright 2025-2026 NXP

systemctl stop obmc-console@ttyVUART0.service

obmc-console-server --config /etc/obmc-console.conf ttyLP6 &

sleep 1

gpioset 0 2=0;sleep 1; gpioset 0 2=1
