# Custom CSS for a fancy look
custom_css = """
#main-container {
    background-color: #f0f0f0;
    font-family: 'Arial', sans-serif;
}
.gradio-container {
    max-width: 700px;
    margin: 0 auto;
    padding: 20px;
    background: white;
    box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
    border-radius: 10px;
}
.gr-button {
    background-color: #4CAF50;
    color: white;
    border: none;
    border-radius: 5px;
    padding: 10px 20px;
    cursor: pointer;
    transition: background-color 0.3s ease;
}
.gr-button:hover {
    background-color: #45a049;
}
.gr-slider input {
    color: #4CAF50;
}
.gr-chat {
    font-size: 16px;
}
#title {
    text-align: center;
    font-size: 2em;
    margin-bottom: 20px;
    color: #333;
}

.black-border {
    border: 3px double #000; /* Black border */
    padding: 10px;
    margin-bottom: 10px;
    box-shadow: 0 0 10px rgba(0, 0, 0, 0.1); /* Subtle shadow for better visibility */
    background: #f0f0f0; /* Light background for contrast */
    color: #333; /* Text color */
}

.black-border-2 {
    border: 3px double #000; /* Black border */
    padding: 10px;
    margin-bottom: 10px;
    box-shadow: 0 0 10px rgba(0, 0, 0, 0.1); /* Subtle shadow for better visibility */
    
}
"""

code_placeholder = """
with gr.Blocks():
    with gr.Row():
        gr.Button(elem_classes="try-it", value="1")

    with gr.Row():
        gr.Markdown(value="2")
"""

css_placeholder = """
.try-it {
    color: blue !important;
    font-size: 20px !important;
}
"""