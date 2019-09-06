#!/bin/bash
********************************************************
#模板用户
copyuser=chenjibiao

********************************************************
read -p "输入用户名：" client_name
read -s -p "输入密码：" client_passwd

#创建客户端证书
expect<<EOF
spawn /etc/openvpn/client/easy-rsa-client/3/easyrsa gen-req $client_name
expect {
"Common Name" { send "\n" }
"Enter PEM pass phrase" { send "${client_passwd}\n" }
}
#expect "]#" { send "exit\n" }
expect eof
EOF


#签发客户端证书
cd /etc/openvpn/easy-rsa/3
./easyrsa import-req /etc/openvpn/client/easy-rsa-client/3.0.6/pki/reqs/${client_name}.req $client_name 

expect<<EOF
spawn ./easyrsa sign client $client_name
expect {
"Confirm request details" { send "yes\n" }
}
#expect "]#" { send "exit\n" }
expect eof
EOF

mkdir /etc/openvpn/client/$client_name
cd /etc/openvpn/client/$client_name
cp /etc/openvpn/easy-rsa/3.0.6/pki/ca.crt .
cp /etc/openvpn/easy-rsa/3.0.6/pki/issued/${client_name}.crt .
cp /etc/openvpn/client/easy-rsa-client/3.0.6/pki/private/${client_name}.key .
cd /etc/openvpn/client
cp ${copyuser}/client.ovpn ${client_name}/
tree .

cd /etc/openvpn/client/${client_name}
sed -i "/^cert/s#.*#cert ${client_name}.crt#" client.ovpn
sed -i "/^key/s#.*#key ${client_name}.key#" client.ovpn

cd /etc/openvpn/client
tar cf ${client_name}.tar ${client_name}/*
rm -rf ${client_name}