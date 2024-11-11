# test_app.py

import pytest
import torch
from transformers import pipeline
from server import respond  # Assuming your main app script is named 'app.py'
import os

def test_env_token():
    try:
        token=os.getenv("HF_ACCESS_TOKEN")
        assert token is not None and token is not "" 
    except Exception as e:
        pytest.fail(f"Env Token Did not Get In: {e}")

# Cancelled Pipeline test due to time issues
# def test_pipeline_initialization():
#     # Initialize the pipeline
#     try:
#         pipe = pipeline(
#             "text-generation",
#             "microsoft/Phi-3-mini-4k-instruct",
#             torch_dtype=torch.bfloat16,
#             device_map="auto"
#         )
#     except Exception as e:
#         pytest.fail(f"Pipeline initialization failed with error: {e}")

# def test_model_response():
#     # Initialize the pipeline
#     pipe = pipeline(
#         "text-generation",
#         "microsoft/Phi-3-mini-4k-instruct",
#         torch_dtype=torch.bfloat16,
#         device_map="auto"
#     )
    
#     # Define a test input
#     test_input = "How do I style a Gradio button to be red?"
    
#     # Get the model's response
#     output = pipe(test_input, max_new_tokens=50)
    
#     # Assert that the output is not empty
#     assert output[0]['generated_text'], "Model output is empty."
#     # Optional: Add more specific assertions about the output

def test_respond_function():
    # Test the respond function from your Gradio app
    message = "Give me CSS code for a blue button."
    history = []
    response_generator = respond(message, history, use_local_model=False)
    
    # Collect responses from the generator
    responses = []
    for chatbot_state, history_state, message_input in response_generator:
        responses.append((chatbot_state, history_state, message_input))
    
    # Check that at least one response was yielded
    assert len(responses) > 0, "No response was yielded from the respond function."
    
    # Check that the final response is not empty
    final_chatbot_state = responses[-1][0]
    assert final_chatbot_state[-1][1], "Assistant's response is empty."