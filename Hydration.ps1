Param(
  [string] [Parameter(Mandatory=$true)] $alias,
  [string] [Parameter(Mandatory=$true)] $adminpassword
)


$outputpath =".\hydrationoutput.txt"

Write-Host 'Please log into Azure now' -foregroundcolor Green;
Login-azAccount 

$Subscription = (Get-azSubscription) |Select Name, Id | Out-GridView -Title "Select Azure Subscription " -PassThru

$sub=Select-azSubscription -SubscriptionName $Subscription.Name

$aadAppName =$alias +"msreadylabapp"

$defaultHomePage ="http://"+"$aadAppName"
$IDENTIFIERURI =[string]::Format("http://localhost:8080/{0}",[Guid]::NewGuid().ToString("N"));
$keyvaultrg =$alias+'-keyvault-rg'
$networkrg =$alias+'-network-rg'
$acrrg =$alias+'-container-rg'
$keyvaultName =$alias +'-akeyvault'
#$omsname=$alias+'-omsready'
#$omsrg= $alias+'-oms-rg'
$location ="East US"
$aadClientSecret = "@abcdefgh123456789"
$vmimagerg =$alias+'-vmimages-rg'
$imagegalname = $alias+'imagegallery'
$imagegaldeflin= $alias +'-imagedef-linux'
$imagegaldefwin= $alias +'-imagedef-win'
$imagepub =$alias +'-myimages'

$strrg =$alias+'-vmimages-rg'
$str=$alias +'storageac001'

$acr=$alias +'acr01'

######-Account Variables
$aztenantid=$sub.Subscription.TenantId
$azsubid=$sub.Subscription.Id

$aadClientSecret = "@abcdefgh123456789";
        $aadClientsecureSecret=ConvertTo-SecureString -String $aadClientSecret -AsPlainText -Force

Register-azProviderFeature -FeatureName GalleryPreview -ProviderNamespace Microsoft.Compute
Register-azResourceProvider -ProviderNamespace Microsoft.Compute
Register-azProviderFeature -FeatureName VirtualMachineTemplatePreview -ProviderNamespace Microsoft.VirtualMachineImages
Register-azResourceProvider -ProviderNamespace Microsoft.VirtualMachineImages
Register-azResourceProvider -ProviderNamespace Microsoft.Keyvault
Register-azResourceProvider -ProviderNamespace Microsoft.Storage
Register-azResourceProvider -ProviderNamespace Microsoft.Network

#Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'


Import-Module Az.Compute


$function =@("keyvault","network","vmimages","jumpbox","container")

        foreach ($rg in $function)

            {

                $rgname = $alias +'-'+ $rg+'-rg'
                New-azResourceGroup -Name $rgname -Location $Location -Force | Out-Null
                Write-Host "Created Resource Group $rgname" -BackgroundColor Green -ForegroundColor DarkBlue 

            }

