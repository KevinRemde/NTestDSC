# Sign into Azure
$azureAccount = "KevRem Azure"

Login-AzureRmAccount
Get-AzureRmSubscription -SubscriptionName $azureAccount | Select-AzureRmSubscription 
# Get-AzureRmSubscription -SubscriptionName "Visual Studio Ultimate with MSDN" | Select-AzureRmSubscription 


# collect initials for generating unique names

$init = Read-Host -Prompt "Please type your initials in lower case, and then press ENTER."


# Prompt for the Azure region in which to build the lab machines

<#
Write-Host ""
Write-Host "Where in the world do you want to put this?"
Write-Host "Carefully enter 'East US' or 'West US'"
$loc = Read-Host -Prompt "and then press ENTER."
#>

# Variables 

$rgName = "RG-VMSS" + $init

# Use these if you want to drive the deployment from local template and parameter files..
#
$localAssets = "C:\Code\MyGitHub\NTestDSC\NTestDSC\"
$templateFileLoc = $localAssets + "azuredeploy.json"
# $parameterFileLoc = $localAssets + "azuredeploy.parameters.json"

# Use these if you want to drive the deployment from Github-based template. 
#
# $assetLocation = "https://rawgit.com/KevinRemde/20161115/master/" 
# If the rawgit.com path is not available, you can try un-commenting the following line instead...
# 
# $assetLocation = "https://cgiresources.blob.core.windows.net/files/"
$assetLocation = "https://raw.githubusercontent.com/KevinRemde/NTest/master/"
$templateFileURI  = $assetLocation + "azuredeploy.json"
# $parameterFileURI = $assetLocation + "azuredeploy.parameters.json" # Use only if you want to use Kevin's defaults (not recommended)


# Use Test-AzureRmDnsAvailability to create and verify unique DNS names.	
#
# Based on the initials entered, find unique DNS names for the four virtual machines.
# NOTE: You may be wondering why I'm not also looking for unique storage account names.  
# Those names are created by the template using randomly generated complex names, based on 
# the resource group ID.

$loc = "East US"


<#
$machine = "webhost"
$uniquename = $false
$counter = 0
while ($uniqueName -eq $false) {
    $counter ++
    $dnsPrefix = "$machine" + "dns" + "$init" + "$counter" 
    if (Test-AzureRmDnsAvailability -DomainNameLabel $dnsPrefix -Location $loc) {
        $uniquename = $true
        $webServerDNSVMName = $dnsPrefix
    }
} 

$machine = "workflowhost"
$uniquename = $false
$counter = 0
while ($uniqueName -eq $false) {
    $counter ++
    $dnsPrefix = "$machine" + "dns" + "$init" + "$counter" 
    if (Test-AzureRmDnsAvailability -DomainNameLabel $dnsPrefix -Location $loc) {
        $uniquename = $true
        $fileServerDNSVMName = $dnsPrefix
    }
} 

#>



# Create the resource group

New-AzureRMResourceGroup -Name $rgname -Location $loc

$automationAccountName = "nAutomation" + $init

New-AzureRMAutomationAccount -ResourceGroupName $rgname -Name $automationAccountName -Location 'East US 2' -Verbose

$RegistrationInfo = Get-AzureRmAutomationRegistrationInfo -ResourceGroupName $rgname -AutomationAccountName $automationAccountName

$NewGUID = [system.guid]::newguid().guid

# Populate the parameter object with parameter values for the azuredeploy.json template to use.
$registrationKey = ($RegistrationInfo.PrimaryKey | ConvertTo-SecureString -AsPlainText -Force)

$parameterObject = @{
    "domainNamePrefix" = "kar20161122"
    "vmssName" = "karvmss"
    "vmSku" = "Standard_A2"
    "adminUsername" = "NAdmin"
    "adminPassword" = "Passw0rd!"  # comment out to be prompted for secured-string password at deployment time
    "windowsOSVersion" = "2012-R-Datacenter"
    "instanceCount" = 3
    "registrationKey" = $RegistrationInfo.PrimaryKey
    "registrationUrl" = $RegistrationInfo.Endpoint
    "automationAccountName" = $automationAccountName
    "jobid" = $NewGUID.ToString()
}


# Build the lab machines. 
# Note: takes approx. 30 minutes to complete.

Write-Host ""
Write-Host "Deploying the VMs.  This will take several minutes to complete."
Write-Host "Started at" (Get-Date -format T)
Write-Host ""

# THIS IS THE MAIN ONE YOU'LL launch to pull the template file from the repository, and use the created parameter object.
# Measure-Command -expression {New-AzureRMResourceGroupDeployment -ResourceGroupName $rgName -TemplateUri $templateFileURI -TemplateParameterObject $parameterObject}

# use only if you want to use a LOCAL copy of the template file.
Measure-Command -expression {New-AzureRmResourceGroupDeployment -Name TestDeployment -ResourceGroupName $rgname -TemplateFile $templateFileLoc -TemplateParameterObject $parameterObject}

# use only if you want to use Kevin's default parameters (not recommended)
# New-AzureRMResourceGroupDeployment -ResourceGroupName $rgName -TemplateUri $templateFileURI -TemplateParameterUri $parameterFileURI

Write-Host ""
Write-Host "Completed at" (Get-Date -format T)


# MORE EXAMPLES of what you may want to run later...

# Shut down all lab VMs in the Resource Group when you're not using them.
# Get-AzureRmVM -ResourceGroupName $rgName | Stop-AzureRmVM -Force

# Restart them when you're continuing the lab.
# Get-AzureRmVM -ResourceGroupName $rgName | Start-AzureRmVM 


# Delete the entire resource group (and all of its VMs and other objects).
# Remove-AzureRmResourceGroup -Name $rgName -Force


