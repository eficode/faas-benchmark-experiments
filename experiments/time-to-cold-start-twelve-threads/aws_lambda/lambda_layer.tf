resource "aws_lambda_layer_version" "time-to-cold-start-twelve-threads-lambda-layer" {
  filename = "${var.path_to_code}/lambda_layer.zip"
  layer_name = "time-to-cold-start-twelve-threads-lambda-layer"
  compatible_runtimes = ["python3.7"]
}

resource "aws_lambda_layer_version" "time-to-cold-start-twelve-threads-monolith-lambda-layer" {
  filename = "${var.path_to_code}/lambda_layer_monolith.zip"
  layer_name = "time-to-cold-start-twelve-threads-monolith-lambda-layer"
  compatible_runtimes = ["python3.7"]
}