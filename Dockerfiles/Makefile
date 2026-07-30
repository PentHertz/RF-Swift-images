# Set default architecture to all if ARCH is not provided
ARCH ?= amd64
CACHE_REPO ?= penthertz/rfswiftdev_resolute
REGISTRY_IMAGE ?= penthertz/rfswiftdev_resolute
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
        $(2) \
        --push \
        -t $(REGISTRY_IMAGE):$(1)_$(ARCH) \
        -f $(3) \
        ..;
endef


define build_and_push_registry_torestore
    @docker buildx build --platform $(PLATFORM) \
        --cache-from=type=registry,ref=$(CACHE_REPO):cache_$(1)_$(ARCH) \
        --cache-to=type=registry,ref=$(CACHE_REPO):cache_$(1)_$(ARCH),mode=min \
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

# Function to build multi-stage with registry cache (for sdr_full stages)
define build_stage_registry_torestore
    @echo "Building stage: $(1) for $(ARCH)"
    @docker buildx build --platform $(PLATFORM) \
        --target $(1) \
        --cache-from=type=registry,ref=$(CACHE_REPO):cache_sdrfull_$(1)_$(ARCH) \
        --cache-to=type=registry,ref=$(CACHE_REPO):cache_sdrfull_$(1)_$(ARCH),mode=min \
        $(2) \
        --push \
        -t $(REGISTRY_IMAGE):sdrfull_$(1)_$(ARCH) \
        -f $(3) \
        ..;
endef

define build_stage_registry
    @echo "Building stage: $(1) for $(ARCH)"
    @docker buildx build --platform $(PLATFORM) \
        --target $(1) \
        --cache-from=type=registry,ref=$(CACHE_REPO):cache_sdrfull_$(1)_$(ARCH) \
        $(2) \
        --push \
        -t $(REGISTRY_IMAGE):sdrfull_$(1)_$(ARCH) \
        -f $(3) \
        ..;
endef

# Function to build multi-stage with local cache (for sdr_full stages)
define build_stage_local
    @echo "Building stage: $(1) for $(ARCH)"
    @docker buildx build --platform $(PLATFORM) \
        --target $(1) \
        $(2) \
        --load \
        -t $(REGISTRY_IMAGE):sdrfull_$(1)_$(ARCH) \
        -f $(3) \
        ..;
endef

# Choose the build function based on STORAGE_TYPE
ifeq ($(STORAGE_TYPE),registry)
    build_and_push = $(build_and_push_registry)
    build_stage = $(build_stage_registry)
else
    build_and_push = $(build_and_push_local)
    build_stage = $(build_stage_local)
endif

#
# Specific build targets using the chosen function
#
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

sdrgnuradio4:
	$(call build_and_push,sdr_gnuradio4,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_$(ARCH),$(CURDIR)/SDR/sdr_gnuradio4.docker)

#
# SDR Full - Multi-stage build targets
#
# These targets build each stage individually and push to registry for caching
# This allows recovery from timeouts by reusing already-built stages
#

# Stage 1: Build stage-begin
sdrfull_stage_begin: clean_cache
	$(call build_stage,stage-begin,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_$(ARCH),$(CURDIR)/SDR/sdr_full.docker)

# Stage 2: Build stage-extraoot1
sdrfull_stage_extraoot1:
	$(call build_stage,stage-extraoot1,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_$(ARCH) --cache-from=type=registry$(COMMA)ref=$(CACHE_REPO):cache_sdrfull_stage-begin_$(ARCH),$(CURDIR)/SDR/sdr_full.docker)

# Stage 3: Build stage-extraoot2
sdrfull_stage_extraoot2:
	$(call build_stage,stage-extraoot2,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_$(ARCH) --cache-from=type=registry$(COMMA)ref=$(CACHE_REPO):cache_sdrfull_stage-extraoot1_$(ARCH),$(CURDIR)/SDR/sdr_full.docker)

