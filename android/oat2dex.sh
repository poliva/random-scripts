#!/bin/bash
# Extract DEX file from inside Android Runtime OAT file using radare2
# (c)2013 Pau Oliva (@pof)

OAT="$1"
if [ -z "${OAT}" ]; then
	echo "Usage: $0 <file.oat>"
	exit 0
fi
HIT=$(r2 -q -c '/ dex\n035' "${OAT}" 2>/dev/null |grep hit0_0 |awk '{print $1}')
if [ -z "${HIT}" ]; then
	echo "[-] ERROR: Can't find dex header"
	exit 1
else
	echo "[+] DEX header found at address: ${HIT}"
fi
SIZE=$(r2 -e scr.color=false -q -c "px 4 @$HIT+32" ${OAT} 2>/dev/null |tail -n 1 |awk '{print $2 $3}' |sed -e "s/^/0x/" |rax2 -e)
echo "[+] Dex file size: ${SIZE} bytes"
r2 -q -c "pr ${SIZE} @${HIT} > ${OAT}.dex" "${OAT}" 2>/dev/null
if [ $? -eq 0 ]; then
	echo "[+] Dex file dumped to: ${OAT}.dex"
else
	echo "[-] ERROR: Something went wrong :("
fi
