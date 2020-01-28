Param(
  [string] [Parameter(Mandatory=$true)] $alias

)
Login-azAccount

Write-Host 'Please log into Azure now' -foregroundcolor Green;
Login-azaccount

$Subscription = (Get-azSubscription) |Select Name, Id | Out-GridView -Title "Select Azure Subscription " -PassThru

$sub=Select-azSubscription -SubscriptionName $Subscription.Name


$hash1 = @{ alias = $alias}


#create image template
New-AzResourceGroupDeployment -Name task1-vmimage -ResourceGroupName "$($alias+'-vmimages-rg')" -TemplateFile .\task1.json -TemplateParameterObject $hash1

