-include .env

.PHONY: forge script test anvil snapshot

install-openzeppelin-contracts:
	forge install Openzeppelin/openzeppelin-contracts --no-commit

install-openzeppelin-contracts-upgradeable:
	forge install Openzeppelin/openzeppelin-contracts-upgradeable --no-commit

install-solmate:
	forge install transmissions11/solmate --no-commit

install-solady:
	forge install vectorized/solady --no-commit

generate:
	go run generate.go -setup -factory -filename "src/Factory.sol"

generate-factory:
	go run generate.go -factory -filename "src/Factory.sol"
	
generate-setup:
	go run generate.go -setup 