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

    #sleep $TIME
    for i in $@
    do
        TXi=$(ifconfig $i | awk '/RX packets /{print $5}')
        RXi=$(ifconfig $i | awk '/TX packets /{print $5}')   
    done

    sleep $TIME

    printf "$TABLEHEADER" "NETIF" "TX" "RX" "TRATE" "RRATE"
    for i in $@
    do
        TX=$(($(ifconfig $i | awk '/RX packets /{print $5}')-$TXi))
        RX=$(($(ifconfig $i | awk '/TX packets /{print $5}')-$TXi))
       
        TXRATEi=$(($TX/$TIME))
        RXRATEi=$(($RX/$TIME))
        printf "$TABLECONTENT" "$i" "$TX" "$RX" "$TXRATE" "$RXRATE"
    done
}


main $@