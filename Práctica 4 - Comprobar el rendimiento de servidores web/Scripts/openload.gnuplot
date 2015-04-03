#!/bin/gnuplot

# Parámetros comunes a todas las gráficas
set xr [0:35000]
set xtics ( 1000,2000,4000,8000,16000,32000 );
set xtics font ",11"
set xlabel "Clientes simultáneos"
set term png size 1280,768


# Total TPS
set ylabel "Total transactions per second"
set output '../Imágenes/openload-totalTPS.png'

plot '../Datos/openload-servidor-totalTPS.dat'  using 1:2:3 notitle with yerrorbars, \
'../Datos/openload-servidor-totalTPS.dat' using 1:2 title 'Servidor web' with lines, \
'../Datos/openload-granja_nginx-totalTPS.dat'  using 1:2:3 notitle with yerrorbars, \
'../Datos/openload-granja_nginx-totalTPS.dat' using 1:2 title 'Granja nginx' with lines, \
'../Datos/openload-granja_haproxy-totalTPS.dat'  using 1:2:3 notitle with yerrorbars, \
'../Datos/openload-granja_haproxy-totalTPS.dat' using 1:2 title 'Granja haproxy' with lines

# Average response time
set ylabel "Tiempo por petición (segundos)"
set output '../Imágenes/openload-avgResponseTime.png'

plot '../Datos/openload-servidor-avgResponseTime.dat'  using 1:2:3 notitle with yerrorbars, \
'../Datos/openload-servidor-avgResponseTime.dat' using 1:2 title 'Servidor web' with lines, \
'../Datos/openload-granja_nginx-avgResponseTime.dat'  using 1:2:3 notitle with yerrorbars, \
'../Datos/openload-granja_nginx-avgResponseTime.dat' using 1:2 title 'Granja nginx' with lines, \
'../Datos/openload-granja_haproxy-avgResponseTime.dat'  using 1:2:3 notitle with yerrorbars, \
'../Datos/openload-granja_haproxy-avgResponseTime.dat' using 1:2 title 'Granja haproxy' with lines
