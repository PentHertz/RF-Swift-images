# Set default architecture to all if ARCH is not provided
ARCH ?= amd64
CACHE_REPO ?= penthertz/rfswiftdev
REGISTRY_IMAGE ?= penthertz/rfswiftdev

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

# Common build and push function
define build_and_push
    @docker buildx build --platform $(PLATFORM) \
        --cache-from=type=registry,ref=$(CACHE_REPO):cache_$(1)$(ARCH) \
        --cache-to=type=registry,ref=$(CACHE_REPO):cache_$(1)$(ARCH),mode=max \
        $(2) \
        --push \
        -t $(REGISTRY_IMAGE):$(1) \
        -f $(3) \
        ..; \
    output=$$(docker buildx imagetools inspect $(REGISTRY_IMAGE):$(1)); \
    if [ -z "$$output" ]; then \
        echo "Failed to retrieve image details. Please check the image name and tag."; \
        exit 1; \
    fi; \
    arch_digest=$$(echo "$$output" | awk '/linux\/$(ARCH)/{getline; getline; print $$2}'); \
    docker buildx imagetools create \
        --tag $(REGISTRY_IMAGE):$(1) \
        $(REGISTRY_IMAGE):$(1)@sha256:$$arch_digest
endef

# Specific build targets using the common function
common:
	$(call build_and_push,corebuild,,$(CURDIR)/corebuild.docker)

sdrsadevices:
	$(call build_and_push,sdrsa_devices,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild --build-arg UHD_BASE=$(UHD_BASE) --build-arg RTLSDR_BASE=$(RTLSDR_BASE),$(CURDIR)/SDR/sdrsa_devices.docker)

sdrsadevicesantsdr:
	$(call build_and_push,sdrsa_devices_antsdr,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild --build-arg UHD_BASE=antsdr_uhd --build-arg RTLSDR_BASE=$(RTLSDR_BASE),$(CURDIR)/SDR/sdrsa_devices.docker)

sdrsadevicesrtlsdrv4:
	$(call build_and_push,sdrsa_devices_rtlsdrv4,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild --build-arg UHD_BASE=$(UHD_BASE) --build-arg RTLSDR_BASE=rtlsdrv4,$(CURDIR)/SDR/sdrsa_devices.docker)

sdrlight:
	$(call build_and_push,sdr_light,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdrsa_devices,$(CURDIR)/SDR/sdr_light.docker)

sdrfull1:
	$(call build_and_push,extraoot1,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light --build-arg JMPSTAGE1=begin --build-arg JMPSTAGE2=begin --build-arg JMPSTAGE3=begin --build-arg JMPSTAGE4=begin --target extraoot1,$(CURDIR)/SDR/sdr_full.docker)

sdrfull2:
	$(call build_and_push,extraoot2,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light --build-arg JMPSTAGE1=begin --build-arg JMPSTAGE2=begin --build-arg JMPSTAGE3=begin --build-arg JMPSTAGE4=begin --target extraoot2,$(CURDIR)/SDR/sdr_full.docker)

sdrfull3:
	$(call build_and_push,extrasofts,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light --build-arg JMPSTAGE1=begin --build-arg JMPSTAGE2=begin --build-arg JMPSTAGE3=begin --build-arg JMPSTAGE4=begin --target extrasofts,$(CURDIR)/SDR/sdr_full.docker)

sdrfull4:
	$(call build_and_push,mldlsofts,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light --build-arg JMPSTAGE1=begin --build-arg JMPSTAGE2=begin --build-arg JMPSTAGE3=begin --build-arg JMPSTAGE4=begin --target mldlsofts,$(CURDIR)/SDR/sdr_full.docker)

sdrfull:
	$(call build_and_push,sdr_full,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light,$(CURDIR)/SDR/sdr_full.docker)

rfid:
	$(call build_and_push,rfid,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild,$(CURDIR)/rfid.docker)

wifi:
	$(call build_and_push,wifi,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdrsa_devices,$(CURDIR)/wifi.docker)

bluetooth:
	$(call build_and_push,bluetooth,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdrsa_devices,$(CURDIR)/bluetooth.docker)

reversing:
	$(call build_and_push,reversing,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild,$(CURDIR)/reversing.docker)

automotive:
	$(call build_and_push,automotive,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild,$(CURDIR)/automotive.docker)

telecom:
	$(call build_and_push,telecom,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdrsa_devices,$(CURDIR)/telecom.docker)

deeptempest:
	$(call build_and_push,sdr_deeptemptest_beta,--build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light,$$(CURDIR)/SDR/sdr_deeptemptest_beta.docker)

build: common sdrsadevices sdrlight sdrfull sdrsadevicesantsdr sdrsadevicesrtlsdrv4 rfid telecom bluetooth wifi automotive reversing
	@echo "Done!"
