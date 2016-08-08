#
# Copyright (C) 2016 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#---------------------------------------
# Compile Raspberrypi Boot Image
MKDOSFS := $(HOST_OUT_EXECUTABLES)/mkdosfs$(HOST_EXECUTABLE_SUFFIX)
MKCOPY := $(HOST_OUT_EXECUTABLES)/mcopy$(HOST_EXECUTABLE_SUFFIX)

INTERNAL_RPI_BOOTIMAGE_DEPS := $(MKDOSFS) $(MCOPY)
INTERNAL_RPI_BOOTIMAGE_BINARY_PATHS := $(sort $(dir $(INTERNAL_RPI_BOOTIMAGE_DEPS)))

INTERNAL_RPI_BOOTIMAGE_FILES := $(filter $(TARGET_BOOT_OUT)/%, \
    $(ALL_PREBUILT) \
    $(ALL_DEFAULT_INSTALLED_MODULES) \
    )

FULL_RPI_BOOTIMAGE_DEPS := \
    kernel \
    $(INTERNAL_RPI_BOOTIMAGE_DEPS) \
    $(INTERNAL_RPI_BOOTIMAGE_FILES)

INTERNAL_RPI_BOOTIMAGE_ARGS := -v

BOARD_BOOTIMAGE_PARTITION_SIZE := $(strip $(BOARD_BOOTIMAGE_PARTITION_SIZE))
ifdef BOARD_BOOTIMAGE_PARTITION_SIZE
  INTERNAL_RPI_BOOTIMAGE_ARGS += --size=$(BOARD_BOOTIMAGE_PARTITION_SIZE)
endif

INSTALLED_RPI_BOOTIMAGE_TARGET := $(PRODUCT_OUT)/rpi-boot.img

# $(1): output file
define build-rpi-bootimage-target
    @echo "Target boot fs image: $(1)"
    @mkdir -p $(dir $(1))
    $(hide) PATH=$(foreach p,$(INTERNAL_RPI_BOOTIMAGE_BINARY_PATHS),$(p):)$$PATH
      ./system/tools/pt-box/mkvfatfs \
      $(INTERNAL_RPI_BOOTIMAGE_ARGS) $(TARGET_BOOT_OUT) $(1)
endef

$(INSTALLED_RPI_BOOTIMAGE_TARGET): $(FULL_RPI_BOOTIMAGE_DEPS)
	$(call pretty, "Install boot fs image: $@")
	$(call build-rpi-bootimage-target, $@)

#---------------------------------------
# Add kernel and booti.img to yudatuncore.
.PHONY: partition
partition: $(INSTALLED_PARTITION_TABLE_TARGET)

.PHONY: rpi-bootimage
rpi-bootimage: $(INSTALLED_RPI_BOOTIMAGE_TARGET)

droidcore: \
   partition \
   kernel \
   rpi-bootimage