# Check if AAD app with $aadAppName was already created
    $SvcPrincipals = (Get-azADServicePrincipal -SearchString $aadAppName);
    if(-not $SvcPrincipals)
    {
        # Create a new AD application if not created before
        
        $now = [System.DateTime]::Now;
        $oneYearFromNow = $now.AddYears(1);
        

        Write-Host "Creating new AAD application ($aadAppName)";
        $ADApp = New-azADApplication -DisplayName $aadAppName -HomePage $defaultHomePage -IdentifierUris $identifierUri  -StartDate $now -EndDate $oneYearFromNow -Password $aadClientsecureSecret;
        $servicePrincipal = New-azADServicePrincipal -ApplicationId $ADApp.ApplicationId;
        $SvcPrincipals = (Get-azADServicePrincipal -SearchString $aadAppName);
        if(-not $SvcPrincipals)
        {
            # AAD app wasn't created 
            Write-Error "Failed to create AAD app $aadAppName. Please log-in to Azure using Login-azAccount  and try again";
            return;
        }
        $aadClientID = $servicePrincipal.ApplicationId;
        Write-Host "Created a new AAD Application ($aadAppName) with ID: $aadClientID ";
    }
    else
    {


       $aadClientID = $SvcPrincipals[0].ApplicationId;
    }



 Try
        {
            $resGroup = Get-azResourceGroup -Name $keyvaultrg -ErrorAction SilentlyContinue;
        }
    Catch [System.ArgumentException]
        {
            Write-Host "Couldn't find resource group:  ($keyvaultrg)";
            $resGroup = $null;
        }
    
    #Create a new resource group if it doesn't exist
    if (-not $resGroup)
        {
            Write-Host "Creating new resource group:  ($keyvaultrg)";
            $resGroup = New-azResourceGroup -Name $keyvaultrg -Location $location;
            Write-Host "Created a new resource group named $keyvaultrg to place keyVault";
        }
    
    Try
        {
            $keyVault = Get-azKeyVault -VaultName $keyvaultName -ErrorAction SilentlyContinue;
        }
    Catch [System.ArgumentException]
        {
            Write-Host "Couldn't find Key Vault: $keyVaultName";
            $keyVault = $null;
        }
    
    #Create a new vault if vault doesn't exist
    if (-not $keyVault)
        {
            Write-Host "Creating new key vault:  ($keyVaultName)";
            $keyVault = New-azKeyVault -VaultName $keyVaultName -ResourceGroupName $keyvaultrg -Sku Standard -Location $location;
            Write-Host "Created a new KeyVault named $keyVaultName to store encryption keys";
        }
    # Specify privileges to the vault for the AAD application - https://msdn.microsoft.com/en-us/library/mt603625.aspx
    Set-azKeyVaultAccessPolicy -VaultName $keyVaultName -ServicePrincipalName $aadClientID -PermissionsToKeys wrapKey -PermissionsToSecrets set;

    Set-azKeyVaultAccessPolicy -VaultName $keyVaultName -EnabledForDiskEncryption -EnabledForTemplateDeployment;

    $diskEncryptionKeyVaultUrl = $keyVault.VaultUri;
	$keyVaultResourceId = $keyVault.ResourceId;

    $seckey1=ConvertTo-SecureString -String $adminpassword -AsPlainText -Force
    Set-AzKeyVaultSecret -Name adminpassword -SecretValue $seckey1 -VaultName $keyvaultName 




    Try
        {
            $resGroup = Get-azResourceGroup -Name $vmimagerg -ErrorAction SilentlyContinue;
        }
    Catch [System.ArgumentException]
        {
            Write-Host "Couldn't find resource group:  ($vmimagerg)";
            $resGroup = $null;
        }
    
    #Create a new resource group if it doesn't exist
    if (-not $resGroup)
        {
            Write-Host "Creating new resource group:  ($vmimagerg)";
            $resGroup = New-azResourceGroup -Name $vmimagerg -Location $location;
            Write-Host "Created a new resource group named $vmimagerg to place keyVault";
        }
    
    Try
        {
            $imagegal = Get-azGallery -ResourceGroupName $vmimagerg -Name $imagegalname -ErrorAction SilentlyContinue
        }
    Catch [System.ArgumentException]
        {
            Write-Host "Couldn't find Shared Image Gallery: $imagegalname";
            $imagegal = $null;
        }
    
     #Create a new Shared Image Gallery if vault doesn't exist
    if (-not $imagegal)
        {
            Write-Host "Creating new Shared Image Gallery:  ($imagegalname)";
          
              $gallery = New-azGallery `
                           -GalleryName $imagegalname `
                           -ResourceGroupName $vmimagerg `
                           -Location $location `
                           -Description 'Shared Image Gallery for my organization'
            
            Write-Host "Created a new Shared Image Gallery named $imagegalname to store VM Images";
        }


        Try
        {
            $imagegaldef1 = Get-azGalleryImageDefinition -ResourceGroupName  $vmimagerg -GalleryName $imagegalname -Name $imagegaldeflin -ErrorAction SilentlyContinue
        }
            Catch [System.ArgumentException]
        {
            Write-Host "Couldn't find Gallery Definition: $imagegaldeflin";
            $imagegaldef1 = $null;
        }
    
     #Create a new Shared Image Gallery if vault doesn't exist
    if (-not $imagegaldef1)
        {
            Write-Host "Creating new Shared Image Gallery Definition for Linux:  ($imagegaldeflin)";
                          $galleryImagelinux = New-azGalleryImageDefinition `
                                               -GalleryName $imagegalname `
                                               -ResourceGroupName $vmimagerg `
                                               -Location $location `
                                               -Name $imagegaldeflin `
                                               -OsState generalized `
                                               -OsType Linux `
                                               -Publisher $imagepub `
                                               -Offer 'rhel75' `
                                               -Sku 'gold'
            
            Write-Host "Created a new Shared Image Gallery Definittion named $imagegaldeflin to store VM Images";
        }

         Try
        {
            $imagegaldef2 = Get-azGalleryImageDefinition -ResourceGroupName  $vmimagerg -GalleryName $imagegalname -Name $imagegaldefwin -ErrorAction SilentlyContinue
        }
            Catch [System.ArgumentException]
        {
            Write-Host "Couldn't find Gallery Definition: $imagegaldefwin";
            $imagegaldef2 = $null;
        }
    
     #Create a new Shared Image Gallery if vault doesn't exist
    if (-not $imagegaldef2)
        {
            Write-Host "Creating new Shared Image Gallery Definition for Linux:  ($imagegaldefwin)";
                          $galleryImagewin = New-azGalleryImageDefinition `
                                               -GalleryName $imagegalname `
                                               -ResourceGroupName $vmimagerg `
                                               -Location $location `
                                               -Name $imagegaldefwin `
                                               -OsState generalized `
                                               -OsType Linux `
                                               -Publisher $imagepub `
                                               -Offer 'win19' `
                                               -Sku 'gold'
            
            Write-Host "Created a new Shared Image Gallery Definittion named $imagegaldefwin to store VM Images";
        }

