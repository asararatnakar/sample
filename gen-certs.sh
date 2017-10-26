#!/bin/bash
SCRIPTDIR="."
export HOME=$SCRIPTDIR
PKI="$SCRIPTDIR/pki"
#. $SCRIPTDIR/fabric-ca_utils
CaDir='/tmp/CAs'
if test ! -d ${CaDir}; then
	mkdir -p $CaDir            
fi
RC=0

curr_year=$(date +"%g")
ten=$((curr_year+10))
five=$((curr_year+5))
two=$((curr_year+2))

now=$(date +"%g%m%d%H%M%SZ")
ten_year=$(date +"$ten%m%d%H%M%SZ")
five_year=$(date +"$five%m%d%H%M%SZ")
two_year=$(date +"$two%m%d%H%M%SZ")

KeyType="$1"
case ${KeyType:=ec} in
    ec) CaKeyLength=256
        CaDigest="sha256"
        EeKeyLength=256
        EeDigest="sha256"
   ;;
   rsa) CaKeyLength=4096
        CaDigest="sha512"
        EeKeyLength=2048
        EeDigest="sha256"
   ;;
   dsa) CaKeyLength=512
        CaDigest="sha256"
        EeKeyLength=512
        EeDigest="sha256"
   ;;
     *) ErrorExit "Unsupported keytype $KeyType"
   ;;
esac

# Shared variables
CaKeyUsage='keyCertSign,cRLSign,digitalSignature'
EeKeyUsage='digitalSignature'
CaExpiry="$ten_year"
EeExpiry="$two_year"

rm -rf $CaDir/$RootCa ./orderer
mkdir -p ./orderer
function createCryptoDirs(){
  mkdir -p ./crypto-config/ordererOrganizations/example.com
  mkdir -p ./crypto-config/ordererOrganizations/example.com/ca
  mkdir -p ./crypto-config/ordererOrganizations/example.com/msp/admincerts
  mkdir -p ./crypto-config/ordererOrganizations/example.com/msp/cacerts
  mkdir -p ./crypto-config/ordererOrganizations/example.com/msp/tlscacerts

  mkdir -p ./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/admincerts
  mkdir -p ./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/cacerts
  mkdir -p ./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/keystore
  mkdir -p ./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/signcerts
  mkdir -p ./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts

  mkdir -p ./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls
  mkdir -p ./crypto-config/ordererOrganizations/example.com/tlsca

  mkdir -p ./crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/admincerts
  mkdir -p ./crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/cacerts
  mkdir -p ./crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/keystore
  mkdir -p ./crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/signcerts
  mkdir -p ./crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/tlscacerts

  mkdir -p ./crypto-config/ordererOrganizations/example.com/users/Admin@example.com/tls

  for ((i=1;i<3;i++)); do
    mkdir -p ./crypto-config/peerOrganizations/org$i.example.com
    mkdir -p ./crypto-config/peerOrganizations/org$i.example.com/ca
    mkdir -p ./crypto-config/peerOrganizations/org$i.example.com/msp/admincerts
    mkdir -p ./crypto-config/peerOrganizations/org$i.example.com/msp/cacerts
    mkdir -p ./crypto-config/peerOrganizations/org$i.example.com/msp/tlscacerts

    mkdir -p ./crypto-config/peerOrganizations/org$i.example.com/peers/peer0.org$i.example.com/msp/admincerts
    mkdir -p ./crypto-config/peerOrganizations/org$i.example.com/peers/peer0.org$i.example.com/msp/cacerts
    mkdir -p ./crypto-config/peerOrganizations/org$i.example.com/peers/peer0.org$i.example.com/msp/keystore
    mkdir -p ./crypto-config/peerOrganizations/org$i.example.com/peers/peer0.org$i.example.com/msp/signcerts
    mkdir -p ./crypto-config/peerOrganizations/org$i.example.com/peers/peer0.org$i.example.com/msp/tlscacerts

    mkdir -p ./crypto-config/peerOrganizations/org$i.example.com/peers/peer0.org$i.example.com/tls
    mkdir -p ./crypto-config/peerOrganizations/org$i.example.com/tlsca

    mkdir -p ./crypto-config/peerOrganizations/org$i.example.com/users/Admin@org$i.example.com/msp/admincerts
    mkdir -p ./crypto-config/peerOrganizations/org$i.example.com/users/Admin@org$i.example.com/msp/cacerts
    mkdir -p ./crypto-config/peerOrganizations/org$i.example.com/users/Admin@org$i.example.com/msp/keystore
    mkdir -p ./crypto-config/peerOrganizations/org$i.example.com/users/Admin@org$i.example.com/msp/signcerts
    mkdir -p ./crypto-config/peerOrganizations/org$i.example.com/users/Admin@org$i.example.com/msp/tlscacerts

    mkdir -p ./crypto-config/peerOrganizations/org$i.example.com/users/Admin@org$i.example.com/tls
  done

}
function copyOrdererCerts(){
  cp ./orderer/example.com* ./crypto-config/ordererOrganizations/example.com/ca/
  cp ./orderer/Admincert.pem ./crypto-config/ordererOrganizations/example.com/msp/admincerts/
  cp ./orderer/example.com-cert.pem ./crypto-config/ordererOrganizations/example.com/msp/cacerts/

  cp ./orderer/Admincert.pem ./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/admincerts/
  cp ./orderer/example.com-cert.pem ./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/cacerts/
  cp ./orderer/ordererkey.pem ./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/keystore/
  cp ./orderer/orderercert.pem ./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp/signcerts/

  cp ./orderer/Admincert.pem ./crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/admincerts
  cp ./orderer/example.com-cert.pem ./crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/cacerts
  cp ./orderer/Adminkey.pem ./crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/keystore
  cp ./orderer/Admincert.pem ./crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/signcerts

}
function copyOrgCerts(){
  for ((i=1;i<3;i++)); do
  cp org$i.example.com/org$i.example.com* ./crypto-config/peerOrganizations/org$i.example.com/ca/
  cp org$i.example.com/Admincert.pem ./crypto-config/peerOrganizations/org$i.example.com/msp/admincerts/
  cp org$i.example.com/org$i.example.com-cert.pem ./crypto-config/peerOrganizations/org$i.example.com/msp/cacerts/

  cp org$i.example.com/Admincert.pem ./crypto-config/peerOrganizations/org$i.example.com/peers/peer0.org$i.example.com/msp/admincerts/
  cp org$i.example.com/org$i.example.com-cert.pem ./crypto-config/peerOrganizations/org$i.example.com/peers/peer0.org$i.example.com/msp/cacerts/
  cp org$i.example.com/peer0key.pem ./crypto-config/peerOrganizations/org$i.example.com/peers/peer0.org$i.example.com/msp/keystore/
  cp org$i.example.com/peer0cert.pem ./crypto-config/peerOrganizations/org$i.example.com/peers/peer0.org$i.example.com/msp/signcerts/

  cp org$i.example.com/Admincert.pem ./crypto-config/peerOrganizations/org$i.example.com/users/Admin@org$i.example.com/msp/admincerts
  cp org$i.example.com/org$i.example.com-cert.pem ./crypto-config/peerOrganizations/org$i.example.com/users/Admin@org$i.example.com/msp/cacerts
  cp org$i.example.com/Adminkey.pem ./crypto-config/peerOrganizations/org$i.example.com/users/Admin@org$i.example.com/msp/keystore
  cp org$i.example.com/Admincert.pem ./crypto-config/peerOrganizations/org$i.example.com/users/Admin@org$i.example.com/msp/signcerts
done
}
createCryptoDirs
# RootCa variables
RootCa="example.com"
RootSubject="/C=US/ST=California/L=San Francisco/O=$RootCa/CN=ca.$RootCa"
ClientEE1="Admin"
ClientSubject1="/C=US/ST=California/L=San Francisco/CN=$ClientEE1@$RootCa"
ClientEE2="orderer"
ClientSubject2="/C=US/ST=California/L=San Francisco/CN=$ClientEE2.$RootCa"
$PKI -f newca -a $RootCa -n "$RootSubject" -t $KeyType -l $CaKeyLength \
     -d $CaDigest -e $CaExpiry -K "$CaKeyUsage" -p $RootCa <<EOF
