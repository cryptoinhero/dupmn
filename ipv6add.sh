#!/bin/bash

readonly GRAY='\e[1;30m'
readonly DARKRED='\e[0;31m'
readonly RED='\e[1;31m'
readonly DARKGREEN='\e[0;32m'
readonly GREEN='\e[1;32m'
readonly DARKYELLOW='\e[0;33m'
readonly YELLOW='\e[1;33m'
readonly DARKBLUE='\e[0;34m'
readonly BLUE='\e[1;34m'
readonly DARKMAGENTA='\e[0;35m'
readonly MAGENTA='\e[1;35m'
readonly DARKCYAN='\e[0;36m'
readonly CYAN='\e[1;36m'
readonly UNDERLINE='\e[1;4m'
readonly NC='\e[0m'

function echo_json() {
    [[ -t 3 ]] && echo -e "$1" >&3
}

function cmd_help() {
    echo -e "Options:\
            \n  - ${YELLOW}./ipv6add.sh add <count> <ip> <netmask> ${NC} Allows the system IPv6 from the ip with the count."
}

function ipadd(){
    count=$1
    start_ipv6=$2
    suffix=${start_ipv6##*:}
    len=${#start_ipv6}-${#suffix}
    prefix="${start_ipv6:0:$len}"
    first=$((0x$suffix))
    for ((i = first; i < first + count; i++)); do
      ip=$(printf "%s%04x\n" $prefix $i)
      dupmn ipadd $ip 64
    done
}
function main() {
    function exit_no_param() {
        # <$1 = param> | <$2 = message>
        if [[ ! $1 ]]; then
            echo -e "$2"
            echo_json "{\"error\":\"$(echo "$2" | sed 's/\\e\[[0-9;]*m//g')\",\"errcode\":3}"
            exit
        fi
    }
    function ip_parse() {
        # <$1 = IPv4 or IPv6> | [$2 = IPv6 brackets]

        IP=$1

        local ipv4_regex="^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"
        local ipv6_regex=(
                "^([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}$|"
                "^([0-9a-fA-F]{1,4}:){1,7}:$|"
                "^([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}$|"
                "^([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}$|"
                "^([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}$|"
                "^([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}$|"
                "^([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}$|"
                "^[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})$|"
                "^:((:[0-9a-fA-F]{1,4}){1,7}|:)$"
        )

        if [[ "$1" =~ $ipv4_regex ]]; then
            IP_TYPE=4
            return
        elif [[ "$1" =~ $(printf "%s" "${ipv6_regex[@]}") ]]; then

            [[ $(echo $IP | grep "^:") ]] && IP="0${IP}"

            if [[ $(echo $IP | grep "::") ]]; then
                IP=$(echo $IP | sed "s/::/$(echo ":::::::::" | sed "s/$(echo $IP | sed 's/[^:]//g')//" | sed 's/:/:0/g')/")
            fi

            IP=$(echo $IP | grep -o "[0-9a-f]\+" | sed "s/^/0x/" | xargs printf "%x\n" | paste -sd ":" | sed "s/:0:/::/")

            while [[ "$IP" =~ "::0:" ]]; do
                IP=$(echo $IP | sed 's/::0:/::/g')
            done
            while [[ "$IP" =~ ":::" ]]; do
                IP=$(echo $IP | sed 's/:::/::/g')
            done

            [[ "$2" == "1" ]] && IP="[$IP]"
            IP_TYPE=6
            return
        fi

        echo -e "${GREEN}$1${NC} doesn't have the structure of a IPv4 or a IPv6"
        echo_json "{\"error\":\"not a IP: $1\",\"errcode\":300}"
        exit
    }
    case "$1" in
      "help")
        cmd_help
        ;;
      "add")
        exit_no_param "$3" "${YELLOW}./ipv6add.sh ipadd <count> <ip> <netmask> [interface]${NC}"
        ip_parse $3
        ipadd $2 $3
        ;;
    esac
}
main $@