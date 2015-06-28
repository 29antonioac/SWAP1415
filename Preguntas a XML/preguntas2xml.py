#!/usr/bin/env python

import sys,itertools
from os.path import basename

def grouper(n, iterable, fillvalue=None):
    """grouper(3, 'ABCDEFG', 'x') --> ABC DEF Gxx"""
    args = [iter(iterable)] * n
    return itertools.zip_longest(fillvalue=fillvalue, *args)

input=sys.argv[1]

with open(input) as f:
    lines=[line.strip() for line in f if line.strip() != "" ]

preguntas = grouper(6,lines,"---")

output=basename(input) + ".xml"
num_preguntas=0

with open(output,"w+") as f:
    for pregunta in preguntas:
        num_preguntas += 1
        f.write("\t<pregunta>\n")
        f.write("\t\t<enunciado> " + pregunta[0] + "</enunciado>\n")
        f.write("\t\t<opcionA> " + pregunta[1] + "</opcionA>\n")
        f.write("\t\t<opcionB> " + pregunta[2] + "</opcionB>\n")
        f.write("\t\t<opcionC> " + pregunta[3] + "</opcionC>\n")
        f.write("\t\t<opcionD> " + pregunta[4] + "</opcionD>\n")
        f.write("\t\t<solucion> " + pregunta[5] + "</solucion>\n")
        f.write("\t</pregunta>\n")

with open(output,"r+") as f:
    contenido = f.read()
    f.seek(0,0)
    f.write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
    f.write("<tema titulo=\"\" cantidad_preguntas=\"" + str(num_preguntas) + "\">\n")
    f.write(contenido)





# for pregunta,A,B,C,D,resp in lines:
#    print("P:",pregunta)
#    print("A:",A)
#    print("B:",B)
#    print("C:",C)
#    print("D:",D)
#    print("Respuesta:",resp)

# print(lines)
