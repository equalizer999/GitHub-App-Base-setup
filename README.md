# GitHub App - Base Setup

## Table of Contents
<details>
<summary>Click to expand</summary>

- [GitHub App - Base Setup](#github-app---base-setup)
  - [Table of Contents](#table-of-contents)
  - [Setting context](#setting-context)
    - [Highlevel architecture](#highlevel-architecture)
  - [Prerequisites and assumptions](#prerequisites-and-assumptions)
  - [Solution setup steps](#solution-setup-steps)
    - [1. Create a GitHub App](#1-create-a-github-app)
    - [2. Set base configuration GitHub App](#2-set-base-configuration-github-app)
    - [3. Generate a private key for the GitHub App](#3-generate-a-private-key-for-the-github-app)
    - [4. Deploy Azure resources](#4-deploy-azure-resources)
    - [5. Deploy Azure Function App code](#5-deploy-azure-function-app-code)
    - [6. Update GitHub App webhook URL](#6-update-github-app-webhook-url)
    - [7. Install the GitHub App on your organization](#7-install-the-github-app-on-your-organization)
    - [8. Test the solution](#8-test-the-solution)
  - [Use and setup Postman collection](#use-and-setup-postman-collection)
    - [1. Import the collection](#1-import-the-collection)
    - [2. Update the collection variables for use](#2-update-the-collection-variables-for-use)
- [Additional resources](#additional-resources)

</details>

## Setting context
This repository contains;
- Resources for setting up a working integration solution with GitHub using a basic set of Azure components.
- Providing a sample Azure Function App (PowerShell) which can be used to receive and process GitHub webhooks.
- Sample/test resources for using [Postman](https://www.postman.com/) as an exploration tool.

### Highlevel architecture
![Highlevel architecture](./docs/images/architecture.drawio.svg)

## Prerequisites and assumptions
What you'll need to set everything up:
- A GitHub account :smile:
- An organization (where your GitHub account has admin rights)
- An active Azure subscription, where you can deploy resources (minimal Contributor rights)
- (optional) Postman - For testing/exploring
- A machine with Az Powershell modules installed (we'll use that for the deployment scripts)

```PowerShell

Install-Module Az

```

## Solution setup steps
### 1. Create a GitHub App
Go to your GitHub organization and create a new GitHub App - under '`Settings - Developer Settings`'.

![Create GitHub App](./docs/images/create-github-app-1.drawio.png)
![Set required values](./docs/images/create-github-app-2.drawio.png)

**Notes**
- Enter a unique name and description for your GitHub App. The name of your GitHub App will be visible to users of the app.
- Enter a Homepage URL for your GitHub App. This URL is visible to users of your app.

### 2. Set base configuration GitHub App

![Base GitHub App configuration - empty](./docs/images/base-github-app-configuration-1.drawio.png)
![Base GitHub App configuration - filled](./docs/images/base-github-app-configuration-2.drawio.png)

Set the required fields and permissions based on what you want to achieve. Please check the [additional resources](#additional-resources) and/or function [source code](./src/functions/http-webhook-receive/run.ps1). Check which permissions are used to achieve the desired result.

***Important*** We'll update the webhook URL later on, so for now just enter a dummy URL.

### 3. Generate a private key for the GitHub App

![GitHub App - overview](./docs/images/generate-github-app-private-key-1.drawio.png)

**Note**
Copy the '`App ID`'. We need it further down the line.

![Generate private key - overview](./docs/images/generate-github-app-private-key-2.drawio.png)
![Generate private key - save private key file](./docs/images/generate-github-app-private-key-3.drawio.png)

Save the private key to a file - securely. We'll need it later on.

### 4. Deploy Azure resources
Connect to the right Azure subscription using your favorite terminal. Use the following commands to make sure you are:

```PowerShell
Connect-AzAccount -Tenant "<your-tenant-ID-here>" -SubscriptionId "<your-subscription-ID-here>"
```

Go to 'deploy' folder in the repo and execute:

```PowerShell
.\1.Deploy-AzResources.ps1 -ResourceGroupName "<your-resource-group-name-here>" -Location "<your-location-here>" -GitHubAppId "<your-github-app-id-here>" -GitHubAppPrivateKeyPath "<your-path-to-the-github-app-private-key-here>"
```

*Optional paramaters:*
- '`ResourceGroupName`' - defaults to '`github-int-eus-231128`'
- '`Location`' - defaults to '`East US`'

**Important**
Check the output and copy the '`ResourceGroupName`' and '`FunctionAppName`'. We need these further down the line.

**Sample**
![Deploy azure resources](./docs/images/deploy-azure-resources.drawio.png)

### 5. Deploy Azure Function App code
Go/stay in the 'deploy' folder and execute the following command and pass in the values '`ResourceGroupName`' and '`FunctionAppName`' from the previous step:

```PowerShell
.\2.CreateAndReleaseDeploymentPackage.ps1 -ResourceGroupName "<paste-here-your-resource-group-name>" -FunctionAppName "<paste-here-your-generated-function-app-name>"
```

**Important**
Check the output and copy the '`FunctionUrl`'. We will need this further down the line.

**Sample**
![Deploy azure function app code](./docs/images/deploy-azure-function-app-code.drawio.png)

### 6. Update GitHub App webhook URL
Go back to your GitHub App and update the Webhook URL with the '`FunctionUrl`' from the previous step.

![Update GitHub App Webhook URL](./docs/images/update-github-app-with-webhookurl.drawio.png)

### 7. Install the GitHub App on your organization
Follow the steps in the GitHub App to install it on your organization. Make sure you have admin rights on the organization, that you select the right organization and that you authorize it to access the right repositories.
See also this [documentation](https://docs.github.com/en/apps/using-github-apps/installing-your-own-github-app) for more information.

**Note**
In the sample below, the GitHub App is created and will be installed in a personal organization.

**Sample**
![Install GitHub App on your organization URL](./docs/images/install-github-app.drawio.png)

### 8. Test the solution
Please check the output of the Azure Function App. You can check if it runs by checking the logs in the Azure Portal. Another way is to go to the GitHub App and check the webhook deliveries.

**Note**
You can use the '`ping`' request to check if everything is setup correctly. If everything **is** setup correctly and working, you'll see a '`pong`' in the response body. You can redeliver that particular message for checking the latest state.

![See webhook deliveries](./docs/images/test-and-check-send-webhooks.drawio.png)

## Use and setup Postman collection
You can use the provided Postman collection for playing around with different API's. This Postman collection only supports calls for:
- Generating accesstoken for a particular organization.
- Approving/commenting a custom deployment rule. 

To make them work, you'll have to do a few steps;

### 1. Import the collection
Please checkout this documentation provided by Postman, for importing the provided [collection](./docs/postman/github-app-samples.postman_collection.json) in Postman: [Howto import collection - Postman docs](https://learning.postman.com/docs/getting-started/importing-and-exporting-data/).

### 2. Update the collection variables for use
![Find Postman collection variables](./docs/images/postman-collection-variables.drawio.png)

You'll need to update the following variables:
1. Update the '`Organization-name`' value to point to your target organization name. This is used for additional API calls.
2. The '`Organization-install-id`' value, for which you want to use the GitHub App (this is different from the 'App ID', because it is specific to your installation on your organization). You can find this value by going to the GitHub App and clicking on the 'Installations' tab. Then click on the 'Configure' button for the organization you want to use. The URL will contain the value as shown below in the sample.

![Get installation id from app](./docs/images/get-installation-id.drawio.png)

3. The '`JwtToken`' value, used for making additional calls and retrieving the right access tokens. You can generate this value by using the provided [Bash script](./src/scripts/github-app-jwt.sh). You'll need to update the following values to make it work (see lines 15-17):
    - The 'App ID' of the GitHub App.
    - The path to the private key file of the GitHub App.
    
This script generates a short-lived JWT token (5 min), which you can use to generate an access token for the organization you want to use. You can find more information about this in the [additional resources](#additional-resources) section.

4. The '`Repo-name`', used for targeting additional API calls to point to the right repository. You can find this value by going to the repository and copying the name.

# Additional resources
- [Building a GitHub App that responds to webhook events - GitHub docs](https://docs.github.com/en/apps/creating-github-apps/writing-code-for-a-github-app/building-a-github-app-that-responds-to-webhook-events)
- [Azure Functions PowerShell developer guide - MSFT Learn docs](https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-powershell?tabs=portal)
- [Authenticating as a GitHub App - Generate a GitHub App JWT token - GitHub Docs](https://docs.github.com/en/developers/apps/building-github-apps/authenticating-with-github-apps#authenticating-as-a-github-app)
- [Generating an installation access token for a GitHub App - GitHub docs ](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-an-installation-access-token-for-a-github-app)
- [GitHub App setup - GitHub docs](https://docs.github.com/en/developers/apps/creating-a-github-app)
- [GitHub App webhook events - GitHub docs](https://docs.github.com/en/developers/apps/setting-up-your-development-environment-to-create-a-github-app#webhook-events)
- [List runners for an organization - GitHub docs](https://docs.github.com/en/rest/actions/self-hosted-runners#list-runner-applications-for-an-organization)
- [Get Repository content - GitHub docs](https://docs.github.com/en/rest/repos/contents#get-repository-content)
- [Approve or reject deployment - Custom Deployment rule - GitHub docs](https://docs.github.com/en/actions/deployment/protecting-deployments/creating-custom-deployment-protection-rules#approving-or-rejecting-deployments )