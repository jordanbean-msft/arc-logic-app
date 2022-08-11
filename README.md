# arc-logic-app

This repo shows you how to write & deploy an Arc-enabled Logic App to an Arc-enabled Kubernetes cluster. An Arc-enabled Kubernetes cluster is any [Cloud Native Computing Foundation (CNCF) Kubernetes cluster](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/validation-program) running anywhere. An Arc-enabled Logic App is a [Logic App Standard that is running on an Arc-enabled Kubernetes cluster](https://docs.microsoft.com/en-us/azure/logic-apps/azure-arc-enabled-logic-apps-overview) hosted anywhere.

![architecture](./.img/architecture.png)

This Logic App takes an HTTP PUT request, writes the JSON to a text file in Azure Blob Storage, then sends an email notification. This is to demostrate that the Logic App can still use the Logic App Standard connectors even though it is running in a non-Azure environment. The Logic App can use Azure AD authentication via a service principal to access Azure resources.

![logicAppWorkflow](./.img/logicAppWorkflow.png)

Also included is an Azure DevOps pipeline to demonstrate the deployment process.

## Disclaimer

**THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.**

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Azure Logic Apps CLI extension](https://docs.microsoft.com/en-us/azure/logic-apps/azure-arc-enabled-logic-apps-create-deploy-workflows?tabs=azure-cli#install-azure-logic-apps-standard-extension-for-azure-cli)
- [Visual Studio Code extension for Azure Logic Apps](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-logicapps)
- [Postman](https://postman.com/)
- Azure subscription & resource group
- An existing [Azure Arc-enabled Kubernetes cluster, App Service Kubernetes Environment & an Azure Arc custom location](https://docs.microsoft.com/en-us/azure/app-service/manage-create-arc-environment)
- An existing [Azure AD identity](https://docs.microsoft.com/en-us/azure/logic-apps/azure-arc-enabled-logic-apps-create-deploy-workflows?tabs=azure-cli#prerequisites) (app registration & service principal)

**Note** that it is best if you run the commands (especially the `zip` command) on Linux, not Windows. This is because the deployment environment is Linux and zip files created using Windows are likely to use a backslash instead of a forward slash, which will not unzip correctly on Linux.

## Deployment

1.  Run the following Azure CLI command to create all of the prerequisites for the Logic App deployment (modify the `./infra/env/dev.parameters.json` file & the command below as needed for your environment).

    ```shell
    az deployment group create --resource-group rg-arcLogicApp-eus-dev --template-file ./main.bicep --parameters ./env/dev.parameters.json
    ```

1.  Run the following Azure CLI command to create the Arc-enabled Logic App (modify the command below as needed for your environment).

    ```shell
    az logicapp create --name logic-arcLogicAppCli-eus-dev --resource-group rg-arcLogicApp-eus-dev --storage-account saarclogicappeusdev --custom-location eb-k3s-gbg
    ```

1.  Run the following Azure CLI command to configure the Arc-enabled Logic App's app settings (these are needed so the Logic App can authenticate & use connections to other services such as Office 365, Blob Storage, etc). These values can be found as the output of the `az deployment` command above as well as the specific Azure AD values for the service principal you created as part of the prerequisites.

    ```shell
    az logicapp config appsettings set --name logic-arcLogicAppCli-eus-dev --resource-group rg-arcLogicApp-eus-dev --subscription dcf66641-6312-4ee1-b296-723bb0a999ba --settings "AzureBlob_connectionString=DefaultEndpointsProtocol=https;AccountName=saarclogicappeusdev;AccountKey=K5zHU6hj6vekYhmuFakekeyQSu8VOHLKLCUX63Tv+WhJTxnZr5Ueu+AStGbzBKw==;EndpointSuffix=core.windows.net WORKFLOWAPP_AAD_CLIENTID=9f183384-f1d1-4b67-bbfe-912750477c4e WORKFLOWAPP_AAD_CLIENTSECRET=iRj8Q~HJobKFakesecretZGnEZkcI6HUW8~deT WORKFLOWAPP_AAD_OBJECTID=9e9b8c20-c979-4537-9896-3c9e2d3eef77 WORKFLOWAPP_AAD_TENANTID=72f988bf-86f1-41af-91ab-2d7cd011db47"
    ```

1.  Right-click on the `./src/ProcessDataAndSendEmail/workflow.json` file & select **Open in Designer**.

1.  Select the `Initialize variable - Email Address` action & modify the email address.

1.  Select the `Upload a Blob to Azure Storage` action, click on the **Change connection** button. Click on **Add new** and provide the connection information. This sets up the Logic App locally. It will use the App Settings values when deployed to Azure.

1.  Select the `Send an email (V2)` action, click on the **Change connection** button. Click on **Add new** and authenticate. This sets up the Logic App locally. It will use the App Settings values when deployed to Azure.

1.  Save the file.

1.  Run the following bash command to zip up the Logic App workflow definition.

    ```shell
    cd src
    zip -r ../app.zip ./
    ```

1.  Run the following Azure CLI command to deploy the Logic App workflow ZIP file to the Logic App hosted on a Kubernetes cluster (modify the command below as needed for your environment).

    ```shell
    az logicapp deployment source config-zip --name logic-arcLogicAppCli-eus-dev --resource-group rg-arcLogicApp-eus-dev --src ./app.zip
    ```

1.  Authorize the Office 365 connection in the Azure portal.

    1.  Go to the [Azure portal](https://portal.azure.com) & navigate to your resource group & Logic App.

    1.  Click on the **Connections** blade.

    1.  On the **API Connections** tab, click on the **office365** connection.

    1.  Click on **Access policies** blade and click on **Add**

    1.  Search for your Azure AD service principal, select it & click on **Add**.

    1.  Under the **Edit API connection** blade, click on the **Authorize** button, authenticate with your ID & click **Save**.

## Connect to your cluster

```shell
az connectedk8s proxy -n eb-k3s-001 -g rg-arcLogicApp-eus-dev --token $TOKEN
```

## Links

- [Connect to Azure Arc-enabled Kubernetes cluster](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/cluster-connect?tabs=azure-cli)
