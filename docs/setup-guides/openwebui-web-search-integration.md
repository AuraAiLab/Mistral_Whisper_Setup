# Web Search Integration for OpenWebUI

This guide explains how to add web search capabilities to OpenWebUI with a focus on privacy and uncensored search results.

## Quick Setup - DuckDuckGo (Privacy-Focused)

DuckDuckGo is integrated directly into OpenWebUI and provides a good balance of privacy and ease of setup:

1. The deployment has already been configured with the following environment variables:
   ```yaml
   - name: WEB_SEARCH_ENABLED
     value: "true"
   - name: WEB_SEARCH_DEFAULT
     value: "duckduckgo"
   - name: WEB_SEARCH_RESULT_COUNT
     value: "5"
   ```

2. To apply this configuration, run:
   ```bash
   kubectl apply -f configs/openwebui/openwebui-deployment.yaml
   ```

3. Restart your OpenWebUI pod:
   ```bash
   kubectl rollout restart deployment openwebui -n openwebui
   ```

## Alternative: Self-Hosted SearXNG (Maximum Privacy)

For complete control over your search privacy, you can set up SearXNG - a self-hosted, meta search engine:

1. Create a new namespace for SearXNG:
   ```bash
   kubectl create namespace searxng
   ```

2. Create a SearXNG deployment:
   ```bash
   cat <<EOF | kubectl apply -f -
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: searxng
     namespace: searxng
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: searxng
     template:
       metadata:
         labels:
           app: searxng
       spec:
         containers:
         - name: searxng
           image: searxng/searxng:latest
           ports:
           - containerPort: 8080
           env:
           - name: BASE_URL
             value: "http://searxng-service.searxng.svc.cluster.local:8080/"
           - name: INSTANCE_NAME
             value: "Private Search Engine"
           - name: AUTOCOMPLETE
             value: "google"
           - name: DEFAULT_LANG
             value: "en"
           - name: DISABLE_METRICS
             value: "true"
   EOF
   ```

3. Create a SearXNG service:
   ```bash
   cat <<EOF | kubectl apply -f -
   apiVersion: v1
   kind: Service
   metadata:
     name: searxng-service
     namespace: searxng
   spec:
     selector:
       app: searxng
     ports:
     - port: 8080
       targetPort: 8080
     type: LoadBalancer
   EOF
   ```

4. Update OpenWebUI to use SearXNG:
   ```yaml
   - name: WEB_SEARCH_ENABLED
     value: "true"
   - name: WEB_SEARCH_DEFAULT
     value: "custom"
   - name: WEB_SEARCH_CUSTOM_NAME
     value: "SearXNG"
   - name: WEB_SEARCH_CUSTOM_URL
     value: "http://searxng-service.searxng.svc.cluster.local:8080/search?q={query}"
   - name: WEB_SEARCH_RESULT_COUNT
     value: "5"
   ```

5. Apply the updated configuration and restart OpenWebUI.

## How to Use Web Search with Mistral

Once you've applied the configuration:

1. In OpenWebUI, create a new chat with your Mistral model
2. Click the **Tools** button in the chat interface to enable web search capabilities 
3. Ask a question that requires up-to-date information
4. The model will now use the search API to get current information and provide it in the response

## Advanced Configuration Options

### Customize Search Settings for DuckDuckGo

You can add additional parameters for DuckDuckGo searches by modifying the deployment:

```yaml
- name: WEB_SEARCH_DUCKDUCKGO_SAFESEARCH
  value: "-1"  # -1 for no filtering, 0 for moderate, 1 for strict
```

### Using Tor with SearXNG for Enhanced Privacy

For maximum privacy, you can configure SearXNG to route searches through Tor:

1. Add Tor as a sidecar container to your SearXNG deployment
2. Configure SearXNG to use the Tor proxy

See the [SearXNG documentation](https://searxng.github.io/searxng/admin/settings/settings.html#outgoing.proxies) for detailed instructions.

## Troubleshooting

If you encounter issues with web search:

1. Verify that web search is enabled in the OpenWebUI settings
2. Check the OpenWebUI logs:
   ```bash
   kubectl logs -n openwebui -l app=openwebui | grep -i search
   ```
3. For DuckDuckGo, be aware there may be rate limiting if too many requests are made in a short time
4. With self-hosted SearXNG, check the SearXNG logs for any errors:
   ```bash
   kubectl logs -n searxng -l app=searxng
   ```
