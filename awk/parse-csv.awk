#!/usr/bin/awk -f
{
 n = parse_csv($0, data)
 for (i = 0; ++i <= n;) {
    gsub(/,/, "\\,", data[i]) #poso antibarra daban les comes
    gsub(/;/,"", data[i]) #elimino punts i comes
    gsub(/\t/," ", data[i]) #elimino tabs
#   printf "%s;%s", data[i], (i < n ? OFS : RS)
    printf "%s", data[i]
    if (i<n) printf ";"
    if (i==n) printf "\n"
 }
}

function parse_csv(str, array,   field, i) { 
  split( "", array )
  str = str ","
  while ( match(str, /[ \t]*("[^"]*(""[^"]*)*"|[^,]*)[ \t]*,/) ) { 
    field = substr(str, 1, RLENGTH)
    gsub(/^[ \t]*"?|"?[ \t]*,$/, "", field)
    gsub(/""/, "\"", field)
    array[++i] = field
    str = substr(str, RLENGTH + 1)
  }
  return i
}

