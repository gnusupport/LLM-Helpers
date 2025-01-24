# Copyright (C) 2025-01-24 by Jean Louis, https://gnu.support

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.

# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# This Flask application serves as an API endpoint that accepts POST
# requests to generate textual descriptions of images using a
# pre-trained vision-to-sequence model (SmolVLM-500M-Instruct). When a
# request is received, it extracts an image URL and an optional prompt
# from the JSON payload, loads the image, and processes it along with
# the prompt using the model. The model generates a textual
# description of the image based on the provided prompt, and the
# response is returned as JSON containing the generated text. The
# application also manages GPU memory by clearing the cache before and
# after processing to optimize resource usage. The server runs locally
# on port 8080.
 
from flask import Flask, request, jsonify
import torch
from PIL import Image
from transformers import AutoProcessor, AutoModelForVision2Seq
from transformers.image_utils import load_image

# Clear GPU memory
torch.cuda.empty_cache()

app = Flask(__name__)

DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

# Initialize processor and model
processor = AutoProcessor.from_pretrained("SmolVLM-500M-Instruct")
model = AutoModelForVision2Seq.from_pretrained(
    "SmolVLM-500M-Instruct",
    torch_dtype=torch.bfloat16,
    _attn_implementation="eager",  # Disable FlashAttention
).to(DEVICE)

@app.route('/v1/chat/completions', methods=['POST'])
def describe_image():
    data = request.json
    image_url = data.get('image')
    prompt = data.get('prompt', "Can you describe this image?")

    # Load image from URL
    image = load_image(image_url)

    # Create input messages
    messages = [
        {
            "role": "user",
            "content": [
                {"type": "image"},
                {"type": "text", "text": prompt}
            ]
        },
    ]

    # Prepare inputs
    prompt = processor.apply_chat_template(messages, add_generation_prompt=True)
    inputs = processor(text=prompt, images=[image], return_tensors="pt")
    inputs = inputs.to(DEVICE)

    # Generate outputs
    generated_ids = model.generate(**inputs, max_new_tokens=500)
    generated_texts = processor.batch_decode(
        generated_ids,
        skip_special_tokens=True,
    )

    # Clear GPU memory
    torch.cuda.empty_cache()

    # Return the generated description
    return jsonify({
        "response": generated_texts[0]
    })

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=8080)
