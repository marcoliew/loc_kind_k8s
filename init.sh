# Update your package list
sudo apt update

# INstall Terraform

# Add HashiCorp GPG key
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add the HashiCorp Linux repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Update and install Terraform
sudo apt update && sudo apt install terraform


# INstall AWS CLI
# Download the installation script
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Unzip the installer
unzip awscliv2.zip

# Run the install
sudo ./aws/install

# Verify the installation
aws --version

# Cleanup
rm -rf awscliv2.zip


# Ansible

# Install software-properties-common if not installed (for managing PPAs)
sudo apt install software-properties-common

# Add the official Ansible PPA
sudo add-apt-repository --yes --update ppa:ansible/ansible

# Install Ansible
sudo apt install ansible

# version
ansible --version


# Velero

# Download the latest Velero release (replace version with the latest)
VELERO_VERSION=$(curl -s https://api.github.com/repos/vmware-tanzu/velero/releases/latest | grep tag_name | cut -d '"' -f 4)

# Download the Velero tar.gz for Linux
curl -LO https://github.com/vmware-tanzu/velero/releases/download/${VELERO_VERSION}/velero-${VELERO_VERSION}-linux-amd64.tar.gz

# Extract the tar.gz file
tar -xvf velero-${VELERO_VERSION}-linux-amd64.tar.gz

# Move the Velero binary to /usr/local/bin
sudo mv velero-${VELERO_VERSION}-linux-amd64/velero /usr/local/bin/

# Verify the Velero installation
velero version


# Istio

# Download the latest Istio release (replace version with the latest)
ISTIO_VERSION=$(curl -sL https://istio.io/latest | grep "The latest" | awk '{print $4}')

# Download the Istio tar.gz for the latest version
curl -L https://istio.io/downloadIstio | sh -

# Move into the Istio directory
cd istio-${ISTIO_VERSION}

# Move the istioctl binary to /usr/local/bin
sudo mv bin/istioctl /usr/local/bin/

# Verify the istioctl installation
istioctl version
