#!/bin/bash

set -e

ENDPOINT=$(terraform output -raw gateway)
API_KEY=$(terraform output -raw api_key)
FUNCTION_NAME="$(terraform output -raw instance)-function1"

curl -X POST -H "x-api-key: $API_KEY" -H "Content-Type: application/json" -d '{}' "$ENDPOINT/$FUNCTION_NAME"
