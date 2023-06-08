# ray-one

## Local Development

### Create a new environment:

Using micromamba virtual environments is recommended:
```bash
python3 -m venv venv
source venv/bin/activate
```

### Install the dependencies for the project you're working on:

```bash
pip install -r {project-dir}/requirements.txt
```

### Start you local ray cluster and the serve service:

```bash
pip install 'ray[default]'
ray start --head --port=6379
```

### Install Ray Serve and initialise it

```bash
pip install 'ray[serve]'
serve start
```

### Job submission

Set the RAY_USER, RAY_TOKEN, and RAY_URL environment variables to the values given to you by the Ray team.

```bash
export RAY_USER=your-username
export RAY_TOKEN=your-token
export RAY_URL=the-url
```

Each project is in its own directory and is submitted to ray by running the `ray-job.py` script in the root directory.

For example, runnign the translate-en-fr project:
```bash
./ray-submit.py submit translate-en-fr/translate-en-fr.py
```

The submission script will ensure the requirements are specified for Ray and submit the job.

### Job status

You can check the status of your job by running the `ray-job.py` script with the `status` command.