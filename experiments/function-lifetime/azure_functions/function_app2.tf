# create zip archive locally
data "archive_file" "function-lifetime2-function-code" {
  type = "zip"
  source_dir = "function_code/function-lifetime-function2"
  output_path = "function2.zip"
}

# upload zip archive to storage contianer
resource "azurerm_storage_blob" "function-lifetime2-code" {
  name = "function-lifetime2-function.zip"
  storage_account_name = azurerm_storage_account.function-lifetime-experiment-storage.name
  storage_container_name = azurerm_storage_container.function-lifetime-container.name
  type = "Block"
  source = "function2.zip"
}

# create function app 'environment'
# different from how AWS lambda works
resource "azurerm_function_app" "function-lifetime2" {
  depends_on = [azurerm_storage_blob.function-lifetime2-code]

  name = "function-lifetime-function2"
  location = var.azure_region
  resource_group_name = azurerm_resource_group.function-lifetime-rg.name
  app_service_plan_id = azurerm_app_service_plan.function-lifetime-plan.id
  storage_connection_string = azurerm_storage_account.function-lifetime-experiment-storage.primary_connection_string
  version = "~2"

  app_settings = {
    HASH = data.archive_file.function-lifetime2-function-code.output_base64sha256
    WEBSITE_RUN_FROM_PACKAGE = "${azurerm_storage_blob.function-lifetime2-code.url}${data.azurerm_storage_account_sas.sas-function-lifetime.sas}"
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.function-lifetime.instrumentation_key
    FUNCTIONS_WORKER_RUNTIME = "python"
  }
}

# Get the functions key out of the app
resource "azurerm_template_deployment" "function-lifetime2-function-key" {
  depends_on = [azurerm_function_app.function-lifetime2]

  name = "function-lifetime2_get_function_key"
  parameters = {
    "functionApp" = azurerm_function_app.function-lifetime2.name
  }
  resource_group_name    = azurerm_resource_group.function-lifetime-rg.name
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
output "function-lifetime-function2_function_key" {
  value = "${lookup(azurerm_template_deployment.function-lifetime2-function-key.outputs, "functionkey")}"
}
output "function-lifetime-function2_function_app_url" {
  value = azurerm_function_app.function-lifetime2.default_hostname
}
