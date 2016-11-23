# Login-AzureRmAccount
#

$azureAccount = "KevRem Azure"
# $azureAccount = "Visual Studio Ultimate with MSDN"

Login-AzureRmAccount
Get-AzureRmSubscription -SubscriptionName $azureAccount | Select-AzureRmSubscription 



$loc = "East US 2"

# collect digits for generating unique names
#
$rnd = Read-Host -Prompt "Please type some number for creating unique names, and then press ENTER."

$rgName = 'TestScaleSet' + $rnd

$autoAccountName = 'myAutomation' + $rnd

New-AzureRmResourcegroup -Name $rgName -Location $loc -Verbose

New-AzureRMAutomationAccount -ResourceGroupName $rgName -Name $autoAccountName -Location $loc -Plan Free -Verbose

$RegistrationInfo = Get-AzureRmAutomationRegistrationInfo -ResourceGroupName $rgName -AutomationAccountName $autoAccountName

$NewGUID = [system.guid]::newguid().guid


# Use these if you want to drive the deployment from local template and parameter files..
#
$localAssets = "C:\Code\MyGitHub\NTestDSC\"
$templateFileLoc = $localAssets + "azuredeploy.json"
$parameterFileLoc = $localAssets + "azuredeploy.parameters.json"

# This deployment requires pulling remote files, either from Azure Storage (Shared Access Signature) or from a URL like Github.
#
$assetLocation = "https://raw.githubusercontent.com/KevinRemde/NTestDSC/master/"

$configuration = "AxonWebServer.ps1"
$configurationName = "AxonWebServer"
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
    -TemplateFile .\azuredeploy.json `
    -TemplateParameterFile .\azuredeploy.parameters.json `
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

    