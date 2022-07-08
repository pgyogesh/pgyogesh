#!/bin/bash

# Assuming kubectl installed.

# Usage
# ./collect-k8spods-logs.sh NAMESPACE NumFilesTobeCollectedForEachPod KUBECONFIGPATH
# Ex: ./collect-k8spods-logs.sh yb-admin-gjalla 2 ~/.kube/config

# Read cmd line args.
export NAMESPACE=$1
export NUMFILES=${2:-2} # collect latest 2 files by default per pod.
export KUBECONFIGPATH=$3

if [[ -z "${KUBECONFIGPATH}" ]]; then
    echo "Using Kubeconfig $KUBECONFIG"
    KUBECONFIGPATH=$KUBECONFIG
fi

# Check if kubeconfig exists.
if [ ! -f "$KUBECONFIGPATH" ]; then
    echo "$KUBECONFIGPATH does not exist."
    exit 1
fi

# Check if namespace exists and we can access it.
namespaceStatus=$(kubectl get namespace --kubeconfig=$KUBECONFIGPATH $NAMESPACE -o jsonpath='{.status.phase}')
if [ "$namespaceStatus" == "Active" ]
then
    echo "namespace $NAMESPACE is present."
else
   echo "namespace $NAMESPACE is not found or active."
   exit 1
fi

# Get pods in the namespace and extract master/tserver pod names.
masterpods=$(kubectl get pod -n $NAMESPACE --kubeconfig=$KUBECONFIGPATH -l app=yb-master -o custom-columns=:metadata.name)
tserverpods=$(kubectl get pod -n $NAMESPACE --kubeconfig=$KUBECONFIGPATH -l app=yb-tserver -o custom-columns=:metadata.name)
echo "master pods found: $masterpods"
echo "tserver pods found: $tserverpods"

# Create temp directory for storing logs.
OutDir="./$NAMESPACE-$(date "+%s")"
mkdir $OutDir

# Loop through all pods 
    # Exec into yb-cleanup container and get log file names
    # Create a namespace/podname directory inside temp directory
    # Copy at most latest $NUMFILES files into above directory
IFS=$(echo -en "\n\b") read -ra PODS <<< $masterpods # remove new lines.
IFS=' ' read -ra masterpod <<< "$PODS" # split pods.
for pod in "${masterpod[@]}"; do
    echo "Process $pod"
    count=$NUMFILES
    logfilesOut=$(kubectl exec -n $NAMESPACE --kubeconfig=$KUBECONFIGPATH $pod -c yb-cleanup -- ls -lt /home/yugabyte/master/logs/ | awk NR\>1 | awk '{print $NF}')
    #echo $logfilesOut
    # ls -lt *postgres* | head -n 2
    IFS=$(echo -en "\n\b") read -ra logFilesWithSpaces <<< $logfilesOut # remove new lines.
    IFS=' ' read -ra logFilesWithoutSpaces <<< "$logFilesWithSpaces" # split pods.
    # IFS=' ' read -ra logfiles <<< "$logfilesOut"
    # for file in "${logfiles[@]}"; do
    mkdir $OutDir/$pod
    for file in "${logFilesWithoutSpaces[@]}"; do
        if [[ $file != *"INFO"?* ]];
        then
            echo "$file doesn't have INFO? in it's name. Skipping it."
            continue
        fi
        if [ "$count" -eq "0" ];
        then
            echo "collected $NUMFILES for current pod";
            break
        fi
        if [ -f "$OutDir/$pod/$file" ];
        then
            echo "$OutDir/$pod/$file exists already."
            # This is happening due to symlink file.
            continue
        fi 
        echo "process $file, count left $count"
        ((count=count-1))
        kubectl --kubeconfig=$KUBECONFIGPATH cp $NAMESPACE/$pod:/home/yugabyte/master/logs/$file $OutDir/$pod/$file -c yb-cleanup
    done
done


IFS=$(echo -en "\n\b") read -ra PODS <<< $tserverpods # remove new lines.
IFS=' ' read -ra tserverpod <<< "$PODS" # split pods.
for pod in "${tserverpod[@]}"; do
    echo "Process $pod"
    infocount=$NUMFILES
    postgrescount=$NUMFILES
    logfilesOut=$(kubectl exec -n $NAMESPACE --kubeconfig=$KUBECONFIGPATH $pod -c yb-cleanup -- ls -lt /home/yugabyte/tserver/logs/ | awk NR\>1 | awk '{print $NF}')
    #echo $logfilesOut
    IFS=$(echo -en "\n\b") read -ra logFilesWithSpaces <<< $logfilesOut # remove new lines.
    IFS=' ' read -ra logFilesWithoutSpaces <<< "$logFilesWithSpaces" # split pods.
    mkdir $OutDir/$pod
    for file in "${logFilesWithoutSpaces[@]}"; do
        collect=false
        # info file
        if [[ $file == *"INFO"?* ]];
        then
            if [ -f "$OutDir/$pod/$file" ];
            then
                echo "$OutDir/$pod/$file exists already."
                # This is happening due to symlink file.
                continue
            fi
            if [ "$infocount" -eq "0" ];
            then
                echo "Already collected $NUMFILES INFO files. Skipping $file"
                continue
            fi
            ((infocount=infocount-1))
            collect=true
        fi

        # postgres file
        if [[ $file == "postgres"* ]];
        then
            if [ "$postgrescount" -eq "0" ];
            then
                echo "Already collected $NUMFILES postgres files. Skipping $file"
                continue
            fi
            ((postgrescount=postgrescount-1))
            collect=true
        fi

        if [[ "${collect}" == "true" ]];
        then
            echo "process $file, count left: postgres: $postgrescount, infocount: $infocount"
            kubectl --kubeconfig=$KUBECONFIGPATH cp $NAMESPACE/$pod:/home/yugabyte/tserver/logs/$file $OutDir/$pod/$file -c yb-cleanup
        else
            echo "Skip $file $collect"
        fi
    done
done

# Create tar out of temp directory.
tar czf $OutDir.tar.gz ./$OutDir
rm -rf $OutDir
echo "Logs are collected in $OutDir.tar.gz"

exit 0