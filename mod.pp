mod "gcp_cloud_billing_insights" {
  # hub metadata
  title         = "GCP Cloud Billing Insights"
  description   = "Monitor and analyze costs across your GCP accounts using pre-built dashboards for GCP Cloud Billing Reports with Powerpipe and Tailpipe."
  color         = "#ea4335"
  documentation = file("./docs/index.md")
  icon          = "/images/mods/turbot/gcp-cloud-billing-insights.svg"
  categories    = ["gcp", "cost", "dashboard", "public cloud"]
  database      = var.database

  opengraph {
    title       = "Powerpipe Mod for GCP Cloud Billing Insights"
    description = "Monitor and analyze costs across your GCP accounts using pre-built dashboards for GCP Cloud Billing Reports with Powerpipe and Tailpipe."
    image       = "/images/mods/turbot/gcp-cloud-billing-insights-social-graphic.png"
  }
}
