#!/usr/bin/env bash
# Noah Bliss

#If using xbootldr these paths may not be the sa-me as /boot/efi.
BOOTX64="/boot/efi/EFI/BOOT/BOOTX64.efi"
#Path to systemd-boot bootloader efi image.
SYSTEMD="/boot/efi/EFI/systemd/systemd-boot.efi"

# Install the kernel upgrade hook for generation and signing of the efi.
cp -r kernel /etc/

# Install the initramfs script and update hook. 
cp -r initramfs-tools /etc/
INITRAMFSSCRIPTFILE='/etc/initramfs-tools/scripts/local-top/mortar'
if ! [ "$1" == "nosource" ]; then source /etc/mortar/mortar.env; fi
sed -i -e "/^CRYPTDEV=.*/{s##CRYPTDEV=\"$CRYPTDEV\"#;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^CRYPTNAME=.*/{s//CRYPTNAME=$CRYPTNAME/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^SLOTUUID=.*/{s//SLOTUUID=$SLOTUUID/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^SLOT=.*/{s//SLOT=$SLOT/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^HEADERSHA256=.*/{s//HEADERSHA256=$HEADERSHA256/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^HEADERFILE=.*/{s##HEADERFILE=\"$HEADERFILE\"#;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"
sed -i -e "/^TOKENID=.*/{s//TOKENID=$TOKENID/;:a" -e '$!N;$!b' -e '}' "$INITRAMFSSCRIPTFILE"

sed -i -e "/^BOOTX64=.*/{s##BOOTX64=\"$BOOTX64\"#;:a" -e '$!N;$!b' -e '}' "/etc/kernel/zzz-mortar-efigensign"
sed -i -e "/^SYSTEMD=.*/{s##SYSTEMD=\"$SYSTEMD\"#;:a" -e '$!N;$!b' -e '}' "/etc/kernel/zzz-mortar-efigensign"

update-initramfs -u

echo "Initramfs updated. You need to run mortar-compilesigninstall [kernelpath] [initramfspath]"
echo "Consult the README for more detail."

sbsign --output $SYSTEMD --key $SECUREBOOT_DB_KEY --cert $SECUREBOOT_DB_CRT $SYSTEMD
cp $SYSTEMD $BOOTX64

echo "Systemd-boot signed for secureboot."