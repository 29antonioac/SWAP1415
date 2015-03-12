# Práctica 1 - Preparando las herramientas de las prácticas

En esta primera práctica prepararemos las herramientas necesarias para todas las prácticas
de la asignatura.

He elegido una distribución que se caracteriza por su gran estabilidad y compatibilidad: **[Debian](https://www.debian.org/)**.
Es una distribución conocidísima de la cual derivan Ubuntu o Linux Mint entre otras.

En su rama stable los paquetes son congelados durante mucho tiempo para garantizar la estabilidad
del sistema, lo que hace que sea muy usado en servidores. En sistemas de escritorio se suele
utilizar la rama testing, ya que no tiene paquetes tan antiguos y también es muy estable.

Usaremos su última versión estable, Debian Wheezy. Descargaremos la versión [netinstall AMD64](http://cdimage.debian.org/debian-cd/7.8.0/amd64/iso-cd/debian-7.8.0-amd64-netinst.iso) ya que nuestras máquinas serán de 64 bits y tendremos una constante conexión a internet.

## Instalando y configurando la primera máquina

Una vez tengamos la imagen, crearemos la máquina virtual. Le asignaremos como nombre "Debian 1", 512MB de RAM y 8GB de disco duro reservado dinámicamente (decaerá un poco el rendimiento del servidor pero nos ahorrará unos GB en el host), y añadimos un segundo adaptador red conectado como **Red interna**, a la que le he puesto como nombre **interna**.

Ahora sólo tenemos que montar la imagen en dicha máquina virtual e ir siguiendo los pasos del instalador (elegir idioma, zona horaria, particiones...) hasta conseguir el sistema completo. Para las prácticas hemos dejado las particiones por defecto: todo el sistema estará en /. No es objeto de la asignatura separarlas por lo que así ahorramos tiempo al instalar.

Durante el proceso de instalación nos aparece el menú de tasksel, eligiendo con la tecla Espacio estas opciones

-- Insertar imagen

La interfaz gráfica la instalaremos para casos de urgencia (el espacio en disco no es problema), pero la desactivaremos cuando terminemos, ya que nos ocupa memoria RAM valiosísima para nuestro servidor.

Como en Debian tasksel instala PostgreSQL, instalaremos MySQL para tener algo homogéneo con los guiones de prácticas. Aprovechamos e instalamos también PHP5 y curl.

```
# aptitude install -y mysql-server php5 curl
```

Ahora instalamos las **Guest Additions** de VirtualBox para acceder a más recursos de la máquina host, ya que a lo mejor nos hace falta en un futuro. Primero ejecutamos

```
# aptitude install -y build-essential module-assistant linux-headers-$(uname -r)
```

Y luego montamos las **Guest Additions** desde el menú **Dispostivos** de VirtualBox y ejecutamos

```
$ cp /media/cdrom0/VBoxLinuxAdditions.run .
$ chmod +x VBoxLinuxAdditions.run
$ sudo ./VBoxLinuxAdditions.run
```

Y tecleamos **yes** cuando nos pregunte.

Ahora es tiempo de configurar la red interna. Abrimos el archivo **/etc/network/interfaces** y añadimos al final lo siguiente

```
# Red interna
auto eth1
iface eth1 inet static
address 192.168.1.200
gateway 192.168.1.1
netmask 255.255.255.0
network 192.168.1.0
broadcast 192.168.1.255
```

Así nuestras dos máquinas virtuales se verán... un segundo, ¡sólo hemos configurado una! Ahora a repetir todo el trabajo para la siguiente... ¿o no?

## Clonando la máquina virtual

Para evitarnos otra vez este trabajo, vamos a utilizar una función de VirtualBox: **clonar**.

Pinchamos con el botón derecho a la máquina virtual que ya tenemos y seleccionamos **clonar**

-- Insertar imagen

Le pondremos de nombre "Debian 2" y marcaremos la opción "Reinicializar la dirección MAC de todas las tarjetas de red", y en la siguiente pantalla elegimos "Clonación completa".

Ahora para evitar confusiones con el nombre de las máquinas, habrá que cambiar el nombre de máquina de "Debian 2". Para ello la arrancamos y cambiamos debian1 por debian2 en los archivos **/etc/hosts** y **/etc/hostname**. Ahora cambiamos la dirección 192.168.1.100 por 192.168.1.200 en **/etc/network/interfaces** , reiniciamos la máquina y listo. ¡Ya tenemos 2 máquinas iguales listas para realizar las prácticas!
