Param(
  [string] [Parameter(Mandatory=$true)] $alias

)

Login-azAccount

Write-Host 'Please log into Azure now' -foregroundcolor Green;

$Subscription = (Get-azSubscription) |Select Name, Id | Out-GridView -Title "Select Azure Subscription " -PassThru

$sub=Select-azSubscription -SubscriptionName $Subscription.Name


$hash1 = @{ alias = $alias; managedImageResGroup = $($alias+'-vmimages-rg');imagegallery = $($alias+'imagegallery') ; imagegallerydef =$($alias+'-imagedef-linux')}


#create image template
New-AzResourceGroupDeployment -Name task1-vmimage -ResourceGroupName "$($alias+'-vmimages-rg')" -TemplateFile .\task2-sig.json -TemplateParameterObject $hash1

#create a hardened windows 2016 image
az resource invoke-action --resource-group $($alias+'-vmimages-rg') --resource-type  Microsoft.VirtualMachineImages/imageTemplates -n $($alias+'-task02') --action Run




