# GitHub App Base Setup

## Table of Contents
<details>
<summary>Click to expand</summary>

1. [GitHub App Base Setup](#github-app-base-setup)
   1. [Table of Contents](#table-of-contents)
   2. [Setting context](#setting-context)
   3. [Prerequisites and assumptions](#prerequisites-and-assumptions)
   4. [Steps for solution setup](#steps-for-solution-setup)
      1. [1. Create GitHub App](#1-create-github-app)
      2. [2. Deploy Azure Function infra and code](#2-deploy-azure-function-infra-and-code)

</details>

## Setting context
This repository contains;
- Resources for setting up a working integration solution with GitHub.
- Resources used in the presentation (pptx, images and a postman collection).

## Prerequisites and assumptions
What you'll need to set everything up:
- A GitHub account
- An organization (where you're GitHub account has admin rights)
- An active Azure subscription, where you can deploy resources (minimal Contributor rights)
- A machine with Az Powershell modules installed (we'll use that for the deployment)

## Steps for solution setup
### 1. Create GitHub App
Please follow the following doc page for creating a PAT.

**Important** Make sure you select (at least) the following scopes and permissions (-> Repository - Full control)
**Important** Copy and/or save the created PAT somewhere private, we need it further down the line.

### 2. Deploy Azure Function infra and code
Connect to the right Azure subscription. Use the following commands to make sure you are:

```PowerShell
Connect-AzAccount -Tenant "<your-tenant-ID-here>" -SubscriptionId "<your-subscription-ID-here>"
```

Then go to 'deploy' folder in repo and execute:

```PowerShell
.\1.Deploy-AzResources.ps1 -ResourceGroupName "<your-resource-group-name-here>" -Location "<your-location-here>"
```

**Important** Check the output and copy the 'FunctionAppName'. We need it further down the line.

Again, go to 'deploy' folder in repo and execute:

```PowerShell
.\2.CreateAndReleaseDeploymentPackage.ps1 -ResourceGroupName "<your-resource-group-name-here>" -FunctionAppName "<paste-here-the-generated-function-app-name>"
```