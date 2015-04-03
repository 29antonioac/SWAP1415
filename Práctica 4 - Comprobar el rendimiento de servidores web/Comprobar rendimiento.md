# Comprobar el rendimiento de servidores web

Partimos de la granja web montada hasta la práctica 3. Para hacer las pruebas usaré mi máquina host
con Archlinux y añadiré adaptadores host-only a las máquinas balanceadora y debian1.

Para ello cargamos los módulos necesarios para tal cosa y creamos el adaptador. Lo haré vía consola
ya que es sólo una orden.

```
[antonio@Antonio-Arch ~]$ sudo modprobe vboxnetadp; sudo modprobe vboxnetflt
[antonio@Antonio-Arch ~]$ sudo VBoxManage hostonlyif create
```

Ahora en ambas máquinas añadimos un tercer adaptador de red "Sólo anfitrión" con nombre "vboxnet0",
que es el que acabamos de crear.

![Imagen Sólo Anfitrión](Imágenes/SoloAnfitrión.png)

Para facilitar las pruebas, añadimos como ya sabemos a **/etc/hosts** las IP de ambas máquinas
y les ponemos un nombre.

Para conseguir las tablas usaré este [script]() que me formatea un .dat de los que saca cada uno de los scripts de cada programa a una tabla del estilo de markdown.

## Apache Benchmark

Instalamos en mi máquina host el paquete apache.

```
[antonio@Antonio-Arch ~]$ sudo pacman -S apache
```

Este [script](Scripts/ab.sh) que ejecuta 10 veces ab y calcula la media y la desviación típica para un número creciente de peticiones. Aquí se muestran tablas y gráficas

## HTTPperf

Instalamos httperf desde los repositorios oficiales

```
[antonio@Antonio-Arch ~]$ sudo pacman -S httperf
```

Y usando este [script](Scripts/httperf.sh), que está adaptado del de ab, sacamos estas tablas y gráficas.

## Openload

Para instalar [OpenWebLoad](http://openwebload.sourceforge.net/) en mi máquina host descargaré los fuentes desde la web oficial y los compilaré, aunque haciendo un pequeño cambio, ya que gcc sigue mucho los estándares de C y no comprende una línea de código.

Hay que eliminar **CTmplChunk::** de la línea 34 de **tmplchunk.h**, ya que está haciendo referencia a la propia clase y gcc no lo comprende.

Una vez hecho el cambio compilamos.

```
[antonio@Antonio-Arch ~]$ ./configure && make
```

Obviamos **make install** ya que no quiero instalarlo en mi sistema, me vale con tener el ejecutable. Lo copiamos de **src** a nuestra carpeta **Scripts** para lanzarlo desde nuestro clásico [script](Scripts/openload.sh) adaptado por supuesto a OpenWebLoad. Aquí tablas y gráficas.
