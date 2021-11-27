#!/bin/bash
clear

INTERFACES=$(ip -o link show | awk -F': ' '{print $2}' | xargs -n1 | sort | xargs)
DATA_SIZE=-1 #Valor default da tipo de dados (bytes) 1=Kb 2=Mb
TIME=${@: -1}
REGEX_STR=-1
LIST_SIZE=-1
IS_LOOP=0

function main() {
    validate_args $@
    data_cleansing
    print_table $INTERFACES
}



function validate_args() {
    while getopts 'c:p:bkml' option; do
        case ${option} in
            c )
                REGEX_STR=${OPTARG}
            ;;

            p ) 
                if [[ ${OPTARG} =~ ^[0-9]+$ ]]; then
                    LIST_SIZE=${OPTARG}
                else
                    echo "ERRO! valor inválido para -p"
                    exit 1
                fi
            ;;

            b )
                if [ $DATA_SIZE -eq -1 ];then
                    DATA_SIZE=0
                else
                    echo "ERRO! Múltiplos valores foram inseridos para o tamanho da informação"
                    exit 1
                fi
            ;;
            k ) 
                if [[ $DATA_SIZE -eq -1 ]];then
                    DATA_SIZE=1
                else
                    echo "ERRO! Múltiplos valores foram inseridos para o tamanho da informação"
                    exit 1
                fi
            ;;
            m ) 
                if [[ $DATA_SIZE -eq -1 ]];then
                    DATA_SIZE=2
                else
                    echo "ERRO! Múltiplos valores foram inseridos para o tamanho da informação"
                    exit 1
                fi
            ;;
        esac
    done

}



function data_cleansing () {
    local interfaces_filtered=()
    if [[ ! $REGEX_STR = -1 ]]; then
        for int in $INTERFACES; do
            if [[ $int =~ $REGEX_STR ]]
            then
                interfaces_filtered+=($int)
            fi
        done
        INTERFACES=${interfaces_filtered[@]}
    fi
    

    if [[ ! $LIST_SIZE = -1 ]]; then
        INTERFACES=$(cut -d ' ' -f 1-$LIST_SIZE <<< $INTERFACES)
    fi   
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