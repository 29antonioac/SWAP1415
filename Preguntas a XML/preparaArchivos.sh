#!/bin/bash

# sed '/^$/d'

input=$1
quitoespacios=$(mktemp)

sed 's/^[ ]*[1-9,A-D,a-d][".","-".".-",)]//' $1 > $quitoespacios # Borra encabezados
sed 's/^[1-9,A-D,a-d][".","-".".-",)]//' $quitoespacios > $1_preparado.txt # Borra encabezados
