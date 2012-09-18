#!/bin/bash
if [ -z $1 ];then echo "Usage: $0 <domain.es>";exit 1;fi
res=$(curl --insecure -s "https://www.nic.es/sgnd/dominio/publicBuscarDominios.action" -d "tDominio.nombreDominio=${1}" |grep -A4 '<td class="disp">' |head -n 5 |egrep -i "(dominio|reservado|disponible)" |tail -n 1 |rev |cut -f 2 -d \" |rev |sed -e "s/\t//g" -e "s/ //g")
echo "$1 - $res"
