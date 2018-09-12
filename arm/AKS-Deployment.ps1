Write-Host ""
Write-Host "Azure AKS Deployment"
Write-Host "Version 1.1.0"
Write-Host ""
Write-Host ""

#Install and Import AzureRM Module
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Importing module..."
Import-Module -Name AzureRM.NetCore -ErrorVariable ModuleError -ErrorAction SilentlyContinue
If ($ModuleError) {
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Installing module..."
    Install-Module -Name AzureRM.NetCore
    Import-Module -Name AzureRM.NetCore
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Installed module..."
}
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Imported module"
Write-Host ""

#Login to Azure
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Logging in to Azure Account..."
Login-AzureRmAccount
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully logged in to Azure Account"
Write-Host ""


#Select SubscriptionId
$SubId = Read-Host "Please input your Subscription Id"
while ($SubId.Length -le 35) {
    Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Subscription Id not valid"
    $SubId = Read-Host "Please input your Subscription Id"
}
Select-AzureRmSubscription -SubscriptionId $SubId
Write-Host "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Subscription successfully selected"
Write-Host ""

#New or Existing Resource Group
while ($RGCheck -ne "Y" -and $RGCheck -ne "N") {
    $RGCheck = Read-Host "Are you deploying a New Resource Group (Y/N)"
    $RGCheck = ($RGCheck).ToUpper()
}
if ($RGCheck -eq "Y") {
    #Create Resource Group
    $RGName = Read-Host "Enter the new ResourceGroup Name"
    $Location = Read-Host "Enter the Location"
    New-AzureRmResourceGroup -Name $RGName -Location $Location
}
if ($RGCheck -eq "N") {
    $RGName = Read-Host "Enter the existing ResourceGroup Name"
}

#Deploy ARM Template for AKS Cluster and Resources
New-AzureRmResourceGroupDeployment -Name AKS -ResourceGroupName $RGName `
-TemplateFile './kubernetes/arm/AKS.deploy.json' `
-TemplateParameterFile './kubernetes/arm/AKS.parameters.json'