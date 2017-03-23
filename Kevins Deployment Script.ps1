# EDIT THIS!
# Put your subscription name in a variable.  
# This is really only needed if your credentials are authorized to access multiple subscriptions.  
# If you only have one subscription, a simple "Login-AzureRmAccount" command will suffice.
#
$azureAccount = "KevRem Azure"
# $azureAccount = "Visual Studio Ultimate with MSDN"

# Login
Login-AzureRmAccount
Get-AzureRmSubscription -SubscriptionName $azureAccount | Select-AzureRmSubscription 


# EDIT THIS!
# Set the path to where you've cloned the NTestDSC contents.
# Important: Make sure the path ends with the "\", as in "C:\Code\MyGitHub\NTestDSC\"
# $localAssets = "C:\Code\MyGitHub\NTestDSC\"

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
# $localAssets = "C:\Code\MyGitHub\NTestDSC\"
$assetLocation = "https://raw.githubusercontent.com/KevinRemde/NTestDSC/master/"

# Setup variables for the local template and parameter files..
#
# $templateFileLoc = $localAssets + "azuredeploy.json"
# $parameterFileLoc = $localAssets + "azuredeploy.parameters.json"

$templateFileLoc = $assetLocation + "azuredeploy.json"
# Not using a parameter file in this sample.
# $parameterFileLoc = $assetLocation + "azuredeploy.parameters.json"

$configuration = "AxonWebServer.ps1"
$configurationName = "AxonWebServer"
$nodeConfigurationName = $configurationName + ".localhost"
$configurationURI = $assetLocation + $configuration

$moduleName = "xNetworking"
$moduleURI = $assetLocation + $moduleName + ".zip"

# Get a unique DNS name
#
$machine = "kar"
$uniquename = $false
$counter = 0
while ($uniqueName -eq $false) {
    $dnsPrefix = "$machine" + "dns" + "$rnd" + "$counter" 
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

# For this deployment I use the github-based template file, parameter file, and additional parameters in the command.
# 
New-AzureRmResourceGroupDeployment -Name TestDeployment -ResourceGroupName $rgName `
    -TemplateUri $templateFileLoc `
    -TemplateParameterObject $parameterObject `
    -registrationKey ($RegistrationInfo.PrimaryKey | ConvertTo-SecureString -AsPlainText -Force) `
    -Verbose 


# later if you want, you can easily remove the resource group and all objects it contains.
#
# Remove-AzureRmResourceGroup -Name $rgName -Force 