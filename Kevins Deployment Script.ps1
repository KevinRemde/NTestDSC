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
$localAssets = "C:\Code\MyGitHub\NTestDSC\"

# Datacenter Region you want to use.  
# Note that some regions don't yet support Azure Automation. You'll get an error if you pick one of those.
$loc = "East US 2"

# Collect digit(s) for generating unique names
#
$rnd = Read-Host -Prompt "Please type some number for creating unique names, and then press ENTER."

$rgName = 'RG-WebScaleSet' + $rnd
$autoAccountName = 'webAutomation' + $rnd

New-AzureRmResourcegroup -Name $rgName -Location $loc -Verbose

New-AzureRMAutomationAccount -ResourceGroupName $rgName -Name $autoAccountName -Location $loc -Plan Free -Verbose

$RegistrationInfo = Get-AzureRmAutomationRegistrationInfo -ResourceGroupName $rgName -AutomationAccountName $autoAccountName

$NewGUID = [system.guid]::newguid().guid


# Setup variables for the local template and parameter files..
#
$templateFileLoc = $localAssets + "azuredeploy.json"
$parameterFileLoc = $localAssets + "azuredeploy.parameters.json"

# This deployment requires pulling remote files, either from Azure Storage (Shared Access Signature) or from a URL like Github.
#
$assetLocation = "https://raw.githubusercontent.com/KevinRemde/NTestDSC/master/"

$configuration = "WebServer.ps1"
$configurationName = "MyService"
$configurationURI = $assetLocation + $configuration

$moduleName = "xNetworking"
$moduleURI = $assetLocation + $moduleName + ".zip"

# Get a unique DNS name
#
$machine = "nex"
$uniquename = $false
$counter = 0
while ($uniqueName -eq $false) {
    $counter ++
    $dnsPrefix = "$machine" + "dns" + "$rnd" + "$counter" 
    if (Test-AzureRmDnsAvailability -DomainNameLabel $dnsPrefix -Location $loc) {
        $uniquename = $true
    }
} 


New-AzureRmResourceGroupDeployment -Name TestDeployment -ResourceGroupName $rgName `
    -TemplateFile $templateFileLoc `
    -TemplateParameterFile $parameterFileLoc `
    -domainNamePrefix $dnsPrefix `
    -registrationKey ($RegistrationInfo.PrimaryKey | ConvertTo-SecureString -AsPlainText -Force) `
    -registrationUr $RegistrationInfo.Endpoint `
    -automationAccountName $autoAccountName `
    -jobid $NewGUID `
    -moduleName $moduleName `
    -moduleURI $moduleURI `
    -configurationName $configurationName `
    -configurationURI $configurationURI `
    -Verbose 


# Remove-AzureRmResourceGroup -Name $rgName -Force