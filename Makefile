PROJECT_DIR = $(network)/$(shell date +'%Y-%m-%d')-$(task)
DEPLOY_DIR = $(network)/$(shell date +'%Y-%m-%d')-deploy
INCIDENT_DIR = $(network)/$(shell date +'%Y-%m-%d')-$(incident)
TEMPLATE_GENERIC = setup-templates/template-generic
TEMPLATE_DEPLOY = setup-templates/template-deploy
TEMPLATE_INCIDENT = setup-templates/template-incident

ifndef $(GOPATH)
    GOPATH=$(shell go env GOPATH)
    export GOPATH
endif

.PHONY: install-foundry
install-foundry:
	echo "Installing Foundry..."
	curl -L https://foundry.paradigm.xyz | bash
	~/.foundry/bin/foundryup --commit $(FOUNDRY_COMMIT)

##
# Project Setup
##
# Run `make setup-task network=<network> task=<task>`
setup-task:
	echo "Setting up task $(task) for network $(network)..."
	rm -rf $(TEMPLATE_GENERIC)/cache $(TEMPLATE_GENERIC)/lib $(TEMPLATE_GENERIC)/out
	cp -r $(TEMPLATE_GENERIC) $(PROJECT_DIR)

# Run `make setup-deploy network=<network>`
setup-deploy:
	echo "Setting up deploy for network $(network)..."
	rm -rf $(TEMPLATE_DEPLOY)/cache $(TEMPLATE_DEPLOY)/lib $(TEMPLATE_DEPLOY)/out
	mkdir -p $(network) && cp -r $(TEMPLATE_DEPLOY) $(DEPLOY_DIR)

# Run `make setup-incident network=<network> incident=<incident-name>`
setup-incident:
	echo "Setting up incident $(incident) for network $(network)..."
	rm -rf $(TEMPLATE_INCIDENT)/cache $(TEMPLATE_INCIDENT)/lib $(TEMPLATE_INCIDENT)/out
	mkdir -p $(network) && cp -r $(TEMPLATE_INCIDENT) $(INCIDENT_DIR)

##
# Solidity Setup
##
.PHONY: deps
deps: install-eip712sign clean-lib forge-deps checkout-op-commit checkout-base-contracts-commit

.PHONY: install-eip712sign
install-eip712sign:
	echo "Installing eip712sign..."
	go install github.com/base-org/eip712sign@v0.0.6

.PHONY: clean-lib
clean-lib:
	echo "Cleaning lib directory..."
	rm -rf lib

.PHONY: forge-deps
forge-deps:
	echo "Installing Forge dependencies..."
	forge install --no-git github.com/foundry-rs/forge-std \
		github.com/OpenZeppelin/openzeppelin-contracts@v4.9.3 \
		github.com/OpenZeppelin/openzeppelin-contracts-upgradeable@v4.7.3 \
		github.com/rari-capital/solmate@8f9b23f8838670afda0fd8983f2c41e8037ae6bc \
		github.com/Saw-mon-and-Natalie/clones-with-immutable-args@105efee1b9127ed7f6fedf139e1fc796ce8791f2 \
		github.com/Vectorized/solady@862a0afd3e66917f50e987e91886b9b90c4018a1

.PHONY: checkout-op-commit
checkout-op-commit:
	[ -n "$(OP_COMMIT)" ] || (echo "OP_COMMIT must be set in .env" && exit 1)
	echo "Checking out Optimism commit $(OP_COMMIT)..."
	rm -rf lib/optimism
	mkdir -p lib/optimism
	cd lib/optimism; \
	git init; \
	git remote add origin https://github.com/ethereum-optimism/optimism.git; \
	git fetch --depth=1 origin $(OP_COMMIT); \
	git reset --hard FETCH_HEAD

.PHONY: checkout-base-contracts-commit
checkout-base-contracts-commit:
	[ -n "$(BASE_CONTRACTS_COMMIT)" ] || (echo "BASE_CONTRACTS_COMMIT must be set in .env" && exit 1)
	echo "Checking out Base Contracts commit $(BASE_CONTRACTS_COMMIT)..."
	rm -rf lib/base-contracts
	mkdir -p lib/base-contracts
	cd lib/base-contracts; \
	git init; \
	git remote add origin https://github.com/base-org/contracts.git; \
	git fetch --depth=1 origin $(BASE_CONTRACTS_COMMIT); \
	git reset --hard FETCH_HEAD

##
# Solidity Testing
##
.PHONY: solidity-test
solidity-test:
	echo "Running Solidity tests..."
	forge test --ffi -vvv
