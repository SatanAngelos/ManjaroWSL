OUT_ZIP=Manjaro.zip
LNCR_EXE=Manjaro.exe

DLR=curl
DLR_FLAGS=-L
LNCR_ZIP_URL=https://github.com/yuk7/wsldl/releases/download/21020500/icons.zip
LNCR_ZIP_EXE=Manjaro.exe

all: $(OUT_ZIP)

zip: $(OUT_ZIP)
$(OUT_ZIP): ziproot
	@echo -e '\e[1;31mBuilding $(OUT_ZIP)\e[m'
	cd ziproot; zip ../$(OUT_ZIP) *

ziproot: Launcher.exe rootfs.tar.gz
	@echo -e '\e[1;31mBuilding ziproot...\e[m'
	mkdir ziproot
	cp Launcher.exe ziproot/${LNCR_EXE}
	cp rootfs.tar.gz ziproot/

exe: Launcher.exe
Launcher.exe: icons.zip
	@echo -e '\e[1;31mExtracting Launcher.exe...\e[m'
	unzip icons.zip $(LNCR_ZIP_EXE)
	mv $(LNCR_ZIP_EXE) Launcher.exe

icons.zip:
	@echo -e '\e[1;31mDownloading icons.zip...\e[m'
	$(DLR) $(DLR_FLAGS) $(LNCR_ZIP_URL) -o icons.zip

rootfs.tar.gz: rootfs
	@echo -e '\e[1;31mBuilding rootfs.tar.gz...\e[m'
	cd rootfs; sudo tar -zcpf ../rootfs.tar.gz `sudo ls`
	sudo chown `id -un` rootfs.tar.gz

rootfs: base.tar
	@echo -e '\e[1;31mBuilding rootfs...\e[m'
	mkdir rootfs
	sudo tar -xpf base.tar -C rootfs
	@echo "# This file was automatically generated by WSL. To stop automatic generation of this file, remove this line." | sudo tee rootfs/etc/resolv.conf > /dev/null
	sudo chmod +x rootfs

base.tar:
	@echo -e '\e[1;31mExporting base.tar using docker...\e[m'
	docker run --name manjarowsl manjarolinux/base:latest /bin/bash -c "pacman --noconfirm -Sy awk; pacman-key --init; pacman-key --populate archlinux; sed -ibak -e 's/#Color/Color/g' -e 's/CheckSpace/#CheckSpace/g' /etc/pacman.conf; pacman --noconfirm -Syyu; pacman-mirrors --api --set-branch testing; pacman-mirrors --fasttrack 5; pacman --noconfirm -Syyuu; pacman --noconfirm --needed -S aria2 base-devel ccache git git-lfs grep inetutils iputils keychain linux-tools lsop lzip nano openssh procps socat sudo tree vivid wget; setcap 'cap_net_admin,cap_net_raw+ep' /usr/sbin/ping; sed -i 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/g' /etc/sudoers; yes | LC_ALL=en_US.UTF-8 pacman -Scc"
	docker export --output=base.tar manjarowsl
	docker rm -f manjarowsl

clean:
	@echo -e '\e[1;31mCleaning files...\e[m'
	-rm ${OUT_ZIP}
	-rm -r ziproot
	-rm Launcher.exe
	-rm icons.zip
	-rm rootfs.tar.gz
	-sudo rm -r rootfs
	-rm base.tar
	-docker rmi manjarolinux/base:latest -f
