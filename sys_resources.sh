#!/usr/bin/env bash
# Stupid Simple SymMon
# ShiTTY System Monitor = SS Mon = SSM
# mini-top
# "This script will display CPU, MEM, DSK & UP-TIME metrics."

echo "==================== SS Monitor ===================="
# echo "Enter which resource you wish to display."
# printf "1: Uptime\n2: CPU\n3: MEM\n4: DSK\n5: All\nShow me: "


# read resource_choice
resource_choice=5 # debug line

get_uptime(){
    # echo $((($(date +%s) - $(sysctl -n kern.boottime | awk '{print $4}' | tr -d ','))/3600)) | awk '{print "This is uptime in hours: \n" $1}'
    boot_time=$(sysctl kern.boottime | awk '{print $5}' | tr -d ',')
    cur_time=$(date +%s)
    uptime_sec=$(((cur_time - boot_time)%60))
    uptime_min=$(((((cur_time - boot_time)%86400)%3600)/60))
    uptime_hours=$(((cur_time - boot_time)%86400/3600))
    uptime_days=$(((cur_time - boot_time)/86400))
    echo "Uptime: $uptime_days days, $uptime_hours hours, $uptime_min minutes, $uptime_sec seconds"
}
# Get CPU Resource Function
get_cpu_usage(){
    # cpu_data=$(ps Ao %cpu | awk '{ sum += $1 } END { print sum }')
    cpu_data=$(ps -A -o %cpu | awk '{s+=$1} END {print s "%"}')
    if [[ ${resource_choice} -eq 2 ]]; then
        echo "CPU Usage: ${cpu_data}"
    else
        echo -e "$cpu_data"
    fi
}

get_mem_usage(){
    # mem_data=$(top -l 1 | awk '/PhysMem/ {used=$2; total=($8/1024)+used; print (used/total)*100 "%"}')
    total_mem=$(sysctl -n hw.memsize | awk '{print ($1 / 1024 / 1024 ) / 1024 " GiB"}')
    used_mem=$(vm_stat | awk '
        /Pages active/ {active=$3}
        /Pages inactive/ {inactive=$3}
        /Pages wired down/ {wired=$NF}
        /Pages purgeable/ {purged=$3}
        END {printf "%.2f", ((active+wired+inactive+purged) * 4096 / 1024 / 1024) / 1024}')
    # used_mem= $(ps -Am -orss= | awk '{sum += $1} END {print sum/1024}')
    mem_data="$used_mem / $total_mem"
    if [[ ${resource_choice} -eq 3 ]]; then
        echo -e "RAM: $mem_data"
    else
        echo -e "$mem_data"
    fi
}

get_dsk_usage(){
    if [[ ${resource_choice} -eq 4 ]]; then
        df -H /System/Volumes/Data | awk 'NR<=2 {print $3, "/", $2}'
    else
        df -H /System/Volumes/Data | awk 'NR==2 {print $3, "/", $2}'
    fi
    # echo $(df -H /System/Volumes/Data | awk 'NR>1 { printf "\n%25s %10s %10s %10s", $1, $2, $3, $4 }')
}

associative_resource(){
    declare -A resource_options
    resource_option[1]="ALL"
    resource_option[2]="CPU"
    resource_option[3]="MEM"
    resource_option[4]="DSK"
    resource_option[5]="UP-TIME"

    # declare -A sys_resource
    # sys_resource["CPU"]=$(ps Ao %cpu | awk '{ sum += $1 } END { print sum }')
    # sys_resource["MEM"]=$(ps Ao %mem | awk '{ sum += $1 } END { print sum }')
    # sys_resource["DSK"]=$(df -H /dev/$(diskutil list | grep ' - Data' | awk '{ print $10}') | awk 'NR>1 { printf "\n%25s %10s %10s %10s", $1, $2, $3, $4 }') # switch to /System/Volumes/Data for stability
    # sys_resource["UP-TIME"]=$(get_uptime)

    declare -A sys_resource
    sys_resource["CPU"]=$(ps Ao %cpu | awk '{ sum += $1 } END { print sum }')
    sys_resource["MEM"]=$(ps Ao %mem | awk '{ sum += $1 } END { print sum }')
    sys_resource["DSK"]=$(df -H /dev/$(diskutil list | grep ' - Data' | awk '{ print $10}') | awk 'NR>1 { printf "\n%25s %10s %10s %10s", $1, $2, $3, $4 }') # switch to /System/Volumes/Data for stability
    sys_resource["UP-TIME"]=$(get_uptime)
}


# echo "Good choice! - ${resource_option[${resource_choice}]}" # debug line

echo "============== Your Resource(s) ================"
if [[ ${resource_choice} -eq 1 ]]; then
    echo $(get_uptime)

elif [[ $resource_choice -eq 2 ]]; then
	echo "$(get_cpu_usage)"

elif [[ $resource_choice -eq 3 ]]; then
	echo "$(get_mem_usage)"

elif [[ $resource_choice -eq 4 ]]; then
    echo "$(get_dsk_usage)"
	# dsk_usage=${sys_resource[${resource_option[${resource_choice}]}]}
	# echo "DSK Usage:      Source          Size       Used     Available$dsk_usage"

elif [[ $resource_choice -eq 5 ]]; then
    # Define color codes
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    ORANGE='\033[38;5;215m'
    CYAN='\033[0;36m'
    RESET='\033[0m'

    while true; do
        clear
        echo "==================== SSMonitor ===================="
        printf "${CYAN}$(get_uptime)${RESET}\n"
        printf "${ORANGE}CPU Usage(1)${RESET} \t ${RED}MEM Usage(2)${RESET} \t ${GREEN}DSK Usage(3)${RESET}\n"
        printf "%7s\t%20s \t%-5s\n" "$(get_cpu_usage)" "$(get_mem_usage)" "$(get_dsk_usage)"
        # sleep 1
        echo -e "\n\n\n"
        read -t 1 -p "Zoom(Telescope) Into Resource......like a pirate...." decision
    done
fi
