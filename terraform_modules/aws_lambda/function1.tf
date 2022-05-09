
# creates zip archive containing lambda code
data "archive_file" "function1_lambda_code" {
  type        = "zip"
  source_file = "${local.src_path}/function1.py"
  output_path = "${local.src_path}/lambda1.zip"
}

# create API endpoint
resource "aws_api_gateway_resource" "function1_api_resource" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  parent_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id
  path_part   = aws_lambda_function.function1_python.function_name
}

# create API endpoint method
resource "aws_api_gateway_method" "function1_lambda_method" {
  rest_api_id      = aws_api_gateway_rest_api.lambda_api.id
  resource_id      = aws_api_gateway_resource.function1_api_resource.id
  http_method      = "POST"
  authorization    = "None"
  api_key_required = true
}

resource "aws_api_gateway_method_response" "function1_response_200" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_resource.function1_api_resource.id
  http_method = aws_api_gateway_method.function1_lambda_method.http_method
  status_code = "200"
}

# point API endpoint at lambda function
resource "aws_api_gateway_integration" "function1_api_integration" {
  rest_api_id             = aws_api_gateway_rest_api.lambda_api.id
  resource_id             = aws_api_gateway_method.function1_lambda_method.resource_id
  http_method             = aws_api_gateway_method.function1_lambda_method.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.function1_python.invoke_arn
}

resource "aws_api_gateway_integration_response" "function1" {
  depends_on = [
    aws_api_gateway_integration.function1_api_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  resource_id = aws_api_gateway_method.function1_lambda_method.resource_id
  http_method = aws_api_gateway_method.function1_lambda_method.http_method
  status_code = aws_api_gateway_method_response.function1_response_200.status_code
}

# add permission for gateway to invoke lambdas
resource "aws_lambda_permission" "function1_apigw_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function1_python.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.lambda_api.execution_arn}/*/*"
}

# create lambda function
resource "aws_lambda_function" "function1_python" {
  filename         = data.archive_file.function1_lambda_code.output_path
  function_name    = "${var.instance}-function1"
  role             = aws_iam_role.lambda_role.arn
  handler          = "function1.lambda_handler"
  runtime          = "python3.7"
  source_code_hash = filesha256(data.archive_file.function1_lambda_code.output_path)
  publish          = true
  layers           = [aws_lambda_layer_version.lambda_layer.arn]
  timeout          = 60
}
