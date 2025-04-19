#!/bin/bash
aws secretsmanager create-secret \
  --name db_credentials \
  --secret-string "{\"username\":\"$DB_USER\",\"password\":\"$DB_PASS\"}"
