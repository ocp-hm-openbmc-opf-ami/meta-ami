
kernel_do_deploy:append() {
	if [ -e ${B}/linux.bin ]
	then
		echo "Copying linux.bin file to deploy dir."
		install -m 0644 ${B}/linux.bin $deployDir/linux.bin
	fi
}

