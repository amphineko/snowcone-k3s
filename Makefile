all: $(patsubst inputs/%.yml,vms/%,$(patsubst inputs/common.yml,,$(wildcard inputs/*.yml))) mustache

base_image = $(shell basename $(shell find tools -name 'fedora-coreos-*-qemu.x86_64.qcow2' -print -quit))

.SECONDARY:

define MUSTACHE =
	@echo "($1) mustache $3 vms/$1/$2"
	@docker run --rm \
		-v $(shell pwd)/templates:/templates \
		-v $(shell pwd)/inputs:/inputs \
		mustache \
		--override /inputs/$1.yml \
		/inputs/common.yml \
		/templates/$3 > vms/$1/$2
endef

define BUTANE = 
	@echo "($1) butane vms/$1/$2.yml vms/$1/$2.json"
	@docker run --rm \
		-v $(shell pwd)/vms:/vms \
		-w /outputs \
		quay.io/coreos/butane:release \
		--files-dir /vms/$1 --pretty --strict --output /vms/$1/$2.json /vms/$1/$2.yml
endef

vms/%/domain.xml: inputs/%.yml inputs/common.yml mustache
	@mkdir -p vms/$*
	$(call MUSTACHE,$*,domain.xml,domain.xml)

vms/%/ignition.base.yml: inputs/%.yml inputs/common.yml templates/base.ignition.yml mustache
	@mkdir -p vms/$*
	$(call MUSTACHE,$*,ignition.base.yml,base.ignition.yml)

vms/%/ignition.base.json : vms/%/ignition.base.yml
	$(call BUTANE,$*,ignition.base)

vms/%/ignition.json: vms/%/ignition.yml vms/%/ignition.base.json
	$(call BUTANE,$*,ignition)

vms/master%/ignition.yml: inputs/master%.yml inputs/common.yml templates/master.ignition.yml mustache
	$(call MUSTACHE,master$*,ignition.yml,master.ignition.yml)

vms/worker%/ignition.yml: inputs/worker%.yml inputs/common.yml templates/worker.ignition.yml mustache
	$(call MUSTACHE,worker$*,ignition.yml,worker.ignition.yml)

vms/%/disk.qcow2: tools/$(base_image)
	@echo "($*) qemu-img create -b $(base_image) vms/$*/disk.qcow2"
	@mkdir -p vms/$*
	@qemu-img create -f qcow2 -F qcow2 -b ../../tools/$(base_image) vms/$*/disk.qcow2 64G

vms/%: vms/%/disk.qcow2 vms/%/ignition.json vms/%/domain.xml
	@echo "($*) virsh define vms/$*/domain.xml"
	@virsh -c qemu:///system define vms/$*/domain.xml

mustache: tools/mustache/Dockerfile
	docker build -t mustache tools/mustache
