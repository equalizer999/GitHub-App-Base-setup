using namespace System.Net

param ($Request, $TriggerMetadata)

# Init : Request header and body variables
$requestHeaders = $Request.Headers
$requestBody = $Request.Body
$requestRawBody = $Request.RawBody

$githubRequestSignature = $requestHeaders.'X-Hub-Signature-256'
$githubHeaderEvent = $requestHeaders.'X-GitHub-Event'
$githubAppInstallTargetId = $requestHeaders.'X-GitHub-Hook-Installation-Target-ID'

# Init : Environment variables
$gitHubAppId = $env:GitHubAppId
$gitHubAppPrivateKeyContentPlain = $env:GitHubAppPrivateKeyContent
$gitHubAppPrivateKeyContent = [System.Text.Encoding]::UTF8.GetBytes($gitHubAppPrivateKeyContentPlain)
$gitHubAppWebhookSecret = $env:GitHubAppWebhookSecret

## TODO: Uncomment the following lines - only for debugging
# Write-Host "GitHubAppID:                $gitHubAppId"
# Write-Host "GitHubAppPrivateKeyContent: $gitHubAppPrivateKeyContentPlain"
# Write-Host "GitHubAppWebhookSecret:     $gitHubAppWebhookSecret"

# Validate if the request body is valid and not tempered with
###########################################
if($null -ne $githubRequestSignature -and $githubRequestSignature -ne '') {
    Write-Host "Validating request body"

    ## Setup right encodings
    $rawBodyData = [Text.Encoding]::UTF8.GetBytes($requestRawBody)
    $keyData = [Text.Encoding]::UTF8.GetBytes($gitHubAppWebhookSecret)

    ## Compute the hash
    $hmac = [System.Security.Cryptography.HMACSHA256]::new($keyData)
    $bodyHash = $hmac.ComputeHash($rawBodyData)
    $hmac.Dispose()

    ## Convert to hex string and right format
    $sha256 = [System.BitConverter]::ToString($bodyHash).ToLower().Replace("-", "")
    $calculatedSignature = "sha256=$sha256"

    ## Compare the computed signature with the header value
    $signaturesEqual = $githubRequestSignature -eq $calculatedSignature

    ## TODO: Uncomment the following lines - only for debugging
    # Write-Host "Expected signature:   '$githubRequestSignature'"
    # Write-Host "Calculated signature: '$calculatedSignature'"
    # Write-Host "Signatures equal:     $signaturesEqual"

    ## If the signatures are equal, the request body is valid
    if ($signaturesEqual -eq $true) {
        Write-Host "Validating request body - OK"
    } else {
        Write-Host "Validating request body - FAILED"

        $responseBody = @{
            message = 'The sha256 hash was incorrect, access not allowed'
        } | ConvertTo-Json

        # Push error response - 401 Unauthorized
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode = [HttpStatusCode]::Unauthorized
            Headers = @{
                "Content-type" = "application/json"
            }
            Body       = $responseBody
        })

        break
    }
} else {
    Write-Host "[WARNING] !!NO request body validation will take place - Missing 'X-Hub-Signature-256' header - recommended to enable this!!"
    ### Docs: https://docs.github.com/en/webhooks/using-webhooks/best-practices-for-using-webhooks
    ### Docs: https://docs.github.com/en/webhooks/using-webhooks/validating-webhook-deliveries
}

# Check if the request comes from GitHub - Ping event
###########################################
if ($githubHeaderEvent -eq 'ping') {
    Write-Host "GitHub ping event received"
    $responseBody = @{
        message = 'pong'
    } | ConvertTo-Json

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{ 
        StatusCode = [HttpStatusCode]::OK
        Headers = @{
            "Content-type" = "application/json"
        }
        Body = $responseBody
    })

    break
}

# Check if the request comes from GitHub - Installation event
###########################################
if ($githubHeaderEvent -eq 'installation') {
    Write-Host "GitHub installation event received"

    $responseBody = @{
        message = 'installation'
    } | ConvertTo-Json

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{ 
        StatusCode = [HttpStatusCode]::OK
        Headers = @{
            "Content-type" = "application/json"
        }
        Body = $responseBody
    })

    break
}

# Generate a GitHub App JWT token
### Docs: https://docs.github.com/en/developers/apps/building-github-apps/authenticating-with-github-apps#authenticating-as-a-github-app
#############################################

## Generate 'iat' and 'exp' dates
$exp = [int][double]::parse((Get-Date -Date $((Get-Date).addseconds(300).ToUniversalTime()) -UFormat %s))
$iat = [int][double]::parse((Get-Date -Date $((Get-Date).ToUniversalTime()) -UFormat %s))

## Generate a signed JWT token
$jwtToken = New-JWT -Algorithm "RS256" -Issuer $gitHubAppId -ExpiryTimestamp $exp -SecretKey $gitHubAppPrivateKeyContent -PayloadClaims @{ "iat" = $iat}

## TODO: Uncomment the following line - only for debugging
# Write-Host "Generated JWT token: $jwtToken"