# Stage 4: Build stage-extrasofts
sdrfull_stage_extrasofts:
	$(call build_stage,stage-extrasofts,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_$(ARCH) --cache-from=type=registry$(COMMA)ref=$(CACHE_REPO):cache_sdrfull_stage-extraoot2_$(ARCH),$(CURDIR)/SDR/sdr_full.docker)

# Stage 5: Build stage-mldlsofts
sdrfull_stage_mldlsofts:
	$(call build_stage,stage-mldlsofts,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_$(ARCH) --cache-from=type=registry$(COMMA)ref=$(CACHE_REPO):cache_sdrfull_stage-extrasofts_$(ARCH),$(CURDIR)/SDR/sdr_full.docker)

# Build all stages sequentially (for local testing or complete rebuild)
sdrfull_staged: sdrfull_stage_begin sdrfull_stage_extraoot1 sdrfull_stage_extraoot2 sdrfull_stage_extrasofts sdrfull_stage_mldlsofts sdrfull_final
	@echo "SDR Full staged build complete for $(ARCH)"

# Final stage: Build complete sdr_full image
sdrfull_final:
	$(call build_and_push,sdr_full,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_$(ARCH) --cache-from=type=registry$(COMMA)ref=$(CACHE_REPO):cache_sdrfull_stage-mldlsofts_$(ARCH),$(CURDIR)/SDR/sdr_full.docker)

# Standard sdrfull target (builds complete image with all cache layers)
sdrfull_torestore:
ifeq ($(STORAGE_TYPE),registry)
	@echo "Building sdr_full with registry caching - using all available cached stages"
	@docker buildx build --platform $(PLATFORM) \
		--cache-from=type=registry,ref=$(CACHE_REPO):cache_sdrfull_stage-begin_$(ARCH) \
		--cache-from=type=registry,ref=$(CACHE_REPO):cache_sdrfull_stage-extraoot1_$(ARCH) \
		--cache-from=type=registry,ref=$(CACHE_REPO):cache_sdrfull_stage-extraoot2_$(ARCH) \
		--cache-from=type=registry,ref=$(CACHE_REPO):cache_sdrfull_stage-extrasofts_$(ARCH) \
		--cache-from=type=registry,ref=$(CACHE_REPO):cache_sdrfull_stage-mldlsofts_$(ARCH) \
		--cache-from=type=registry,ref=$(CACHE_REPO):cache_sdr_full_$(ARCH) \
		--cache-to=type=registry,ref=$(CACHE_REPO):cache_sdr_full_$(ARCH),mode=max \
		--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_$(ARCH) \
		--push \
		-t $(REGISTRY_IMAGE):sdr_full_$(ARCH) \
		-f $(CURDIR)/SDR/sdr_full.docker \
		..
else
	$(call build_and_push,sdr_full,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_$(ARCH),$(CURDIR)/SDR/sdr_full.docker)
endif

sdrfull:
ifeq ($(STORAGE_TYPE),registry)
	@echo "Building sdr_full with registry caching - using all available cached stages"
	@docker buildx build --platform $(PLATFORM) \
		--cache-from=type=registry,ref=$(CACHE_REPO):cache_sdrfull_stage-begin_$(ARCH) \
		--cache-from=type=registry,ref=$(CACHE_REPO):cache_sdrfull_stage-extraoot1_$(ARCH) \
		--cache-from=type=registry,ref=$(CACHE_REPO):cache_sdrfull_stage-extraoot2_$(ARCH) \
		--cache-from=type=registry,ref=$(CACHE_REPO):cache_sdrfull_stage-extrasofts_$(ARCH) \
		--cache-from=type=registry,ref=$(CACHE_REPO):cache_sdrfull_stage-mldlsofts_$(ARCH) \
		--cache-from=type=registry,ref=$(CACHE_REPO):cache_sdr_full_$(ARCH) \
		--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_$(ARCH) \
		--push \
		-t $(REGISTRY_IMAGE):sdr_full_$(ARCH) \
		-f $(CURDIR)/SDR/sdr_full.docker \
		..
else
	$(call build_and_push,sdr_full,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_$(ARCH),$(CURDIR)/SDR/sdr_full.docker)
endif

