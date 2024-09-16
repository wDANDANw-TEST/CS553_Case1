import gradio as gr
from huggingface_hub import InferenceClient
import torch
from transformers import pipeline

# Inference client setup
client = InferenceClient("HuggingFaceH4/zephyr-7b-beta")
pipe = pipeline("text-generation", "microsoft/Phi-3-mini-4k-instruct", torch_dtype=torch.bfloat16, device_map="auto")

# Global flag to handle cancellation
stop_inference = False

# Respond function for chatbot input
def respond(message, history, system_message="You are a helpful assistant", max_tokens=512, temperature=0.7, top_p=0.95, use_local_model=False):
    global stop_inference
    stop_inference = False
    
    # Initialize history if it's None
    if history is None:
        history = []

    if use_local_model:
        messages = [{"role": "system", "content": system_message}]
        for val in history:
            if val[0]:
                messages.append({"role": "user", "content": val[0]})
            if val[1]:
                messages.append({"role": "assistant", "content": val[1]})
        messages.append({"role": "user", "content": message})

        response = ""
        for output in pipe(
            messages,
            max_new_tokens=max_tokens,
            temperature=temperature,
            do_sample=True,
            top_p=top_p,
        ):
            if stop_inference:
                response = "Inference cancelled."
                yield history + [(message, response)]
                return
            token = output['generated_text'][-1]['content']
            response += token
            yield history + [(message, response)]  # Yield history + new response
    else:
        messages = [{"role": "system", "content": system_message}]
        for val in history:
            if val[0]:
                messages.append({"role": "user", "content": val[0]})
            if val[1]:
                messages.append({"role": "assistant", "content": val[1]})
        messages.append({"role": "user", "content": message})

        response = ""
        for message_chunk in client.chat_completion(
            messages,
            max_tokens=max_tokens,
            stream=True,
            temperature=temperature,
            top_p=top_p,
        ):
            if stop_inference:
                response = "Inference cancelled."
                yield history + [(message, response)]
                return
            token = message_chunk.choices[0].delta.content
            response += token
            yield history + [(message, response)]

def cancel_inference():
    global stop_inference
    stop_inference = True

# Function to update Gradio element dynamically
def update_css(command):
    if "jump" in command.lower():
        return """
            .gradio-container {
                animation: jump 1s ease infinite;
            }
            @keyframes jump {
                0%, 100% { transform: translateY(0); }
                50% { transform: translateY(-20px); }
            }
        """
    return ""

# Define the interface
with gr.Blocks() as demo:
    with gr.Row():
        with gr.Column(scale=1):
            code_panel = gr.Textbox(label="Gradio Code Panel", placeholder="Describe the Gradio element (e.g., gr.Button())")
            chat_input = gr.Textbox(label="Chat", placeholder="Type 'Make this block jump'", interactive=True)
            history_display = gr.Chatbot(label="Chat History")

            # Submit the CSS command and update history
            chat_input.submit(respond, [chat_input, history_display], history_display)
            css_response = gr.Code()

        with gr.Column(scale=1):
            render_output = gr.Markdown("<div class='gradio-container'>Rendered Gradio Element</div>")
            chat_input.submit(update_css, chat_input, render_output)

    # Add linter or checker functionality (basic linting for syntax)
    def linter(code):
        # Basic check to ensure valid Gradio element syntax
        if "gr." in code:
            return "Valid Gradio element!"
        return "Invalid Gradio element syntax. Please try again."

    code_panel.submit(linter, code_panel, history_display)

if __name__ == "__main__":
    demo.launch()