.PHONY: help lint build

# Use bash for inline if-statements in arch_patch target
SHELL:=bash

# Enable BuildKit for Docker build
export DOCKER_BUILDKIT:=1
export COMPOSE_DOCKER_CLI_BUILD:=1
export BUILDKIT_PROGRESS:=plain

export aptCacher:=192.168.53.212
#export aptCacher:=
progress:=auto #plain auto
MKVVERSION:="1.18.1"
FDKVERSION:="2.0.3"


# https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help:
	@$(MAKE) -pRrq -f $(lastword $(MAKEFILE_LIST)) : 2>/dev/null | awk -v RS= -F: '/^# Fichiers/,/^# Base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

lint: ## stop all containers
	@echo "lint dockerfile ..."
	docker run -i --rm hadolint/hadolint < Dockerfile

build: ## build image
	@echo "build image ..."
	docker buildx bake --file bake.hcl --progress plain final
	#docker buildx use default
	#docker buildx build --load --progress plain --build-arg FDKVERSION="${FDKVERSION}" --build-arg aptCacher="${aptCacher}" --build-arg PREFIX="/usr/local" --build-arg=MKVVERSION="${MKVVERSION}" --build-arg BUILD_DATE=$(date +%Y%m%d) --platform amd64 -f ./Dockerfile --target final -t edgd1er/docker-ripper .

buildbin: ## build binaries
	@echo "Build binaries"
	docker buildx bake --file bake.hcl --progress plain buildbin
	docker buildx bake --file bake.hcl --progress plain final --load
	#export COMPOSE_BAKE=true
	#docker buildx build --progress plain --target builder --build-arg FDKVERSION="${FDKVERSION}" --build-arg aptCacher="${aptCacher}" --build-arg PREFIX="/opt/" --build-arg=MKVVERSION="${MKVVERSION}"  -f ./Dockerfile --output type=tar,dest=out.tar .

buildbinptf:
	@echo "Building for arm64 and amd64"
	docker buildx bake --file bake-multi.hcl --progress plain buildbin
	docker buildx bake --file bake-multi.hcl --progress plain final


run:
	docker-compose up

check:
	@local=$$(grep -oP "(?<=current makemkvcon's version: )[0-9].[0-9]+\.[0-9]+" README.md | tr -d ' '); \
	echo -e "local  makemkv version: $$local"; \
	remote=$$( curl -Ls 'http://www.makemkv.com/download/' | grep -oPm1 '(?<=MakeMKV )[0-9].[0-9]+\.[0-9]+' ); \
	echo "remote makemkv version: "$$remote; \
	if [[ $$remote != $$local ]]; then \
   		echo "setting makemkv's version to $$remote" ; \
		sed -i "s/MKVVERSION=*/MKVVERSION=$$remote/g" docker-compose.yml; \
		sed -i -E "s/MKVVERSION=\"([^\"]+)/MKVVERSION=\"$$remote/g"  bake.hcl; \
		sed -i -E "s/MKVVERSION=\"([^\"]+)/MKVVERSION=\"$$remote/g"  bake-multi.hcl; \
		sed -i "s/MKVVERSION=1.*/MKVVERSION=$$remote/g" Dockerfile;\
		sed -i "s/MKVVERSION=1.*/MKVVERSION=$$remote/g" compose.yml;\
		sed -i "s/MKVVERSION:=\".*/MKVVERSION:=\"$$remote\"/g" Makefile;\
		sed -i "s/current makemkvcon's version:.*/current makemkvcon's version: $$remote/g" README.md; fi

#   		#sed -i "s/FDKVERSION: .*/FDKVERSION: " ;
#		sed -i "s/MKVVERSION=1.*/MKVVERSION=$$remote/g" Dockerfile.build;\
#		sed -i "s/MKVVERSION=1.*/MKVVERSION=$$remote/g" Dockerfile.old;\
