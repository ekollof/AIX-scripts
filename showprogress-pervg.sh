#!/bin/bash
#
# Shows progress of volume group syncing by looking at stale PPs
#

hostname=${1}

if [ ${#} != 1 ]; then
    echo "${0} <LPAR>"
    exit 255
fi

mkdir -p timestamps

active=$(ssh ${hostname} lsvg -o)

total=0
for vg in ${active}; do
    vgdata=$(ssh ${hostname} lsvg ${vg})
    total_pp=$(printf "${vgdata}\n" | grep 'TOTAL PP' | awk '{print $6}')
    num_stale_pp=$(printf "${vgdata}\n" | grep 'STALE PP' | awk '{print $6}')
    pp_size=$(printf "${vgdata}\n" | grep 'PP SIZE' | awk '{print $6}')

    if ((${num_stale_pp} > 0)); then
        if [ ! -e timestamps/${hostname}-pervg-${vg}.stamp ]; then
            date +%s > timestamps/${hostname}-pervg-${vg}.stamp
        fi
        if [ ! -e timestamps/${hostname}-pervg-${vg}.numpp ]; then
            echo ${num_stale_pp} > timestamps/${hostname}-pervg-${vg}.numpp
        fi

        now=$(date +%s)
        starttime=$(cat timestamps/${hostname}-pervg-${vg}.stamp)
        startpps=$(cat timestamps/${hostname}-pervg-${vg}.numpp)

        ((delta=(now-starttime)+1))
        ((numprocessed=startpps-num_stale_pp))
        ((totalprocessed=total_pp-num_stale_pp))
        ((processed=total_pp*pp_size - totalprocessed*pp_size))
        ((stampprocessed=(numprocessed*pp_size)))
        if ((${delta} > 0)); then
            ((speed=stampprocessed/delta))
        else
            speed=0
        fi
        if ((${speed} > 0)); then
            ((secleft=processed / speed + 1))
            hsecleft=$(printf '%dh:%dm:%ds\n' $(($secleft/3600)) $(($secleft%3600/60)) $(($secleft%60)))
        else
            hsecleft="INF"
        fi

        echo "${hostname}: ${vg} : ${processed} MB remaining . ${speed} MB/sec (est). ETA ~${hsecleft}."
        ((total=total+speed))
    else
        rm -f timestamp/${hostname}-pervg-${vg}.stamp
        rm -f timestamp/${hostname}-pervg-${vg}.numpp
    fi
done

if ((${total} > 0)); then
    echo "Total throughput: ${total} MB/sec"
    echo
fi
