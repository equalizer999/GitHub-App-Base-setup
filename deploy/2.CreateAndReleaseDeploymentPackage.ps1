Param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $ResourceGroupName = "github-int-we-",

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $FunctionAppName    
)

# Validate parameters
## Test if resource group exists
$azGroup = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if ($null -eq $azGroup) {
    Write-Output "Resource group '$ResourceGroupName' does not exist"
    exit
}

## Test if function app exists
$azFunctionApp = Get-AzWebApp -ResourceGroupName $ResourceGroupName -Name $FunctionAppName -ErrorAction SilentlyContinue
if ($null -eq $azFunctionApp) {
    Write-Output "Function app '$FunctionAppName' does not exist"
    exit
}

# Init
$functionAppNameToLowerCase = $FunctionAppName.ToLowerInvariant()
$functionAppZipName = $functionAppNameToLowerCase + "-" + ((Get-Date).ToUniversalTime()).ToString('yyyyMMddHHmmss') + ".zip".ToLowerInvariant()

# Create function app archive
$excludeFilesAndFolders = @(".git",".vscode","bin","Microsoft",".funcignore",".gitignore") 
$fileToSendArray = @()

## Listing files to archive
foreach ($file in get-childitem -Path ..\src\functions) { 
    if ($file.name -notin $excludeFilesAndFolders) {
        $fileToSendArray += $file.fullname
    } 
}

## Create archive
Write-Host "Creating archive: '$functionAppZipName'"
Compress-Archive -Path $fileToSendArray -DestinationPath $functionAppZipName -Force -CompressionLevel Fastest
Write-Host "-> Done"

# break # TODO: Comment out this line to continue with the next step - debug only

# Deploy to Azure function app
Write-Host "Starting deploy for created archive to function app: '$functionAppNameToLowerCase' - This can take some time"

## Function app sources deployment
$funcAppArchivePath = "$PSScriptRoot/$functionAppZipName"

# Use Publish-AzWebapp cmdlet to upload the zip file to the function app
Publish-AzWebapp -ResourceGroupName $ResourceGroupName -Name $functionAppNameToLowerCase -ArchivePath $funcAppArchivePath -Force | Out-Null
Write-Host "-> Done"

# Print out details including function url
Write-Host ""
Write-Host "---------------------------------------------------"
Write-Host "ResourceGroupName: $ResourceGroupName"
Write-Host "FunctionAppName:   $functionAppName"
Write-Host "FunctionUrl:       https://$functionAppNameToLowerCase.azurewebsites.net/api/http-webhook-receive"
Write-Host "---------------------------------------------------"
