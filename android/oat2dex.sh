#!/bin/bash
# Extract DEX file from inside Android Runtime OAT file using radare2
# (c)2013 Pau Oliva (@pof)

OAT="$1"
if [ -z "${OAT}" ]; then
	echo "Usage: $0 <file.oat>"
	exit 0
fi
HITS=( $(r2 -n -q -c '/ dex\n035' "${OAT}" 2>/dev/null |grep hit |awk '{print $1}') )
if [ ${#HITS[@]} -eq 0 ]; then
	echo "[-] ERROR: Can't find dex headers"
	exit 1
elif [ ${#HITS[@]} -eq 1 ]; then
	echo "[+] DEX header found at address: ${HITS[0]}"
else
	echo "[+] Multiple DEX headers found at addresses:"
	for addr in ${HITS[@]}; do echo "  $addr"; done
fi

for DEX_ADDR in ${HITS[@]}; do
	SIZE=$(r2 -n -q -c "pf i @${DEX_ADDR}+32 ~[2]" "${OAT}" 2>/dev/null)
	echo "[+] Dex file size: ${SIZE} bytes"
	r2 -q -c "pr ${SIZE} @${DEX_ADDR} > ${OAT}.${DEX_ADDR}.dex" "${OAT}" 2>/dev/null
	if [ $? -eq 0 ]; then
		echo "[+] Dex file dumped to: ${OAT}.${DEX_ADDR}.dex"
	else
		echo "[-] ERROR: Something went wrong :("
	fi
done