# Legacy individual stage targets (kept for backwards compatibility with old Dockerfile)
sdrfull1:
	$(call build_and_push,extraoot1,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_$(ARCH) --build-arg JMPSTAGE1=begin --build-arg JMPSTAGE2=begin --build-arg JMPSTAGE3=begin --build-arg JMPSTAGE4=begin --target extraoot1,$(CURDIR)/SDR/sdr_full.docker)

sdrfull2:
	$(call build_and_push,extraoot2,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_$(ARCH) --build-arg JMPSTAGE1=begin --build-arg JMPSTAGE2=begin --build-arg JMPSTAGE3=begin --build-arg JMPSTAGE4=begin --target extraoot2,$(CURDIR)/SDR/sdr_full.docker)

sdrfull3:
	$(call build_and_push,extrasofts,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_$(ARCH) --build-arg JMPSTAGE1=begin --build-arg JMPSTAGE2=begin --build-arg JMPSTAGE3=begin --build-arg JMPSTAGE4=begin --target extrasofts,$(CURDIR)/SDR/sdr_full.docker)

sdrfull4:
	$(call build_and_push,mldlsofts,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_$(ARCH) --build-arg JMPSTAGE1=begin --build-arg JMPSTAGE2=begin --build-arg JMPSTAGE3=begin --build-arg JMPSTAGE4=begin --target mldlsofts,$(CURDIR)/SDR/sdr_full.docker)

sdrfull_intelgpu:
	$(call build_and_push,sdr_full_intelgpu,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_intelgpu_$(ARCH),$(CURDIR)/SDR/sdr_full.docker)

sdrfull_nvidiagpu:
	$(call build_and_push,sdr_full_nvidiagpu,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light_nvidiagpu_$(ARCH),$(CURDIR)/SDR/sdr_full.docker)

#
# Other image targets
#
rfid:
	$(call build_and_push,rfid,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild_$(ARCH),$(CURDIR)/rfid.docker)

network:
	$(call build_and_push,network,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdrsa_devices_$(ARCH),$(CURDIR)/general_network.docker)

wifi:
	$(call build_and_push,wifi,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):network_$(ARCH),$(CURDIR)/wifi_basic.docker)

bluetooth:
	$(call build_and_push,bluetooth,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdrsa_devices_$(ARCH),$(CURDIR)/bluetooth.docker)

reversing:
	$(call build_and_push,reversing,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild_$(ARCH),$(CURDIR)/reversing.docker)

automotive:
	$(call build_and_push,automotive,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild_$(ARCH),$(CURDIR)/automotive.docker)

android:
	$(call build_and_push,android,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild_$(ARCH),$(CURDIR)/android.docker)

osint:
	$(call build_and_push,osint,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild_$(ARCH),$(CURDIR)/osint.docker)

ad:
	$(call build_and_push,ad,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):network_$(ARCH),$(CURDIR)/ad.docker)

hardware:
	$(call build_and_push,hardware,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdrsa_devices_$(ARCH),$(CURDIR)/hardware.docker)

telecom_utils:
	$(call build_and_push,telecom_utils,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdrsa_devices_$(ARCH),$(CURDIR)/telecom/telecom_utils.docker)

telecom_2Gto3G:
	$(call build_and_push,telecom_2Gto3G,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):telecom_utils_$(ARCH),$(CURDIR)/telecom/telecom_2Gto3G.docker)

telecom_4Gto5G:
	$(call build_and_push,telecom_4Gto5G,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):telecom_utils_$(ARCH),$(CURDIR)/telecom/telecom_4Gto5G.docker)

telecom_4G_5GNSA:
	$(call build_and_push,telecom_4G_5GNSA,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):telecom_utils_$(ARCH),$(CURDIR)/telecom/telecom_4G_5GNSA.docker)

telecom_5G_train:
	$(call build_and_push,telecom_5G_train,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):telecom_4G_5GNSA_$(ARCH),$(CURDIR)/telecom/telecom_4Gto5G_extended.docker)

telecom_5G:
	$(call build_and_push,telecom_5G,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):telecom_utils_$(ARCH),$(CURDIR)/telecom/telecom_5G.docker)

