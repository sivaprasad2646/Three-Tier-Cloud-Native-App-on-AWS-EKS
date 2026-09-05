import os
import json
import boto3
import logging
from flask import Flask, request, jsonify
from flask_cors import CORS
from prometheus_flask_exporter import PrometheusMetrics
from prometheus_client import Counter, Histogram
import time

# ── App setup
app = Flask(__name__)
CORS(app)
metrics = PrometheusMetrics(app)

# ── Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ── Custom Prometheus metrics
ai_requests_total = Counter(
    "ai_assistant_requests_total",
    "Total number of AI assistant requests",
    ["status"]   # label: success or error
)

ai_response_latency = Histogram(
    "ai_assistant_response_duration_seconds",
    "Time taken to get response from Bedrock",
    buckets=[0.5, 1.0, 2.0, 5.0, 10.0, 30.0]
)

# ── Bedrock client
# No access keys — uses IRSA (pod's IAM role automatically)
bedrock = boto3.client(
    service_name="bedrock-runtime",
    region_name=os.environ.get("AWS_REGION", "us-east-1")
)

MODEL_ID = "amazon.nova-lite-v1:0"

# ── System prompt — scopes the AI to DevOps topics only
SYSTEM_PROMPT = """You are a DevOps AI Assistant specializing in:
- Kubernetes troubleshooting and concepts
- CI/CD pipelines (GitLab, Jenkins, ArgoCD)
- Docker and containerization
- AWS services (EKS, ECR, RDS, IAM, Secrets Manager)
- Terraform and Infrastructure as Code
- Prometheus, Grafana, and observability
- Helm charts and deployment strategies

Answer clearly and concisely. If the question is not related to DevOps,
infrastructure, or cloud computing, politely say it's outside your scope.
Keep answers under 300 words unless a detailed explanation is needed."""


def call_bedrock(query: str) -> str:
    body = json.dumps({
        "system": [
            {"text": SYSTEM_PROMPT}
        ],
        "messages": [
            {
                "role": "user",
                "content": [
                    {"text": query}
                ]
            }
        ],
        "inferenceConfig": {
            "max_new_tokens": 512,
            "temperature": 0.3
        }
    })

    response = bedrock.invoke_model(
        modelId=MODEL_ID,
        body=body,
        contentType="application/json",
        accept="application/json"
    )

    response_body = json.loads(response["body"].read())

    return response_body["output"]["message"]["content"][0]["text"]


# ── Health check endpoint
@app.route("/health")
def health():
    return jsonify({"status": "healthy", "service": "ai-assistant"}), 200


# ── Main AI endpoint
@app.route("/api/ai-assistant", methods=["POST"])
def ai_assistant():
    data = request.get_json()

    # Input validation
    if not data or "query" not in data:
        ai_requests_total.labels(status="error").inc()
        return jsonify({"error": "Missing required field: query"}), 400

    query = data["query"].strip()

    if not query:
        ai_requests_total.labels(status="error").inc()
        return jsonify({"error": "Query cannot be empty"}), 400

    if len(query) > 500:
        ai_requests_total.labels(status="error").inc()
        return jsonify({"error": "Query too long — max 500 characters"}), 400

    # Call Bedrock and track latency
    start_time = time.time()

    try:
        logger.info(f"Calling Bedrock with query: {query[:50]}...")
        answer = call_bedrock(query)
        duration = time.time() - start_time

        # Record metrics
        ai_response_latency.observe(duration)
        ai_requests_total.labels(status="success").inc()

        logger.info(f"Bedrock response received in {duration:.2f}s")

        return jsonify({
            "query": query,
            "answer": answer,
            "model": MODEL_ID,
            "latency_seconds": round(duration, 2)
        }), 200

    except bedrock.exceptions.ThrottlingException:
        ai_requests_total.labels(status="error").inc()
        logger.error("Bedrock throttled the request")
        return jsonify({"error": "Service busy — please try again"}), 429

    except Exception as e:
        ai_requests_total.labels(status="error").inc()
        logger.error(f"Bedrock call failed: {str(e)}")
        return jsonify({"error": "AI service temporarily unavailable"}), 503


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5001, debug=False)