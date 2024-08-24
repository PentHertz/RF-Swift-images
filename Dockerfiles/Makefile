# Set default architecture to all if ARCH is not provided
ARCH ?= all
CACHE_REPO ?= penthertz/rfswiftdev
REGISTRY_IMAGE ?= penthertz/rfswiftdev

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
            -f SDR/corebuild.docker \
            ..

sdrlight: common
		docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_sdr_light \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_sdr_light,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild \
            --build-arg UHD_BASE=uhd \
            --build-arg RTLSDR_BASE=rtlsdr \
            --push \
            -t $(REGISTRY_IMAGE):sdr_light \
            -f SDR/sdr_light.docker \
            ..

sdrlightantsdr: common
		docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_sdr_light \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_sdr_light,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild \
            --build-arg UHD_BASE=antsdr_uhd \
            --build-arg RTLSDR_BASE=rtlsdr \
            --push \
            -t $(REGISTRY_IMAGE):sdr_light \
            -f SDR/sdr_light.docker \
            ..

sdrlightrtlsdrv4: common
		docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_sdr_light \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_sdr_light,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild \
            --build-arg UHD_BASE=uhd \
            --build-arg RTLSDR_BASE=rtlsdrv4 \
            --push \
            -t $(REGISTRY_IMAGE):sdr_light \
            -f SDR/sdr_light.docker \
            ..


sdrfull1: common sdrlight
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_extraoot \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_extraoot,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light \
            --push \
            -t $(REGISTRY_IMAGE):extraoot \
            --target extraoot \
            -f SDR/sdr_full.docker \
            ..

sdrfull2: common sdrlight
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_extrasofts \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_extrasofts,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light \
            --push \
            -t $(REGISTRY_IMAGE):extrasofts \
            --target extraoot \
            -f SDR/sdr_full.docker \
            ..

sdrfull3: common sdrlight
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_mldlsofts \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_mldlsofts,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light \
            --push \
            -t $(REGISTRY_IMAGE):mldlsofts \
            --target extraoot \
            -f SDR/sdr_full.docker \
            ..

sdrfull: common sdrlight
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_sdr_full \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_sdr_full,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light \
            --push \
            -t $(REGISTRY_IMAGE):sdr_full \
            -f SDR/sdr_full.docker \
            ..

rfid: common
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_rfid \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_rfid,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild \
            --push \
            -t $(REGISTRY_IMAGE):rfid \
            -f rfid.docker \
            ..

wifi: common sdrlight
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_wifi \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_wifi,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light \
            --push \
            -t $(REGISTRY_IMAGE):wifi \
            -f wifi.docker \
            ..


bluetooth: common sdrlight
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_bluetooth \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_bluetooth,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild \
            --push \
            -t $(REGISTRY_IMAGE):bluetooth \
            -f bluetooth.docker \
            ..

reversing: common
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_reversing \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_reversing,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild \
            --push \
            -t $(REGISTRY_IMAGE):reversing \
            -f reversing.docker \
            ..

automotive: common
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_automotive \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_automotive,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):corebuild \
            --push \
            -t $(REGISTRY_IMAGE):automotive \
            -f automotive.docker \
            ..

telecom: common sdrlight
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_telecom \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_telecom,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light \
            --push \
            -t $(REGISTRY_IMAGE):telecom \
            -f telecom.docker \
            ..

deeptempest: common sdrlight
	docker buildx build --platform $(PLATFORM) \
            --cache-from=type=registry,ref=$(CACHE_REPO):cache_sdr_deeptemptest_beta \
            --cache-to=type=registry,ref=$(CACHE_REPO):cache_sdr_deeptemptest_beta,mode=max \
            --build-arg BASE_IMAGE=$(REGISTRY_IMAGE):sdr_light \
            --push \
            -t $(REGISTRY_IMAGE):sdr_deeptemptest_beta \
            -f SDR/sdr_deeptemptest_beta.docker \
            ..

build: bluetooth wifi rfid reversing automotive telecom sdrfull sdrlightantsdr sdrlightrtlsdrv4
	echo "Done!"