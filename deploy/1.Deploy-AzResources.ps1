Param(

    [string] $ResourceGroupLocation = 'East US',

    [string] $ResourceGroupName = "github-int-eus-231128",

    [string] $TemplateFile = "azuredeploy.json",

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $GitHubAppId,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string] $GitHubAppPrivateKeyPath,

    # Optional
    [string] $GitHubAppWebhookSecret
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

Write-Output "Reading contents from 'GitHubAppPrivateKeyPath'"

# Test if path for GitHubAppPrivateKeyPath exists
if (-not (Test-Path $GitHubAppPrivateKeyPath)) {
    Write-Output "GitHubAppPrivateKeyPath '$GitHubAppPrivateKeyPath' does not exist"
    exit
}

# Read GitHubAppPrivateKeyContent from file and convert to SecureString
$GitHubAppPrivateKeyContent = Get-Content $GitHubAppPrivateKeyPath -Raw
$GitHubAppPrivateKeyContentAsSecureString = ConvertTo-SecureString $GitHubAppPrivateKeyContent -AsPlainText -Force

Write-Host "-> Done"

# Test if GitHubAppWebhookSecret is set and not contains an empty string and convert that value to a SecureString
$GitHubAppWebhookSecretAsSecureString = $null
if ($null -ne $GitHubAppWebhookSecret -and $GitHubAppWebhookSecret.Length -gt 0) {
    Write-Output "Converting value from 'GitHubAppWebhookSecret' to SecureString"

    # Convert GitHubAppWebhookSecret to SecureString
    $GitHubAppWebhookSecretAsSecureString = ConvertTo-SecureString $GitHubAppWebhookSecret -AsPlainText -Force

    Write-Host "-> Done"
}

# Test if template file path exists
$TemplateFilePath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateFile))
if (-not (Test-Path $TemplateFilePath)) {
    Write-Output "Template file '$TemplateFilePath' does not exist"
    exit
}

# Resourcegroup deployment - Create the resource group only when it doesn't already exist
if ($null -eq (Get-AzResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Verbose -ErrorAction SilentlyContinue)) {
    Write-Host "Creating resource group '$ResourceGroupName' - This can take some time"
    $deploymentResult = New-AzResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Force -ErrorAction Stop
    Write-Host "-> Done"
} else {
    Write-Host "Skipping resource group creation -> Already exist"
}

# Resource deployment
Write-Host "Deploying resources - This can take some time"
$deploymentResult = New-AzResourceGroupDeployment -Name ((Get-ChildItem $TemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('yyyyMMdd-HHmmss')) `
                                    -ResourceGroupName $ResourceGroupName `
                                    -TemplateFile $TemplateFilePath `
                                    -gitHubAppId $GitHubAppId `
                                    -gitHubAppPrivateKeyContent $GitHubAppPrivateKeyContentAsSecureString `
                                    -gitHubAppWebhookSecret $GitHubAppWebhookSecretAsSecureString `
                                    -Force `
                                    -ErrorVariable ErrorMessages

if ($ErrorMessages) {
    Write-Output '', 'Template deployment returned the following errors:', @(@($ErrorMessages) | ForEach-Object { $_.Exception.Message.TrimEnd("`r`n") })
    exit
}

Write-Host "-> Done"

# Show deployment details
$functionAppName = $deploymentResult.Outputs.functionAppName.value

Write-Host ""
Write-Host "---------------------------------------------------"
Write-Host "ResourceGroupName: $ResourceGroupName"
Write-Host "FunctionAppName:   $functionAppName"
Write-Host "---------------------------------------------------"