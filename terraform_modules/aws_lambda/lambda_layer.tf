resource "aws_lambda_layer_version" "lambda_layer" {
  filename            = "${local.src_path}/lambda_layer.zip"
  layer_name          = "${var.instance}_lambda_layer"
  compatible_runtimes = ["python3.7"]
}

