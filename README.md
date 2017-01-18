# NTestDSC
## Testing Scale Set w/AADSC
This repo holds sample Azure Resource Manager template files and PowerShell script for deploying a load-balanced scale-set of virtual machines in Azure.  It also creates an Azure Automation account and populates it with an Azure Automation DSC script, which is then applied to the machines in the scale set.

For our example, the DSC configures a web server, and also downloads and installs a file.


