#!/bin/bash

set -e

source "$fbrd/fb_cli/utils.sh"

# provision infrastructure, run experiment code and then destroy infrastructure

# the experiment name to test
experiment_name=$1
# unique experiment idenfifier for the experiments started in parallel for the different cloud providers
experiment_meta_identifier=$2

# ===== create infrastructure

pmsg "Bootstrapping cloud functions ..."
bash "$fbrd/orchestration/orchestrator.sh" "$experiment_name" "bootstrap" "azure_functions"

pmsg "Bootstrapping client vm ..."
bash "$fbrd/orchestration/orchestrator.sh" "$experiment_name" "bootstrap" "aws_ec2"

# ====== run experiment

pmsg "Running experiment ..."
bash "$fbrd/orchestration/executor.sh" "$experiment_name" "$experiment_meta_identifier" "azure_functions"

# ====== destroy infrastructure

pmsg "Destroying cloud functions ..."
bash "$fbrd/orchestration/orchestrator.sh" "$experiment_name" "destroy" "azure_functions"

pmsg "Destroying client vm ..."
bash "$fbrd/orchestration/orchestrator.sh" "$experiment_name" "destroy" "aws_ec2"

# ===== remove experiment pid file

pmsg "Removing experiment pidfile"

rm -f "/tmp/$experiment_name-azure_functions.pid"

smsg "Done running experiment orchestration."