$scope2 = '/subscriptions/' + $azsubid
New-azRoleAssignment  -ApplicationId $aadClientID -RoleDefinitionName Contributor -Scope $scope2



# Create a Container registry

    Try
        {
            $acrobj = Get-AzContainerRegistry -ResourceGroupName $acrrg -Name $acr -ErrorAction SilentlyContinue
        }
    Catch [System.ArgumentException]
        {
            Write-Host "Couldn't find Azure Container Registry: $acr";
            $acrobj = $null;
        }
    
     #Create a new Shared Image Gallery if vault doesn't exist
    if (-not $acrobj)
        {
            Write-Host "Creating new azure container registry:  ($acr)";
          
              $registry = New-AzContainerRegistry `
                           -Name $acr `
                           -ResourceGroupName $acrrg `
                           -EnableAdminUser `
                           -Sku Premium 
            
            Write-Host "Created a new Azure Container registry named $acr ";
        }
	
	
	
	  Try
        {
            $acrstr = Get-Azstorageaccount -ResourceGroupName $strrg -Name $str -ErrorAction SilentlyContinue
        }
    Catch [System.ArgumentException]
        {
            Write-Host "Couldn't find Azure Storage Account: $str";
            $acrstr = $null;
        }
    
     #Create a new Shared Image Gallery if vault doesn't exist
    if (-not $acrstr)
        {
            Write-Host "Creating new azure container registry:  ($str)";
          
              $storage = New-Azstorageaccount `
                           -Name $str `
                           -ResourceGroupName $strrg `
                           -location 'eastus' `
                           -Skuname Standard_LRS 
            
            Write-Host "Created a new Azure Storage Account named $str ";
        }
	
	

New-AzRoleAssignment -ObjectId ef511139-6170-438e-a6e1-763dc31bdf74 -Scope /subscriptions/$azsubid/resourceGroups/$vmimagerg -RoleDefinitionName Contributor

Write-Host "`t Hydration execution in progress but You can proceed with labs" -foregroundcolor Green;

    


New-azResourceGroupDeployment -Name "Vnet-Deployment02" -ResourceGroupName $networkrg -TemplateUri 'https://raw.githubusercontent.com/prarolab/soephase2/master/Task2/artefacts/lab2westus/WestUS-network.json' -TemplateParameterObject @{"alias"=$alias}


New-azResourceGroupDeployment -Name "Vnet-Deployment" -ResourceGroupName $networkrg -TemplateUri 'https://msreadylabs.blob.core.windows.net/workshop/azuredeployCopy.json' -TemplateParameterObject @{"alias"=$alias}

New-azResourceGroupDeployment -Name "devopsagent" -ResourceGroupName $networkrg -TemplateUri 'https://msreadylabs.blob.core.windows.net/workshop/azuredevopsagent.json' -TemplateParameterObject @{"alias"=$alias}


if((Test-Path  $outputpath) -eq 'True' )
        {
            Clear-Content $outputpath
        }
        Write-Output "aadClientID ----------" |Out-File $outputpath -Append 
        $aadClientID.Guid |Out-File $outputpath -Append
        Write-Output "`t`r`n AzureAD Client Secret ---------->>" |Out-File $outputpath -Append
        $aadClientSecret|Out-File $outputpath -Append
         Write-Output "`t`r`n Subscription Id---------->>" |Out-File $outputpath -Append
        $azsubid|Out-File $outputpath -Append
        Write-Output "`t`r`n Azure Tenant Id---------->>" |Out-File $outputpath -Append
        $aztenantid|Out-File $outputpath -Append
        Write-Output "`r`n Keyvault Name  ---------->>>>" |Out-File $outputpath -Append
        $keyvaultName|Out-File $outputpath -Append

Start $outputpath

Write-Host "Please note  AzureADClientId, ,ClientSecret, Subcription and Tenant detail. Refer $outputpath  " -foregroundcolor Green;
    Write-Host "`t aadClientID: $aadClientID" -foregroundcolor Green;
 Write-Host "`t aadClientSecret: $aadClientSecret " -foregroundcolor Green;
 Write-Host "`t TenantId: $aztenantid" -foregroundcolor Green;
 Write-Host "`t SubscriptionId: $azsubid" -foregroundcolor Green;
    Write-Host "`t keyVaultNAme: $keyvaultName" -foregroundcolor Green;


    
