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
# Actian Dataflow.
#     - Either RPM package or ZIP is acceptable.

#-------------------------------------------------------------------------------


# Variables for files and locations used

dataflow_rpm = `ls -t /tmp/actian-dataflow*.rpm 2> /dev/null | head -1 | tr -d "\n"`
dataflow_zip = `ls -t /tmp/actian-dataflow*.zip 2> /dev/null | head -1 | tr -d "\n"`

# If the DataFlow package is an RPM then install       

bash 'RPM install' do  
  code <<-EOH
    if [ '#{dataflow_rpm}' != '' ]; then 
      sudo rpm -i --prefix /home/actian/dataflow #{dataflow_rpm} 
    fi
  EOH
  cwd '/home/actian'
  user 'actian'
end

# If the DataFlow package is a ZIP then install       

bash 'ZIP install' do  
  code <<-EOH
    if [ '#{dataflow_zip}' != '' ]; then 
      unzip #{dataflow_zip}; 
      ln -s actian-dataflow* dataflow
    fi
  EOH
  cwd '/home/actian'
  user 'actian'
end

# Update login profile to set DataFlow environment

bash 'Set Environment' do  
  code <<-EOH
    if [ '#{dataflow_zip}' != '' -o '#{dataflow_rpm}' != '' ]; then 
      echo 'export PATH=$PATH:/home/actian/dataflow/bin' >> /home/actian/.bashrc
      echo 'export DR_HOME=/home/actian/dataflow' >> /home/actian/.bashrc
      echo 'export JAVA_HOME=/usr/lib/jvm/jre' >> /home/actian/.bashrc
    fi
  EOH
  cwd '/home/actian'
  user 'actian'
end

#-------------------------------------------------------------------------------
# End of Chef ruby script
#-------------------------------------------------------------------------------
