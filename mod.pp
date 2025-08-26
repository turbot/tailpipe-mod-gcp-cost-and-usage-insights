mod "gcp_cost_and_usage_insights" {
  # hub metadata
  title         = "GCP Cost and Usage Insights"
  description   = "Monitor and analyze costs across your GCP accounts using pre-built dashboards for GCP Cost and Usage Reports with Powerpipe and Tailpipe."
  color         = "#ea4335"
  documentation = file("./docs/index.md")
  icon          = "/images/mods/turbot/gcp-cost-and-usage-insights.svg"
  categories    = ["gcp", "cost", "dashboard", "public cloud"]
  database      = var.database

  opengraph {
    title       = "Powerpipe Mod for GCP Cost and Usage Insights"
    description = "Monitor and analyze costs across your GCP accounts using pre-built dashboards for GCP Cost and Usage Reports with Powerpipe and Tailpipe."
    image       = "/images/mods/turbot/gcp-cost-and-usage-insights-social-graphic.png"
  }
}
