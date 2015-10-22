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

# This chef script will install a previously downloaded evaluation edition of 
# Actain Vector as installation VE in /opt/Actian/Vector.
#     - Either native package (ingbuild) or RPM is acceptable.

# The following files are required by this script and should have previously 
# been downloaded from Actian into the folder from which Vagrant was launched:
#    1. Vector Evaluation Installation download. This can be the native package
#       manager (ingbuild) or RPM format binaries:
#         e.g. actian-vector-4.2.1-190-eval-linux-ingbuild-x86_64.tgz
#              actian-vector-4.2.1-190-eval-linux-rpm-x86_64.tgz
#    2. Vector authorisation string in a file called 'authstring'
#       This will have been emailed to you when you registered for the evaluation
#       at http://bigdata.actian.com/Vector
#    3. If you downloaded the RPM the associated Public Key.
#         e.g. actian-vector-4.2.1-190-eval-linux-rpm-x86_64-key.asc

#-------------------------------------------------------------------------------


# Variables for files and locations used

vector_publickey_with_path = `ls -t /tmp/actian-vector*.asc 2> /dev/null | head -1 | tr -d "\n"`
vector_package_with_path   = `ls -t /tmp/actian-vector*.tgz 2> /dev/null | head -1 | tr -d "\n"`

vector_install_loc  = "/home/actian/installer/"
vector_installation = `ls -t /tmp/actian-vector*.tgz | head -1 | tr -d "\n" | sed "s@/tmp/@@g" | sed "s/.tgz//"`

installer  = ::File.join( vector_install_loc, vector_installation, "/express_install.sh" )
authstring = ::File.join( vector_install_loc, vector_installation, "/authstring" )
publickey  = ::File.join( vector_install_loc, vector_installation, "/publickey" )
rpm_loc    = ::File.join( vector_install_loc, vector_installation )

# Temporary file created here as problematic creating quoted text via Vagrant

file '/tmp/DBMS_Password_Set' do
  content <<-EOH
ALTER USER actian WITH PASSWORD = 'actian' 
\\p
\\g
\\q 
EOH
  owner 'actian'
  mode 00700
end

# Untar the Vector installation package - Can be ingbuild or RPM

execute "tar -xzf /tmp/actian-vector*.tgz" do
  cwd "#{vector_install_loc}"
  not_if { File.exist?("#{installer}") }
end

# Copy over the authstring - Should always exist

execute "cp /tmp/authstring #{authstring}" do end

# Copy over the RPM Public Key - If it exists

execute "if [ '#{vector_publickey_with_path}' != '' ]; then cp #{vector_publickey_with_path} #{publickey}; fi" do end

# Install the Public Key if applicable 

execute "rpm --import #{publickey}" do
  cwd "#{rpm_loc}"
  only_if { File.exist?("#{publickey}") }
end

# Install Vector

bash 'run installer' do  
  code <<-EOH
    #{installer} -acceptlicense /opt/Actian/Vector VH > /tmp/vector_install.log 2>&1
  EOH
  not_if { File.exist?('/opt/Actian/Vector/ingres/files/errlog.log') }
end

#-------------------------------------------------------------------------------
# End of Chef ruby script
#-------------------------------------------------------------------------------
