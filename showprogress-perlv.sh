#!/bin/bash
#
# Tells you which lv has stale PPs

hostname=${1}

if [ ${#} != 1 ]; then
    echo "${0} <LPAR>"
    exit 255
fi

active=$(ssh ${hostname} lsvg -o)

active_lv=$(ssh ${hostname} lsvg -l ${active} | grep open | awk '{print $1}')

for lv in ${active_lv}; do
    total_pp=$(ssh ${hostname} lslv -L ${lv} | grep 'PPs:' | head -1 | awk '{print $4}')
    num_stale_pp=$(ssh ${hostname} lslv -L ${lv} | grep 'STALE PP' | awk '{print $3}')
    if ((${num_stale_pp} > 0)); then
        ((stale_pp_count = stale_pp_count + 1))
        echo "${hostname} : ${lv} has ${num_stale_pp}/${total_pp} stale PPs"
    fi
done
