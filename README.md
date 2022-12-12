# Hero Testnet Installer
**Domain:** testnet.heroesofnft.com

### Subnet Details
**VM ID:** nzfDQr8VpSZwsJNTqqDPiDGCPc79GLe7QL3qdTbCkPJ8MFevG
**Subnet ID:** 2MCNtqDyTQp7nAnj2iTREG7jdeJa3QRYWjvGvQh5uc9EqDmLTH
**Chain ID:** p91WZe6xXivSgCBZwWwJmAfyxM92r819G7sqqRrYYRPzy49bP

### Requirements
To participate in the Hero Testnet, a current Avalanche fuji node must be installed.
If you do not know how to install avalanche fuji node, you can install it by examining this document. 
**Avalanche Node Installer**: https://docs.avax.network/nodes/build/set-up-node-with-installer

### Install
**bash hero-testnet-installer.sh \<options>**

|  Option |  Value | Default  |
| ------------ | ------------ | ------------ |
|  \--version |  (subnet-evm  version number) | default: -latest (If the parameter is left blank, the latest version is automatically installed.)  |
|  \--vm-id |  subnet vm id | default: nzfDQr8VpSZwsJNTqqDPiDGCPc79GLe7QL3qdTbCkPJ8MFevG (Hero Testnet)  |

After the script is run, the subnet-evm version will be installed. After installation, hero-testnet will be defined to your fuji node and the process will be completed successfully.