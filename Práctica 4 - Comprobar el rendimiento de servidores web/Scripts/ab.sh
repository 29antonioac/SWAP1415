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

input=( 2 3 )
input=("0.556" "1.456" "45.111" "7.812" "5.001")
echo "Input=${input[@]}"
mediaAritmetica input[@]
desviacionTipica input[@]

# PETICIONES=( 1000 2000 4000 8000 16000 32000 )
# #PETICIONES=( 1000 2000 4000 )
# PRUEBAS=10
# declare -A URLS=( ["granja_nginx"]="http://www.servidorswap.net/index.html" ["servidor"]="http://debian1/index.html" )
# #declare -A URLS=( ["granja_haproxy"]="http://www.servidorswap.net/index.html")
#
# for destino in ${!URLS[@]}
# do
#   if [ -a "../Datos/ab-$destino.dat" ]; then rm ../Datos/ab-$destino.dat; fi
#   #if [ -a "../Datos/ab-desv-$destino.dat" ]; then rm ../Datos/ab-desv-$destino.dat; fi
# done
#
#
# for peticiones in ${PETICIONES[@]}
# do
#   for destino in ${!URLS[@]}
#   do
#     testTime=()
#     failedRequests=()
#     requestPerSecond=()
#     timePerRequest=()
#     salida=""
#     echo "Probando con $peticiones peticiones en $destino..."
#     # Realizar número de pruebas y acumular tiempos
#     for (( prueba=1; prueba<=$PRUEBAS; prueba++ ))
#     do
#       salida=`ab -n $peticiones -c 20 ${URLS[$destino]} 2> /dev/null`
#       testTime+=(`echo $salida | egrep "Time taken for tests:" | tr -s ' ' | cut -d" " -f5`)
#       failedRequests+=(`echo $salida | egrep "Failed requests:" | tr -s ' ' | cut -d" " -f3`)
#       requestPerSecond+=(`echo $salida | egrep "Requests per second:" | tr -s ' ' | cut -d" " -f4`)
#       timePerRequest+=(`echo $salida | egrep "Time per request:" | egrep "\(mean\)" | tr -s ' ' | cut -d" " -f4`)
#     done
#     # Calcular media aritmética
#     media=`echo "($media + $suma) / $PRUEBAS" | bc -l`
#     #echo -e "$peticiones $media" >> ../Datos/ab-media-$destino.dat
#
#     # Calculamos la desviación típica
#     desv=0
#     for t in ${valores[@]}
#     do
#       desv=`echo "$desv + ($t - $media)^2" | bc -l`
#     done
#     desv=`echo "sqrt($desv / $PRUEBAS)" | bc -l`
#     # Añadimos a la tabla de valores con formato peticiones media desv
#     echo -e "$peticiones $media $desv" >> ../Datos/ab-$destino.dat
#   done
# done