deeptempest:
	$(call build_and_push,deeptempest,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdrsa_devices_$(ARCH),$(CURDIR)/SDR/sdr_deeptemptest_beta.docker)

telecom_5G_bladerf:
	$(call build_and_push,telecom_5G_bladerf,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):telecom_utils_$(ARCH),$(CURDIR)/telecom/telecom_5G_bladerf.docker)

clean_cache:
	@echo "Cleaning Docker build cache and volumes..."
	@docker buildx prune -af
	@docker volume prune -f
	@docker system prune -af --volumes


# Print the build report (tools/packages that failed to install) baked into an
# already-built image. Pulls the image if needed.
#   make report IMG=corebuild ARCH=amd64
#   make report IMG=automotive ARCH=arm64
IMG ?= corebuild
report:
	@docker run --rm --entrypoint sh $(REGISTRY_IMAGE):$(IMG)_$(ARCH) -c \
		'cat /var/lib/db/rfswift_build_report.tsv 2>/dev/null || echo "(no failures recorded)"'
#
# Convenience targets
#
build: common sdrsadevices sdrlight sdrfull sdrsadevicesantsdr sdrsadevicesrtlsdrv4 rfid network ad telecom_utils telecom_2Gto3G telecom_4G_5GNSA telecom_5G bluetooth wifi automotive android osint reversing
	@echo "Done!"

# Help target
help:
	@echo "RF Swift Docker Build System"
	@echo ""
	@echo "Usage: make [target] ARCH=[amd64|arm64|riscv64] STORAGE_TYPE=[local|registry]"
	@echo ""
	@echo "Main targets:"
	@echo "  common              - Build corebuild base image"
	@echo "  sdrsadevices        - Build SDR SA devices image"
	@echo "  sdrlight            - Build SDR light image"
	@echo "  sdrgnuradio4        - Build GNU Radio 4.0 (GR4) add-on image on top of sdr_light"
	@echo "  sdrfull             - Build complete SDR full image (with caching)"
	@echo "  sdrfull_staged      - Build SDR full with explicit stage-by-stage building"
	@echo ""
	@echo "SDR Full stage targets (for debugging/recovery):"
	@echo "  sdrfull_stage_begin      - Build stage-begin"
	@echo "  sdrfull_stage_extraoot1  - Build stage-extraoot1"
	@echo "  sdrfull_stage_extraoot2  - Build stage-extraoot2"
	@echo "  sdrfull_stage_extrasofts - Build stage-extrasofts"
	@echo "  sdrfull_stage_mldlsofts  - Build stage-mldlsofts"
	@echo "  sdrfull_final            - Build final stage"
	@echo ""
	@echo "Other image targets:"
	@echo "  rfid, network, wifi, bluetooth, reversing, automotive, hardware"
	@echo "  telecom_utils, telecom_2Gto3G, telecom_4G_5GNSA, telecom_5G, deeptempest"
	@echo ""
	@echo "Examples:"
	@echo "  make sdrfull ARCH=arm64 STORAGE_TYPE=registry"
	@echo "  make sdrfull_staged ARCH=amd64 STORAGE_TYPE=registry"
	@echo "  make sdrfull_stage_extraoot1 ARCH=arm64 STORAGE_TYPE=registry"

.PHONY: common sdrsadevices sdrsadevicesantsdr sdrsadevicesrtlsdrv4 sdrlight sdrlight_intelgpu sdrlight_nvidiagpu sdrgnuradio4 \
	sdrfull sdrfull_staged sdrfull_stage_begin sdrfull_stage_extraoot1 sdrfull_stage_extraoot2 \
	sdrfull_stage_extrasofts sdrfull_stage_mldlsofts sdrfull_final \
	sdrfull1 sdrfull2 sdrfull3 sdrfull4 sdrfull_intelgpu sdrfull_nvidiagpu \
	rfid network wifi bluetooth reversing automotive hardware \
	telecom_utils telecom_2Gto3G telecom_4Gto5G telecom_4G_5GNSA telecom_5G telecom_5G_bladerf \
	deeptempest build help

