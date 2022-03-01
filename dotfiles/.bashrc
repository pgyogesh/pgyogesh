# Aliases

alias sc='set_context -s'
alias k='kubectl'
alias kg='kubectl get'
alias ke='kubectl exec -it'
alias kgp='kubectl get pods'
alias kgpn='kubectl get pods -n'
alias kgpw='kubectl get pods -o wide'
alias kgn='kubectl get ns'
alias kgs='kubectl get services'


# Functions

## Bash

### Login to yb-tserver-0
tsbash() {
    kubectl exec -it yb-tserver-0 -n $1 -- bash
}

### Login to yb-master-0
msbash() {
    kubectl exec -it yb-master-0 -n $1 -- bash
}

### Login to any pod
pbash() {
    kubectl exec -it $1 -n $2 -- bash
}

## Custom Commands

###
tscmd() {
  kubectl exec yb-tserver-0 -n $1 -- $2
}

