#!/bin/bash
#clear

INTERFACES=$(ip -o link show | awk -F': ' '{print $2}' | xargs -n1 | sort | xargs)
DATA_SIZE=-1 #Valor default da tipo de dados (bytes) 1=Kb 2=Mb
TIME=${@: -1}
REGEX_STR=-1
LIST_SIZE=-1
SORT_TYPE=-1
IS_LOOP=0

function main() {
    validate_args $@
    data_cleansing
    print_data
}

function validate_args() {
    while getopts 'c:p:bkmltrTRv' option; do
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
                validate_data_size 0
            ;;
            k ) 
                validate_data_size 1
            ;;
            m ) 
                validate_data_size 2
            ;;

            t )
                validate_sort_type 1
            ;;
            
            r )
                validate_sort_type 2
            ;;
            
            T )
                validate_sort_type 3
            ;;
            
            R )
                validate_sort_type 4
            ;;
            
            v )
                validate_sort_type 5
            ;;


        esac
    done

}

function validate_data_size () {
        if [[ $DATA_SIZE -eq -1 ]];then
        DATA_SIZE=$1
    else
        echo "ERRO! Múltiplos valores foram inseridos para o tamanho da informação"
        exit 1
    fi

}


function validate_sort_type () {
        if [[ $SORT_TYPE -eq -1 ]];then
        SORT_TYPE=$1
    else
        echo "ERRO! Múltiplos valores foram inseridos para o tipo de sort"
        exit 1
    fi

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

    if [[ $DATA_SIZE = -1 ]]; then
        DATA_SIZE=0
    fi
}

function print_table() {
    local TABLECONTENT="%-20s %-12s %-12s %-12.2f %-12.2f\n"
    local ITF_DATA=()

    for i in $@
    do
        ITF_DATA+=($(ifconfig $i | awk '/RX packets /{print $5}'))
        ITF_DATA+=($(ifconfig $i | awk '/TX packets /{print $5}'))
    done
    sleep $TIME    
    
    
    idx=-1
    for i in $@
    do
        #TX do intervalo (final - inicial)
        TX=$(($(ifconfig $i | awk '/RX packets /{print $5}')-${ITF_DATA[$(($idx+1))]}))
        #RX do intervalo (final - inicial)
        RX=$(($(ifconfig $i | awk '/TX packets /{print $5}')-${ITF_DATA[$(($idx+2))]}))

        if [[ ! $DATA_SIZE = 0 ]];then
            TX=$(($TX/1024*$DATA_SIZE))
            RX=$(($RX/1024*$DATA_SIZE))
        fi

        TXRATE=$(($TX/$TIME))
        RXRATE=$(($RX/$TIME))
        #Como sabemos que queremos apenas o TX e o RX sabemos que ao ir buscar a informação ao vetor é sempre idx+1 ou idx+2
        ((idx+=2)) 
        printf "$TABLECONTENT" "$i" "$TX" "$RX" "$TXRATE" "$RXRATE"
    done
}



function print_data() {
    if [[ $IS_LOOP = 0 ]]; then
        local TABLEHEADER="%-20s %-12s %-12s %-12s %-12s\n"
        printf "$TABLEHEADER" "NETIF" "TX" "RX" "TRATE" "RRATE"
        
        case $SORT_TYPE in
            -1 ) 
                print_table $INTERFACES
            ;;
            1 )
                print_table $INTERFACES | sort -k 2 -n -r
            ;;

            2 )
                print_table $INTERFACES | sort -k 3 -n -r
            ;;

            3 )
                print_table $INTERFACES | sort -k 4 -n -r
            ;;

            4 )
                print_table $INTERFACES | sort -k 5 -n -r
            ;;

            5 )
                print_table $INTERFACES | sort -r
            ;;
        
        
        esac
    else
        local TABLEHEADER="%-20s %-12s %-12s %-12s %-12s\n"
        #TODO esta é para o loop
    fi

}

main $@