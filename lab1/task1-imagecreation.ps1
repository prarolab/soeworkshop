Param(
  [string] [Parameter(Mandatory=$true)] $alias

)
Login-azAccount

Write-Host 'Please log into Azure now' -foregroundcolor Green;
az login

$Subscription = (Get-azSubscription) |Select Name, Id | Out-GridView -Title "Select Azure Subscription " -PassThru


az account set -s $Subscription.id
az resource invoke-action --resource-group $($alias+'-vmimages-rg') --resource-type  Microsoft.VirtualMachineImages/imageTemplates -n $($alias+'-task01') --action Run

