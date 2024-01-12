APP_NAME := java-app
PORT := 8080

BUILD_DIR := $(CURDIR)/target
BIN_DIR := $(BUILD_DIR)/bin

OS := $(shell uname -s)

.DEFAULT_GOAL := help

# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: init
init:
	@mkdir -p "$(BUILD_DIR)"

.PHONY: clean
clean:
	@rm -rf target

##@ Build

.PHONY: build
build: init ## Build and install the binary.
	docker run -it --rm --name=$(APP_NAME) -v "$(PWD)":/build -w /build maven:3.9.6-eclipse-temurin-17 mvn clean install

.PHONY: run
run:
	@echo "➡️Launching server..."
	docker run -it --rm -p=$(PORT):$(PORT) --name=$(APP_NAME) -v "$(PWD)":/work -w /work maven:3.9.6-eclipse-temurin-17 java -jar target/quickstart-java-app.jar

.PHONY: docker-build
docker-build: build ## Build the container
	docker build -t $(APP_NAME) .

.PHONY: docker-run
docker-run: ## Run the container
	docker run -i -t --rm -p=$(PORT):$(PORT) --name="$(APP_NAME)" $(APP_NAME)

.PHONY: shell
shell:
	docker run -i -t --rm --name="$(APP_NAME)" --entrypoint sh $(APP_NAME)

