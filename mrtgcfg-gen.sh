#!/bin/bash

#
# This is a script to generate MRTG config file
# Author: Jin Chen (jinchenbravo@gmail.com)
# 
#
set -x

function gen-disk-conf {

host=$1
snmpcommunity=$2

dtemplate="mrtg-disk-template-conf"

A=( `snmpwalk -v 2c $host -c $snmpcommunity hrStorage | grep "HOST-RESOURCES-TYPES::hrStorageFixedDisk" | cut -d'.' -f2 | cut -d' ' -f1` )
B=( `snmpwalk -v 2c $host -c $snmpcommunity hrStorage | grep "HOST-RESOURCES-TYPES::hrStorageNetworkDisk" | cut -d'.' -f2 | cut -d' ' -f1` )

C=("${A[@]}" "${B[@]}")

for i in "${C[@]}"
do
    descraw=`snmpwalk -v 2c $host -c $snmpcommunity hrStorageDescr.$i | cut -d' ' -f4  `
#    | sed -r "s/\//\\\//g"
    desc=${descraw//\//\\\/}
    if [ ! -z "$desc" ]; then
            factor=`snmpwalk -v 2c $host -c $snmpcommunity hrStorageAllocationUnits.$i | cut -d' ' -f4`
            sed -e "s/\${SETUP}/$host/g" \
                -e "s/\${SNMPCOMMUNITY}/$snmpcommunity/g" \
                -e "s/\${INDEX}/$i/g" \
                -e "s/\${DESC}/$desc/g" \
                -e "s/\${FACTOR}/$factor/g" \
                < $dtemplate >> $host.cfg
    fi
done


}

function gen-inf-conf {
    host=$1
    snmpcommunity=$2

    /usr/bin/cfgmaker --zero-speed=1000000000 $snmpcommunity@$host \
    >> $host.cfg
}

template="mrtg-template-conf"
host=$1
snmpcommunity=$2
maxmem=$3 # 300,000,000 means 300G because factor is 1024 (this is the default value)
maxswap=$4 #300,000,000 means 300G because factor is 1024 (this is the default value)
maxcpu=$5 # default value is 2000 which means the system has up to 20 cpu cores

sed -e "s/\${SETUP}/$host/g" \
    -e "s/\${SNMPCOMMUNITY}/$snmpcommunity/g" \
    -e "s/\${MAXSWAP}/${maxswap:-300000000}/g" \
    -e "s/\${MAXMEM}/${maxmem:-300000000}/g" \
    -e "s/\${MAXCPU}/${maxcpu:-2000}/g" \
    < $template > $host.cfg

gen-disk-conf $1 $2
gen-inf-conf $1 $2
