# Set default architecture to all if ARCH is not provided
ARCH ?= amd64
CACHE_REPO ?= penthertz/rfswiftdev
REGISTRY_IMAGE ?= penthertz/rfswiftdev
STORAGE_TYPE ?= local  # Set to "registry" to use registry-based caching

# Drivers
UHD_BASE ?= uhd
RTLSDR_BASE ?= rtlsdr

# Determine the platform based on the ARCH value
ifeq ($(ARCH),amd64)
    PLATFORM=linux/amd64
else ifeq ($(ARCH),arm64)
    PLATFORM=linux/arm64/v8
else ifeq ($(ARCH),riscv64)
    PLATFORM=linux/riscv64
else
    $(error Unsupported architecture: $(ARCH). Supported values are amd64, arm64, riscv64)
endif

# Function to build and push using registry cache
define build_and_push_registry
    @docker buildx build --platform $(PLATFORM) \
        --cache-from=type=registry,ref=$(CACHE_REPO):cache_$(1)_$(ARCH) \
        --cache-to=type=registry,ref=$(CACHE_REPO):cache_$(1)_$(ARCH),mode=max \
        $(2) \
        --push \
        -t $(REGISTRY_IMAGE):$(1)_$(ARCH) \
        -f $(3) \
        ..;
endef

# Function to build and push using local cache
define build_and_push_local
    @docker buildx build --platform $(PLATFORM) \
        $(2) \
        --load \
        -t $(REGISTRY_IMAGE):$(1)_$(ARCH) \
        -f $(3) \
        ..;
endef

# Choose the build function based on STORAGE_TYPE
ifeq ($(STORAGE_TYPE),registry)
    build_and_push = $(build_and_push_registry)
else
    build_and_push = $(build_and_push_local)
endif

#
# Specific build targets using the chosen function
common:
	$(call build_and_push,corebuild,,$(CURDIR)/corebuild.docker)

sdrsadevices:
	$(call build_and_push,sdrsa_devices,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild_$(ARCH) --build-arg UHD_BASE=$(UHD_BASE) --build-arg RTLSDR_BASE=$(RTLSDR_BASE),$(CURDIR)/SDR/sdrsa_devices.docker)

sdrsadevicesantsdr:
	$(call build_and_push,sdrsa_devices_antsdr,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild_$(ARCH) --build-arg UHD_BASE=antsdr_uhd --build-arg RTLSDR_BASE=$(RTLSDR_BASE),$(CURDIR)/SDR/sdrsa_devices.docker)

sdrsadevicesrtlsdrv4:
	$(call build_and_push,sdrsa_devices_rtlsdrv4,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild_$(ARCH) --build-arg UHD_BASE=$(UHD_BASE) --build-arg RTLSDR_BASE=rtlsdrv4,$(CURDIR)/SDR/sdrsa_devices.docker)

sdrlight:
	$(call build_and_push,sdr_light,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdrsa_devices_$(ARCH),$(CURDIR)/SDR/sdr_light.docker)

sdrlight_intelgpu:
	$(call build_and_push,sdr_light_intelgpu,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_$(ARCH),$(CURDIR)/SDR/sdr_light_intelgpu.docker)

sdrlight_nvidiagpu:
	$(call build_and_push,sdr_light_nvidiagpu,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_$(ARCH),$(CURDIR)/SDR/sdr_light_nvidiagpu.docker)

sdrfull1:
	$(call build_and_push,extraoot1,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_$(ARCH) --build-arg JMPSTAGE1=begin --build-arg JMPSTAGE2=begin --build-arg JMPSTAGE3=begin --build-arg JMPSTAGE4=begin --target extraoot1,$(CURDIR)/SDR/sdr_full.docker)

sdrfull2:
	$(call build_and_push,extraoot2,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_$(ARCH) --build-arg JMPSTAGE1=begin --build-arg JMPSTAGE2=begin --build-arg JMPSTAGE3=begin --build-arg JMPSTAGE4=begin --target extraoot2,$(CURDIR)/SDR/sdr_full.docker)

sdrfull3:
	$(call build_and_push,extrasofts,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_$(ARCH) --build-arg JMPSTAGE1=begin --build-arg JMPSTAGE2=begin --build-arg JMPSTAGE3=begin --build-arg JMPSTAGE4=begin --target extrasofts,$(CURDIR)/SDR/sdr_full.docker)

sdrfull4:
	$(call build_and_push,mldlsofts,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_$(ARCH) --build-arg JMPSTAGE1=begin --build-arg JMPSTAGE2=begin --build-arg JMPSTAGE3=begin --build-arg JMPSTAGE4=begin --target mldlsofts,$(CURDIR)/SDR/sdr_full.docker)

sdrfull:
	$(call build_and_push,sdr_full,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_$(ARCH),$(CURDIR)/SDR/sdr_full.docker)

sdrfull_intelgpu:
	$(call build_and_push,sdr_full_intelgpu,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_intelgpu_$(ARCH),$(CURDIR)/SDR/sdr_full.docker)

sdrfull_nvidiagpu:
	$(call build_and_push,sdr_full_nvidiagpu,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_nvidiagpu_$(ARCH),$(CURDIR)/SDR/sdr_full.docker)

rfid:
	$(call build_and_push,rfid,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild_$(ARCH),$(CURDIR)/rfid.docker)

wifi:
	$(call build_and_push,wifi,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdrsa_devices_$(ARCH),$(CURDIR)/wifi.docker)

bluetooth:
	$(call build_and_push,bluetooth,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdrsa_devices_$(ARCH),$(CURDIR)/bluetooth.docker)

reversing:
	$(call build_and_push,reversing,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild_$(ARCH),$(CURDIR)/reversing.docker)

automotive:
	$(call build_and_push,automotive,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild_$(ARCH),$(CURDIR)/automotive.docker)

telecom_utils:
	$(call build_and_push,telecom_utils,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdrsa_devices_$(ARCH),$(CURDIR)/telecom/telecom_utils.docker)

telecom_2Gto3G:
	$(call build_and_push,telecom_2Gto3G,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):telecom_utils_$(ARCH),$(CURDIR)/telecom/telecom_2Gto3G.docker)

telecom_4Gto5G:
	$(call build_and_push,telecom_4Gto5G,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):telecom_utils_$(ARCH),$(CURDIR)/telecom/telecom_4Gto5G.docker)

deeptempest:
	$(call build_and_push,sdr_deeptemptest_beta,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_$(ARCH),$(CURDIR)/SDR/sdr_deeptemptest_beta.docker)

build: common sdrsadevices sdrlight sdrfull sdrsadevicesantsdr sdrsadevicesrtlsdrv4 rfid telecom_utils telecom_2Gto3G telecom_4Gto5G bluetooth wifi automotive reversing
	@echo "Done!"