from typing import List

import numpy as np
from fastapi import Body, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from InstructorEmbedding import INSTRUCTOR
from pydantic import BaseModel
from ray import serve
from transformers import AutoTokenizer

# In development you do not want to load the large models
DEV_MODE = True

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST"],
)


class Payload(BaseModel):
    instruction: str
    sentence: str
    model: str | None = "base"


class BatchPayload(BaseModel):
    encode: List
    model: str | None = "base"


class Result(BaseModel):
    status: str
    result: List


@serve.deployment(num_replicas=1, ray_actor_options={"num_cpus": 8, "num_gpus": 0.2})
@serve.ingress(app)
class InstructorEmbeddings:
    def __init__(self):
        # Load models
        self.model_base = INSTRUCTOR("hkunlp/instructor-base")
        if not DEV_MODE:
            self.model_large = INSTRUCTOR("hkunlp/instructor-large")
            self.model_xl = INSTRUCTOR("hkunlp/instructor-xl")

        self.tokenizer_base = AutoTokenizer.from_pretrained("hkunlp/instructor-base")
        if not DEV_MODE:
            self.tokenizer_large = AutoTokenizer.from_pretrained(
                "hkunlp/instructor-large"
            )
            self.tokenizer_xl = AutoTokenizer.from_pretrained("hkunlp/instructor-xl")

    # Note: This is always required for a serve model,
    #       because we monitor this endpoint in production
    @app.get("/health-check")
    def healthcheck(self) -> Result:
        return Result(status="ok", result=[])

    @app.post("/encode")
    def embeddings(self, body: Payload = Body()) -> Result:
        model = self.model_base
        tokenizer = self.tokenizer_base

        # Only load additonal models when we aren't in dev mode
        if not DEV_MODE and body.model == "large":
            model = self.model_large
            tokenizer = self.tokenizer_large
        elif not DEV_MODE and body.model == "xl":
            model = self.model_xl
            tokenizer = self.tokenizer_xl

        # Add 1 to account for the instruct/sentence separation token
        token_length = len(tokenizer(body.instruction + body.sentence)["input_ids"]) + 1
        if token_length > 512:
            return Result(
                status=(
                    "Error: `max_seq_length` is 512 tokens: query size is %d tokens (%d characters)"
                    % (token_length, (len(body.instruction) + len(body.sentence)))
                ),
                result=[],
            )

        embeddings = model.encode([[body.instruction, body.sentence]])
        return Result(status="ok", result=embeddings.tolist()[0])

    @app.post("/encode-batch")
    def embeddings(self, body: BatchPayload = Body()) -> Result:
        if str(type(body.encode)) != "<class 'list'>":
            return Result(
                status=(
                    "Error: the encode parameter is not the correct type, should be `<class 'list'>` but it is `%s`"
                    % type(body.encode)
                ),
                result=[],
            )

        model = self.model_base
        # Only allow model selection if we aren't in dev mode
        if not DEV_MODE and body.model == "large":
            model = self.model_large
        elif not DEV_MODE and body.model == "xl":
            model = self.model_xl

        embeddings = model.encode(body.encode)
        return Result(status="ok", result=embeddings.tolist())


serve.run(
    InstructorEmbeddings.bind(),
    name="InstructorEmbeddings",
    route_prefix="/embeddings/instructor",
    _blocking=False,
)
