#!/bin/bash

if [ $# -ne 3 ]
then
  echo "Tienes que meter 3 parámetros"
  exit 1
fi

INPUT="$1"
XLABEL="$2"
YLABEL="$3"

echo "| $XLABEL | $YLABEL |  Error  |"
echo "| :-----: | :-----: | :-----: |"

while read dato media error
do
  echo "| $dato | $media | $error |"
done < $INPUT
