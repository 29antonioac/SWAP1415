# Creación clúster Lustre

En este trabajo optativo vamos a crear un pequeño clúster con el sistema de archivos distribuido Lustre. Obviaré los detalles de la implementación y el significado de las siglas, ya que se pueden (y deben) consultar en el primer enlace de la bibliografía.

Nuestro clúster constará de 4 máquinas:

- 2 máquinas cliente.
- La máquina MGS/MDT, con un RAID1 de 2 discos con metadatos.
- 2 máquinas OSS, también con RAID1 de 2 discos cada uno con los datos.

La máquina MGS/MDT tendrá segundo adaptador de red en modo **sólo anfitrión** para poder conectarnos por ssh y tener una consola decente y con posibilidad de copiar y pegar. Tanto ésta como todas las demás tendrán otro adaptador **red interna**, en MGS/MDT será eth2 y en las demás eth1.

## Preparando herramientas

En esta ocasión vamos a hacer un clúster con la distribución GNU/Linux CentOS 6.6, la cual es compatible oficialmente con Lustre. Nos descargaremmos CentOS 6.6 del archivo de CentOS, ya que la versión actual es la 7, que salió en Julio de 2014.

[Repositorio CentOS 6.6](http://isoredirect.centos.org/centos/6/isos/x86_64/)

La instalaremos normalmente, con un disco de 8GB donde instalaremos todo el sistema (luego añadiremos un RAID1) y 512MB de RAM. Instalaremos aquí lo común a todas las máquinas del clúster y luego la clonaremos correctamente para seguir preparando todo eficazmente.

Una vez tengamos la máquina instalada, subimos la red con

```
[root@localhost ~]# dhclient eth0; dhclient eth1
```

Instalamos nano por comodidad, ya que no me manejo aún con vim.

```
[root@localhost ~]# yum install nano
```

Editamos el archivo **/etc/sysconfig/network** para conectar a la red durante el inicio.

```
[root@localhost ~]# nano /etc/sysconfig/network
-----------------------

ONBOOT=yes
```

Ahora nos descargamos los archivos necesarios desde el mirror oficial de [Lustre](http://downloads.whamcloud.com/public/lustre/latest-maintenance-release/), aquí está la lista de archivos. Lo metemos en un fichero de texto **descargas.txt** y lo descargamos con wget.

```
https://downloads.hpdd.intel.com/public/lustre/latest-maintenance-release/el6/server/RPMS/x86_64/kernel-2.6.32-431.23.3.el6_lustre.x86_64.rpm
https://downloads.hpdd.intel.com/public/lustre/latest-maintenance-release/el6/server/RPMS/x86_64/kernel-firmware-2.6.32-431.23.3.el6_lustre.x86_64.rpm
https://downloads.hpdd.intel.com/public/lustre/latest-maintenance-release/el6/server/RPMS/x86_64/lustre-2.5.3-2.6.32_431.23.3.el6_lustre.x86_64.x86_64.rpm
https://downloads.hpdd.intel.com/public/lustre/latest-maintenance-release/el6/server/RPMS/x86_64/lustre-modules-2.5.3-2.6.32_431.23.3.el6_lustre.x86_64.x86_64.rpm
https://downloads.hpdd.intel.com/public/lustre/latest-maintenance-release/el6/server/RPMS/x86_64/lustre-osd-ldiskfs-2.5.3-2.6.32_431.23.3.el6_lustre.x86_64.x86_64.rpm
https://downloads.hpdd.intel.com/public/e2fsprogs/latest/el6/RPMS/x86_64/e2fsprogs-1.42.12.wc1-7.el6.x86_64.rpm
https://downloads.hpdd.intel.com/public/e2fsprogs/latest/el6/RPMS/x86_64/e2fsprogs-libs-1.42.12.wc1-7.el6.x86_64.rpm
https://downloads.hpdd.intel.com/public/e2fsprogs/latest/el6/RPMS/x86_64/libcom_err-1.42.12.wc1-7.el6.x86_64.rpm
https://downloads.hpdd.intel.com/public/e2fsprogs/latest/el6/RPMS/x86_64/libss-1.42.12.wc1-7.el6.x86_64.rpm
-----------------------
[root@localhost ~]# wget -i descargas.txt
```

Debemos instalar estos paquetes con un orden algo determinado para no tenerm problemas de dependencias.

Primero el kernel modificado.

```
[root@localhost ~]# rpm -ivh --force kernel-2.6.32-431.23.3.el6_lustre.x86_64.rpm kernel-firmware-2.6.32-431.23.3.el6_lustre.x86_64.rpm
```

Ahora las herramientas para el sistema de archivos

```
[root@localhost ~]# rpm -Uvh e2fsprogs-1.42.12.wc1-7.el6.x86_64.rpm e2fsprogs-libs-1.42.12.wc1-7.el6.x86_64.rpm libcom_err-1.42.12.wc1-7.el6.x86_64.rpm libss-1.42.12.wc1-7.el6.x86_64.rpm
```

Ahora los módulos de Lustre

```
[root@localhost ~]# rpm -ivh lustre-modules-2.5.3-2.6.32_431.23.3.el6_lustre.x86_64.x86_64.rpm lustre-osd-ldiskfs-2.5.3-2.6.32_431.23.3.el6_lustre.x86_64.x86_64.rpm
```

Ahora las librerías para la comunicación entre nodos

```
[root@localhost ~]# yum install net-snmp-libs
```

Y por último Lustre

```
[root@localhost ~]# rpm -ivh lustre-2.5.3-2.6.32_431.23.3.el6_lustre.x86_64.x86_64.rpm
```

Ahora desactivamos SELinux desde la línea de arranque del kernel Lustre para evitar políticas de seguridad no deseadas.

```
[root@localhost ~]# nano /boot/grub/grub.cfg
-----------------------

kernel /vmlinuz-2.6.32-431.23.3.el6_lustre.x86_64 ro root=/dev/mapper/VolGroup-lv_root rd_NO_LUKS  KEYBOARDTYPE=pc KEYTABLE=es rd_NO_MD rd_LVM_LV=VolGroup/lv_swap SYSFONT=latarcyrheb-sun16 crashkernel=auto LANG=es_ES.UTF-8 rd_LVM_LV=VolGroup/lv_root rd_NO_DM rhgb quiet selinux=0

```

Desactivamos iptables por la misma razón (podríamos configurarlo adecuadamente pero no es objeto de este ejercicio)

```
[root@localhost ~]# chkconfig iptables off
```

Creamos el fichero **/etc/modprobe.d/lustre.conf** con este contenido:

```
[root@localhost ~]# nano /etc/modprobe.d/lustre.conf
-----------------------

options lnet networks=tcp0(eth2)
```

Ahora apagamos la máquina y la clonamos 4 veces, reinicializando las MAC de las tarjetas de red y haciendo clonaciones completas. Así no tendremos que volver a preparar las máquinas :).

## Creación del servidor MGS/MDT

Para este servidor usaremos la máquina original, no la clonada. Introducimos 2 discos de 2GB para formar un RAID1 tal como hicimos en la [Práctica 6](../"Práctica 6 - Discos en RAID"). Después de crear el RAID reiniciamos, ya que el nombre del array cambiará.

Ahora sobre el RAID1 creamos el sistema de archivos Lustre para MGS y MDT. El nombre que elegimos para el clúster es **swap**.

```
[root@localhost ~]# mkfs.lustre --fsname=swap --mgs --mdt --index=0 /dev/md127
```

Ahora montamos ese dispositivo en una carpeta de nuestro sistema.

```
[root@localhost ~]# mkdir /mdt
[root@localhost ~]# mount -t lustre /dev/md0 /mdt/
```

Y editamos **/etc/fstab** para automontar al inicio

```
[root@localhost ~]# nano /etc/fstab
-----------------------

/dev/md0                /mdt                    lustre  auto,defaults        0 0
```

## Creación de servidores OSS/OST

Es posible que después de clonar haya que tocar un poco el aspecto de la red (adaptadores con nombre cambiado y echar arriba la red interna), pero eso ya lo hemos trabajado en prácticas. Aún así, en esta versión de CentOS sólo hay que editar el archivo **/etc/sysconfig/network-scripts/ifcfg-(nombre de la interfaz)** y poner los parámetros necesarios con este esqueleto:

```
DEVICE=eth1
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=yes
BOOTPROTO=none
NETWORK=192.168.1.0
NETMASK=255.255.255.0
IPADDR=192.168.1.102
GATEWAY=192.168.1.1
```

Después de comprobar que la red interna va sin problemas (la conexión a internet no la vamos a arreglar puesto que no hace falta, aunque sería sólo poner las DNS en orden), creamos el RAID1 pertinente con los 2 discos que hemos agregado al igual que en MGS/MDT, reiniciamos y le damos formato:

```
[root@localhost ~]# mkfs.lustre --fsname=swap --mgsnode=192.168.1.100@tcp --ost --index=1 /dev/md127
```

Fijarse bien que hemos puesto en mgsnode la dirección del nodo MGS y como índice 1. Esto no puede coincidir en ningún nodo.

Ahora montamos en una carpeta de sistema el sistema de archivos

```
[root@localhost ~]# mkdir /lustre
[root@localhost ~]# mount -t lustre /dev/md127 /lustre/
```

Y añadimos la línea correspondiente a **/etc/fstab**

```
[root@localhost ~]# nano /etc/fstab
-----------------------

/dev/md0                /lustre                    lustre  auto,defaults        0 0
```



## Bibliografía

[Introducción a Lustre](http://www.systerminal.com/2014/07/21/introduccion-a-lustre/)

[Instalación de Lustre en CentOS 6.5](http://www.systerminal.com/2014/07/21/instalacion-de-lustre-en-centos-6-5/)
