import gradio as gr
from huggingface_hub import InferenceClient
import torch
from transformers import pipeline

import cssutils
from css import custom_css, code_placeholder, css_placeholder
import os

# Global flag to handle cancellation
stop_inference = False

# Inference client setup
client = InferenceClient("HuggingFaceH4/zephyr-7b-beta", token=os.environ["HF_ACCESS_TOKEN"])
pipe = pipeline(
    "text-generation",
    "microsoft/Phi-3-mini-4k-instruct",
    torch_dtype=torch.bfloat16,
    device_map="auto"  
)

# Global flag to handle cancellation
stop_inference = False

def create_prompt_from_messages(messages):
    prompt = ""
    for message in messages:
        role = message['role']
        content = message['content']
        if role == 'system':
            prompt += f"{content}\n\n"
        elif role == 'user':
            prompt += f"User: {content}\n"
        elif role == 'assistant':
            prompt += f"Assistant: {content}\n"
    prompt += "Assistant: "
    return prompt

def respond(
    message,
    history,
    system_message="You are a friendly Gradio and CSS expert. Provide CSS for Gradio elements.",
    max_tokens=512,
    temperature=0.7,
    top_p=0.95,
    use_local_model=False,
):
    global stop_inference
    stop_inference = False  # Reset cancellation flag

    # Create a local copy of the history
    if history is None:
        history = []
    else:
        history = history.copy()

    history.append((message, ""))  # Add user's message to history
    yield history, history, ""  # Update chatbot with user's message and clear input

    # Prepare messages for the model
    messages = [{"role": "system", "content": system_message}]
    for user_msg, bot_msg in history[:-1]:
        messages.append({"role": "user", "content": user_msg})
        messages.append({"role": "assistant", "content": bot_msg})
    messages.append({"role": "user", "content": message})

    # Create prompt from messages
    prompt = create_prompt_from_messages(messages)
    response = ""

    if use_local_model:
        from transformers import AutoModelForCausalLM, AutoTokenizer, TextIteratorStreamer
        import threading

        model_name = "microsoft/Phi-3-mini-4k-instruct"
        tokenizer = AutoTokenizer.from_pretrained(model_name)
        model = AutoModelForCausalLM.from_pretrained(
            model_name,
            torch_dtype=torch.bfloat16,
            device_map="auto"
        )

        streamer = TextIteratorStreamer(tokenizer, skip_prompt=True, skip_special_tokens=True)

        input_ids = tokenizer(prompt, return_tensors="pt").input_ids.to(model.device)

        generation_kwargs = dict(
            input_ids=input_ids,
            max_new_tokens=max_tokens,
            temperature=temperature,
            top_p=top_p,
            do_sample=True,
            streamer=streamer
        )

        # Generate in a separate thread
        thread = threading.Thread(target=model.generate, kwargs=generation_kwargs)
        thread.start()

        try:
            for token in streamer:
                if stop_inference:
                    break
                response += token
                history[-1] = (message, response)
                yield history, history, ""  # Yield updated history and clear input
        except Exception as e:
            response = f"An error occurred: {str(e)}"
            history[-1] = (message, response)
            yield history, history, ""
            return

        thread.join()

    else:
        # API-based inference
        for message_chunk in client.chat_completion(
            messages,
            max_tokens=max_tokens,
            stream=True,
            temperature=temperature,
            top_p=top_p,
        ):
            
            if stop_inference:
                response = "Inference cancelled."
                history[-1] = (message, response)
                yield history, history, ""  # Update chatbot and clear input
                return
            token = message_chunk.get('choices', [{}])[0].get('delta', {}).get('content', '')
            response += token
            history[-1] = (message, response)
            yield history, history, ""  # Yield updated history and clear input

# Function to cancel inference
def cancel_inference():
    global stop_inference
    stop_inference = True

def check_css_validity(css_string):
    parser = cssutils.CSSParser()
    try:
        stylesheet = parser.parseString(css_string)
        return True, stylesheet.cssText.decode('utf-8')  # CSS is valid
    except Exception as e:
        return False, str(e)  # Invalid CSS with error message

