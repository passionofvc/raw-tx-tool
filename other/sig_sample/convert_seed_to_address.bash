#http://bip32.org/
#convert seed to hd address
#bip49

APP_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#bx settings
export BX_CONFIG=${APP_HOME}/bx.cfg

coin_type='145' #BCH
#coin_type='245' #SLP

######## xprv #########
#The binary data to encode as Base16.
#This can be text or any other data
#1 Entropy
entropy=$( echo "fuck poor entropy" | bx base16-encode )

#2 create new mnemonic[12/24] words list from 32 bytes entropy
mnemonic=$( echo "${entropy}" | bx base16-encode | bx sha256 | cut -c 1-64 | bx mnemonic-new )

#3) make master seed from mnemonic with password
master_seed=$( echo ${mnemonic} | bx mnemonic-to-seed | bx hd-new -v  76066276)     #mainnet
#master_seed=$( echo ${mnemonic} | bx mnemonic-to-seed | bx hd-new -v 70615956 )     #testnet

master_seed_xpub=$( bx hd-to-public ${master_seed} )
echo 'master seed[xprv]:      '"${master_seed}"
echo 'master seed[xpub]:      '"${master_seed_xpub}"

#1) Version:
echo -n 'version:          ' & echo  ${master_seed} | bx base58-decode | cut -c 1-8
#0488ade4 (where 0x0488ade4 = 76066276 base10) mainnet
#04358394 (where 0x04358394 = 70615956 base10) testnet
#2) Depth:
echo -n 'depth:            ' & echo ${master_seed} | bx base58-decode | cut -c 9-10
#00

#3) Parent Fingerprint:
echo -n 'finger print:     ' & echo ${master_seed} | bx base58-decode | cut -c 11-18
#00000000

#4) Child Index:
echo -n 'child index:      ' & echo ${master_seed} | bx base58-decode | cut -c 19-26
#00000000

#5) Chain Code:
echo -n 'chain code:       ' & echo ${master_seed} | bx base58-decode | cut -c 27-90

#ac90e67c6fde5a78af593a92b2f7da18aafb15191e2de6c84adb5be6047898ce

#6) Private secp256k1 Elliptic Curve Key:
echo -n 'private key:      ' & echo ${master_seed}  |  bx base58-decode | cut -c 93-156

#45d3191f06bdaab42011850612c07b3d761953d1bd345d3b8e3a5fe14d5297c9

#echo -n 'private key:      ' & echo ${master_seed}  | bx hd-to-ec
#45d3191f06bdaab42011850612c07b3d761953d1bd345d3b8e3a5fe14d5297c9

echo -n 'address    :      ' & echo ${master_seed}  | bx hd-to-ec | bx ec-to-public | bx ec-to-address -v 0

#HMAC-SHA512 mathematical magic for calculating up to 2 to 4 billion public keys and associated public addresses for extended public keys
# m/44'/145'/0'
echo -n "m/44'/"${coin_type}"'/0'#[xprv]:  " & echo ${master_seed}  | bx hd-private -d -i 44 | bx hd-private -d -i ${coin_type} | bx hd-private -d -i 0 
echo -n "m/44'/"${coin_type}"'/0'#[xpub]:  " & echo ${master_seed}  | bx hd-private -d -i 44 | bx hd-private -d -i ${coin_type} | bx hd-private -d -i 0 | bx hd-to-public 
echo -n "m/44'/"${coin_type}"'/0'#[addr]:  " & echo ${master_seed}  | bx hd-private -d -i 44 | bx hd-private -d -i ${coin_type} | bx hd-private -d -i 0 | bx hd-to-public | bx hd-to-ec | bx ec-to-address -v 0


#####################
#publicAddress pairs. It generates the addresses as the nth external change address of 
# the first account from that mnemonic this derivation path: m/44’/145’/0’/0/n
#your ginco wallet address create by m/44'/145'/0'/0/0 path
######## xpub #########
for i in {0..5}
do
    xprv=$( echo ${master_seed} | bx hd-private -d -i 44 | bx hd-private -d -i "${coin_type}" | bx hd-private -d -i 0 | bx hd-private -i 0 | bx hd-private -i ${i} | bx hd-to-ec )
    xpub=$( echo ${master_seed} | bx hd-private -d -i 44 | bx hd-private -d -i "${coin_type}" | bx hd-private -d -i 0 | bx hd-private -i 0 | bx hd-private -i ${i} | bx hd-to-public )
    #echo ${xpub}

#1 version
#echo ${xpub} | bx base58-decode | cut -c 1-8
#0488b21e (where 0x0488ade4 = 76066276 base10)

#2 depth
#echo ${xpub} | bx base58-decode | cut -c 9-10

#3 Parent Fingerprint
#echo ${xpub} | bx base58-decode | cut -c 11-18

#4 child index
#echo ${xpub} | bx base58-decode | cut -c 19-26

#5 chain code
#echo ${xpub} | bx base58-decode | cut -c 27-90

#6 Public secp256k1 Elliptic Curve Key
#echo ${xpub} | bx base58-decode | cut -c 91-156
#echo ${xpub} | bx hd-to-ec

#M/44'/0'/1'/2/3 address
#0,111
    addr=$( echo -n ${xpub} | bx hd-to-ec | bx ec-to-address -v 0 )
    echo -n "m/44'/"${coin_type}"'/0'/0/${i}    : " && echo $addr ${xprv}
done

#M/44'/0'/1'/2/3 wif key
#version [01]
#wif-key 128, 239
#echo ${master_seed} | bx hd-private -d -i 44 | bx hd-private -d -i 0 | bx hd-private -d -i 0 | bx hd-private -i 0 | bx hd-private -i 0 | bx hd-to-ec | sed 's/$/01/' | bx base58check-encode -v 128

