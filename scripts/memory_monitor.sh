#!/bin/bash

DATE=$(date +%F)
mkdir -p $DATE

while true
do
  TIME=$(date +%T)
  FILE="$DATE/$TIME.txt"
  ps -eo pid,pcpu,pmem,vsz,rss,command --sort -pmem > $FILE
  gzip $FILE
  sleep 300
done
