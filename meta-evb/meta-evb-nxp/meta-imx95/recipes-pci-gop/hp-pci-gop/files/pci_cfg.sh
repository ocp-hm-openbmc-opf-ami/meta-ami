cd /sys/kernel/config/pci_ep/
mkdir functions/pci_epf_test/func3
echo 0x1131 > functions/pci_epf_test/func3/vendorid
echo 0x1234 > functions/pci_epf_test/func3/deviceid
cat functions/pci_epf_test/func3/deviceid
cat functions/pci_epf_test/func3/vendorid
echo 16 > functions/pci_epf_test/func3/msi_interrupts
echo 8 > functions/pci_epf_test/func3/msix_interrupts
ln -s functions/pci_epf_test/func3/ controllers/4c380000.pcie-ep/

#echo 1 > /sys/kernel/config/pci_ep/controllers/4c380000.pcie-ep/start
