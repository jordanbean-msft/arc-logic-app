# Documentation Links:
  Helpful documentation links for understanding the process of Arc-Enabling an existing Kubernetes Cluster and preparing it to run an Arc-Enabled Logic App.

  Connecting a cluster to Arc - https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/quickstart-connect-cluster?tabs=azure-cli
  
  Creating a Custom Location to host services - https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/custom-locations
  
  Installing Cluster extensions - https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/extensions
  
  App Service Extension - https://docs.microsoft.com/en-us/azure/app-service/overview-arc-integration


**Note:** If your Kubernetes cluster is on-prem and your load balancer services deploy with internal IP addresses, you will need to uncomment the $natip variable and set it to the valid external ip you will be using to nat the cluster behind.  You will also need to uncomment the last line to allow the command to set the public-ip parameter to the value of the $natip variable.