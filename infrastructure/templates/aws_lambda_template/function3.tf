
# creates zip archive containing lambda code
data "archive_file" "exp3-lambda-code" {
  type = "zip"
  source_file = "${var.path_to_code}/function3.py"
  output_path = "${var.path_to_code}/lambda3.zip"
}

# create API endpoint
resource "aws_api_gateway_resource" "exp3-api-resource" {
  rest_api_id = aws_api_gateway_rest_api.exp-api.id
  parent_id = aws_api_gateway_rest_api.exp-api.root_resource_id
  path_part = "exp3"
}

# create API endpoint method
resource "aws_api_gateway_method" "exp3-lambda-method" {
  rest_api_id = aws_api_gateway_rest_api.exp-api.id
  resource_id = aws_api_gateway_resource.exp3-api-resource.id
  http_method = "POST"
  authorization = "None"
  api_key_required = true
}

resource "aws_api_gateway_method_response" "exp2-response_200" {
  rest_api_id = aws_api_gateway_rest_api.exp-api.id
  resource_id = aws_api_gateway_resource.exp3-api-resource.id
  http_method = aws_api_gateway_method.exp3-lambda-method.http_method
  status_code = "200"
}

# point API endpoint at lambda function
resource "aws_api_gateway_integration" "exp3-api-integration" {
  rest_api_id = aws_api_gateway_rest_api.exp-api.id
  resource_id = aws_api_gateway_method.exp3-lambda-method.resource_id
  http_method = aws_api_gateway_method.exp3-lambda-method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.exp3-python.invoke_arn
}

resource "aws_api_gateway_integration_response" "exp3" {
  depends_on = [
    aws_api_gateway_integration.exp3-api-integration
  ]
  rest_api_id = aws_api_gateway_rest_api.exp-api.id
  resource_id = aws_api_gateway_method.exp3-lambda-method.resource_id
  http_method = aws_api_gateway_method.exp3-lambda-method.http_method
  status_code = aws_api_gateway_method_response.exp2-response_200.status_code
}

# add permission for gateway to invoke lambdas
resource "aws_lambda_permission" "exp3-apigw-permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.exp3-python.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.exp-api.execution_arn}/*/*"
}

# create lambda function
resource "aws_lambda_function" "exp3-python" {
  filename = data.archive_file.exp3-lambda-code.output_path
  function_name = "exp3-python"
  role = aws_iam_role.exp-role.arn
  handler = "function3.lambda_handler"
  runtime = "python3.7"
  source_code_hash = filesha256(data.archive_file.exp3-lambda-code.output_path)
  publish = true
}
