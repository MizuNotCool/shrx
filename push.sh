#!/bin/bash

while getopts ":-:" o; do
    case "${OPTARG}" in
        reboot)
            REBOOT=1
            ;;
        use_remount)
            USE_REMOUNT=1
            ;;
    esac
done

adb wait-for-device root
adb wait-for-device shell "mount | grep -q ^tmpfs\ on\ /system && umount -fl /system/{bin,etc} 2>/dev/null"
if [[ "${USE_REMOUNT}" = "1" ]]; then
    adb wait-for-device shell "remount"
elif [[ "$(adb shell stat -f --format %a /system)" = "0" ]]; then
    echo "ERROR: /system has 0 available blocks, consider using --use_remount"
    exit -1
else
    adb wait-for-device shell "stat --format %m /system | xargs mount -o rw,remount"
fi

if [[ `adb shell ls /system/bin/shrx 2> /dev/null` ]]; then
    echo "Removing existing shrx files"
    adb wait-for-device shell "find /system -name *shrx* -delete"
    exit 0
fi

adb wait-for-device push system/addon.d/60-shrx.sh /system/addon.d/
adb wait-for-device push system/bin/shrx /system/bin/
adb wait-for-device push system/etc/init/shrx.rc /system/etc/init/

SERIALNO=$(adb shell getprop ro.boot.serialno)
PRODUCT=$(adb shell getprop ro.build.product)

if [[ -f "system/etc/shrx.conf.${SERIALNO}" ]]; then
    adb wait-for-device push system/etc/shrx.conf.${SERIALNO} /system/etc/shrx.conf
elif [[ -f "system/etc/shrx.conf.${PRODUCT}" ]]; then
    adb wait-for-device push system/etc/shrx.conf.${PRODUCT} /system/etc/shrx.conf
else
    adb wait-for-device push system/etc/shrx.conf /system/etc/
fi

if [[ "${REBOOT}" = "1" ]]; then
    adb wait-for-device reboot
fi
