# Use official SearXNG image
FROM searxng/searxng:latest

# Copy our ultra-fast configuration
COPY kubernetes/02-configmap.yaml /tmp/configmap.yaml

# Extract settings from configmap and apply them
RUN mkdir -p /etc/searxng && \
    grep -A 10000 "settings.yml: |" /tmp/configmap.yaml | \
    tail -n +2 | \
    sed 's/^    //' > /etc/searxng/settings.yml

# Set environment variables for ultra-fast performance
ENV SEARXNG_SECRET="ryha-ai-ultra-fast-kubernetes-2024-advanced-anti-captcha"
ENV UWSGI_WORKERS=6
ENV UWSGI_THREADS=4
ENV UWSGI_BUFFER_SIZE=65536

# Expose port 8080
EXPOSE 8080

# Start SearXNG with optimized settings
CMD ["uwsgi", "--http-socket", "0.0.0.0:8080", "--module", "searx.webapp", "--workers", "6", "--threads", "4"]