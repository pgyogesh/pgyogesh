spin[0]="-"
spin[1]="\\"
spin[2]="|"
spin[3]="/"
echo -n "[Running] ${spin[0]}" && while kill -0 $1
do
  for i in "${spin[@]}"
  do
        echo -ne "\b$i"
        sleep 0.2
  done
done
