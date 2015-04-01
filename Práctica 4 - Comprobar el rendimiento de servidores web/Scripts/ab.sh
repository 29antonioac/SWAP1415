#!/bin/bash

PETICIONES=( 1000 2000 4000 8000 16000 32000 )
#PETICIONES=( 1000 2000 4000)
PRUEBAS=10
declare -A URLS=( ["granja_nginx"]="http://www.servidorswap.net/index.html" ["servidor"]="http://debian1/index.html" )
#declare -A URLS=( ["granja_haproxy"]="http://www.servidorswap.net/index.html")

for destino in ${!URLS[@]}
do
  if [ -a "../Datos/ab-$destino.dat" ]; then rm ../Datos/ab-$destino.dat; fi
  #if [ -a "../Datos/ab-desv-$destino.dat" ]; then rm ../Datos/ab-desv-$destino.dat; fi
done


for peticiones in ${PETICIONES[@]}
do
  for destino in ${!URLS[@]}
  do
    media=0
    suma=0
    valores=()
    echo "Probando con $peticiones peticiones en $destino..."
    # Realizar número de pruebas y acumular tiempos
    for (( prueba=1; prueba<=$PRUEBAS; prueba++ ))
    do
      tiempo=`ab -n $peticiones -c 20 ${URLS[$destino]} 2> /dev/null | grep concurrent | cut -d" " -f10`
      suma=`echo "$suma + $tiempo" | bc -l`
      valores+=($tiempo)
    done
    # Calcular media aritmética
    media=`echo "($media + $suma) / $PRUEBAS" | bc -l`
    #echo -e "$peticiones $media" >> ../Datos/ab-media-$destino.dat

    # Calculamos la desviación típica
    desv=0
    for t in ${valores[@]}
    do
      desv=`echo "$desv + ($t - $media)^2" | bc -l`
    done
    desv=`echo "sqrt($desv / $PRUEBAS)" | bc -l`
    # Añadimos a la tabla de valores con formato peticiones media desv
    echo -e "$peticiones $media $desv" >> ../Datos/ab-$destino.dat
  done
done
