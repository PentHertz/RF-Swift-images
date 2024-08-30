# Set default architecture to all if ARCH is not provided
ARCH ?= all
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
else ifeq ($(ARCH),all)
    PLATFORM=linux/amd64,linux/arm64/v8,linux/riscv64
else
    $(error Unsupported architecture: $(ARCH). Supported values are amd64, arm64, riscv64, all)
endif

common:
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_corebuild \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_corebuild,mode=max \
            --push \
            -t $(REGISTRY_IMAGE):corebuild \
            -f corebuild.docker \
            ..

sdrsadevices:
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_sdrsadevices \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_sdrsadevices,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild \
            --build-arg UHD_BASE=$(UHD_BASE) \
            --build-arg RTLSDR_BASE=$(RTLSDR_BASE) \
            --push \
            -t $(REGISTRY_IMAGE):sdrsa_devices \
            -f SDR/sdrsa_devices.docker \
            ..

sdrsadevicesantsdr:
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_sdr_devices_antsdr \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_sdr_devices_antsdr,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild \
            --build-arg UHD_BASE=antsdr_uhd \
            --build-arg RTLSDR_BASE=$(RTLSDR_BASE) \
            --push \
            -t $(REGISTRY_IMAGE):sdrsa_devices_antsdr \
            -f SDR/sdrsa_devices.docker \
            ..

sdrsadevicesrtlsdrv4:
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_sdrsa_devices_rtlsdrv4 \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_sdrsa_devices_rtlsdrv4,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild \
            --build-arg UHD_BASE=$(UHD_BASE) \
            --build-arg RTLSDR_BASE=rtlsdrv4 \
            --push \
            -t $(REGISTRY_IMAGE):sdrsa_devices_rtlsdrv4 \
            -f SDR/sdrsa_devices.docker \
            ..

sdrlight:
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_sdr_light \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_sdr_light,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdrsa_devices \
            --push \
            -t $(REGISTRY_IMAGE):sdr_light \
            -f SDR/sdr_light.docker \
            ..

sdrfull1:
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_extraoot1 \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_extraoot1,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light \
            --build-arg JMPSTAGE1=begin \
            --build-arg JMPSTAGE2=begin \
            --build-arg JMPSTAGE3=begin \
            --build-arg JMPSTAGE4=begin \
            --push \
            -t $(REGISTRY_IMAGE):extraoot1 \
            --target extraoot1 \
            -f SDR/sdr_full.docker \
            ..

sdrfull2:
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_extraoot2 \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_extraoot2,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light \
            --build-arg JMPSTAGE1=begin \
            --build-arg JMPSTAGE2=begin \
            --build-arg JMPSTAGE3=begin \
            --build-arg JMPSTAGE4=begin \
            --push \
            -t $(REGISTRY_IMAGE):extraoot2 \
            --target extraoot2 \
            -f SDR/sdr_full.docker \
            ..

sdrfull3:
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_extrasofts \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_extrasofts,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light \
            --build-arg JMPSTAGE1=begin \
            --build-arg JMPSTAGE2=begin \
            --build-arg JMPSTAGE3=begin \
            --build-arg JMPSTAGE4=begin \
            --push \
            -t $(REGISTRY_IMAGE):extrasofts \
            --target extrasofts \
            -f SDR/sdr_full.docker \
            ..

sdrfull4:
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_mldlsofts \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_mldlsofts,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light \
            --build-arg JMPSTAGE1=begin \
            --build-arg JMPSTAGE2=begin \
            --build-arg JMPSTAGE3=begin \
            --build-arg JMPSTAGE4=begin \
            --push \
            -t $(REGISTRY_IMAGE):mldlsofts \
            --target mldlsofts \
            -f SDR/sdr_full.docker \
            ..

sdrfull:
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_sdr_full \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_sdr_full,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light \
            --push \
            -t $(REGISTRY_IMAGE):sdr_full \
            -f SDR/sdr_full.docker \
            ..

rfid:
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_rfid \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_rfid,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild \
            --push \
            -t $(REGISTRY_IMAGE):rfid \
            -f rfid.docker \
            ..

wifi:
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_wifi \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_wifi,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdrsa_devices \
            --push \
            -t $(REGISTRY_IMAGE):wifi \
            -f wifi.docker \
            ..

bluetooth:
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_bluetooth \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_bluetooth,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdrsa_devices \
            --push \
            -t $(REGISTRY_IMAGE):bluetooth \
            -f bluetooth.docker \
            ..

reversing:
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_reversing \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_reversing,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild \
            --push \
            -t $(REGISTRY_IMAGE):reversing \
            -f reversing.docker \
            ..

automotive:
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_automotive \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_automotive,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild \
            --push \
            -t $(REGISTRY_IMAGE):automotive \
            -f automotive.docker \
            ..

telecom:
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_telecom \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_telecom,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdrsa_devices \
            --push \
            -t $(REGISTRY_IMAGE):telecom \
            -f telecom.docker \
            ..

deeptempest:
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_sdr_deeptemptest_beta \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_sdr_deeptemptest_beta,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light \
            --push \
            -t $(REGISTRY_IMAGE):sdr_deeptemptest_beta \
            -f SDR/sdr_deeptemptest_beta.docker \
            ..

build: common sdrsadevices sdrlight sdrfull sdrsadevicesantsdr sdrsadevicesrtlsdrv4 rfid telecom bluetooth wifi automotive reversing
	echo "Done!"
