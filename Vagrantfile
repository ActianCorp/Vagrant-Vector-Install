#-------------------------------------------------------------------------------

# Copyright 2015 Actian Corporation
 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
 
# http://www.apache.org/licenses/LICENSE-2.0
 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#-------------------------------------------------------------------------------

# Pre-requisites required before running this script:
#   1. Install Vagrant (Version 1.7.4 used constructing the above)
#   2. Install Oracle Virtual Box (5.0.4 or later) 
#   3. Enable hardware virtulaisation in the BIOS if it is disabled.

# This Vagrant script will perfom the following operations:
#   1. Create a Cento 6.7 Linux environment that is fully up to date.
#   2. Install, via Chef, Actian Vector previously downloaded.
#         - Requires an authstring
#         - Will also require a Public Key for RPM install.
#   3. Run the Actian DBT3 tests.
#   4. If present, install Actian DataFlow.

# The approach to using 'Chef' in this script may seem strange as the installation
# and chef-apply are performed via the "config.vm.provision 'shell' ...."
# This was intentional to create a generic script that would work for providers
# Oracle Virtual Box and Azure.
#     Using Azure 'chef_apply' will fail installing Chef. Even when Chef is manually
#     installed to circumvent this, it will then fail applying a Recipe even 
#     though it appears to complete successfully.

#-------------------------------------------------------------------------------

# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.box = 'box-cutter/centos67'

  # Provider - Virtual Box VM (Default)

  config.vm.provider :virtualbox do |vb, override|

    # Display the VirtualBox GUI when booting the machine
    vb.gui    = true
    
    # Give the VM an appropriate name
    vb.name   = 'VectorEvaluationVM'

    # Customize the amount of memory on the VM 
    vb.memory = "4096"

    # Use 4 CPUs for Vector
    #vb.cpus = '4'

    # Forward essential Vector ports to allow access from Host    

    # 1. Management Server Discovery port
    override.vm.network "forwarded_port", guest: 16902, host: 33902
    # 2. Management Server Command port (Actian Director)
    override.vm.network "forwarded_port", guest: 27712, host: 33712
    # 3. Communication Server port (GCC for IngresNet and ODBC)
    override.vm.network "forwarded_port", guest: 27719, host: 33719
    # 4. Data Access Server port (.Net and JDBC)
    override.vm.network "forwarded_port", guest: 44103, host: 33103

    # Forward terminal access port
    override.vm.network "forwarded_port", guest: 22, host: 33022

  end

  # Provider - Microsoft Azure VM
  #            Documented below are the settings that need to be changed as they are specific
  #            to youe Azure subscription. 

  config.vm.provider :azure do |azure, override|

    override.vm.box               = 'azure'

    override.ssh.private_key_path = 'azurevagrant.pem'
                                    # You can stick with the naming of this file but you must generate
                                    # your own.
    override.ssh.pty              = true
    override.vm.boot_timeout      = 1500

    # Vagrant share does not work for Azure provider.
    override.vm.synced_folder '.', '/vagrant', disabled: true

    # Mandatory Settings 
    azure.mgmt_certificate        = 'azurevagrant.pem'
                                    # See above.
    azure.mgmt_endpoint           = 'https://management.core.windows.net'
    azure.subscription_id         = '########-####-####-####-############'
                                    # Your Azure Account Subscription ID.
    azure.vm_image                = '5112500ae3b842c8b9c604889f8753c3__OpenLogic-CentOS-67-20150815'
    azure.vm_name                 = 'VectorEvaluationVM'

    azure.ssh_private_key_file    = 'azurevagrant.pem'
                                    # See above.

    # Optional Settings
    azure.cloud_service_name      = 'VectorEvaluationVM' 
    azure.vm_location             = 'North Europe'
                                    # You may wish to set this to something appropriate to your location.

    azure.ssh_port                = '22' 

    # Need larger than default Standard A1 Azuure VM to install and run Actian Vector
    azure.vm_size                 = 'Basic_A2' 

  end

# Common code from here. 

  if Vagrant.has_plugin?("vagrant-cachier")
    # Configure cached packages to be shared between instances of the same base box.
    # More info on http://fgrehm.viewdocs.io/vagrant-cachier/usage
    config.cache.scope = :box
  end

  config.vm.provision 'shell', name: 'OS Updates', privileged: true, inline: <<-SHELL
    echo never > /sys/kernel/mm/transparent_hugepage/enabled
    sed -i \'s/^SELINUX=.*$/SELINUX=disabled/\' /etc/selinux/config
    yum -y update
    # Required for DBT3 Scripts
    yum -y install git gcc time
    # Required for Vector
    yum -y install libaio
    # Required for Vector rpm 
    yum -y install libX11 libXext libXi libXrender libXtst alsa-lib
    # Required for DataFlow 
    yum -y install unzip java-1.7.0-openjdk.x86_64
  SHELL

