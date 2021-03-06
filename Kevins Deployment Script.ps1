﻿# Login

Login-AzureRmAccount

$subscriptionId = 
    ( Get-AzureRmSubscription |
        Out-GridView `
            -Title "Select an Azure Subscription ..." `
            -PassThru
    ).SubscriptionId

$subscr = Select-AzureRmSubscription -SubscriptionId $subscriptionId


# EDIT THIS!
# Set the path to where you've cloned the NTestDSC contents.
# Important: Make sure the path ends with the "\", as in "C:\Code\MyGitHub\NTestDSC\"
 $localAssets = "C:\Code\MyGitHub\NTestDSC\"

# Datacenter Region you want to use.  
# Note that some regions don't yet support Azure Automation. You'll get an error if you pick one of those.
$loc = "East US 2"

# Collect digit(s) for generating unique names
#
$unique = Read-Host -Prompt "Please type some number for creating unique names, and then press ENTER."

$rgName = 'RG-WebScaleSet' + $unique
$autoAccountName = 'webAutomation' + $unique
$dscname = "dsc" + $unique

New-AzureRmResourcegroup -Name $rgName -Location $loc -Verbose

New-AzureRMAutomationAccount -ResourceGroupName $rgName -Name $autoAccountName -Location $loc -Plan Free -Verbose

$RegistrationInfo = Get-AzureRmAutomationRegistrationInfo -ResourceGroupName $rgName -AutomationAccountName $autoAccountName
$RegistrationKey = ConvertTo-SecureString -String $RegistrationInfo.PrimaryKey -AsPlainText -Force

$NewGUID = [system.guid]::newguid().guid

# This deployment requires pulling remote files, either from Azure Storage (Shared Access Signature) or from a URL like Github.
#
$assetLocation = "https://raw.githubusercontent.com/KevinRemde/NTestDSC/master/"

# Setup variables for the local template and parameter files..
#
$templateFileLoc = $localAssets + "azuredeploy.json"
# $parameterFileLoc = $localAssets + "azuredeploy.parameters.json"

$templateFileURI = $assetLocation + "azuredeploy.json"
# Not using a parameter file in this sample.
# $parameterFileLoc = $assetLocation + "azuredeploy.parameters.json"

$configuration = "WebServerDSC.ps1"
$configurationName = "WebServerDSC"
$nodeConfigurationName = $configurationName + ".localhost"
$configurationURI = $assetLocation + $configuration # Gets the configuration from the asset store.

$moduleName = "xNetworking"
$moduleURI = $assetLocation + $moduleName + ".zip"

# Get a unique DNS name
#
$machine = "webdns" + "$rnd"
$dnsPrefix = $machine
$uniquename = (Test-AzureRmDnsAvailability -DomainNameLabel $dnsPrefix -Location $loc)
$counter = 0
while ($uniqueName -eq $false) {
    $dnsPrefix = "$machine" + "$counter" 
    if (Test-AzureRmDnsAvailability -DomainNameLabel $dnsPrefix -Location $loc) {
        $uniquename = $true
    }
    $counter ++
} 


$parameterObject = @{
    "domainNamePrefix" = $dnsPrefix
    "vmssname" = $dscname
    "adminUserName" = "kevin"
    "registrationUrl" = $RegistrationInfo.Endpoint 
    "jobid" = "$NewGUID"
    "instanceCount" = 3
    "automationAccountName" = $autoAccountName
    "nodeConfigurationName" = $nodeConfigurationName
    "moduleName" = $moduleName
    "moduleURI" = $moduleURI
    "assetLocation" = $assetLocation
    "configurationName" = $configurationName
    "configurationURI" = $configurationURI
}

#
# For this deployment I use the local template file, and additional parameters in the command.
# 
<#
New-AzureRmResourceGroupDeployment -Name TestDeployment -ResourceGroupName $rgName `
    -TemplateFile $templateFileLoc `
    -TemplateParameterObject $parameterObject `
    -registrationKey ($RegistrationInfo.PrimaryKey | ConvertTo-SecureString -AsPlainText -Force) `
    -Verbose 
#>

# For this deployment I use the github-based template file and additional parameters in the command.
# 

New-AzureRmResourceGroupDeployment -Name TestDeployment -ResourceGroupName $rgName `
    -TemplateUri $templateFileURI `
    -TemplateParameterObject $parameterObject `
    -registrationKey ($RegistrationInfo.PrimaryKey | ConvertTo-SecureString -AsPlainText -Force) `
    -Verbose 


# later if you want, you can easily remove the resource group and all objects it contains.
#
# Remove-AzureRmResourceGroup -Name $rgName -Force 