# Generate an GitHub App Access token from the JWT
if ($null -ne $githubAppInstallTargetId) {

    $githubInstallationId = $requestBody.installation.id

    $apiUrl = "https://api.github.com/app/installations/$githubInstallationId/access_tokens"

    ## Format headers with generated jwt header token
    $accessTokenHeaders = @{
        "Accept" = "application/vnd.github+json"
        "Authorization" = "Bearer $jwtToken"
    }

    ## Fetching access token for installation
    $jsonResult = Invoke-WebRequest -Uri $apiUrl -Headers $accessTokenHeaders -Method POST | ConvertFrom-Json
    $accesstoken = $jsonResult.token

    ## TODO: Uncomment the following line - only for debugging
    # Write-Host "Fetched Access token for installation '$githubInstallationId': $accesstoken"
}

##########################################################################################
# Using the GitHub App Access token to access the GitHub API - example requests below

## Init
$owner = "<your-organization-name>"  ## TODO: Replace with your own GitHub usern/organization name or fetch from the request body
$repoName = "<your-repo-name>"       ## TODO: Replace with your own GitHub repository name or fetch from the request body

## Format default headers with jwt header token
$accessTokenHeaders = @{
    "Accept" = "application/vnd.github+json"
    "Content-Type" = "application/json"
    "Authorization" = "Bearer $accesstoken"
}

## Get the repositories this token has access to
###########################################
# Write-Host "List repository access for current access token"
# $apiUrl = "https://api.github.com/installation/repositories"
# $repoAccessRequestResult = Invoke-WebRequest -Uri $apiUrl -Headers $accessTokenHeaders -Method GET
# Write-Host $repoAccessRequestResult.Content

                
## Get the runner information for a repo
### Requires Org permission: 'Read only' for 'administration'
### Requires Repo permission: 'Read only' for 'organization_self_hosted_runners'
### Docs: https://docs.github.com/en/rest/actions/self-hosted-runners#list-runner-applications-for-an-organization
###########################################
# Write-Host "Fetch runner info for repo '$repoName'"
# $apiUrl = "https://api.github.com/repos/$owner/$repoName/actions/runners"
# $repoRunnerRequestResult = Invoke-WebRequest -Uri $apiUrl -Headers $accessTokenHeaders -Method GET
# Write-Host $repoRunnerRequestResult.Content


## Load the files in a directory
### Docs: https://docs.github.com/en/rest/repos/contents#get-repository-content
###########################################
# Write-Host "Fetch runner info for repo '$repoName'"
# $apiUrl = "https://api.github.com/repos/$owner/$repoName/contents"
# $filesRequestResult = Invoke-WebRequest -Uri $apiUrl -Headers $accessTokenHeaders -Method GET
# Write-Host $filesRequestResult.Content


## Fetch a file contents (RAW) from a directory (e.g. README.md)
### Docs: https://docs.github.com/en/rest/repos/contents#get-repository-content
###########################################
# $individualFileHeaders = @{
#     "Authorization" = "Bearer $accesstoken"
# }

# Write-Host "Fetch README.md file contents for repo '$repoName'"
# $apiUrl = "https://api.github.com/repos/$owner/$repoName/contents/README.md"
# $individualFileRequestResult = Invoke-WebRequest -Uri $apiUrl -Headers $individualFileHeaders -Method GET
# $individualFileJsonResult = $individualFileRequestResult.Content | ConvertFrom-Json
# $individualFileStringResult = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($individualFileJsonResult.content))
# Write-Host $individualFileStringResult


## Comment or approve an environment deployment rule
### Docs: https://docs.github.com/en/actions/deployment/protecting-deployments/creating-custom-deployment-protection-rules#approving-or-rejecting-deployments 
# if ($githubHeaderEvent -eq 'deployment_protection_rule') {
#     Write-Host "GitHub '$githubHeaderEvent' event received"

    # $environment = $requestBody.environment
    # $deploymentCallbackUrl = $requestBody.deployment_callback_url

    ## Comment on the deployment
    # $commentBody = @{
    #     "environment_name" = $environment
    #     "comment" = "Approval is still in progress"
    # } | ConvertTo-Json
    
    # Write-Host "Updating deployment found on '$deploymentCallbackUrl' with additional comments"
    # $commentedResult = Invoke-WebRequest -Uri $deploymentCallbackUrl -Body $commentBody -Headers $accessTokenHeaders -Method POST
    # Write-Host "-> done"

    ## Approve the deployment
    # $approvedBody = @{
    #    "environment_name" = $environment
    #    "state" = "approved"
    #    "comment" = "Approved by GitHub App"
    # } | ConvertTo-Json

    # Write-Host "Approving deployment found on '$deploymentCallbackUrl'"
    # $approvedResult = Invoke-WebRequest -Uri $deploymentCallbackUrl -Body $approvedBody -Headers $accessTokenHeaders -Method POST
    # Write-Host "-> done"
# }

# Push default response - 204 No Content
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::NoContent
})