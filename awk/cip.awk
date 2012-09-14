#!/usr/bin/awk -f
#
# Convert IP addresses between dotted decimal and binary.
# 'Binary' means 32 bits interpreted as a signed int.
# Sorry, can't handle IPv6.
#
# run like this: echo "167772172" |./cip.awk

#BEGIN {
#        FS=","
#}

function ltrim(s) { sub(/^[ \t]+/, "", s); return s }
function rtrim(s) { sub(/[ \t]+$/, "", s); return s }
function trim(s)  { return rtrim(ltrim(s)); }
function cip(s) {
        sign=substr(s,0,1);
        if (sign == "-") {
                s = substr(s,2)
                s = strtonum(0xffffffff)-strtonum(s)+1;
        }
        hex = sprintf("%08X",s);
        oct1=substr(hex,0,2);
        oct1=strtonum(sprintf("0x%s",oct1));
        oct2=substr(hex,3,2);
        oct2=strtonum(sprintf("0x%s",oct2));
        oct3=substr(hex,5,2);
        oct3=strtonum(sprintf("0x%s",oct3));
        oct4=substr(hex,7,2);
        oct4=strtonum(sprintf("0x%s",oct4));
        s=sprintf("%d.%d.%d.%d",oct1,oct2,oct3,oct4);
        return s
}

$1 {
	print cip(trim($1))
}
