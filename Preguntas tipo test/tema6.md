# Preguntas tema 6

Tenemos una Raspberry Pi con el liviano gestor de descargas PyLoad instalado.
Queremos acceder a él desde fuera de casa para poder mandar ficheros a descargar
siempre que tengamos la oportunidad, pero después de configurarlo todo, vemos que
el cortafuegos bloquea el tráfico... ¿Qué orden de iptables debemos ejecutar para
conseguir conectarnos a PyLoad? El puerto de la interfaz remota es el 7227.

**NOTA**: Suponer que las órdenes las ponemos en un script o similar, para que no haya problemas de orden de las reglas.

1.`iptables -A OUTPUT -p tcp --dport 7227 -j ACCEPT`
2.`iptables -A INPUT -p tcp --dport 7227 -j DROP`
3.`iptables -A OUTPUT -p tcp --dport 7227 -j DROP`
4.`iptables -A INPUT -p tcp --dport 7227 -j ACCEPT`


Respuesta correcta: **4**
