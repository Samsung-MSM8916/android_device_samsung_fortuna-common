#!/system/bin/sh
# Copyright (c) 2009-2013, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

#Read the arguments passed to the script
config="$1"

LOG_TAG="qcom-bluetooth"
LOG_NAME="${0}:"

loge ()
{
  /system/bin/log -t $LOG_TAG -p e "$LOG_NAME $@"
}

logi ()
{
  /system/bin/log -t $LOG_TAG -p i "$LOG_NAME $@"
}

failed ()
{
  loge "$1: exit code $2"
  exit $2
}

program_bdaddr ()
{
  /system/bin/btnvtool -O
  logi "Bluetooth Address programmed successfully"
}

#
# enable bluetooth profiles dynamically
#
config_bt ()
{
  baseband=`getprop ro.baseband`
 
  case $baseband in
    "msm")
        setprop ro.qualcomm.bluetooth.opp true
        setprop ro.qualcomm.bluetooth.hfp true
        setprop ro.qualcomm.bluetooth.hsp true
        setprop ro.qualcomm.bluetooth.pbap true
        setprop ro.qualcomm.bluetooth.ftp true
        setprop ro.qualcomm.bluetooth.nap true
        setprop ro.bluetooth.sap true
        setprop ro.bluetooth.dun true
        setprop ro.qualcomm.bluetooth.map true
        setprop ro.bluetooth.hfp.ver 1.6
        setprop ro.qualcomm.bt.hci_transport smd
        ;;
  esac
  logi "Bluetooth config successfully"
}

logi "init.qcom.bt.sh config = $config"
case "$config" in
    "onboot")
        program_bdaddr
        config_bt
        exit 0
    ;;
esac

BOARD=`getprop ro.board.platform`
POWER_CLASS=`getprop qcom.bt.dev_power_class` 
LE_POWER_CLASS=`getprop qcom.bt.le_dev_pwr_class`
TRANSPORT=`getprop ro.qualcomm.bt.hci_transport`
STACK=`getprop ro.qc.bluetooth.stack`

case $POWER_CLASS in
  *) PWR_CLASS="";;
esac

case $LE_POWER_CLASS in
  *) LE_PWR_CLASS="-P 1";;
esac

eval $(/system/bin/hci_qcomm_init -e $PWR_CLASS $LE_PWR_CLASS && echo "exit_code_hci_qcomm_init=0" || echo "exit_code_hci_qcomm_init=1")

case $exit_code_hci_qcomm_init in
  0) logi "Bluetooth QSoC firmware download succeeded, $BTS_DEVICE $BTS_TYPE $BTS_BAUD $BTS_ADDRESS";;
  *) failed "Bluetooth QSoC firmware download failed" $exit_code_hci_qcomm_init;
     case $STACK in
         *)
            logi "** Bluedroid stack off **"
            setprop bluetooth.status off
        ;;
     esac

     exit $exit_code_hci_qcomm_init;;
esac

case $TRANSPORT in
    "smd")
       case $STACK in
           *)
              logi "** Bluedroid stack on **"
              setprop bluetooth.status on
           ;;
       esac
     ;;
esac

exit 0
