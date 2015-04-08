# Preguntas tema 3

Supuesta esta configuración de red. ¿Qué deberías hacer para que los ordenadores de la red 192.168.1.0 "vean" los de 192.168.3.0?

![Imagen configuración red](http://static.thegeekstuff.com/wp-content/uploads/2012/04/route-command.png)

1. En los PC's de la subred 192.168.3.0 `# sudo add default gw 192.168.3.10` y en 192.168.3.10 `# route add -net 192.168.3.0 netmask 255.255.255.0 gw 192.168.1.10`

2. En los PC's de la subred 192.168.1.0 `# sudo add default gw 192.168.1.10` y en 192.168.1.10 `# route add -net 192.168.3.0 netmask 255.255.255.0 gw 192.168.3.10`

3. En los PC's de la subred 192.168.1.0 `# sudo add default gw 192.168.3.10` y en 192.168.1.10 `# route add -net 192.168.3.0 netmask 255.255.255.0 gw 192.168.3.10`

4. En los PC's de la subred 192.168.3.0 `# sudo add default gw 192.168.1.10` y en 192.168.1.10 `# route add -net 192.168.3.0 netmask 255.255.255.0 gw 192.168.3.10`

Respuesta correcta: **2**

[Fuente de la imagen](http://www.thegeekstuff.com/2012/04/route-examples/)
