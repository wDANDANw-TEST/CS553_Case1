FROM ngrok/ngrok:latest

# Copy Ngrok configuration
COPY ngrok.yml /etc/ngrok/ngrok.yml

# Expose Ngrok web interface port
EXPOSE 4040

# Start Ngrok with the configuration file
CMD ["start", "--all", "--config", "/etc/ngrok/ngrok.yml"]