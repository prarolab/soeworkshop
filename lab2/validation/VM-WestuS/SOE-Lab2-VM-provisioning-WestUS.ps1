Param(
  [string] [Parameter(Mandatory=$true)] $alias
)

$vmimagerg =$alias+'-vmimages-rg'

Write-Host 'Please log into Azure now' -foregroundcolor Green;
Login-AzAccount

$Subscription = (Get-AzSubscription) |Select Name, Id | Out-GridView -Title "Select Azure Subscription " -PassThru

$sub=Select-AzSubscription -SubscriptionName $Subscription.Name

New-AzResourceGroupDeployment -Name "SOE-Lab2-VMDeployment" -ResourceGroupName $vmimagerg -TemplateUri "https://raw.githubusercontent.com/prarolab/soephase2/master/Task2/artefacts/lab2westus/lab2vm-westus.json" -TemplateParameterObject @{"alias"=$alias}

