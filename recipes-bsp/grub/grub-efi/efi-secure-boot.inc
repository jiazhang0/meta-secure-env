# Create a boot entry for Automatic Certificate Provision.
# This is especially useful for certain hardware, e.g,
# Intel NUC5i3MYHE, doedn't support to display a customized
# BIOS boot option used to launch LockDown.efi.
menuentry "Automatic Certificate Provision" {
    chainloader "${prefix}/LockDown.efi"
}
