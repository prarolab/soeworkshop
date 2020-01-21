Param(
  [string] [Parameter(Mandatory=$true)] $alias

)


Write-Host 'Please log into Azure now' -foregroundcolor Green;

$Subscription = (Get-azSubscription) |Select Name, Id | Out-GridView -Title "Select Azure Subscription " -PassThru

$sub=Select-azSubscription -SubscriptionName $Subscription.Name


$hash1 = @{ alias = $alias}

$alias = "praro2"

#create image template
New-AzResourceGroupDeployment -Name task1-vmimage -ResourceGroupName "praro2-vmimages-rg" -TemplateFile E:\Azure\ready20\task2\task1.json -TemplateParameterObject $hash1

#create a hardened windows 2016 image
az resource invoke-action --resource-group $($alias+'-vmimages-rg') --resource-type  Microsoft.VirtualMachineImages/imageTemplates -n praro2-task01 --action Run

