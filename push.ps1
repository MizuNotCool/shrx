#!/usr/bin/env pwsh

param(
    [switch]$reboot = $false,
    [switch]$use_remount = $false
)

adb wait-for-device root
adb wait-for-device shell "mount | grep -q ^tmpfs\ on\ /system && umount -fl /system/{bin,etc} 2>/dev/null"
if ($use_remount) {
    adb wait-for-device shell "remount"
} elseif ((adb shell stat -f --format %a /system) -eq "0") {
    Write-Error "ERROR: /system has 0 available blocks, consider using -use_remount" -ErrorAction Stop
} else {
    adb wait-for-device shell "stat --format %m /system | xargs mount -o rw,remount"
}

if ("adb shell 'ls /system/bin/shrx 2> /dev/null'" -eq "/system/bin/shrx") {
    echo "Removing existing shrx files"
    adb wait-for-device shell "find /system -name *shrx* -delete"
    exit
}

adb wait-for-device push system/addon.d/60-shrx.sh /system/addon.d/
adb wait-for-device push system/bin/shrx /system/bin/
adb wait-for-device push system/etc/init/shrx.rc /system/etc/init/

$serialno = adb shell getprop ro.boot.serialno
$product = adb shell getprop ro.build.product

if (Test-Path "system/etc/shrx.conf.${serialno}" -PathType leaf) {
    adb wait-for-device push system/etc/shrx.conf.${serialno} /system/etc/shrx.conf
} elseif (Test-Path "system/etc/shrx.conf.${product}" -PathType leaf) {
    adb wait-for-device push system/etc/shrx.conf.${product} /system/etc/shrx.conf
} else {
    adb wait-for-device push system/etc/shrx.conf /system/etc/
}

if ($reboot) {
    adb wait-for-device reboot
}
