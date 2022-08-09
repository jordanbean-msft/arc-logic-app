# arc-logic-app

## Deployment

1.  Run the following Azure CLI command to create all of the prerequisites for the Logic App deployment (modify the `./infra/env/dev.parameters.json` file & the command below as needed for your environment).

    ```shell
    az deployment group create --resource-group rg-arcLogicApp-eus-dev --template-file ./main.bicep --parameters ./env/dev.parameters.json
    ```

1.  Run the following Azure CLI command to create the Logic App (modify the command below as needed for your environment).

    ```shell
    az logicapp create --name logic-arcLogicAppCli1-eus-dev --resource-group rg-arcLogicApp-eus-dev --storage-account saarclogicappeusdev --custom-location eb-k3s-gbg
    ```

1.  Run the following PowerShell command to zip up the Logic App workflow definition.

    ```shell
    Compress-Archive ./src/* ./app.zip -Update
    ```

1.  Run the following Azure CLI command to deploy the Logic App workflow ZIP file to the Logic App hosted on a Kubernetes cluster (modify the command below as needed for your environment)..

    ```shell
    az logicapp deployment source config-zip --name logic-arcLogicAppCli-eus-dev --resource-group rg-arcLogicApp-eus-dev --src ./app.zip
    ```
