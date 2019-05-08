#!/bin/bash

# $1 is the license variable, $2 is a default port to prepend
# Parse a license account variable, using a provided port or adding a default
# typically @<license FQDN> so add $2 as 1999, or the account variable is potentially
# 9999@<license FQDN>
for i in `echo $1|tr ',' ' '`; do
        echo ${i}|grep -q "@"
        [[ $? -eq 0 ]] && echo ${i} || echo "$2@$i"
done
