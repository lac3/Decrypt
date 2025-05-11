#!/bin/bash

sizes=(180 167 152 120 87 80 60 58 40)

for size in "${sizes[@]}"
do
    sips -z "$size" "$size" "icon_1024.jpg" --out "icon_$size.jpg"
done
