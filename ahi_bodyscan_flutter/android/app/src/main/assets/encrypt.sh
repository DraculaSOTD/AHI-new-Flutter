#!/bin/bash
#
# Encrypt all cereal files and verifiy against the original
#
set -e

key=4a93bd83a4f80590338f66248e9bdb60
iv=8b8c09de7fd6e8d96e4f3ed5fe83324e

mkdir -p /tmp/Encoded

function encryptFiles() {

    # Cereal files
    for f in Encoded/*.cereal; do
        echo -n "Encrypting $f"
        openssl enc -aes-128-cbc -K $key -iv $iv -in $f -out $f.bin

        echo -ne ": OK "

        openssl enc -d -aes-128-cbc -K $key -iv $iv -in $f.bin -out /tmp/$f

        echo -ne "verifiying: "
        cmp --silent $f /tmp/$f && echo -e "OK" || (echo "Failed Verification!" && exit -1)
        rm /tmp/$f
    done

    # ML files
    for f in Encoded/*.tflite; do
        echo -n "Encrypting $f"
        openssl enc -aes-128-cbc -K $key -iv $iv -in $f -out $f.bin

        echo -ne ": OK "

        openssl enc -d -aes-128-cbc -K $key -iv $iv -in $f.bin -out /tmp/$f

        echo -ne "verifiying: "
        cmp --silent $f /tmp/$f && echo -e "OK" || (echo "Failed Verification!" && exit -1)
        rm /tmp/$f
    done

}

encryptFiles

# Move encrypted files to folder to make it easier to gather for upload
mkdir -p Encrypted
cd Encoded/
for f in *.bin; do
    mv $f ../Encrypted/
done
