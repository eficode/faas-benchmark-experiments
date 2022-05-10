# create IAM role for lambdas
resource "aws_iam_role" "lambda_role" {
  name               = "${var.instance}-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# TODO is this needed?
# attach permission to the iam role to allow lambdas to invoke other lambdas
# resource "aws_iam_role_policy_attachment" "lambda_full_access" {
# role       = aws_iam_role.lambda_role.name
# policy_arn = "arn:aws:iam::aws:policy/AWSLambdaFullAccess"
# }

# create API gateway
resource "aws_api_gateway_rest_api" "lambda_api" {
  name        = var.instance
  description = "${var.instance} benchmark environment"
}

# add a deployment of the api
resource "aws_api_gateway_deployment" "benchmark" {
  depends_on = [
    aws_api_gateway_integration.function1_api_integration,
  ]
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  stage_name  = "benchmark"
}

# create api useage plan key
resource "aws_api_gateway_api_key" "key" {
  name = "${var.instance}_key"
}

# create api usage plan
resource "aws_api_gateway_usage_plan" "plan" {
  name = "${var.instance}_usage_plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.lambda_api.id
    stage  = aws_api_gateway_deployment.benchmark.stage_name
  }

  throttle_settings {
    burst_limit = 1000
    rate_limit  = 1000
  }
}

# attach api key to useage plan
resource "aws_api_gateway_usage_plan_key" "key" {
  key_id        = aws_api_gateway_api_key.key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.plan.id
}