y
y
EOF

# Client1
$PKI -f newcert -a $RootCa -n "$ClientSubject1" -t $KeyType -l $EeKeyLength \
     -d $EeDigest -e $EeExpiry -K "$EeKeyUsage" -p $ClientEE1 <<EOF
y
y
EOF

# Client2
$PKI -f newcert -a $RootCa -n "$ClientSubject2" -t $KeyType -l $EeKeyLength \
     -d $EeDigest -e $EeExpiry -K "$EeKeyUsage" -p $ClientEE2 <<EOF
y
y
EOF

rm -rf *.der *req*.pem
mv *.pem orderer
copyOrdererCerts

for ((i=1;i<3;i++)); do
# RootCa variables
RootCa="org$i.example.com"
RootSubject="/C=US/ST=California/L=San Francisco/O=$RootCa/CN=ca.$RootCa"

# ClientEE variables
ClientEE1="Admin"
ClientSubject1="/C=US/ST=California/L=San Francisco/CN=$ClientEE1@$RootCa"

# ClientEE2 variables
ClientEE2="peer0"
ClientSubject2="/C=US/ST=California/L=San Francisco/CN=$ClientEE2.$RootCa"

#cd $HOME

rm -rf $CaDir/$RootCa
# TLS root cert
$PKI -f newca -a $RootCa -n "$RootSubject" -t $KeyType -l $CaKeyLength \
     -d $CaDigest -e $CaExpiry -K "$CaKeyUsage" -p $RootCa <<EOF
y
y
EOF

# Client1
$PKI -f newcert -a $RootCa -n "$ClientSubject1" -t $KeyType -l $EeKeyLength \
     -d $EeDigest -e $EeExpiry -K "$EeKeyUsage" -p $ClientEE1 <<EOF
y
y
EOF

# Client2
$PKI -f newcert -a $RootCa -n "$ClientSubject2" -t $KeyType -l $EeKeyLength \
     -d $EeDigest -e $EeExpiry -K "$EeKeyUsage" -p $ClientEE2 <<EOF
y
y
EOF

mkdir -p $RootCa
rm -rf *.der *req*.pem
mv *.pem $RootCa/
done

#organize the certs
copyOrgCerts

#Clean the existing folders
rm -rf org* orderer
