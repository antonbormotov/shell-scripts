#!/bin/bash
set -ea


for file in ./links*
do
    if [[ -f ${file} ]]; then
        printf "\nFile $(basename "$file")\n"
        sum=0
        count=0
        size=0
        while IFS='' read -r link || [[ -n "$link" ]]; do
            response_code=$(curl -sSfI -o  /dev/null "${link}" -w '%{http_code}')
            if [[ "${response_code}" = "200"  ]]; then
                let size=$(curl -sSf -o  /dev/null "${link}" -w '%{size_download}')
                count=$((count+1))
                let sum+=size
                printf "%s) %s: %s Bytes \n" "${count}" "${link}" "${size}"
            else
                printf "%s) %s: Skipping, exit code is %s \n" "${count}" "${link}" "${response_code}"
            fi
        done < "$(basename "$file")"
        if [ "${count}" -gt 0 ]; then
            let sum=sum/count/1024
            printf "Total: %s links,  avg ~%s KB \n" "${count}" "${sum}"
        else
            printf "Total: no valid urls,  skipping file %s \n" "${file}"
        fi
    fi
done
