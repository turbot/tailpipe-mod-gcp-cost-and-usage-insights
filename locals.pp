// Benchmarks and controls for specific services should override the "service" tag
locals {
  gcp_cloud_billing_insights_common_tags = {
    category = "Insights"
    plugin   = "gcp"
    service  = "GCP/CloudBilling"
  }
}
