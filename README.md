# CFME-Automate-Utilities
A collection of methods and utilities for CloudForms Automate

## Using these methods
Prereqs - all done on the database appliance within your CloudForms region
* Ensure the CloudForms database is configured and running
* Navigate to the (rhtconsulting/cfme-rhconsulting-scripts repo)[https://github.com/rhtconsulting/cfme-rhconsulting-scripts] and download and install the scripts. 

```sh
$ git clone https://github.com/Cameronwyatt/CFME-Automate-Utilities.git
$ miqimport domain Utilities </path/to/CFME-Automate-Utilities> 
```

## Utilities / Infrastructure / VM / Provisioning / Naming / vmname
This method calculates a unique name for a VM. It queries the CloudForms VMDB for all VM names matching the user-customized variable `prefix` with the unique identifier of digits 0-9 repeated `NUM_DIGIT` times added to the end. For example, if `prefix` is set to `test` and `NUM_DIGITS` is set to `2`, it will query the database for all VMs named `prefix00` through `prefix99`. This is done using a regular expression and the Ruby on Rails ActiveRecord `where` method for efficiency purposes. This allows it to only execute one query against the database to find all names that match the specified format.

In addition, the method will query the CloudForms VMDB for any provision requests that are currently in-flight and make sure that the VM name being chosen does not conflict.

## Contributing
If interested in contributing anything to this repository, please create a pull request and it will be evaluated. 
