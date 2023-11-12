# GitHub App Base Setup

## Table of Contents
<details>
<summary>Click to expand</summary>

1. [GitHub App Base Setup](#github-app-base-setup)
   1. [Table of Contents](#table-of-contents)
   2. [Setting context](#setting-context)
   3. [Prerequisites and assumptions](#prerequisites-and-assumptions)
   4. [Steps for solution setup](#steps-for-solution-setup)
      1. [Create GitHub App](#create-github-app)
      2. [Deploy Azure Function infra and code](#deploy-azure-function-infra-and-code)
2. [Using this repository as a template](#using-this-repository-as-a-template)
3. [Additional resources](#additional-resources)

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

```PowerShell

Install-Module Az

```


## Steps for solution setup
### Create GitHub App
Please follow the following doc page for creating a PAT.

**Important** Make sure you select (at least) the following scopes and permissions (-> Repository - Full control)
**Important** Copy and/or save the created PAT somewhere private, we need it further down the line.

### Deploy Azure Function infra and code
Connect to the right Azure subscription. Use the following commands to make sure you are:

```PowerShell
Connect-AzAccount -Tenant "<your-tenant-ID-here>" -SubscriptionId "<your-subscription-ID-here>"
```

Then go to 'deploy' folder in repo and execute:

```PowerShell
.\1.Deploy-AzResources.ps1 -ResourceGroupName "<your-resource-group-name-here>" -Location "<your-location-here>" -GitHubAppId "<your-github-app-id-here>" -GitHubAppPrivateKeyPath "<your-github-app-private-key-path-here>"
```

**Important** Check the output and copy the 'FunctionAppName'. We need it further down the line.

Again, go to 'deploy' folder in repo and execute:

```PowerShell
.\2.CreateAndReleaseDeploymentPackage.ps1 -ResourceGroupName "<your-resource-group-name-here>" -FunctionAppName "<paste-here-the-generated-function-app-name>"
```

## Using this repository as a template
You can use this repository as a template for creating your own GitHub App projects based on Azure Functions in PowerShell. To do so, follow these steps:

- Click on the "Use this template" button on the top right of this page. This will create a new repository in your account with the same files and folders as this one.
- Clone the new repository to your local machine and open it in your preferred editor.
- Modify the `src/functions/http-webhook-receive/run.ps1` file to implement your own logic for handling webhook events and API calls. You can use the existing code as a reference or delete it and start from scratch.
- Modify the `deploy/azuredeploy.json` and `deploy/azuredeploy.parameters.json` files to customize the Azure resources you need for your project. You can add or remove resources as needed, but make sure to update the dependencies and outputs accordingly.
- Modify the `README.md` file to document your project's purpose, features, and instructions. You can use the existing structure as a guide or create your own.
- Commit and push your changes to the remote repository.
- Follow the steps in the [Deploy Azure Function infra and code](#deploy-azure-function-infra-and-code) section to deploy your project to Azure.
- Follow the steps in the [Create GitHub App](#create-github-app) section to register your project as a GitHub App and install it on your organization or repositories.

# Additional resources
- [Azure Functions PowerShell developer guide](https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-powershell?tabs=portal)
- [Authenticating with GitHub Apps](https://docs.github.com/en/developers/apps/building-github-apps/authenticating-with-github-apps)
- [GitHub API reference](https://docs.github.com/en/rest)
