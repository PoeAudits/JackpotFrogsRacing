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


deploy-windfall-harness:
	forge script script/DeployWindfallHarness.s.sol:DeployWindfallHarness --private-key $(PRIVATE_KEY) --fork-url localhost --optimize --broadcast

deploy-windfall-harness-filled:
	forge script script/DeployWindfallHarness.s.sol:DeployWindfallHarness --private-key $(PRIVATE_KEY) --fork-url localhost --optimize --broadcast && forge script script/FillTree.s.sol --private-key $(PRIVATE_KEY) --fork-url localhost --optimize --broadcast

anvil-canto:
	anvil -f canto --fork-block-number 8790000

anvil-canto-latest:
	anvil -f canto

halmos-setup:
	forge script script/HalmosSetup.s.sol:HalmosSetup --rpc-url localhost --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 -vvvv --broadcast