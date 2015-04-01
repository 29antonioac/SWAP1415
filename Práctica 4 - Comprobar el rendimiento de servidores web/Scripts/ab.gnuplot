#!/bin/gnuplot

set xr [0:35000]
set yr [0:1.5]
set xtics ( 1000,2000,4000,8000,16000,32000);
set xtics font ",11"
set xlabel "Peticiones totales"
set ylabel "Tiempo por petición (segundos)"
set term png size 1280,768
set output '../Imágenes/ab.png'

#plot "file.txt" using 1:($2-$3):($2-$3):($2+$3):($2+$3) with candlesticks
#plot '../Datos/ab-granja_nginx.dat' title 'granja_nginx' with candlesticks, \
#'../Datos/ab-granja_haproxy.dat' title 'granja_haproxy' with candlesticks , \
#'../Datos/ab-servidor.dat' title 'servidor' with candlesticks

plot '../Datos/ab-servidor.dat'  using 1:2:3 notitle with yerrorbars, \
'../Datos/ab-servidor.dat' using 1:2 title 'Servidor web' with lines, \
'../Datos/ab-granja_nginx.dat'  using 1:2:3 notitle with yerrorbars, \
'../Datos/ab-granja_nginx.dat' using 1:2 title 'Granja nginx' with lines, \
'../Datos/ab-granja_haproxy.dat'  using 1:2:3 notitle with yerrorbars, \
'../Datos/ab-granja_haproxy.dat' using 1:2 title 'Granja haproxy' with lines
