#!/bin/gnuplot

set term png
set boxwidth 0.5
set style fill solid

# Availability
set output '../Imágenes/siege-availability.png'

set xtics ("Disponibilidad" 0.5)

set yrange [0:150]
set ytics (0,20,40,60,80,100)

plot '../Datos/siege-availability.dat' every 2 using 1:2 title 'Servidor web' with boxes ls 1, \
     '../Datos/siege-availability.dat' every 2::1 using 1:2 title 'Granja nginx' with boxes ls 2, \
     '../Datos/siege-availability.dat' every 2::2 using 1:2 title 'Granja haproxy' with boxes ls 3

# Transaction Rate
set output '../Imágenes/siege-transactionRate.png'

set xtics ("Transacciones por segundo" 0.5)

set yrange [0:1]
set ytics (0,0.2,0.4,0.6,0.8,1)

plot '../Datos/siege-transactionRate.dat' every 2 using 1:2 title 'Servidor web' with boxes ls 1, \
     '../Datos/siege-transactionRate.dat' every 2::1 using 1:2 title 'Granja nginx' with boxes ls 2, \
     '../Datos/siege-transactionRate.dat' every 2::2 using 1:2 title 'Granja haproxy' with boxes ls 3


# Failed Requests
set output '../Imágenes/siege-failedRequests.png'

set xtics ("Peticiones fallidas" 0.5)

set yrange [0:20]
set ytics (0,5,10,15,20)

plot '../Datos/siege-failedRequests.dat' every 2 using 1:2 title 'Servidor web' with boxes ls 1, \
     '../Datos/siege-failedRequests.dat' every 2::1 using 1:2 title 'Granja nginx' with boxes ls 2, \
     '../Datos/siege-failedRequests.dat' every 2::2 using 1:2 title 'Granja haproxy' with boxes ls 3

# Successful transactions
set output '../Imágenes/siege-successful.png'

set xtics ("Peticiones correctas" 0.5)

set yrange [0:50]
set ytics (0,10,20,30,40,50)

plot '../Datos/siege-successful.dat' every 2 using 1:2 title 'Servidor web' with boxes ls 1, \
     '../Datos/siege-successful.dat' every 2::1 using 1:2 title 'Granja nginx' with boxes ls 2, \
     '../Datos/siege-successful.dat' every 2::2 using 1:2 title 'Granja haproxy' with boxes ls 3

# Longest transaction
set output '../Imágenes/siege-longestTransaction.png'

set xtics ("Transación más larga (seg)" 0.5)

set yrange [0:50]
set ytics (0,10,20,30,40,50)

plot '../Datos/siege-longestTransaction.dat' every 2 using 1:2 title 'Servidor web' with boxes ls 1, \
     '../Datos/siege-longestTransaction.dat' every 2::1 using 1:2 title 'Granja nginx' with boxes ls 2, \
     '../Datos/siege-longestTransaction.dat' every 2::2 using 1:2 title 'Granja haproxy' with boxes ls 3
