# create zip archive locally
data "archive_file" "single-function-time-to-cold-start-multithreaded-twelve3-function-code" {
  type = "zip"
  source_dir = "function_code/single-function-time-to-cold-start-multithreaded-twelve-function3"
  output_path = "function3.zip"
}

# upload zip archive to storage contianer
resource "azurerm_storage_blob" "single-function-time-to-cold-start-multithreaded-twelve3-code" {
  name = "single-function-time-to-cold-start-multithreaded-twelve3-function.zip"
  storage_account_name = azurerm_storage_account.single-function-time-to-cold-start-multithreaded-twelve-experiment-storage.name
  storage_container_name = azurerm_storage_container.single-function-time-to-cold-start-multithreaded-twelve-container.name
  type = "Block"
  source = "function3.zip"
}

# create function app 'environment'
# different from how AWS lambda works
resource "azurerm_function_app" "single-function-time-to-cold-start-multithreaded-twelve3" {
  depends_on = [azurerm_storage_blob.single-function-time-to-cold-start-multithreaded-twelve3-code]

  name = "single-function-time-to-cold-start-multithreaded-twelve-function3"
  location = var.azure_region
  resource_group_name = azurerm_resource_group.single-function-time-to-cold-start-multithreaded-twelve-rg.name
  app_service_plan_id = azurerm_app_service_plan.single-function-time-to-cold-start-multithreaded-twelve-plan.id
  storage_connection_string = azurerm_storage_account.single-function-time-to-cold-start-multithreaded-twelve-experiment-storage.primary_connection_string
  version = "~2"

  app_settings = {
    HASH = data.archive_file.single-function-time-to-cold-start-multithreaded-twelve3-function-code.output_base64sha256
    WEBSITE_RUN_FROM_PACKAGE = "${azurerm_storage_blob.single-function-time-to-cold-start-multithreaded-twelve3-code.url}${data.azurerm_storage_account_sas.sas-single-function-time-to-cold-start-multithreaded-twelve.sas}"
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.single-function-time-to-cold-start-multithreaded-twelve.instrumentation_key
    FUNCTIONS_WORKER_RUNTIME = "python"
  }
}

# Get the functions key out of the app
resource "azurerm_template_deployment" "single-function-time-to-cold-start-multithreaded-twelve3-function-key" {
  depends_on = [azurerm_function_app.single-function-time-to-cold-start-multithreaded-twelve3]

  name = "single-function-time-to-cold-start-multithreaded-twelve3_get_function_key"
  parameters = {
    "functionApp" = azurerm_function_app.single-function-time-to-cold-start-multithreaded-twelve3.name
  }
  resource_group_name    = azurerm_resource_group.single-function-time-to-cold-start-multithreaded-twelve-rg.name
  deployment_mode = "Incremental"

  template_body = <<BODY
  {
      "$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
      "contentVersion": "1.0.0.0",
      "parameters": {
          "functionApp": {"type": "string", "defaultValue": ""}
      },
      "variables": {
          "functionAppId": "[resourceId('Microsoft.Web/sites', parameters('functionApp'))]"
      },
      "resources": [
      ],
      "outputs": {
          "functionkey": {
              "type": "string",
              "value": "[listkeys(concat(variables('functionAppId'), '/host/default'), '2018-11-01').functionKeys.default]"                                                                                }
      }
  }
  BODY
}

# output some useful variables
output "single-function-time-to-cold-start-multithreaded-twelve-function3_function_key" {
  value = "${lookup(azurerm_template_deployment.single-function-time-to-cold-start-multithreaded-twelve3-function-key.outputs, "functionkey")}"
}
output "single-function-time-to-cold-start-multithreaded-twelve-function3_function_app_url" {
  value = azurerm_function_app.single-function-time-to-cold-start-multithreaded-twelve3.default_hostname
}