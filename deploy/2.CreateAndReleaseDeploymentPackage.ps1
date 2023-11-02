Param(
    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $ResourceGroupName = "github-int-we-",

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $FunctionAppName    
)


# Init
$funcappZipName = $FunctionAppName + ((Get-Date).ToUniversalTime()).ToString('yyyyMMddHHmmss') + ".zip".ToLowerInvariant()

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
Write-Host "Creating archive: '$funcappZipName'"
Compress-Archive -Path $fileToSendArray -DestinationPath $funcappZipName -Force -CompressionLevel Fastest
Write-Host "-> Done"

break # TODO: Remove this line to continue with the next step - debug only

# Deploy to Azure function app
Write-Host "Deploying created archive to function app: '$FunctionAppName'"

## Function app sources deployment
$funcAppArchivePath = "$PSScriptRoot\$funcappZipName"

Write-Host "Deploy function app sources (from '$archivePath') - This can take some time"
Publish-AzWebapp -ResourceGroupName $ResourceGroupName -Name $FunctionAppName -ArchivePath $funcAppArchivePath -Force | Out-Null
Write-Host "-> Done"

## Show details
Write-Host ""
Write-Host "------------------------------"
Write-Host "WEBHOOK_URL: https://$FunctionAppName.azurewebsites.net/api/http-webhook-receive"
Write-Host "------------------------------"