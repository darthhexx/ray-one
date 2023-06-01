# ray-one

## Local Development

### Create a new environment and source it:

```bash
python3 -m venv venv
source venv/bin/activate
```

### Install the dependencies:

```bash
pip install -r requirements.txt
```

### Start you local ray cluster and the serve service:

```bash
ray start --head --port=6379
```

### Install Ray Serve and initialise it

```bash
pip install 'ray[serve]'
serve start --http-port=8000
```
