# Login-AzureRmAccount

$azureAccount = "KevRem Azure"
# $azureAccount = "Visual Studio Ultimate with MSDN"

Login-AzureRmAccount
Get-AzureRmSubscription -SubscriptionName $azureAccount | Select-AzureRmSubscription 



$loc = "East US 2"

# collect digits for generating unique names

$rnd = Read-Host -Prompt "Please type some number for creating unique names, and then press ENTER."

$rgName = 'TestScaleSets' + $rnd

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

$moduleName = "xNetworking"
$moduleURI = $assetLocation + $moduleName + ".zip"


New-AzureRmResourceGroupDeployment -Name TestDeployment -ResourceGroupName $rgName `
    -TemplateFile .\azuredeploy.json `
    -TemplateParameterFile .\azuredeploy.parameters.json `
    -registrationKey ($RegistrationInfo.PrimaryKey | ConvertTo-SecureString -AsPlainText -Force) `
    -registrationUr $RegistrationInfo.Endpoint `
    -automationAccountName $autoAccountName `
    -jobid $NewGUID -Verbose `
    -moduleName = $moduleName `
    -moduleURI = $moduleURI
