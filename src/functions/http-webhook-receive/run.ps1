using namespace System.Net

param ($Request, $TriggerMetadata)

$requestHeaders = $Request.Headers
$requestBody = $Request.Body

$githubHeaderEvent = $requestHeaders.'X-GitHub-Event'
$githubInstallationId = $requestHeaders.'X-GitHub-Hook-Installation-Target-ID'

## Check if the request comes from GitHub - Ping event
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

## Check if the request comes from GitHub - Installation event
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

## Init
$gitHubAppId = $env:GitHubAppId
$gitHubAppPrivateKeyContent = [System.Text.Encoding]::UTF8.GetBytes($env:GitHubAppPrivateKeyContent)

## Generate 'iat' and 'exp' dates
$exp = [int][double]::parse((Get-Date -Date $((Get-Date).addseconds(300).ToUniversalTime()) -UFormat %s))
$iat = [int][double]::parse((Get-Date -Date $((Get-Date).ToUniversalTime()) -UFormat %s))

## Generate a signed JWT token
$jwtToken = New-JWT -Algorithm "RS256" -Issuer $gitHubAppId -ExpiryTimestamp $exp -SecretKey $gitHubAppPrivateKeyContent -PayloadClaims @{ "iat" = $iat}

Write-Host "Generated JWT token: $jwt" ## TODO: Remove this line - only for debugging

# Generate an GitHub App Access token from the JWT
if ($null -ne $githubInstallationId) {

    ## Format headers with generated jwt header token
    $accessTokenHeaders = @{
        "Accept" = "application/vnd.github+json"
        "Authorization" = "Bearer $jwtToken"
    }

    $apiUrl = "https://api.github.com/app/installations/$githubInstallationId/access_tokens"

    ## Fetching access token for installation
    $webRequestResult = Invoke-WebRequest -Uri $apiUrl -Headers $accessTokenHeaders -Method POST
    $jsonResult = ConvertFrom-Json($webRequestResult.Content)
    $accesstoken = $jsonResult.token

    Write-Host "Fetched Access token for installation '$githubInstallationId': $accesstoken" ## TODO: Remove this line - only for debugging
}

##########################################################################################
# Using the GitHub App Access token to access the GitHub API - example requests below

## Init
$owner = "equalizer999"             ## TODO: Replace with your own GitHub usern/organization name
$repoName = "github-integration"    ## TODO: Replace with your own GitHub repository name

## Format headers with generated jwt header token
$accessTokenHeaders = @{
    "Accept" = "application/vnd.github+json"
    "Authorization" = "Bearer $accesstoken"
}

## Get the repositories this token has access to
$apiUrl = "https://api.github.com/installation/repositories"
$webRequestResult = Invoke-WebRequest -Uri $apiUrl -Headers $accessTokenHeaders -Method POST
$jsonResult = ConvertFrom-Json($webRequestResult.Content)
                
## Get the runner information for a repo
$apiUrl="https://api.github.com/repos/$owner/$repoName/actions/runners"
$webRequestResult = Invoke-WebRequest -Uri $apiUrl -Headers $accessTokenHeaders -Method POST
$jsonResult = ConvertFrom-Json($webRequestResult.Content)

# Load the files in a directory
$apiUrl="https://api.github.com/repos/$owner/$repoName/contents"
$webRequestResult = Invoke-WebRequest -Uri $apiUrl -Headers $accessTokenHeaders -Method POST
$jsonResult = ConvertFrom-Json($webRequestResult.Content)

# Load a file in a directory
github_api_url="https://api.github.com/repos/$owner/$repoName/contents/README.md"
$webRequestResult = Invoke-WebRequest -Uri $apiUrl -Headers $accessTokenHeaders -Method POST

# Push default response - 204 No Content
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::NoContent
})