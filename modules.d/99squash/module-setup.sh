#!/bin/bash

check() {
    if ! dracut_module_included "systemd-initrd"; then
        derror "dracut-squash only supports systemd bases initramfs"
        return 1
    fi

    if ! find_binary mksquashfs >/dev/null || ! find_binary unsquashfs >/dev/null ; then
        derror "dracut-squash module requires squashfs-tools"
        return 1
    fi

    for i in CONFIG_SQUASHFS CONFIG_BLK_DEV_LOOP CONFIG_OVERLAY_FS ; do
        if ! check_kernel_config $i; then
            derror "dracut-squash module requires kernel configuration $i (y or m)"
            return 1
        fi
    done

    return 255
}

depends() {
    echo "bash systemd-initrd"
    return 0
}

installkernel() {
    hostonly="" instmods squashfs loop overlay
}

install() {
    inst_multiple kmod modprobe mount mkdir ln echo
    inst $moddir/setup-squash.sh /squash/setup-squash.sh
    inst $moddir/clear-squash.sh /squash/clear-squash.sh
    inst $moddir/init.sh /squash/init.sh

    inst "$moddir/squash-mnt-clear.service" "$systemdsystemunitdir/squash-mnt-clear.service"
    $SYSTEMCTL -q --root "$initdir" add-wants initrd-switch-root.target squash-mnt-clear.service
}
