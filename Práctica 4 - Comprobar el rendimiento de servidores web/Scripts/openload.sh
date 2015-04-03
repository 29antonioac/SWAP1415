#!/bin/bash

function mediaAritmetica()
{
  declare -a numeros=("${!1}")
  local media=0
  for item in ${numeros[@]}
  do
    media=`echo "scale=3; $media + $item" | bc -l`
  done
  media=`echo "scale=3;$media / ${#numeros[@]}" | bc -l`
  echo "$media"
}

function desviacionTipica()
{
  declare -a valores=("${!1}")
  media=`mediaAritmetica valores[@]`
  desv=0
  for item in ${valores[@]}
  do
      desv=`echo "scale=3; $desv + ($item - $media)^2" | bc -l `
  done
  desv=`echo "scale=3;sqrt($desv / ${#valores[@]})" | bc -l`
  echo "$desv"
}

PETICIONES=( 1000 2000 4000 8000 16000 32000 )
PRUEBAS=10
declare -A URLS=( ["granja_nginx"]="http://www.servidorswap.net/index.html" ["servidor"]="http://debian1/index.html" )
# declare -A URLS=( ["granja_haproxy"]="http://www.servidorswap.net/index.html")

for destino in ${!URLS[@]}
do
  if [ -a "../Datos/openload-$destino-totalTPS.dat" ]; then rm ../Datos/openload-$destino-totalTPS.dat; fi
  if [ -a "../Datos/openload-$destino-avgResponseTime.dat" ]; then rm ../Datos/openload-$destino-avgResponseTime.dat; fi
done


for peticiones in ${PETICIONES[@]}
do
  for destino in ${!URLS[@]}
  do
    totalTPS=()
    avgResponseTime=()
    salida=""
    echo "Probando con $peticiones peticiones en $destino..."

    # Realizar número de pruebas y acumular tiempos
    for (( prueba=1; prueba<=$PRUEBAS; prueba++ ))
    do
      salida=`./openload -l 30 ${URLS[$destino]} $peticiones 2> /dev/null`
      totalTPS+=(`echo "$salida" | egrep "Total TPS:" | tr -s ' ' | cut -d" " -f3`)
      avgResponseTime+=(`echo "$salida" | egrep "Avg. Response time:" | tr -s ' ' | cut -d" " -f4`)
    done

    # Calcular media aritmética
    media_totalTPS=`mediaAritmetica totalTPS[@]`
    media_avgResponseTime=`mediaAritmetica avgResponseTime[@]`

    # Calculamos la desviación típica
    desv_totalTPS=`desviacionTipica totalTPS[@]`
    desv_avgResponseTime=`desviacionTipica avgResponseTime[@]`

    echo "media_totalTPS=$media_totalTPS"
    echo "media_avgResponseTime=$media_avgResponseTime"
    echo "desv_totalTPS=$desv_totalTPS"
    echo "desv_avgResponseTime=$desv_avgResponseTime"
    echo

    # Añadimos a la tabla de valores con formato peticiones media desv
    echo "$peticiones $media_totalTPS $desv_totalTPS" >> ../Datos/openload-$destino-totalTPS.dat
    echo "$peticiones $media_avgResponseTime $desv_avgResponseTime" >> ../Datos/openload-$destino-avgResponseTime.dat
  done
done
