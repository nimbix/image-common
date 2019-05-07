#!/bin/bash

for i in `echo $1|tr ',' ' '`; do
        echo ${i}|grep -q "@"
        [[ $? -eq 0 ]] && echo ${i} || echo "$2@$i"
done
