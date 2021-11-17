#!/bin/bash
clear

INTERFACES=$(ip -o link show | awk -F': ' '{print $2}')

TIME=10

function main() {
    print_table ${INTERFACES}
    validate_args $@
}


function validate_args() {
    while getopts ':c' option; do
    case ${option} in
    c )
        echo "Cona"
    ;;
    
    ?)
      echo "Invalid option: -${OPTARG}."
      exit 2
    ;;
    esac
    done
}



function print_table() {
    local TABLEHEADER="%-20s %-12s %-12s %-12s %-12s\n"
    local TABLECONTENT="%-20s %-12s %-12s %-12.2f %-12.2f\n"
    local ITF_DATA=()
    for i in $@
    do
        ITF_DATA+=($(ifconfig $i | awk '/RX packets /{print $5}'))
        ITF_DATA+=($(ifconfig $i | awk '/TX packets /{print $5}'))
    done
    sleep $TIME    
    printf "$TABLEHEADER" "NETIF" "TX" "RX" "TRATE" "RRATE"
    
    idx=-1
    for i in $@
    do
        #TX do intervalo (final - inicial)
        TX=$(($(ifconfig $i | awk '/RX packets /{print $5}')-${ITF_DATA[$(($idx+1))]}))
        #RX do intervalo (final - inicial)
        RX=$(($(ifconfig $i | awk '/TX packets /{print $5}')-${ITF_DATA[$(($idx+2))]}))

        TXRATE=$(($TX/$TIME))
        RXRATE=$(($RX/$TIME))
        #Como sabemos que queremos apenas o TX e o RX sabemos que ao ir buscar a informação ao vetor é sempre idx+1 ou idx+2
        ((idx+=2)) 
        printf "$TABLECONTENT" "$i" "$TX" "$RX" "$TXRATE" "$RXRATE"
    done
}


main $@