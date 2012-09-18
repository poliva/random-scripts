#!/bin/sh
radare -d $@ <<_EOF_
!cont entrypoint
s 0x08048000
!cont close
!maps
f dump_start @ \`!maps~0x080[0]#1\`
f dump_end @ \`!maps~0x080[2]#0\`
!printf Dump size:
? dump_end-dump_start
f~dump
b dump_end-dump_start
wt dumped
q
y
_EOF_
