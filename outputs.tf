output "litellm_endpoint" {
  description = "LiteLLM Endpoint"
  value       = "http://${aws_instance.inf_nodes["cpu"].public_ip}:4000/ui"
}

output "vllm_endpoint" {
  description = "vLLM Endpoint"
  value       = "http://${aws_instance.inf_nodes["gpu"].public_ip}:8000/v1"
}
