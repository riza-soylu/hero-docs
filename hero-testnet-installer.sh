#!/bin/bash
# Pulls latest pre-built node binary from GitHub and installs it as a systemd service.
# Intended for non-technical validators, assumes running on compatible Ubuntu.

#helper function that prints usage
usage() {
  echo "Usage: $0 [--help] [--version <tag>] [--vm-id <vm-id>]"
  echo "Options:"
  echo "   --help            Shows this message"
  echo "   --version <tag>          Installs <tag> subnet-evm version, default is the latest"
  echo "   --vm-id <vm-id>          VM ID of the chain on the Subnet, defaults to Hero Testnet: nzfDQr8VpSZwsJNTqqDPiDGCPc79GLe7QL3qdTbCkPJ8MFevG"

  echo ""
  exit 0
}

# Argument parsing convenience functions.
usage_error() {
  echo >&2 "$(basename $0):  $1"
  exit 2
}
assert_argument() { test "$1" != "$EOL" || usage_error "$2 requires an argument"; }
echo "Hero Testnet install..."
# process command line arguments
if [ "$#" != 0 ]; then
  EOL=$(echo '\01\03\03\07')
  set -- "$@" "$EOL"
  while [ "$1" != "$EOL" ]; do
    opt="$1"
    shift
    case "$opt" in
    --vm-id)
      assert_argument "$1" "$opt"
      vm-id="$1"
      shift
      ;;
    --version)
      assert_argument "$1" "$opt"
      version="$1"
      shift
      ;;
    - | '' | [!-]*) set -- "$@" "$opt" ;;          # positional argument, rotate to the end
    --*=*) set -- "${opt%%=*}" "${opt#*=}" "$@" ;; # convert '--name=arg' to '--name' 'arg'
    --) while [ "$1" != "$EOL" ]; do
      set -- "$@" "$1"
      shift
    done ;;                                             # process remaining arguments as positional
    -*) usage_error "unknown option: '$opt'" ;;         # catch misspelled options
    *) usage_error "this should NEVER happen ($opt)" ;; # sanity test for previous patterns

    esac
  done
  shift # $EOL
fi
#running as root gives the wrong homedir, check and exit if run with sudo.
vm_id=${vm_id:-nzfDQr8VpSZwsJNTqqDPiDGCPc79GLe7QL3qdTbCkPJ8MFevG}
version=${version:-latest}

if ((EUID == 0)); then
  echo "The script is not designed to run as root user. Please run it without sudo prefix."
  exit
fi

check_reqs() {
  if ! command -v curl &>/dev/null; then
    echo "curl could not be found, will install..."
    sudo apt-get install curl -y
  fi
  if ! command -v wget &>/dev/null; then
    echo "wget could not be found, will install..."
    sudo apt-get install wget -y
  fi
  if ! command -v dig &>/dev/null; then
    echo "dig could not be found, will install..."
    sudo apt-get install dnsutils -y
  fi

}
echo "Preparing environment..."
check_reqs
foundIP="$(dig +short myip.opendns.com @resolver1.opendns.com)"
foundArch="$(uname -m)" #get system architecture
foundOS="$(uname)"      #get OS
if [ "$foundOS" != "Linux" ]; then
  #sorry, don't know you.
  echo "Unsupported operating system: $foundOS!"
  echo "Exiting."
  exit
fi
if [ "$foundArch" = "aarch64" ]; then
  getArch="arm64" #we're running on arm arch (probably RasPi)
  echo "Found arm64 architecture..."
elif [ "$foundArch" = "x86_64" ]; then
  getArch="amd64" #we're running on intel/amd
  echo "Found amd64 architecture..."
else
  #sorry, don't know you.
  echo "Unsupported architecture: $foundArch!"
  echo "Exiting."
  exit
fi
if test -f "/etc/systemd/system/avalanchego.service"; then
  foundAvalancheGo=true
  echo "Found AvalancheGo systemd service already installed, switching to upgrade mode."
  echo "Stopping service..."
  sudo systemctl stop avalanchego
else
  foundAvalancheGo=false
  echo "Couldn't found AvalancheGo systemd service, please run avalanchego-installer.sh before this script."
  echo "Exiting."
  exit
fi
# download and copy node files
mkdir -p /tmp/avalanche-node-subnet-install #make a directory to work in
rm -rf /tmp/avalanche-node-subnet-install/* #clean up in case previous install didn't
cd /tmp/avalanche-node-subnet-install

echo "Looking for $getArch version $version..."
if [ "$version" = "latest" ]; then
  fileName="$(curl -s https://api.github.com/repos/ava-labs/subnet-evm/releases/latest | grep "linux_$getArch.*tar\(.gz\)*\"" | cut -d : -f 2,3 | tr -d \" | cut -d , -f 2)"
else
  fileName="https://github.com/ava-labs/subnet-evm/releases/download/v$version/subnet-evm_"$version"_linux_$getArch.tar.gz"
fi
echo $fileName
if [[ $(wget -S --spider $fileName 2>&1 | grep 'HTTP/1.1 200 OK') ]]; then
  echo "Subnet-evm version found."
else
  echo "Unable to find Subnet-evm version $version. Exiting."
  if [ "$foundAvalancheGo" = "true" ]; then
    echo "Restarting service..."
    sudo systemctl start avalanchego
  fi
  exit
fi
echo "Attempting to download: $fileName"
wget -nv --show-progress $fileName
echo "Unpacking node files..."

tar xvf subnet-evm_*.tar.gz
rm subnet-evm_*.tar.gz
cp subnet-evm ~/avalanche-node/plugins/$vm_id
echo "Node files unpacked into $HOME/avalanche-node/plugins/$vm_id"
echo
if [ "$foundAvalancheGo" = "true" ]; then
  echo "Node upgraded, starting service..."
  sudo systemctl start avalanchego
  echo "New subnet-evm version: $version"
  echo "Done!"
  exit
fi
