#!/bin/bash

RAY_VERSION="2.4.0"

function job_submit() {
	DIR=$( echo "$1" | cut -d'/' -f1 )
	FILE=$( echo "$1" | cut -d'/' -f2 )

	if [ -z "$DIR" ] || [ ! -d "$DIR" ] || [ ! -f "$DIR/$FILE" ] || [[ $( echo "$FILE" | grep -o '...$' ) != ".py" ]]; then
		echo -e "Please provide the name of the python file to run.\n"
		echo "Note that it must be in the format {project-dir}/{entrypoint-file} and the file must have a '.py' extension."
		exit 6
	fi

	if [ ! -f "$DIR/requirements.txt" ]; then
		echo "$1/requirements.txt is missing for the project"
		exit 7
	fi

	REQS=$( cat "$DIR/requirements.txt" )
	if [ -z "$REQS" ]; then
		echo "$DIR/requirements.txt has no entries"
		exit 8
	fi

	tmp_env_yaml=$( mktemp )
	echo -e "---\npip:" > $tmp_env_yaml
	for req in $REQS; do
		echo "  - $req" >> $tmp_env_yaml
	done

	HTTPS_PROXY="socks5://127.0.0.1:8080" \
	RAY_ADDRESS="https://${RAY_USER}:${RAY_TOKEN}@${RAY_URL}" \
	ray job submit \
		--no-wait \
		--runtime-env $tmp_env_yaml \
		--working-dir "./$DIR" \
		-- python "$FILE"

	rm $tmp_env_yaml
}

function job_action() {
	if [ -z "$1" ]; then
		echo "Please provide the job action"
		exit 9
	fi

	if [[ "$1" == "delete" ]]; then
		echo -n "Are you sure you want to delete job $2? [y/N] "
		read -r CONFIRM
		if [ "$CONFIRM" != "y" ]; then
			echo "Skipping deleting"
			exit
		fi
	fi

	if [ -z "$2" ]; then
		echo "Please provide the job submission id"
		exit 10
	fi

	HTTPS_PROXY="socks5://127.0.0.1:8080" RAY_ADDRESS="https://${RAY_USER}:${RAY_TOKEN}@${RAY_URL}" ray job "$1" "$2"
}

if [ -z "$RAY_USER" ]; then
	echo "RAY_USER env variable is not set"
	exit 1
fi

if [ -z "$RAY_TOKEN" ]; then
	echo "RAY_TOKEN env variable is not set"
	exit 2
fi

if [ -z "$RAY_URL" ]; then
	echo "RAY_URL env variable is not set"
	exit 3
fi

INSTALLED_VERSION=$( ray --version 2>/dev/null )
if [ $? -ne 0 ] || [ -z "$INSTALLED_VERSION" ] || [[ $( echo $INSTALLED_VERSION | awk '{print $NF }' ) != "$RAY_VERSION" ]]; then
	echo -e "This script relies on ray $RAY_VERSION being installed.\n"
	echo -n "Please install ray with: pip install 'ray[default]==$RAY_VERSION' "
	echo "or source your ray mamba/conda/pipenv environment and run the script again."
	exit 4
fi

if [ ! -d .git ]; then
	echo "This script must be run from the root of the Github project"
	exit 5
fi

case "$1" in
	"submit" )
		job_submit "$2"
		;;
	"status" )
		job_action status "$2"
		;;
	"logs" )
		job_action logs "$2"
		;;
	"delete")
		job_action delete "$2"
		;;
	* )
		echo -e "Please provide the action you want to perform: submit, status, logs, delete.\n"
		echo "Example submission:"
		echo "  > ray-job.sh submit <project-dir>/<entrypoint-python-file>"
		echo -e "\nand for the other actions:"
		echo -e "  > ray-job.sh status|logs|delete <job-submission-id>\n"
		exit
		;;
esac
