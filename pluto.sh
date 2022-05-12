#!/bin/bash
touch /logi/info.log
(printf "Czas uruchomienia kontenera:\n" && date && printf "\nDostepna pamiec hosta:\n" && sed -n "1p" /proc/meminfo && printf "\nLimit pamieci przydzielony kontenerowi w bajtach:\n" && sed -n "1p" /sys/fs/cgroup/memory/memory.limit_in_bytes) > /logi/info.log
