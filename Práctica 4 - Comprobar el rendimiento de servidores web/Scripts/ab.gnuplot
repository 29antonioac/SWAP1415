#!/bin/gnuplot

# Parámetros comunes a todas las gráficas
set xr [0:17000]
set xtics ( 1000,2000,4000,8000,16000 );
set xtics font ",11"
set xlabel "Peticiones totales"
set term png size 1280,768


# Test time
set ylabel "Tiempo del test (segundos)"
set output '../Imágenes/ab-testTime.png'

plot '../Datos/ab-servidor-testTime.dat'  using 1:2:3 notitle with yerrorbars, \
'../Datos/ab-servidor-testTime.dat' using 1:2 title 'Servidor web' with lines, \
'../Datos/ab-granja_nginx-testTime.dat'  using 1:2:3 notitle with yerrorbars, \
'../Datos/ab-granja_nginx-testTime.dat' using 1:2 title 'Granja nginx' with lines, \
'../Datos/ab-granja_haproxy-testTime.dat'  using 1:2:3 notitle with yerrorbars, \
'../Datos/ab-granja_haproxy-testTime.dat' using 1:2 title 'Granja haproxy' with lines

# Time per request
set ylabel "Tiempo por petición (milisegundos)"
set output '../Imágenes/ab-timePerRequest.png'

plot '../Datos/ab-servidor-timePerRequest.dat'  using 1:2:3 notitle with yerrorbars, \
'../Datos/ab-servidor-timePerRequest.dat' using 1:2 title 'Servidor web' with lines, \
'../Datos/ab-granja_nginx-timePerRequest.dat'  using 1:2:3 notitle with yerrorbars, \
'../Datos/ab-granja_nginx-timePerRequest.dat' using 1:2 title 'Granja nginx' with lines, \
'../Datos/ab-granja_haproxy-timePerRequest.dat'  using 1:2:3 notitle with yerrorbars, \
'../Datos/ab-granja_haproxy-timePerRequest.dat' using 1:2 title 'Granja haproxy' with lines

# Requests per second
set ylabel "Peticiones por segundo"
set output '../Imágenes/ab-requestsPerSecond.png'

plot '../Datos/ab-servidor-requestsPerSecond.dat'  using 1:2:3 notitle with yerrorbars, \
'../Datos/ab-servidor-requestsPerSecond.dat' using 1:2 title 'Servidor web' with lines, \
'../Datos/ab-granja_nginx-requestsPerSecond.dat'  using 1:2:3 notitle with yerrorbars, \
'../Datos/ab-granja_nginx-requestsPerSecond.dat' using 1:2 title 'Granja nginx' with lines, \
'../Datos/ab-granja_haproxy-requestsPerSecond.dat'  using 1:2:3 notitle with yerrorbars, \
'../Datos/ab-granja_haproxy-requestsPerSecond.dat' using 1:2 title 'Granja haproxy' with lines

# Peticiones fallidas
set ylabel "Peticiones fallidas"
set output '../Imágenes/ab-failedRequests.png'

plot '../Datos/ab-servidor-failedRequests.dat'  using 1:2:3 notitle with yerrorbars, \
'../Datos/ab-servidor-failedRequests.dat' using 1:2 title 'Servidor web' with lines, \
'../Datos/ab-granja_nginx-failedRequests.dat'  using 1:2:3 notitle with yerrorbars, \
'../Datos/ab-granja_nginx-failedRequests.dat' using 1:2 title 'Granja nginx' with lines, \
'../Datos/ab-granja_haproxy-failedRequests.dat'  using 1:2:3 notitle with yerrorbars, \
'../Datos/ab-granja_haproxy-failedRequests.dat' using 1:2 title 'Granja haproxy' with lines
