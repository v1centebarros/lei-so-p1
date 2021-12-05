#!/bin/bash
clear

INTERFACES=($(ip -o link show | awk -F': ' '{print $2}' | sort))    #Interfaces de rede ordenadas por ordem alfabética
DATA_SIZE=-1                                                        #Valor default da tipo de dados (bytes) 0=b 1=Kb 2=Mb
TIME=${@: -1}                                                       #Input do utilizador do tempo que o programa deve correr
REGEX_STR=-1                                                        #Regex inserida quando utilizada a flag -c
LIST_SIZE=-1                                                        #Inteiro positivo que define o número de interfaces a mostar quando utilizada a flag -p
SORT_TYPE=-1                                                        #Inteiro que define o tipo de ordenação usada quando utilizado as opções de ordenação
IS_LOOP=0                                                           #(0-1) define se o programa deve ser corrido em loop (flag -l)
IS_REVERSE=0                                                        #(0-1) define se a flag -v foi utilizada para mostrar a ordem inversa
declare -a TXDATA                                                   #Array onde vai ser guardado os valores TX
declare -a RXDATA                                                   #Array onde vai ser guardado os valores RX
declare -a TXRATE                                                   #Array onde vai ser guardado os valores TXRATE
declare -a RXRATE                                                   #Array onde vai ser guardado os valores RXRATE
declare -a RXLOOP=($(for i in ${INTERFACES[@]}; do echo 0; done))   #Array onde vai ser guardado os valores RXTOT (Este vetor tem de ser inicializado com 0s senão a primeira soma é impossível)
declare -a TXLOOP=($(for i in ${INTERFACES[@]}; do echo 0; done))   #Array onde vai ser guardado os valores TXTOT (Este vetor tem de ser inicializado com 0s senão a primeira soma é impossível)
export LC_NUMERIC="en_US.UTF-8"                                     #Define o tipo de formatação dos valores numéricos (foi usado para resolver o problema de não aparecer o 0 das unidades (.23->0.23))

