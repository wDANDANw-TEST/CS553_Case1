import os

# Get the access token from an environment variable (GitHub Secrets)
access_token = os.getenv("HF_ACCESS_TOKEN")

# Set the environment variable on the Hugging Face container
with open("/etc/environment", "a") as env_file:
    env_file.write(f"\nHF_ACCESS_TOKEN={access_token}\n")

print("HF_ACCESS_TOKEN set in environment.")