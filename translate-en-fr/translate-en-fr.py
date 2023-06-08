from transformers import GenerationConfig, pipeline


class Translator:
    def __init__(self):
        gen_config = GenerationConfig.from_pretrained("t5-small")
        self.model = pipeline(
            "translation_en_to_fr", model="t5-small", generation_config=gen_config
        )

    def translate(self, text: str) -> str:
        model_output = self.model(text)
        return model_output[0]["translation_text"]


en_fr = Translator()
french = en_fr.translate(
    "The Linux kernel, at over 8 million lines of code and well over 1000 contributors to each release, is one of the largest and most active free software projects in existence."
)

print(f"\n{french}")
