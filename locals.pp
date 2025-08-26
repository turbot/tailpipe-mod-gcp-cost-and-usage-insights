// Benchmarks and controls for specific services should override the "service" tag
locals {
  gcp_cost_and_usage_insights_common_tags = {
    category = "Insights"
    plugin   = "gcp"
    service  = "GCP/CloudBillingReports"
  }
}
