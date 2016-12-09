# ====================================
# Calculate the name of a VM, ensuring uniqueness
#
# Change NUM_DIGITs to specify how many digits should be added to the end of a VM name
#
# NOTE - Designed for CloudForms 4.1 due to changes to Ruby on Rails ActiveRecord query methods
#
# @author:      Cameron Wyatt
# @email:       cameron.m.wyatt <at> gmail.com
# @last_update: 2016/12/08
# ====================================

NUM_DIGITS = 2

def log(level, msg)
  $evm.log(level,"#{msg}")
end

# log final name and update it on the object
def log_and_update_vm_name(new_vm_name, prov)
  $evm.object['vmname'] = new_vm_name
  log(:info, "VM Name to be saved:|#{new_vm_name}|")

  # set options related to VM hostname here
  log(:info, 'Setting hostname options on provisioning object')
  prov.set_option(:vm_target_name, new_vm_name)
  prov.set_option(:vm_target_hostname, new_vm_name)
  prov.set_option(:linux_host_name, new_vm_name)
end

# add unique identifier to the end of the VMs name
# the first index that has not yet been used will be added to the VM name
def get_vm_name(prov)
  log(:info, 'Calculating VM name')

  # Organization specific VM name customization goes here
  # do not include an index or the $n{} syntax
  prefix = 'test' #TODO: input logic for organization specific VM name customization

  # query for all VMs that match the prefix with NUM_DIGITS number of digits at the end
  # an empty array is returned if no VMs match
  vm_names_matching_prefix = $evm.vmdb(:vm).where('name ~ ?', "#{prefix}[0-9]{#{NUM_DIGITS}}").collect{|vm| vm.name}
  log(:info, "Found VMs matching naming convention:|#{vm_names_matching_prefix}|")

  # create a list of all indices from VMs that match the naming convention
  taken_indices = vm_names_matching_prefix.collect{|x| x.last(NUM_DIGITS).to_i}.sort

  # find the first index that hasn't been already used in a VM name
  # check in-flight provisions to ensure naming uniqueness
  # if the index hasn't been taken already, and there are no in-flight provisions with a conflicting name
  # then found a suitable name
  (1..("9"*NUM_DIGITS).to_i).each do |index|
    unless taken_indices.include?(index)
      vm_name_with_index = "#{prefix}#{index.to_s.rjust(NUM_DIGITS, '0')}"

      # if there are no in-flight provisions and this index hasn't been used before, we've found the name to give this VM
      log_and_update_vm_name(vm_name_with_index, prov) if $evm.vmdb(:miq_provision)
                                                          .where('state != ?', 'finished')
                                                          .none?{|task| task.get_option(:vm_target_name) == vm_name_with_index}
      break
    end
  end
end

begin
  #get prov from possible sources
  prov = $evm.root['miq_provision_request'] rescue nil
  prov ||= $evm.root['miq_provision'] rescue nil
  prov ||= $evm.root['miq_provision_request_template'] rescue nil

  # get task object in case we need to pull dialog options at this point in provision process
  task = $evm.root['service_template_provision_request'] rescue nil
  task ||= prov.miq_provision_request.miq_request rescue nil

  # get dialog options and tags and ws_values in case we need it for vm naming
  dialog_options = task.get_option(:dialog) rescue nil
  tags = prov.get_tags rescue nil
  ws_values = prov.get_option(:ws_values) rescue nil

  # get environment id selected from the dialog
  env = nil
  env ||= dialog_options['dialog_tag_0_environment'] if dialog_options
  env ||= tags[:environment] if tags

  vm_name = prov.get_option(:vm_name).to_s.strip

  if vm_name.blank? || vm_name == 'changeme'
    get_vm_name(prov)
  end

  log(:info, 'Finished selection of VM name')
  exit MIQ_OK

rescue => err
  # go back to default naming if we have an error
  log(:warn, "Reverting to default vm_name")
  log(:warn, "[#{err}]\n#{err.backtrace.join("\n")}")

  # inspect objects for debugging purposes
  log(:info, "Inspecting prov object: #{prov.inspect}") if prov
  log(:info, "Inspecting task object: #{task.inspect}") if task

  # log and update the vm name
  log_and_update_vm_name(vm_name, prov)

  # get errors variables (or create new hash) and set message
  message = 'Unable to successfully update VM name. VM Name may not be set correctly.'
  errors = prov.get_option(:errors) || {}

  # set hash with this method error
  errors[:vm_name_error] = message

  # set errors option
  prov.set_option(:errors, errors)

  exit MIQ_WARN
end
