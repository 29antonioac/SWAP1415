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

PETICIONES=( 1000 2000 4000 8000 16000 )


PRUEBAS=10
# declare -A URLS=( ["granja_nginx"]="http://www.servidorswap.net/index.php" ["servidor"]="http://debian1/index.php" )
declare -A URLS=( ["granja_haproxy"]="http://www.servidorswap.net/index.php")

for destino in ${!URLS[@]}
do
  if [ -a "../Datos/ab-$destino-testTime.dat" ]; then rm ../Datos/ab-$destino-testTime.dat; fi
  if [ -a "../Datos/ab-$destino-failedRequests.dat" ]; then rm ../Datos/ab-$destino-failedRequests.dat; fi
  if [ -a "../Datos/ab-$destino-requestsPerSecond.dat" ]; then rm ../Datos/ab-$destino-requestsPerSecond.dat; fi
  if [ -a "../Datos/ab-$destino-timePerRequest.dat" ]; then rm ../Datos/ab-$destino-timePerRequest.dat; fi
done


for peticiones in ${PETICIONES[@]}
do
  for destino in ${!URLS[@]}
  do
    testTime=()
    failedRequests=()
    requestsPerSecond=()
    timePerRequest=()
    salida=""
    echo -n "Probando con $peticiones peticiones en $destino... "

    # Realizar número de pruebas y acumular tiempos
    for (( prueba=1; prueba<=$PRUEBAS; prueba++ ))
    do
      salida=`ab -n $peticiones -c 1000 -r -s 60 ${URLS[$destino]} 2> /dev/null`
      testTime+=(`echo "$salida" | egrep "Time taken for tests:" | tr -s ' ' | cut -d" " -f5`)
      failedRequests+=(`echo "$salida" | egrep "Failed requests:" | tr -s ' ' | cut -d" " -f3`)
      requestsPerSecond+=(`echo "$salida" | egrep "Requests per second:" | tr -s ' ' | cut -d" " -f4`)
      timePerRequest+=(`echo "$salida" | egrep "Time per request:" | egrep "\(mean\)" | tr -s ' ' | cut -d" " -f4`)
      echo -n $prueba...
    done
    echo

    # Calcular media aritmética
    media_testTime=`mediaAritmetica testTime[@]`
    media_failedRequests=`mediaAritmetica failedRequests[@]`
    media_requestsPerSecond=`mediaAritmetica requestsPerSecond[@]`
    media_timePerRequest=`mediaAritmetica timePerRequest[@]`

    # Calculamos la desviación típica
    desv_testTime=`desviacionTipica testTime[@]`
    desv_failedRequests=`desviacionTipica failedRequests[@]`
    desv_requestsPerSecond=`desviacionTipica requestsPerSecond[@]`
    desv_timePerRequest=`desviacionTipica timePerRequest[@]`

    # Añadimos a la tabla de valores con formato peticiones media desv
    echo "$peticiones $media_testTime $desv_testTime" >> ../Datos/ab-$destino-testTime.dat
    echo "$peticiones $media_failedRequests $desv_failedRequests" >> ../Datos/ab-$destino-failedRequests.dat
    echo "$peticiones $media_requestsPerSecond $desv_requestsPerSecond" >> ../Datos/ab-$destino-requestsPerSecond.dat
    echo "$peticiones $media_timePerRequest $desv_timePerRequest" >> ../Datos/ab-$destino-timePerRequest.dat
  done
done
