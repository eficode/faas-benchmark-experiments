# output the invocation url
output "invoke_url" {
  value = aws_api_gateway_deployment.track-cloudfunctions-lifecycle-prod.invoke_url
}

# output the api key
output "api_key" {
  value = aws_api_gateway_api_key.track-cloudfunctions-lifecycle-key.value
}
