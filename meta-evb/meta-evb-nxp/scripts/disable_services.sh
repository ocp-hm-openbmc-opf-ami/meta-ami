#! /bin/bash
# Copyright 2025-2026 NXP

systemctl disable systemd-networkd-wait-online.service

mkdir -p /etc/systemd/system/systemd-networkd-wait-online.service.d
echo -e "[Service]\nExecStart=\nExecStart=/usr/lib/systemd/systemd-networkd-wait-online --timeout=5" > /etc/systemd/system/systemd-networkd-wait-online.service.d/override.conf
systemctl daemon-reexec

systemctl disable uart-render-controller.service
systemctl stop uart-render-controller.service

systemctl disable trace-enable.service
systemctl stop trace-enable.service

reboot
