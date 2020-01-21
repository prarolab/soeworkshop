Param(
  [string] [Parameter(Mandatory=$true)] $alias
)

$vmimagerg =$alias+'-vmimages-rg'

Write-Host 'Please log into Azure now' -foregroundcolor Green;
#Login-azAccount

$Subscription = (Get-azSubscription) |Select Name, Id | Out-GridView -Title "Select Azure Subscription " -PassThru

$sub=Select-azSubscription -SubscriptionName $Subscription.Name


New-azResourceGroupDeployment -Name "SOE-Lab1-VMDeployment" -ResourceGroupName $vmimagerg -TemplateUri 'https://raw.githubusercontent.com/prarolab/soephase2/master/task1/artefacts/lab1-soevm.json' -TemplateParameterObject @{"alias"=$alias}

