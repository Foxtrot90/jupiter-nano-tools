#!/bin/bash
boot_arg=jupiternano.disable_charging

if grep -iq "${boot_arg}=[a-zA-Z0-9]" /proc/cmdline
then
    sudo i2cset -f -y 0 0x5b 0x71 129
    echo "Battery charging disabled"
else
    sudo i2cset -f -y 0 0x5b 0x71 0x00
    echo "Battery charging enabled"
fi

if grep -iq "${boot_arg}=[a-zA-Z0-9]" /proc/cmdline
then
    sudo i2cset -f -y 1 0x5b 0x71 129
    echo "Battery charging disabled"
else
    sudo i2cset -f -y 1 0x5b 0x71 0x00
    echo "Battery charging enabled"
fi
