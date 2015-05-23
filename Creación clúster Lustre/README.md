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

https://downloads.hpdd.intel.com/public/lustre/latest-maintenance-release/el6/client/RPMS/x86_64/lustre-client-2.5.3-2.6.32_431.23.3.el6.x86_64.x86_64.rpm
https://downloads.hpdd.intel.com/public/lustre/latest-maintenance-release/el6/client/RPMS/x86_64/lustre-client-modules-2.5.3-2.6.32_431.23.3.el6.x86_64.x86_64.rpm

-----------------------
[root@localhost ~]# wget -i descargas.txt
```

Debemos instalar estos paquetes con un orden algo determinado para no tener problemas de dependencias.

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

Ahora apagamos la máquina y la clonamos 3 veces, reinicializando las MAC de las tarjetas de red y haciendo clonaciones completas. Así no tendremos que volver a preparar las máquinas servidoras :).

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

Ahora hacemos los mismos pasos para el otro nodo OSS/OST.

## Creación de los clientes

Usaremos 2 clientes para comprobar que las escrituras no son bloqueantes, que es una de las muchas bazas de este sistema de archivos. Necesitamos máquinas limpias ya que no podemos usar el kernel de lustre para los clientes, así que instalamos una y clonamos. Ahora tenemos que instalar las utilidades del cliente, las cuales ya nos descargamos anteriormente. Esto lo hacemos en ambos clientes.

```
[root@localhost ~]# rpm -ivh lustre-client-modules-2.5.3-2.6.32_431.23.3.el6.x86_64.x86_64.rpm lustre-client-2.5.3-2.6.32_431.23.3.el6.x86_64.x86_64.rpm --nodeps
```

En general la opción **--nodeps** no es recomendable en ningún caso, pero la usaremos para evitar downgradear el kernel, ya que nos pide una versión algo más antigua.

Creamos una carpeta donde montar el sistema de archivos

```
[root@localhost ~]# mkdir /lustre
```

Y hacemos la prueba. Lanzamos simultáneamente en ambas máquinas un pequeño bucle para comprobar que las escrituras no son bloqueantes.

```
[root@localhost ~]# for i in {1..500}; do echo cliente 1 - iteracion $i; done
```

```
[root@localhost ~]# for i in {1..500}; do echo cliente 2 - iteracion $i; done
```

Los lanzamos a la vez y veremos que, como esperábamos, las escrituras no son bloqueantes, ¡se intercalan las iteraciones!

```
cliente2 - iteracion 1
cliente2 - iteracion 2
cliente2 - iteracion 3
cliente2 - iteracion 4
cliente2 - iteracion 5
cliente2 - iteracion 6
cliente2 - iteracion 7
cliente2 - iteracion 8
cliente2 - iteracion 9
cliente2 - iteracion 10
cliente2 - iteracion 11
cliente2 - iteracion 12
cliente2 - iteracion 13
cliente2 - iteracion 14
cliente2 - iteracion 15
cliente2 - iteracion 16
cliente2 - iteracion 17
cliente2 - iteracion 18
cliente2 - iteracion 19
cliente2 - iteracion 20
cliente2 - iteracion 21
cliente2 - iteracion 22
cliente2 - iteracion 23
cliente2 - iteracion 24
cliente2 - iteracion 25
cliente2 - iteracion 26
cliente2 - iteracion 27
cliente2 - iteracion 28
cliente2 - iteracion 29
cliente2 - iteracion 30
cliente2 - iteracion 31
cliente2 - iteracion 32
cliente2 - iteracion 33
cliente2 - iteracion 34
cliente2 - iteracion 35
cliente2 - iteracion 36
cliente2 - iteracion 37
cliente2 - iteracion 38
cliente2 - iteracion 39
cliente2 - iteracion 40
cliente2 - iteracion 41
cliente2 - iteracion 42
cliente2 - iteracion 43
cliente2 - iteracion 44
cliente2 - iteracion 45
cliente2 - iteracion 46
cliente2 - iteracion 47
cliente2 - iteracion 48
cliente2 - iteracion 49
cliente2 - iteracion 50
cliente2 - iteracion 51
cliente2 - iteracion 52
cliente2 - iteracion 53
cliente2 - iteracion 54
cliente2 - iteracion 55
cliente2 - iteracion 56
cliente2 - iteracion 57
cliente2 - iteracion 58
cliente2 - iteracion 59
cliente2 - iteracion 60
cliente2 - iteracion 61
cliente2 - iteracion 62
cliente2 - iteracion 63
cliente2 - iteracion 64
cliente2 - iteracion 65
cliente2 - iteracion 66
cliente2 - iteracion 67
cliente2 - iteracion 68
cliente2 - iteracion 69
cliente2 - iteracion 70
cliente2 - iteracion 71
cliente2 - iteracion 72
cliente2 - iteracion 73
cliente2 - iteracion 74
cliente2 - iteracion 75
cliente2 - iteracion 76
cliente2 - iteracion 77
cliente2 - iteracion 78
cliente2 - iteracion 79
cliente2 - iteracion 80
cliente2 - iteracion 81
cliente2 - iteracion 82
cliente2 - iteracion 83
cliente2 - iteracion 84
cliente2 - iteracion 85
cliente2 - iteracion 86
cliente2 - iteracion 87
cliente2 - iteracion 88
cliente2 - iteracion 89
cliente2 - iteracion 90
cliente2 - iteracion 91
cliente2 - iteracion 92
cliente2 - iteracion 93
cliente1 - iteracion 1
cliente1 - iteracion 2
cliente1 - iteracion 3
cliente2 - iteracion 94
cliente2 - iteracion 95
cliente2 - iteracion 96
cliente2 - iteracion 97
cliente2 - iteracion 98
cliente2 - iteracion 99
cliente2 - iteracion 100
cliente2 - iteracion 101
cliente2 - iteracion 102
cliente2 - iteracion 103
cliente2 - iteracion 104
cliente2 - iteracion 105
cliente2 - iteracion 106
cliente2 - iteracion 107
cliente2 - iteracion 108
cliente2 - iteracion 109
cliente2 - iteracion 110
cliente2 - iteracion 111
cliente2 - iteracion 112
cliente2 - iteracion 113
cliente2 - iteracion 114
cliente2 - iteracion 115
cliente2 - iteracion 116
cliente2 - iteracion 117
cliente2 - iteracion 118
cliente2 - iteracion 119
cliente2 - iteracion 120
cliente2 - iteracion 121
cliente2 - iteracion 122
cliente2 - iteracion 123
cliente2 - iteracion 124
cliente2 - iteracion 125
cliente2 - iteracion 126
cliente2 - iteracion 127
cliente2 - iteracion 128
cliente2 - iteracion 129
cliente2 - iteracion 130
cliente2 - iteracion 131
cliente2 - iteracion 132
cliente2 - iteracion 133
cliente2 - iteracion 134
cliente2 - iteracion 135
cliente2 - iteracion 136
cliente2 - iteracion 137
cliente2 - iteracion 138
cliente2 - iteracion 139
cliente2 - iteracion 140
cliente2 - iteracion 141
cliente2 - iteracion 142
cliente2 - iteracion 143
cliente2 - iteracion 144
cliente2 - iteracion 145
cliente2 - iteracion 146
cliente2 - iteracion 147
cliente2 - iteracion 148
cliente2 - iteracion 149
cliente2 - iteracion 150
cliente2 - iteracion 151
cliente2 - iteracion 152
cliente2 - iteracion 153
cliente2 - iteracion 154
cliente2 - iteracion 155
cliente2 - iteracion 156
cliente2 - iteracion 157
cliente2 - iteracion 158
cliente2 - iteracion 159
cliente2 - iteracion 160
cliente2 - iteracion 161
cliente2 - iteracion 162
cliente2 - iteracion 163
cliente2 - iteracion 164
cliente2 - iteracion 165
cliente2 - iteracion 166
cliente2 - iteracion 167
cliente2 - iteracion 168
cliente2 - iteracion 169
cliente2 - iteracion 170
cliente2 - iteracion 171
cliente2 - iteracion 172
cliente2 - iteracion 173
cliente2 - iteracion 174
cliente2 - iteracion 175
cliente2 - iteracion 176
cliente2 - iteracion 177
cliente2 - iteracion 178
cliente2 - iteracion 179
cliente2 - iteracion 180
cliente2 - iteracion 181
cliente2 - iteracion 182
cliente2 - iteracion 183
cliente2 - iteracion 184
cliente2 - iteracion 185
cliente2 - iteracion 186
cliente2 - iteracion 187
cliente2 - iteracion 188
cliente2 - iteracion 189
cliente2 - iteracion 190
cliente2 - iteracion 191
cliente2 - iteracion 192
cliente2 - iteracion 193
cliente2 - iteracion 194
cliente2 - iteracion 195
cliente2 - iteracion 196
cliente2 - iteracion 197
cliente2 - iteracion 198
cliente2 - iteracion 199
cliente2 - iteracion 200
cliente2 - iteracion 201
cliente2 - iteracion 202
cliente2 - iteracion 203
cliente2 - iteracion 204
cliente2 - iteracion 205
cliente2 - iteracion 206
cliente2 - iteracion 207
cliente2 - iteracion 208
cliente2 - iteracion 209
cliente2 - iteracion 210
cliente2 - iteracion 211
cliente2 - iteracion 212
cliente2 - iteracion 213
cliente2 - iteracion 214
cliente2 - iteracion 215
cliente2 - iteracion 216
cliente2 - iteracion 217
cliente2 - iteracion 218
cliente2 - iteracion 219
cliente2 - iteracion 220
cliente2 - iteracion 221
cliente2 - iteracion 222
cliente2 - iteracion 223
cliente2 - iteracion 224
cliente2 - iteracion 225
cliente2 - iteracion 226
cliente2 - iteracion 227
cliente2 - iteracion 228
cliente2 - iteracion 229
cliente2 - iteracion 230
cliente2 - iteracion 231
cliente2 - iteracion 232
cliente2 - iteracion 233
cliente2 - iteracion 234
cliente2 - iteracion 235
cliente2 - iteracion 236
cliente2 - iteracion 237
cliente2 - iteracion 238
cliente2 - iteracion 239
cliente2 - iteracion 240
cliente2 - iteracion 241
cliente2 - iteracion 242
cliente2 - iteracion 243
cliente2 - iteracion 244
cliente2 - iteracion 245
cliente2 - iteracion 246
cliente2 - iteracion 247
cliente2 - iteracion 248
cliente2 - iteracion 249
cliente2 - iteracion 250
cliente2 - iteracion 251
cliente2 - iteracion 252
cliente2 - iteracion 253
cliente2 - iteracion 254
cliente2 - iteracion 255
cliente2 - iteracion 256
cliente2 - iteracion 257
cliente2 - iteracion 258
cliente2 - iteracion 259
cliente2 - iteracion 260
cliente2 - iteracion 261
cliente2 - iteracion 262
cliente2 - iteracion 263
cliente2 - iteracion 264
cliente2 - iteracion 265
cliente2 - iteracion 266
cliente2 - iteracion 267
cliente2 - iteracion 268
cliente2 - iteracion 269
cliente2 - iteracion 270
cliente2 - iteracion 271
cliente2 - iteracion 272
cliente2 - iteracion 273
cliente2 - iteracion 274
cliente2 - iteracion 275
cliente2 - iteracion 276
cliente2 - iteracion 277
cliente2 - iteracion 278
cliente2 - iteracion 279
cliente2 - iteracion 280
cliente2 - iteracion 281
cliente2 - iteracion 282
cliente2 - iteracion 283
cliente2 - iteracion 284
cliente2 - iteracion 285
cliente2 - iteracion 286
cliente2 - iteracion 287
cliente2 - iteracion 288
cliente2 - iteracion 289
cliente2 - iteracion 290
cliente2 - iteracion 291
cliente2 - iteracion 292
cliente2 - iteracion 293
cliente2 - iteracion 294
cliente2 - iteracion 295
cliente2 - iteracion 296
cliente2 - iteracion 297
cliente2 - iteracion 298
cliente2 - iteracion 299
cliente2 - iteracion 300
cliente2 - iteracion 301
cliente2 - iteracion 302
cliente2 - iteracion 303
cliente2 - iteracion 304
cliente2 - iteracion 305
cliente2 - iteracion 306
cliente2 - iteracion 307
cliente2 - iteracion 308
cliente2 - iteracion 309
cliente1 - iteracion 4
cliente1 - iteracion 5
cliente1 - iteracion 6
cliente1 - iteracion 7
cliente1 - iteracion 8
cliente1 - iteracion 9
cliente1 - iteracion 10
cliente1 - iteracion 11
cliente1 - iteracion 12
cliente1 - iteracion 13
cliente1 - iteracion 14
cliente1 - iteracion 15
cliente1 - iteracion 16
cliente1 - iteracion 17
cliente1 - iteracion 18
cliente1 - iteracion 19
cliente1 - iteracion 20
cliente1 - iteracion 21
cliente1 - iteracion 22
cliente1 - iteracion 23
cliente1 - iteracion 24
cliente1 - iteracion 25
cliente1 - iteracion 26
cliente1 - iteracion 27
cliente1 - iteracion 28
cliente1 - iteracion 29
cliente1 - iteracion 30
cliente1 - iteracion 31
cliente1 - iteracion 32
cliente1 - iteracion 33
cliente1 - iteracion 34
cliente1 - iteracion 35
cliente1 - iteracion 36
cliente1 - iteracion 37
cliente1 - iteracion 38
cliente1 - iteracion 39
cliente1 - iteracion 40
cliente1 - iteracion 41
cliente1 - iteracion 42
cliente1 - iteracion 43
cliente1 - iteracion 44
cliente1 - iteracion 45
cliente1 - iteracion 46
cliente1 - iteracion 47
cliente1 - iteracion 48
cliente1 - iteracion 49
cliente1 - iteracion 50
cliente1 - iteracion 51
cliente1 - iteracion 52
cliente1 - iteracion 53
cliente1 - iteracion 54
cliente1 - iteracion 55
cliente1 - iteracion 56
cliente1 - iteracion 57
cliente1 - iteracion 58
cliente1 - iteracion 59
cliente1 - iteracion 60
cliente1 - iteracion 61
cliente1 - iteracion 62
cliente1 - iteracion 63
cliente1 - iteracion 64
cliente1 - iteracion 65
cliente1 - iteracion 66
cliente1 - iteracion 67
cliente1 - iteracion 68
cliente1 - iteracion 69
cliente1 - iteracion 70
cliente1 - iteracion 71
cliente1 - iteracion 72
cliente1 - iteracion 73
cliente1 - iteracion 74
cliente1 - iteracion 75
cliente1 - iteracion 76
cliente1 - iteracion 77
cliente1 - iteracion 78
cliente1 - iteracion 79
cliente1 - iteracion 80
cliente1 - iteracion 81
cliente1 - iteracion 82
cliente1 - iteracion 83
cliente1 - iteracion 84
cliente1 - iteracion 85
cliente1 - iteracion 86
cliente1 - iteracion 87
cliente1 - iteracion 88
cliente1 - iteracion 89
cliente1 - iteracion 90
cliente1 - iteracion 91
cliente1 - iteracion 92
cliente1 - iteracion 93
cliente1 - iteracion 94
cliente1 - iteracion 95
cliente1 - iteracion 96
cliente1 - iteracion 97
cliente1 - iteracion 98
cliente1 - iteracion 99
cliente1 - iteracion 100
cliente1 - iteracion 101
cliente1 - iteracion 102
cliente1 - iteracion 103
cliente1 - iteracion 104
cliente1 - iteracion 105
cliente1 - iteracion 106
cliente1 - iteracion 107
cliente1 - iteracion 108
cliente1 - iteracion 109
cliente1 - iteracion 110
cliente1 - iteracion 111
cliente1 - iteracion 112
cliente1 - iteracion 113
cliente1 - iteracion 114
cliente1 - iteracion 115
cliente1 - iteracion 116
cliente1 - iteracion 117
cliente1 - iteracion 118
cliente1 - iteracion 119
cliente1 - iteracion 120
cliente1 - iteracion 121
cliente1 - iteracion 122
cliente1 - iteracion 123
cliente1 - iteracion 124
cliente1 - iteracion 125
cliente1 - iteracion 126
cliente1 - iteracion 127
cliente1 - iteracion 128
cliente1 - iteracion 129
cliente1 - iteracion 130
cliente1 - iteracion 131
cliente1 - iteracion 132
cliente1 - iteracion 133
cliente1 - iteracion 134
cliente1 - iteracion 135
cliente1 - iteracion 136
cliente1 - iteracion 137
cliente1 - iteracion 138
cliente1 - iteracion 139
cliente1 - iteracion 140
cliente1 - iteracion 141
cliente1 - iteracion 142
cliente1 - iteracion 143
cliente1 - iteracion 144
cliente1 - iteracion 145
cliente1 - iteracion 146
cliente1 - iteracion 147
cliente1 - iteracion 148
cliente1 - iteracion 149
cliente1 - iteracion 150
cliente1 - iteracion 151
cliente1 - iteracion 152
cliente1 - iteracion 153
cliente1 - iteracion 154
cliente1 - iteracion 155
cliente1 - iteracion 156
cliente1 - iteracion 157
cliente1 - iteracion 158
cliente1 - iteracion 159
cliente1 - iteracion 160
cliente1 - iteracion 161
cliente1 - iteracion 162
cliente1 - iteracion 163
cliente1 - iteracion 164
cliente1 - iteracion 165
cliente1 - iteracion 166
cliente1 - iteracion 167
cliente1 - iteracion 168
cliente1 - iteracion 169
cliente1 - iteracion 170
cliente1 - iteracion 171
cliente1 - iteracion 172
cliente1 - iteracion 173
cliente1 - iteracion 174
cliente1 - iteracion 175
cliente1 - iteracion 176
cliente1 - iteracion 177
cliente1 - iteracion 178
cliente1 - iteracion 179
cliente1 - iteracion 180
cliente1 - iteracion 181
cliente1 - iteracion 182
cliente1 - iteracion 183
cliente1 - iteracion 184
cliente1 - iteracion 185
cliente1 - iteracion 186
cliente1 - iteracion 187
cliente1 - iteracion 188
cliente1 - iteracion 189
cliente1 - iteracion 190
cliente1 - iteracion 191
cliente1 - iteracion 192
cliente1 - iteracion 193
cliente1 - iteracion 194
cliente1 - iteracion 195
cliente1 - iteracion 196
cliente1 - iteracion 197
cliente1 - iteracion 198
cliente1 - iteracion 199
cliente1 - iteracion 200
cliente1 - iteracion 201
cliente1 - iteracion 202
cliente1 - iteracion 203
cliente1 - iteracion 204
cliente1 - iteracion 205
cliente1 - iteracion 206
cliente1 - iteracion 207
cliente1 - iteracion 208
cliente1 - iteracion 209
cliente1 - iteracion 210
cliente1 - iteracion 211
cliente1 - iteracion 212
cliente1 - iteracion 213
cliente1 - iteracion 214
cliente1 - iteracion 215
cliente1 - iteracion 216
cliente1 - iteracion 217
cliente1 - iteracion 218
cliente1 - iteracion 219
cliente1 - iteracion 220
cliente1 - iteracion 221
cliente1 - iteracion 222
cliente1 - iteracion 223
cliente1 - iteracion 224
cliente1 - iteracion 225
cliente1 - iteracion 226
cliente1 - iteracion 227
cliente1 - iteracion 228
cliente1 - iteracion 229
cliente1 - iteracion 230
cliente1 - iteracion 231
cliente1 - iteracion 232
cliente1 - iteracion 233
cliente1 - iteracion 234
cliente1 - iteracion 235
cliente1 - iteracion 236
cliente1 - iteracion 237
cliente1 - iteracion 238
cliente1 - iteracion 239
cliente1 - iteracion 240
cliente1 - iteracion 241
cliente1 - iteracion 242
cliente1 - iteracion 243
cliente1 - iteracion 244
cliente1 - iteracion 245
cliente1 - iteracion 246
cliente1 - iteracion 247
cliente1 - iteracion 248
cliente1 - iteracion 249
cliente1 - iteracion 250
cliente1 - iteracion 251
cliente1 - iteracion 252
cliente1 - iteracion 253
cliente1 - iteracion 254
cliente1 - iteracion 255
cliente1 - iteracion 256
cliente1 - iteracion 257
cliente1 - iteracion 258
cliente1 - iteracion 259
cliente1 - iteracion 260
cliente1 - iteracion 261
cliente1 - iteracion 262
cliente1 - iteracion 263
cliente1 - iteracion 264
cliente1 - iteracion 265
cliente1 - iteracion 266
cliente1 - iteracion 267
cliente1 - iteracion 268
cliente1 - iteracion 269
cliente1 - iteracion 270
cliente1 - iteracion 271
cliente1 - iteracion 272
cliente1 - iteracion 273
cliente1 - iteracion 274
cliente1 - iteracion 275
cliente1 - iteracion 276
cliente1 - iteracion 277
cliente1 - iteracion 278
cliente1 - iteracion 279
cliente1 - iteracion 280
cliente1 - iteracion 281
cliente1 - iteracion 282
cliente1 - iteracion 283
cliente1 - iteracion 284
cliente1 - iteracion 285
cliente1 - iteracion 286
cliente1 - iteracion 287
cliente1 - iteracion 288
cliente1 - iteracion 289
cliente1 - iteracion 290
cliente1 - iteracion 291
cliente1 - iteracion 292
cliente1 - iteracion 293
cliente1 - iteracion 294
cliente1 - iteracion 295
cliente1 - iteracion 296
cliente1 - iteracion 297
cliente1 - iteracion 298
cliente1 - iteracion 299
cliente1 - iteracion 300
cliente1 - iteracion 301
cliente1 - iteracion 302
cliente1 - iteracion 303
cliente1 - iteracion 304
cliente1 - iteracion 305
cliente1 - iteracion 306
cliente1 - iteracion 307
cliente1 - iteracion 308
cliente1 - iteracion 309
cliente1 - iteracion 310
cliente1 - iteracion 311
cliente1 - iteracion 312
cliente1 - iteracion 313
cliente1 - iteracion 314
cliente1 - iteracion 315
cliente1 - iteracion 316
cliente1 - iteracion 317
cliente1 - iteracion 318
cliente1 - iteracion 319
cliente1 - iteracion 320
cliente1 - iteracion 321
cliente1 - iteracion 322
cliente1 - iteracion 323
cliente1 - iteracion 324
cliente1 - iteracion 325
cliente1 - iteracion 326
cliente1 - iteracion 327
cliente1 - iteracion 328
cliente1 - iteracion 329
cliente1 - iteracion 330
cliente1 - iteracion 331
cliente1 - iteracion 332
cliente1 - iteracion 333
cliente1 - iteracion 334
cliente1 - iteracion 335
cliente1 - iteracion 336
cliente1 - iteracion 337
cliente1 - iteracion 338
cliente1 - iteracion 339
cliente1 - iteracion 340
cliente1 - iteracion 341
cliente1 - iteracion 342
cliente1 - iteracion 343
cliente1 - iteracion 344
cliente1 - iteracion 345
cliente1 - iteracion 346
cliente1 - iteracion 347
cliente1 - iteracion 348
cliente1 - iteracion 349
cliente1 - iteracion 350
cliente1 - iteracion 351
cliente1 - iteracion 352
cliente1 - iteracion 353
cliente1 - iteracion 354
cliente1 - iteracion 355
cliente1 - iteracion 356
cliente1 - iteracion 357
cliente1 - iteracion 358
cliente1 - iteracion 359
cliente1 - iteracion 360
cliente1 - iteracion 361
cliente1 - iteracion 362
cliente1 - iteracion 363
cliente1 - iteracion 364
cliente1 - iteracion 365
cliente1 - iteracion 366
cliente1 - iteracion 367
cliente1 - iteracion 368
cliente1 - iteracion 369
cliente1 - iteracion 370
cliente1 - iteracion 371
cliente1 - iteracion 372
cliente1 - iteracion 373
cliente1 - iteracion 374
cliente1 - iteracion 375
cliente1 - iteracion 376
cliente1 - iteracion 377
cliente1 - iteracion 378
cliente1 - iteracion 379
cliente1 - iteracion 380
cliente1 - iteracion 381
cliente1 - iteracion 382
cliente1 - iteracion 383
cliente1 - iteracion 384
cliente1 - iteracion 385
cliente1 - iteracion 386
cliente1 - iteracion 387
cliente1 - iteracion 388
cliente1 - iteracion 389
cliente1 - iteracion 390
cliente1 - iteracion 391
cliente1 - iteracion 392
cliente1 - iteracion 393
cliente1 - iteracion 394
cliente1 - iteracion 395
cliente1 - iteracion 396
cliente1 - iteracion 397
cliente1 - iteracion 398
cliente1 - iteracion 399
cliente1 - iteracion 400
cliente1 - iteracion 401
cliente1 - iteracion 402
cliente1 - iteracion 403
cliente1 - iteracion 404
cliente1 - iteracion 405
cliente1 - iteracion 406
cliente1 - iteracion 407
cliente1 - iteracion 408
cliente1 - iteracion 409
cliente1 - iteracion 410
cliente1 - iteracion 411
cliente1 - iteracion 412
cliente1 - iteracion 413
cliente1 - iteracion 414
cliente1 - iteracion 415
cliente1 - iteracion 416
cliente1 - iteracion 417
cliente1 - iteracion 418
cliente1 - iteracion 419
cliente1 - iteracion 420
cliente1 - iteracion 421
cliente1 - iteracion 422
cliente1 - iteracion 423
cliente1 - iteracion 424
cliente1 - iteracion 425
cliente1 - iteracion 426
cliente1 - iteracion 427
cliente1 - iteracion 428
cliente1 - iteracion 429
cliente1 - iteracion 430
cliente1 - iteracion 431
cliente1 - iteracion 432
cliente1 - iteracion 433
cliente1 - iteracion 434
cliente1 - iteracion 435
cliente1 - iteracion 436
cliente1 - iteracion 437
cliente1 - iteracion 438
cliente1 - iteracion 439
cliente1 - iteracion 440
cliente1 - iteracion 441
cliente1 - iteracion 442
cliente1 - iteracion 443
cliente1 - iteracion 444
cliente1 - iteracion 445
cliente1 - iteracion 446
cliente1 - iteracion 447
cliente1 - iteracion 448
cliente1 - iteracion 449
cliente1 - iteracion 450
cliente1 - iteracion 451
cliente1 - iteracion 452
cliente1 - iteracion 453
cliente1 - iteracion 454
cliente1 - iteracion 455
cliente1 - iteracion 456
cliente1 - iteracion 457
cliente1 - iteracion 458
cliente1 - iteracion 459
cliente1 - iteracion 460
cliente1 - iteracion 461
cliente1 - iteracion 462
cliente1 - iteracion 463
cliente1 - iteracion 464
cliente1 - iteracion 465
cliente1 - iteracion 466
cliente1 - iteracion 467
cliente1 - iteracion 468
cliente1 - iteracion 469
cliente1 - iteracion 470
cliente1 - iteracion 471
cliente1 - iteracion 472
cliente1 - iteracion 473
cliente1 - iteracion 474
cliente1 - iteracion 475
cliente1 - iteracion 476
cliente1 - iteracion 477
cliente1 - iteracion 478
cliente1 - iteracion 479
cliente1 - iteracion 480
cliente1 - iteracion 481
cliente1 - iteracion 482
cliente1 - iteracion 483
cliente1 - iteracion 484
cliente1 - iteracion 485
cliente1 - iteracion 486
cliente1 - iteracion 487
cliente1 - iteracion 488
cliente1 - iteracion 489
cliente1 - iteracion 490
cliente1 - iteracion 491
cliente1 - iteracion 492
cliente1 - iteracion 493
cliente1 - iteracion 494
cliente1 - iteracion 495
cliente1 - iteracion 496
cliente1 - iteracion 497
cliente1 - iteracion 498
cliente1 - iteracion 499
cliente1 - iteracion 500
cliente2 - iteracion 310
cliente2 - iteracion 311
cliente2 - iteracion 312
cliente2 - iteracion 313
cliente2 - iteracion 314
cliente2 - iteracion 315
cliente2 - iteracion 316
cliente2 - iteracion 317
cliente2 - iteracion 318
cliente2 - iteracion 319
cliente2 - iteracion 320
cliente2 - iteracion 321
cliente2 - iteracion 322
cliente2 - iteracion 323
cliente2 - iteracion 324
cliente2 - iteracion 325
cliente2 - iteracion 326
cliente2 - iteracion 327
cliente2 - iteracion 328
cliente2 - iteracion 329
cliente2 - iteracion 330
cliente2 - iteracion 331
cliente2 - iteracion 332
cliente2 - iteracion 333
cliente2 - iteracion 334
cliente2 - iteracion 335
cliente2 - iteracion 336
cliente2 - iteracion 337
cliente2 - iteracion 338
cliente2 - iteracion 339
cliente2 - iteracion 340
cliente2 - iteracion 341
cliente2 - iteracion 342
cliente2 - iteracion 343
cliente2 - iteracion 344
cliente2 - iteracion 345
cliente2 - iteracion 346
cliente2 - iteracion 347
cliente2 - iteracion 348
cliente2 - iteracion 349
cliente2 - iteracion 350
cliente2 - iteracion 351
cliente2 - iteracion 352
cliente2 - iteracion 353
cliente2 - iteracion 354
cliente2 - iteracion 355
cliente2 - iteracion 356
cliente2 - iteracion 357
cliente2 - iteracion 358
cliente2 - iteracion 359
cliente2 - iteracion 360
cliente2 - iteracion 361
cliente2 - iteracion 362
cliente2 - iteracion 363
cliente2 - iteracion 364
cliente2 - iteracion 365
cliente2 - iteracion 366
cliente2 - iteracion 367
cliente2 - iteracion 368
cliente2 - iteracion 369
cliente2 - iteracion 370
cliente2 - iteracion 371
cliente2 - iteracion 372
cliente2 - iteracion 373
cliente2 - iteracion 374
cliente2 - iteracion 375
cliente2 - iteracion 376
cliente2 - iteracion 377
cliente2 - iteracion 378
cliente2 - iteracion 379
cliente2 - iteracion 380
cliente2 - iteracion 381
cliente2 - iteracion 382
cliente2 - iteracion 383
cliente2 - iteracion 384
cliente2 - iteracion 385
cliente2 - iteracion 386
cliente2 - iteracion 387
cliente2 - iteracion 388
cliente2 - iteracion 389
cliente2 - iteracion 390
cliente2 - iteracion 391
cliente2 - iteracion 392
cliente2 - iteracion 393
cliente2 - iteracion 394
cliente2 - iteracion 395
cliente2 - iteracion 396
cliente2 - iteracion 397
cliente2 - iteracion 398
cliente2 - iteracion 399
cliente2 - iteracion 400
cliente2 - iteracion 401
cliente2 - iteracion 402
cliente2 - iteracion 403
cliente2 - iteracion 404
cliente2 - iteracion 405
cliente2 - iteracion 406
cliente2 - iteracion 407
cliente2 - iteracion 408
cliente2 - iteracion 409
cliente2 - iteracion 410
cliente2 - iteracion 411
cliente2 - iteracion 412
cliente2 - iteracion 413
cliente2 - iteracion 414
cliente2 - iteracion 415
cliente2 - iteracion 416
cliente2 - iteracion 417
cliente2 - iteracion 418
cliente2 - iteracion 419
cliente2 - iteracion 420
cliente2 - iteracion 421
cliente2 - iteracion 422
cliente2 - iteracion 423
cliente2 - iteracion 424
cliente2 - iteracion 425
cliente2 - iteracion 426
cliente2 - iteracion 427
cliente2 - iteracion 428
cliente2 - iteracion 429
cliente2 - iteracion 430
cliente2 - iteracion 431
cliente2 - iteracion 432
cliente2 - iteracion 433
cliente2 - iteracion 434
cliente2 - iteracion 435
cliente2 - iteracion 436
cliente2 - iteracion 437
cliente2 - iteracion 438
cliente2 - iteracion 439
cliente2 - iteracion 440
cliente2 - iteracion 441
cliente2 - iteracion 442
cliente2 - iteracion 443
cliente2 - iteracion 444
cliente2 - iteracion 445
cliente2 - iteracion 446
cliente2 - iteracion 447
cliente2 - iteracion 448
cliente2 - iteracion 449
cliente2 - iteracion 450
cliente2 - iteracion 451
cliente2 - iteracion 452
cliente2 - iteracion 453
cliente2 - iteracion 454
cliente2 - iteracion 455
cliente2 - iteracion 456
cliente2 - iteracion 457
cliente2 - iteracion 458
cliente2 - iteracion 459
cliente2 - iteracion 460
cliente2 - iteracion 461
cliente2 - iteracion 462
cliente2 - iteracion 463
cliente2 - iteracion 464
cliente2 - iteracion 465
cliente2 - iteracion 466
cliente2 - iteracion 467
cliente2 - iteracion 468
cliente2 - iteracion 469
cliente2 - iteracion 470
cliente2 - iteracion 471
cliente2 - iteracion 472
cliente2 - iteracion 473
cliente2 - iteracion 474
cliente2 - iteracion 475
cliente2 - iteracion 476
cliente2 - iteracion 477
cliente2 - iteracion 478
cliente2 - iteracion 479
cliente2 - iteracion 480
cliente2 - iteracion 481
cliente2 - iteracion 482
cliente2 - iteracion 483
cliente2 - iteracion 484
cliente2 - iteracion 485
cliente2 - iteracion 486
cliente2 - iteracion 487
cliente2 - iteracion 488
cliente2 - iteracion 489
cliente2 - iteracion 490
cliente2 - iteracion 491
cliente2 - iteracion 492
cliente2 - iteracion 493
cliente2 - iteracion 494
cliente2 - iteracion 495
cliente2 - iteracion 496
cliente2 - iteracion 497
cliente2 - iteracion 498
cliente2 - iteracion 499
cliente2 - iteracion 500
```

## Bibliografía

[Introducción a Lustre](http://www.systerminal.com/2014/07/21/introduccion-a-lustre/)

[Instalación de Lustre en CentOS 6.5](http://www.systerminal.com/2014/07/21/instalacion-de-lustre-en-centos-6-5/)
