#!/bin/bash

if [ -z "$RAY_JOB_SUBMIT_USER" ]; then
	echo "RAY_JOB_SUBMIT_USER env variable is not set"
	exit 1
fi

if [ -z "$RAY_JOB_SUBMIT_TOKEN" ]; then
	echo "RAY_JOB_SUBMIT_TOKEN env variable is not set"
	exit 2
fi

if [ -z "$RAY_JOB_SUBMIT_URL" ]; then
	echo "RAY_JOB_SUBMIT_URL env variable is not set"
	exit 3
fi

if [ ! -f requirements.txt ]; then
	echo "requirements.txt is missing"
	exit 4
fi

REQS=$( cat requirements.txt )
if [ -z "$REQS" ]; then
	echo "requirements.txt has no entries"
	exit 5
fi

RUNTIME_ENV="'{\"pip\": "
SEP=""
for req in $REQS; do
	RUNTIME_ENV="${RUNTIME_ENV}${SEP}[\"$req\"]"
	SEP=","
done
RUNTIME_ENV="${RUNTIME_ENV}}'"

# submit the ray job using user:token authentication
RAY_ADDRESS="https://${RAY_JOB_SUBMIT_USER}:${RAY_JOB_SUBMIT_TOKEN}@${RAY_JOB_SUBMIT_URL}" \
	ray job submit \
	--runtime-env-json "$RUNTIME_ENV" \
	--working-dir ./$(basename $(pwd)) \
	-- python instructor-service.py
