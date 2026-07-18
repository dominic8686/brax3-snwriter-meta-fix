#!/system/bin/sh
# TEMP META diagnostic - NOT for commit. Captures WHY snWriter's final backup
# (REQ_BackupNvram2BinRegion / SP_META_SetCleanBootFlag_r) times out (15s) even
# though META is healthy (IMEI + modem NVRAM work). Runs as u:r:su:s0.
#
# Key addition: every 2s it dumps the KERNEL STACK (/proc/<pid>/stack), state and
# wchan of each backup actor, so during the 15s hang we can see exactly what the
# handler is blocked on (a syscall / mutex / modem-CCCI wait / socket / block I/O).
# Also keeps dmesg/logcat/avc and a full ps of D-state + nvram/meta/ccci procs.
D=/mnt/vendor/nvdata
auditctl -r 0 -b 16384 2>/dev/null
: > $D/bx-stacks.txt
: > $D/bx-ps.txt
getprop > $D/bx-props.txt 2>&1
getenforce > $D/bx-enforce.txt 2>&1

ACTORS="nvram_daemon meta_tst mtk_hal_nvramagent nvram_agent ccci_mdinit ccci_rpcd atcid md_ctrl"

i=0
while [ $i -lt 90 ]; do
    auditctl -r 0 2>/dev/null
    UP=$(cat /proc/uptime 2>/dev/null | cut -d. -f1)
    {
        echo "======== loop $i  up=${UP}s  $(date) ========"
        for a in $ACTORS; do
            for pid in $(pidof "$a" 2>/dev/null); do
                STATE=$(awk '{print $3}' /proc/$pid/stat 2>/dev/null)
                WCHAN=$(cat /proc/$pid/wchan 2>/dev/null)
                echo "--- $a pid=$pid state=$STATE wchan=$WCHAN ---"
                cat /proc/$pid/stack 2>/dev/null
                echo "  syscall: $(cat /proc/$pid/syscall 2>/dev/null)"
            done
        done
    } >> $D/bx-stacks.txt 2>&1

    ps -A -o PID,PPID,STAT,WCHAN:24,NAME 2>/dev/null | grep -iE "STAT|nvram|meta|ccci|md_|atci| D " >> $D/bx-ps.txt 2>&1
    echo "---- loop $i up=${UP}s ----" >> $D/bx-ps.txt 2>&1

    dmesg 2>/dev/null | grep -i "avc:" > $D/.bx-avc.tmp 2>&1; mv $D/.bx-avc.tmp $D/bx-avc.txt 2>/dev/null
    if [ $((i % 3)) -eq 0 ]; then
        dmesg > $D/.d.tmp 2>&1; mv $D/.d.tmp $D/bx-dmesg2.txt 2>/dev/null
        logcat -b all -d > $D/.l.tmp 2>&1; mv $D/.l.tmp $D/bx-logcat2.txt 2>/dev/null
    fi
    sync
    i=$((i+1))
    sleep 2
done
