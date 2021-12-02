# Projeto \#1 de SO


# TODO LIST
- [X] tentar imprimir a informação num determinado intervalo de tempo
- [x] Validação dos parâmetros de entrada
- [X] Argumento obrigatório para calcular as taxas de transferência
- [X] Selecionar a interface de rede a analisar através de RegEx (**-c**)
- [X] Visualizar a informação em diferentes tamanhos de informação
	- [X] Bytes (**-b**)
	- [X] Kilobytes (**-k**)
	- [X] Megabytes (**-m**)
- [X] Apresentação da informação em forma de tabela
	- [X] Cabeçalho
	- [X] Apresentação das interfaces de rede por ordem alfabética
- [X] Argumento capaz de controlar o número de interfaces a mostrar (**-p**)
- [X] Alterar a ordem da tabela com um argumento extra
	- [X] **-t** ordenar por TX
	- [X] **-r** ordenar por RX ascendente
	- [X] **-T** ordenar por TRATE ascendente
	- [X] **-R** ordenar por RRATE ascendente
	- [X] **-v** ordenar pela ordem inversa
- [ ] Argumento para correr o script em loop (**-l**)
	- [ ] 2 colunas para mostrar a quantidade de dados transmitidos e recebidos desde o início da execução 
	- [ ] As outras colunas representam apenas a última iteração
- [ ] Validar nos PCs da sala 101
- [ ] Relatório

# Comandos úteis
* ifconfig
* ip
* awk
* cat
* cut
* getopts
* grep
* head
* printf
* sleep
* sort


# TODO

* Saber se a posição do valor de tempo é sempre o último ou pode variar
* Devia dar erro `./netifstat.sh -p 1 -c "l.*" 1 -b -k 1`
* É preciso dar fix às divisões

* Para tratar do Revese fazer algo do tipo
