#!/bin/bash
#clear

INTERFACES=$(ip -o link show | awk -F': ' '{print $2}' | sort)  #Interfaces de rede ordenadas por ordem alfabética
DATA_SIZE=-1                                                    #Valor default da tipo de dados (bytes) 1=Kb 2=Mb
TIME=${@: -1}                                                   #Input do utilizador do tempo que o programa deve correr
REGEX_STR=-1                                                    #Regex inserida quando utilizada a flag -c
LIST_SIZE=-1                                                    #Inteiro positivo que define o número de interfaces a mostar quando utilizada a flag -p
SORT_TYPE=-1                                                    #Inteiro que define o tipo de ordenação usada quando utilizado as opções de ordenação
IS_LOOP=0                                                       #(0-1) define se o programa deve ser corrido em loop (flag -l)
IS_REVERSE=0                                                    #(0-1) define se a flag -v foi utilizada para mostrar a ordem inversa


#Função onde o script é iniciado e onde a ordem de execução das funções é definida 
function main() {
    validate_args $@                                            #Validação dos dados inseridos
    data_cleansing                                              #Filtragem das interfaces a mostrar consoante as opções usadas
    print_data                                                  #Impressão da tabela de dados gerada após o tratamento dos dados
}

# Função responsável pela validação dos dados e das opções inseridos pelo user
# Através do comando getopts são verificadas as opções inseridas e em cada uma
# é executada uma diferente tarefa
# -c é passado para a variável REGEX_STR o valor da regex inserida
# -p é verificado se o valor inserido é um número inteiro positivo 
# e passado para a variável LIST_SIZE
# -b/-k/-m é verificado se não estão a ser usadas duas em simultâneo caso contrário
# é passado um código para a variável DATA_SIZE
# -t-/T/-r/-R funcionamento semelhante aos comandos anteriores onde a variável é SORT_TYPE
# -v é passado para a variável IS_REVERSE o valor 1
function validate_args() {

    while getopts 'c:p:bkmltrTRv' option; do
        case ${option} in
            c )
                validate_regex_string
            ;;

            p ) 
                validate_list_size
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
                IS_REVERSE=1
            ;;
            
            l )
                IS_LOOP=1
            ;;

        esac
    done

}

# Função responsável por validar os dados das opções -b/-k/-m
# Verifica se DATA_SIZE continua com o valor -1 (ainda não usada)
# caso seja -1 DATA_SIZE passa a ser igual ao argumento passado para a função
# caso seja diferente -1 envia mensagem de erro
function validate_data_size () {
        if [[ $DATA_SIZE -eq -1 ]];then
        DATA_SIZE=$1
    else
        echo "ERRO! Múltiplos valores foram inseridos para o tamanho da informação"
        exit 1
    fi

}

# Função responsável por validar os dados das opções -t-/T/-r/-R
# Verifica se SORT_TYPE continua com o valor -1 (ainda não usada)
# caso seja -1 SORT_TYPE passa a ser igual ao argumento passado para a função
# caso seja diferente -1 envia mensagem de erro
function validate_sort_type () {
        if [[ $SORT_TYPE -eq -1 ]];then
        SORT_TYPE=$1
    else
        echo "ERRO! Múltiplos valores foram inseridos para o tipo de sort"
        exit 1
    fi
}


# Função responsável por validar os dados das opção -p
# Caso a opção seja usada mais que uma vez o script deve
# Lançar um erro e parar imediatamente. Começa-se por validar
# se o $LIST_SIZE é -1 (ainda não usado) e depois é validado se
# o valor inserido é um valor inteiro positivo

function validate_list_size () {
    if [[ $LIST_SIZE -eq -1 ]];then 
        if [[ ${OPTARG} =~ ^[0-9]+$ ]]; then
            LIST_SIZE=${OPTARG}
        else
            echo "ERRO! valor inválido para -p"
            exit 1
        fi
    else
        echo "ERRO! Opção -p inserida mais que uma vez"
        exit 1
    fi

}

# Função responsável por validar os dados das opção -c
# Caso a opção seja usada mais que uma vez o script deve
# Lançar um erro e parar imediatamente. Começa-se por validar
# se o $REGEX_STR é -1 (ainda não usado)
function validate_regex_string () {
    if [[ $REGEX_STR = -1 ]]; then
        REGEX_STR=${OPTARG}
    else
        echo "ERRO a opção -c foi utilizada mais do que uma vez"
        exit 1
    fi
}


