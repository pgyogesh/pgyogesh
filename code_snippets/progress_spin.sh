spin[0]="-"
spin[1]="\\"
spin[2]="|"
spin[3]="/"
echo -n "[Running] ${spin[0]}" && while ps -ef |grep <process_name> |grep -v grep > /dev/null
do
  for i in "${spin[@]}"
  do
        echo -ne "\b$i"
        sleep 0.2
  done
done