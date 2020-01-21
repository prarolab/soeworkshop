Param(
  [string] [Parameter(Mandatory=$true)] $alias
)

$vmimagerg =$alias+'-vmimages-rg'

Write-Host 'Please log into Azure now' -foregroundcolor Green;
Login-AzureRmAccount

$Subscription = (Get-AzureRmSubscription) |Select Name, Id | Out-GridView -Title "Select Azure Subscription " -PassThru

$sub=Select-AzureRmSubscription -SubscriptionName $Subscription.Name

New-AzureRmResourceGroupDeployment -Name "SOE-Lab1-VMDeployment" -ResourceGroupName $vmimagerg -TemplateFile https://msreadylabs.blob.core.windows.net/workshop/Lab2-SoeVM-WestUS.json -TemplateParameterObject @{"alias"=$alias}