# Função responsável pela filtragem das interfaces consoante os filtros
# selecionados pelo utilizador. Começa por verificar a Regex inserida e
# itera por todas as Interfaces adicionando a interfaces_filtered as válidas
# passa a seguir para o número de interfaces a mostrar (-p) com o comando cut
# são selecionadas da interface 1 até n e o resto é removido
# Caso não seja selecionada nenhuma opção de tamanho de dados é assumido o -b(código 0)
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

# Função responsável pela impressão dos resultados
# É efetuada a recolha de dados uma primeira vez e
# a seguir é feito um sleep para dar o intervalo de recolha de dados
# e estes guardados num array
# terminado o sleep é efetuada a segunda iteração sobre as interface
# para recolher os dados finais e calculados os valores a mostrar 
function print_table() {
    local ITF_DATA=()
    local LOOP_DATA=()
    for i in $INTERFACES
    do
        ITF_DATA+=($(ifconfig $i | awk '/RX packets /{print $5}'))
        ITF_DATA+=($(ifconfig $i | awk '/TX packets /{print $5}'))
    done
    sleep $TIME    
    
    idx=-1
    for i in $INTERFACES
    do
        #TX do intervalo (final - inicial)
        TX=$(($(ifconfig $i | awk '/RX packets /{print $5}')-${ITF_DATA[$(($idx+1))]}))
        #RX do intervalo (final - inicial)
        RX=$(($(ifconfig $i | awk '/TX packets /{print $5}')-${ITF_DATA[$(($idx+2))]}))

        

        if [[ ! $DATA_SIZE = 0 ]];then
            TX=$(echo "scale=2 ;$TX/1024*$DATA_SIZE" | bc)
            RX=$(echo "scale=2 ;$RX/1024*$DATA_SIZE" | bc)
        fi

        TXRATE=$(echo "scale=2;$TX/$TIME" | bc)
        RXRATE=$(echo "scale=2;$RX/$TIME" | bc)
                
        LOOP_DATA[$idx+1]=$((${LOOP_DATA[$idx+1]}+$TX))
        LOOP_DATA[$idx+1]=$((${LOOP_DATA[$idx+1]}+$RX))

        if [[ $IS_LOOP = 0 ]]; then
            local TABLECONTENT="%-20s %-12s %-12s %-12.1f %-12.1f\n"
            printf "$TABLECONTENT" "$i" "$TX" "$RX" "$TXRATE" "$RXRATE"
        else
            local TABLECONTENT="%-20s %-12s %-12s %-12.1f %-12.1f %-12.1f %-12.1f\n"
            printf "$TABLECONTENT" "$i" "$TX" "$RX" "$TXRATE" "$RXRATE" "${LOOP_DATA[$idx+1]}" "${LOOP_DATA[$idx+2]}"
        fi
        #Como sabemos que queremos apenas o TX e o RX sabemos que ao ir buscar a informação ao vetor é sempre idx+1 ou idx+2
        ((idx+=2)) 
    done
}

function print_sorted_data() {
        case $SORT_TYPE in
        -1 ) 
            print_table $INTERFACES
        ;;
        1 )
            print_table $INTERFACES | sort -k 2 -n $( (( IS_REVERSE == 0 )) && printf %s '-r' )
        ;;

        2 )
            print_table $INTERFACES | sort -k 3 -n -r $( (( IS_REVERSE == 0 )) && printf %s '-r' )
        ;;

        3 )
            print_table $INTERFACES | sort -k 4 -n -r $( (( IS_REVERSE == 0 )) && printf %s '-r' )
        ;;

        4 )
            print_table $INTERFACES | sort -k 5 -n -r $( (( IS_REVERSE == 0 )) && printf %s '-r' )
        ;;

        5 )
            print_table $INTERFACES | sort -r $( (( IS_REVERSE == 0 )) && printf %s '-r' )
        ;;
    esac
}



function print_data() {
    if [[ $IS_LOOP = 0 ]];then
        local TABLEHEADER="%-20s %-12s %-12s %-12s %-12s\n"
        printf "$TABLEHEADER" "NETIF" "TX" "RX" "TRATE" "RRATE"
        print_sorted_data
    else
        local TABLEHEADER="%-20s %-12s %-12s %-12s %-12s %-12s %-12s\n"
        printf "$TABLEHEADER" "NETIF" "TX" "RX" "TRATE" "RRATE" "TXTOT" "RXTOT"

        while :
        do
            print_sorted_data
            printf "\n"
        done   
    fi 
}


main $@
