echo "This script will create a unified kernel image for Pop_OS! Recovery and install an UEFI entry."
echo "This will delete any current recovery files on the EFI partition."
read -p "Proceed? (y/n)" RUN_SCRIPT	
case "$RUN_SCRIPT" in
	[nN]*) echo "Exiting..."; exit 0 ;;
esac


#Save information about recovery partition
source /etc/mortar/mortar.env;
blkid /dev/disk/by-partlabel/recovery --output export > /etc/mortar/pop-recovery.env;
if ! [ -f /etc/mortar/pop-paths.env ]; then 
echo "Problem with pop-paths.env";
exit 1;
else
source /etc/mortar/pop-paths.env;
fi

#Remove Existing Pop_OS Recovery from /boot
if [ -d "/boot/efi/EFI/Recovery-"$UUID ]; then 
rm -r /boot/efi/EFI/Recovery-$UUID > /dev/null; 
else echo "No Pop_OS! Recovery in EFI folder.";
fi

if [ -f /boot/efi/loader/entries/Recovery-$UUID ]; then
rm -r /boot/efi/loader/entries/Recovery-$UUID > /dev/null;
else echo "No Pop_OS! entry in systemd."
fi

objcopy \
    --add-section .osrel=/etc/os-release --change-section-vma .osrel=0x20000 \
    --add-section .cmdline="$RECOVERY_CMDLINE" --change-section-vma .cmdline=0x30000 \
    --add-section .linux="$RECOVERY_PATH/vmlinuz.efi" --change-section-vma .linux=0x40000 \
    --add-section .initrd="$RECOVERY_PATH/initrd.gz" --change-section-vma .initrd=0x3000000 \
    "$EFISTUBFILE" "$RECOVERY_INSTALL_PATH$RECOVERY_IMAGE_NAME" || exit 1;

sbsign --output $RECOVERY_EFI_PATH$RECOVERY_IMAGE_NAME --key $SECUREBOOT_DB_KEY --cert $SECUREBOOT_DB_CRT $RECOVERY_INSTALL_PATH$RECOVERY_IMAGE_NAME || exit 1;

echo "Recovery image created and signed."
echo ""
echo "This script expects recovery to be booted with a UEFI Menu Entry."
read -p "Install UEFI menu entry? (y/n)" RUN_SCRIPT	
case "$RUN_SCRIPT" in
	[yY]*) efibootmgr -c -L "Recovery" -d $RECOVERY_IMAGE_DEVICE -p $RECOVERY_PARTITION_NUM -l $RECOVERY_EFI_PATH$RECOVERY_IMAGE_NAME || exit 1; exit 0 ;;
esac