with gr.Blocks(css=custom_css) as demo:
    with gr.Row():
        with gr.Column(elem_classes="black-border"):
            with gr.Column(elem_classes="black-border"):

                # Code panel for entering Gradio component code
                code_panel = gr.Code(
                    label="Gradio Code", 
                    language="python", 
                    value=code_placeholder,
                    lines=15,
                    scale=10
                )
        
                css_panel = gr.Code(
                    label="CSS Code", 
                    language="css", 
                    value=css_placeholder,
                    scale=3
                )
            
            # Button to trigger the rendering of components
            with gr.Column(elem_classes="black-border", scale=1):
                render_button = gr.Button("Render")

        # Render Playground
        with gr.Column(elem_classes="black-border-2") as dynamic_container:
            gr.Markdown(value="Playground Preview")

            # Update listener to call the function upon button click
            @gr.render(inputs=[code_panel, css_panel], triggers=[render_button.click])
            def update_playground(user_code, css_code):
                valid, minified_css_code = check_css_validity(css_code)
                if not valid:
                    gr.Markdown(f"<div style='text-align:center; color:red;'>CSS is not valid!</div>")
                    return

                # Inject CSS dynamically into the head
                gr.HTML(f"<style>{minified_css_code}</style>")

                # Clear the dynamic container
                dynamic_container.children = []

                local_scope = {}
                try:
                    # Dynamically execute user input code and create components
                    exec(user_code, globals(), local_scope)
                except Exception as e:
                    gr.Markdown(f"<div style='text-align:center; color:red;'>Error: {str(e)}</div>")
                    return

                # Add the generated components to the dynamic container
                with dynamic_container:
                    for val in local_scope.values():
                        if isinstance(val, gr.components.IOComponent) or isinstance(val, gr.Blocks):
                            val.render()

    # Add the chatbot at the bottom
    with gr.Row():
        with gr.Column(elem_classes="black-border"):
            gr.Markdown("## CSS Assistant")

            # Chatbot components
            chatbot = gr.Chatbot(height=300)

            # Accordion for chat history
            with gr.Accordion("Chat History", open=False):
                chat_history = gr.Chatbot()

            # Input for user messages
            message_input = gr.Textbox(
                label="Your message",
                placeholder="Give me suggestions on CSS for round gradio textbox for alerts."
            )

            # Send and Cancel buttons
            with gr.Row():
                send_button = gr.Button("Send")
                cancel_button = gr.Button("Cancel")

            # Additional settings in an accordion
            with gr.Accordion("Settings", open=False):
                use_local_model = gr.Checkbox(label="Use Local Model", value=False)
                system_message_input = gr.Textbox(
                    label="System Message",
                    value="You are a friendly Gradio and CSS expert. Provide CSS for Gradio elements."
                )
                max_tokens_slider = gr.Slider(
                    label="Max Tokens", minimum=1, maximum=2048, value=512, step=1
                )
                temperature_slider = gr.Slider(
                    label="Temperature", minimum=0.0, maximum=1.0, value=0.7, step=0.1
                )
                top_p_slider = gr.Slider(
                    label="Top P", minimum=0.0, maximum=1.0, value=0.95, step=0.05
                )

    # State to hold the chat history
    history = gr.State([])

    # Set up the send button click event
    send_button.click(
        fn=respond,
        inputs=[
            message_input,
            history,
            system_message_input,
            max_tokens_slider,
            temperature_slider,
            top_p_slider,
            use_local_model
        ],
        outputs=[chatbot, history, message_input],
        queue=True
    )

    # Set up the cancel button click event
    cancel_button.click(
        fn=cancel_inference,
        inputs=None,
        outputs=None
    )

    # Update chat history whenever history changes
    def update_chat_history(history):
        return history

    history.change(
        fn=update_chat_history,
        inputs=history,
        outputs=chat_history
    )

demo.launch()