#Função onde o script é iniciado e onde a ordem de execução das funções é definida 
function main() {
    validate_args $@                                            #Validação dos dados inseridos
    validate_time                                               #Validação do valor de tempo
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
# Caso seja uma opção inválida, é chamada a função usage com as regras a usar
# É feito no final a validação se os argumentos inseridos foram usados corretamente, isto é, se o número de argumentos é o correto
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
            ?)
                echo "Opção Inválida: -${OPTARG}."
                echo
                usage
            ;;
        esac
    done

    if [[ $OPTIND -ne $# ]]; then
        echo "Número de argumentos inválido"
        exit 1
    fi
}

# Função que é invocada caso seja inserido um valor inválido
# Imprimindo todas as opções válidas
function usage {
        echo "Usage: $(basename $0) [-cpbkmltrTRv]" 2>&1
        echo '   -c   filtra por expressão regular'
        echo '   -p   número de interfaces a mostrar'
        echo '   -b   Mostrar dados em bytes'
        echo '   -k   Mostrar dados em kilobytes'
        echo '   -b   Mostrar dados em megabytes'
        echo '   -d   shows d in the output'
        echo '   -t   ordenar por TX'
        echo '   -r   ordenar por RX'
        echo '   -T   ordenar por TRATE'
        echo '   -R   ordenar por RRATE'
        echo '   -v   ordenar pela ordem inversa'
        exit 1
}

# Função de validação do tempo inserido
# O tempo inserido tem de ser um número inteiro positivo
# Caso não seja é impressa uma mensagem de erro e o programa termina
function validate_time () {
    if [[ ! $TIME =~ ^[1-9][0-9]*$ ]]; then
        echo "ERRO! valor inválido o tempo"
        exit 1
    fi
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
        if [[ ${OPTARG} =~ ^[1-9]+$ ]]; then
            LIST_SIZE=${OPTARG}
        else
            echo "ERRO! Valor inválido para -p"
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
        echo "ERRO! A opção -c foi utilizada mais do que uma vez"
        exit 1
    fi
}

# Função responsável pela filtragem das interfaces consoante os filtros
# selecionados pelo utilizador. Começa por verificar a Regex inserida e
# itera por todas as Interfaces adicionando a interfaces_filtered as válidas
# passa a seguir para o número de interfaces a mostrar (-p) com o comando cut
# são selecionadas da interface 1 até n e o resto é removido
# Caso esse valor seja 0 não vale a pena estar a correr o programa portanto é impressa uma mensagem de erro
# Caso não seja selecionada nenhuma opção de tamanho de dados é assumido o -b(código 0)
function data_cleansing () {
    local interfaces_filtered=()
    if [[ ! $REGEX_STR = -1 ]]; then
        for int in ${INTERFACES[@]}; do
            if [[ $int =~ $REGEX_STR ]]
            then
                interfaces_filtered+=($int)
            fi
        done
        INTERFACES=(${interfaces_filtered[@]})

        if [[ ${#INTERFACES[@]} -le 0 ]]; then
            echo "ERRO! Não há interfaces a mostrar. Experimente outra regex"
            exit 1
        fi
    fi
    
    if [[ ! $LIST_SIZE = -1 ]]; then
        INTERFACES=($(cut -d ' ' -f 1-$LIST_SIZE <<< ${INTERFACES[@]}))
    fi

    if [[ $DATA_SIZE = -1 ]]; then
        DATA_SIZE=0
    fi
}

# Função responsável pela impressão dos resultados
# Os vetores TXDATA E RXDATA são reiniciados para limpar os dados da última iteração
# É efetuada a primeira recolha de dados e são guardados os valores nos respetivos vetores
# É executado um sleep com o tempo inserido pelo utilizador
# É efetuada a segunda recolha de dados onde é calculado o valor de TX e RX
# Caso seja selecionada alguma opção de tamanho de dados, é efetuada a conversão
# É efetuado o cálculo do TXRATE e RXRATE com duas casas decimais
# Caso o script esteja a correr em loop é adicionado o TX/RX da iteração atual ao que se encontra no TX/RXLOOP 
function calculate_data() {
    local i=0
    TXDATA=()
    RXDATA=()
    for itf in ${INTERFACES[@]}
    do
        RXDATA+=($(ifconfig $itf | awk '/RX packets /{print $5}'))
        TXDATA+=($(ifconfig $itf | awk '/TX packets /{print $5}'))

    done
    sleep $TIME    
    
    for itf in ${INTERFACES[@]}
    do
        #RX do intervalo (final - inicial)
        RXDATA[i]=$(($(ifconfig $itf | awk '/RX packets /{print $5}')-${RXDATA[i]}))
        #TX do intervalo (final - inicial)
        TXDATA[i]=$(($(ifconfig $itf | awk '/TX packets /{print $5}')-${TXDATA[i]}))

        if [[ ! $DATA_SIZE = 0 ]];then
            TXDATA[i]=$(echo "scale=0 ;$TXDATA/1024*$DATA_SIZE" | bc)
            RXDATA[i]=$(echo "scale=0 ;$RXDATA/1024*$DATA_SIZE" | bc)
        fi

        TXRATE[i]=$(echo "scale=2;${TXDATA[i]}/$TIME" | bc)
        RXRATE[i]=$(echo "scale=2;${RXDATA[i]}/$TIME" | bc)

        if [[ $IS_LOOP = 1 ]]; then
            TXLOOP[i]=$(echo "scale=0;${TXLOOP[i]}+${TXDATA[i]}" | bc)
            RXLOOP[i]=$(echo "scale=0;${RXLOOP[i]}+${RXDATA[i]}" | bc)
        fi
        ((i+=1))
    done
}

# Função de print do conteúdo
# Para cada interface, é impresso o conteúdo do respectivo TX RX TRATE RXRATE
# Caso esteja a correr em loop (IS_LOOP != 1) são adicionadas mais duas colunas com os totais
function print_table () {
    local i=0
    for int in ${INTERFACES[@]}; do      
        if [[ $IS_LOOP = 0 ]];then
            local TABLECONTENT="%-20s %12d %12d %12.1f %12.1f\n"
            printf "$TABLECONTENT" "$int" "${TXDATA[i]}" "${RXDATA[i]}" "${TXRATE[i]}" "${RXRATE[i]}"
        else
            local TABLECONTENT="%-20s %12d %12d %12.1f %12.1f %12d %12d\n"
            printf "$TABLECONTENT" "$int" "${TXDATA[i]}" "${RXDATA[i]}" "${TXRATE[i]}" "${RXRATE[i]}" "${TXLOOP[i]}" "${RXLOOP[i]}"
        fi
        ((i+=1))
    done     
}

# Função responsável pela impressão dos dados ordenados
# A função calculate_data é chamada para obter os dados necessários
# Consoante o método de ordenação definido pelo user (-1 default) é executado
# o sort pretendido onde os valores de argumento de sort é o número da coluna a ser usada
# para a ordenação. Caso seja usada a opção -v é adicionada ao comando sort a opção -r.
# Em qualquer dos casos a função print_table é chamada com os dados ainda "não ordenados"
function print_sorted_data() {
        calculate_data
        case $SORT_TYPE in
        -1 ) 
            print_table | sort $( (( IS_REVERSE == 1 )) && printf %s '-r' )
        ;;
        1 )
            print_table | sort -k 2 -n $( (( IS_REVERSE == 1 )) && printf %s '-r' )
        ;;

        2 )
            print_table | sort -k 3 -n $( (( IS_REVERSE == 1 )) && printf %s '-r' )
        ;;

        3 )
            print_table | sort -k 4 -n $( (( IS_REVERSE == 1 )) && printf %s '-r' )
        ;;

        4 )
            print_table | sort -k 5 -n $( (( IS_REVERSE == 1 )) && printf %s '-r' )
        ;;
    esac
}

# Função responsável por imprimir a tabela 
# Aqui é definido o Cabeçalho da tabela, que muda consoante o valor de IS_LOOP
# Caso esteja a correr em loop a função print_sorted_data fica a correr em loop para
# estar sempre a obter dados
function print_data() {
    if [[ $IS_LOOP = 0 ]];then
        local TABLEHEADER="%-20s %12s %12s %12s %12s\n"
        printf "$TABLEHEADER" "NETIF" "TX" "RX" "TRATE" "RRATE"
        print_sorted_data
    else
        local TABLEHEADER="%-20s %12s %12s %12s %12s %12s %12s\n"
        printf "$TABLEHEADER" "NETIF" "TX" "RX" "TRATE" "RRATE" "TXTOT" "RXTOT"

        while :
        do
            print_sorted_data
            printf "\n"
        done   
    fi 
}

#Chamada da função main, com os argumentos inseridos pelo utilizador
main $@