# Upload the required files for the Vector install
# This approach taken as Azure does not allow access to /vagrant share

  config.vm.provision 'file', source: 'authstring', destination: '/tmp/authstring'

  Dir['actian-vector*.tgz'].each do |file_name|
    config.vm.provision :file do |file|
      file.source = file_name
      file.destination = '/tmp/' + File.basename(file_name)
    end
  end

  Dir['actian-vector*.asc'].each do |file_name|
    config.vm.provision :file do |file|
      file.source = file_name
      file.destination = '/tmp/' + File.basename(file_name)
    end
  end

# Upload the required files for the DataFlow install

  Dir['actian-dataflow*.*'].each do |file_name|
    config.vm.provision :file do |file|
      file.source = file_name
      file.destination = '/tmp/' + File.basename(file_name)
    end
  end

# Upload Chef Recipes (Run locally to circumvent Azure problem)

  config.vm.provision 'file', source: 'actian-user.rb', destination: '/tmp/actian-user.rb'

  config.vm.provision 'file', source: 'vector-installer.rb', destination: '/tmp/vector-installer.rb'

  config.vm.provision 'file', source: 'dataflow-installer.rb', destination: '/tmp/dataflow-installer.rb'

# Install Chef (Circumvent auto install as problematic for Azure)

  config.vm.provision 'shell', name: 'Install Chef', privileged: true, inline: <<-SHELL
    curl -L https://www.opscode.com/chef/install.sh | bash > /tmp/chef_install.log 2>&1
  SHELL

# Create the Actian Linux user ('chef_apply' fails for Azure)
# Separate from Vector install so user can be given sudo access to uploaded files

  config.vm.provision 'shell', name: 'Create Actian User', privileged: true, inline: <<-SHELL
    chef-apply /tmp/actian-user.rb
  SHELL

# Set the Actian Linux user password

  config.vm.provision 'shell', name: 'Set Actian Password', privileged: true, inline: <<-SHELL
    echo -e "actian\nactian" | passwd actian > /tmp/passwd_set.log 2>&1
  SHELL

# Give Actian sudo access with NOPASSWD (Required for DBT3 Test Suite)

  config.vm.provision 'shell', name: 'Grant Actian sudo', privileged: true, inline: <<-SHELL
    echo 'actian ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/actian
  SHELL

# Install Vector ('chef_apply' fails for Azure)

  config.vm.provision 'shell', name: 'Install Vector', privileged: true, inline: <<-SHELL
    chef-apply /tmp/vector-installer.rb
  SHELL

# Stop Vector. Good practise to restart as started by root after install

  config.vm.provision 'shell', name: 'Stop Vector', privileged: true, inline: <<-SHELL
    sudo su - actian -c 'ingstop > /tmp/ingstop.log 2>&1'
  SHELL

# Always Start Vector. Required on VM start as well as initial restart after install hence 'always'

  config.vm.provision 'shell', name: 'Start Vector', run: 'always', privileged: true, inline: <<-SHELL
    sudo su - actian -c 'ingstart > /tmp/ingstart.log 2>&1'
  SHELL

# Set Actian DBMS password for JDBC/ODBC/Net Access (DBMS Authentication on by default)

  config.vm.provision 'shell', name: 'Set Actian DBMS Password', privileged: true, inline: <<-SHELL
    sudo su - actian -c 'sql iidbdb < /tmp/DBMS_Password_Set > /tmp/DBMS_Password_Set.log 2>&1'
  SHELL

# Download and Run the DBT3 Test Suite 

  config.vm.provision 'shell', name: 'DBT3 Test Suite', privileged: true, inline: <<-SHELL
    cd /home/actian
    if [ ! -d VectorH-DBT3-Scripts ]; then
      su actian -c 'git clone -q https://github.com/ActianCorp/VectorH-DBT3-Scripts'
      su - actian -c 'cd VectorH-DBT3-Scripts;chmod 755 *.sh;./load-run-dbt3-benchmark.sh > /tmp/load-run-dbt3-benchmark.log 2>&1'
    fi
  SHELL

# Install DataFlow (If download present)

  config.vm.provision 'shell', name: 'Install DataFlow', privileged: true, inline: <<-SHELL
    chef-apply /tmp/dataflow-installer.rb
  SHELL

end

#-------------------------------------------------------------------------------
# End of Vagrant script
#-------------------------------------------------------------------------------
