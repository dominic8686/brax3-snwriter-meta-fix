#!/system/bin/sh
# TEMP META diagnostic - NOT for commit. Runs as u:r:su:s0, writes /mnt/vendor/nvdata.
#
# HYPOTHESIS TEST: /linkerconfig/ld.config.txt stays a 1-byte stub in META because
# perform_apex_config never runs (its post-fs-data block breaks on /data-dependent
# bind mounts, since /data is not mounted). The linkerconfig BINARY works fine.
# So: explicitly regenerate /linkerconfig here, then test whether keystore2 can link.
# If it links after regen -> the fix is "generate the config in META" (then restore
# keystore2 + mount_all). bx-keystore2.txt holds the before/after.
D=/mnt/vendor/nvdata
auditctl -r 0 -b 16384 2>/dev/null
for f in stacks ps linker keystore2; do : > $D/bx-$f.txt; done
getprop > $D/bx-props.txt 2>&1
getenforce > $D/bx-enforce.txt 2>&1

ACTORS="nvram_daemon meta_tst mtk_hal_nvramagent nvram_agent ccci_mdinit ccci_rpcd atcid md_ctrl"
LC=/linkerconfig/ld.config.txt

i=0
while [ $i -lt 90 ]; do
    auditctl -r 0 2>/dev/null
    UP=$(cat /proc/uptime 2>/dev/null | cut -d. -f1)

    # --- backup-actor kernel stacks ---
    {
        echo "======== loop $i  up=${UP}s  $(date) ========"
        for a in $ACTORS; do
            for pid in $(pidof "$a" 2>/dev/null); do
                echo "--- $a pid=$pid state=$(awk '{print $3}' /proc/$pid/stat 2>/dev/null) wchan=$(cat /proc/$pid/wchan 2>/dev/null) ---"
                cat /proc/$pid/stack 2>/dev/null
            done
        done
    } >> $D/bx-stacks.txt 2>&1
    ps -A -o PID,PPID,STAT,WCHAN:24,NAME 2>/dev/null | grep -iE "STAT|nvram|meta|ccci|md_|atci| D " >> $D/bx-ps.txt 2>&1

    # --- linkerconfig state each loop ---
    {
        echo "==== linker loop $i up=${UP}s  apexd.status=$(getprop apexd.status) ===="
        echo "ld.config.txt bytes : $(wc -c < $LC 2>/dev/null)"
        echo "default.links       : $(grep -m1 '^namespace.default.links' $LC 2>/dev/null)"
        echo "i18n apex lib       : $(ls /apex/com.android.i18n/lib64/libandroidicu.so 2>/dev/null || echo MISSING)"
    } >> $D/bx-linker.txt 2>&1

    # --- keystore2 link test (no LD_DEBUG; 'CANNOT LINK' => broken, runs => links).
    #     NO script-side regen here -- the init `exec linkerconfig` must do it. ---
    if [ $((i % 2)) -eq 0 ]; then
        {
            echo "==== keystore2 loop $i up=${UP}s (config=$(wc -c < $LC 2>/dev/null)B) ===="
            timeout 3 /system/bin/keystore2 2>&1 | head -6
            echo "(done)"
        } >> $D/bx-keystore2.txt 2>&1
    fi

    dmesg 2>/dev/null | grep -i "avc:" > $D/.a.tmp 2>&1; mv $D/.a.tmp $D/bx-avc.txt 2>/dev/null
    if [ $((i % 3)) -eq 0 ]; then
        dmesg > $D/.d.tmp 2>&1; mv $D/.d.tmp $D/bx-dmesg2.txt 2>/dev/null
        logcat -b all -d > $D/.l.tmp 2>&1; mv $D/.l.tmp $D/bx-logcat2.txt 2>/dev/null
    fi
    sync
    i=$((i+1))
    sleep 2
done
