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

# This Chef script will create the actian user ready for Vector installation  

#-------------------------------------------------------------------------------


# Setup the required user and user structure                   

user 'actian' do
  uid '400'
  home '/home/actian'
  manage_home true
  shell '/bin/bash'
end

directory '/home/actian/installer' do
  owner 'actian'
  mode 00700
  recursive true
end

directory '/home/actian/.ssh' do
  owner 'actian'
  mode 00700
  recursive true
end

file '/home/actian/.bashrc' do
  content <<-EOH
[ -f ~/.ingVHsh ] && source ~/.ingVHsh
EOH
  owner 'actian'
  mode 00700
end

#-------------------------------------------------------------------------------
# End of Chef ruby script
#-------------------------------------------------------------------------------
