CC_VER := 11
CC := gcc
KERNEL_VER 	:= 5.10.43.3
KERNEL_NAME	:= linux-msft-wsl-$(KERNEL_VER)
KERNEL_ARC 	:= $(KERNEL_NAME).tar.gz
KERNEL_URL 	:= https://github.com/microsoft/WSL2-Linux-Kernel/archive/refs/tags/$(KERNEL_ARC)
PWD := $(shell pwd)
SRC_DIR := $(PWD)/kernel-$(KERNEL_VER)
OUT_DIR := $(PWD)/$(CC)-$(CC_VER)
OBJ_DIR := $(OUT_DIR)/obj
WORK_DIR := /usr/src/kernel
DOCKER_OPTS := --rm \
		-v "$(SRC_DIR):$(WORK_DIR)" \
		-v "$(OBJ_DIR):/usr/src/output" \
		-w "$(WORK_DIR)" \
		-u "$(shell id -u):$(shell id -g)"
DOCKER_IMG := $(CC)-builder:$(CC_VER)
MAKE_OPTS := O=../output
MAKE := docker run $(DOCKER_OPTS) $(DOCKER_IMG) make $(MAKE_OPTS)

ifeq (Darwin, $(shell uname))
NPROC := $(shell getconf _NPROCESSORS_ONLN)
else
NPROC := $(shell nproc)
endif

BUILD_OPTS :=
ifeq (clang, $(CC))
BUILD_OPTS += CC=clang-$(CC_VER) LD=ld.lld-$(CC_VER) AR=llvm-ar-$(CC_VER) \
		NM=llvm-nm-$(CC_VER) STRIP=llvm-strip-$(CC_VER) OBJCOPY=llvm-objcopy-$(CC_VER) \
		OBJDUMP=llvm-objdump-$(CC_VER) READELF=llvm-readelf-$(CC_VER) HOSTCC=clang-$(CC_VER) \
		HOSTCXX=clang++-$(CC_VER) HOSTAR=llvm-ar-$(CC_VER) HOSTLD=ld.lld-$(CC_VER)
endif

VMLINUX := $(OUT_DIR)/$(KERNEL_NAME).vmlinux
BZIMAGE := $(OUT_DIR)/$(KERNEL_NAME).bzImage

.PHONY: all gcc-9 gcc-10 gcc-11 clang-11 clang-12 oldconfig menuconfig kernel modules modules_install clean

all: oldconfig kernel

gcc-9:
	@make CC=gcc CC_VER=9

gcc-10:
	@make CC=gcc CC_VER=10

gcc-11:
	@make CC=gcc CC_VER=11

clang-11:
	@make CC=clang CC_VER=11

clang-12:
	@make CC=clang CC_VER=12

$(KERNEL_ARC):
	@set -eu; \
	echo "Download $(KERNEL_ARC)"; \
	curl -fsSL -o "$(KERNEL_ARC)" "$(KERNEL_URL)"; \
	\
	if [ -d "$(SRC_DIR)" ]; then \
		echo "Cleanup kernel source"; \
		rm -rf "$(SRC_DIR)"; \
	fi

$(SRC_DIR): $(KERNEL_ARC)
	@set -eu; \
	echo "Extract kernel source"; \
	mkdir -p $(SRC_DIR); \
	tar zxf "$(KERNEL_ARC)" -C "$(SRC_DIR)" --strip-components=1; \

build-gcc-builder:
	@docker build . --build-arg GCC_VER=$(CC_VER) -t gcc-builder:$(CC_VER)

build-clang-builder:
	@docker build . -f Dockerfile.clang --build-arg CLANG_VER=$(CC_VER) -t clang-builder:$(CC_VER)

oldconfig: $(SRC_DIR) build-$(CC)-builder
	@set -eu; \
	echo "[$(CC)-$(CC_VER)] make oldconfig"; \
	mkdir -p $(OBJ_DIR); \
	cp $(SRC_DIR)/Microsoft/config-wsl $(OBJ_DIR)/.config; \
	$(MAKE) oldconfig

menuconfig: $(SRC_DIR) build-$(CC)-builder 
	@set -eu; \
	echo "[$(CC)-$(CC_VER)] make menuconfig"; \
	mkdir -p $(OBJ_DIR); \
	cp $(SRC_DIR)/Microsoft/config-wsl $(OBJ_DIR)/.config; \
	docker run -it $(DOCKER_OPTS) $(DOCKER_IMG) make $(MAKE_OPTS) menuconfig

$(VMLINUX):
	@set -eu; \
	echo "[$(CC)-$(CC_VER)] make -j $(NPROC) $(BUILD_OPTS) vmlinux"; \
	$(MAKE) -j $(NPROC) $(BUILD_OPTS) vmlinux; \
	cp -p "$(OBJ_DIR)/vmlinux" "$(VMLINUX)"

$(BZIMAGE):
	@set -eu; \
	echo "[$(CC)-$(CC_VER)] make -j $(NPROC) $(BUILD_OPTS) bzImage"; \
	$(MAKE) -j $(NPROC) $(BUILD_OPTS) bzImage; \
	cp -p "$(OBJ_DIR)/arch/x86/boot/bzImage" "$(BZIMAGE)"

kernel: $(VMLINUX) $(BZIMAGE)

modules:
	@set -eu; \
	echo "[$(CC)-$(CC_VER)] make -j $(NPROC) $(BUILD_OPTS) modules"; \
	$(MAKE) -j $(NPROC) $(BUILD_OPTS) modules

modules_install:
	@make -C $(SRC_DIR) O=$(OBJ_DIR) modules_install

clean:
	@rm -rf $(OUT_DIR)
