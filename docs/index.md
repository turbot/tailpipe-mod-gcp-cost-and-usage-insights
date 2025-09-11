# GCP Cloud Billing Insights Mod

[Tailpipe](https://tailpipe.io) is an open-source CLI tool that allows you to collect logs and query them with SQL.

[Google Cloud Platform (GCP)](https://cloud.google.com/) is a suite of cloud computing services that runs on the same infrastructure that Google uses internally for its end-user products.

The [GCP Cloud Billing Insights Mod](https://hub.powerpipe.io/mods/turbot/tailpipe-mod-gcp-cloud-billing-insights) contains pre-built dashboards which can be used to monitor and analyze costs across your GCP projects using [Cloud Billing Reports](https://cloud.google.com/billing/docs/reports).

<img src="https://raw.githubusercontent.com/turbot/tailpipe-mod-gcp-cloud-billing-insights/main/docs/images/gcp_cloud_billing_insights_cost_by_project_dashboard.png" width="50%" type="thumbnail"/>
<img src="https://raw.githubusercontent.com/turbot/tailpipe-mod-gcp-cloud-billing-insights/main/docs/images/gcp_cloud_billing_insights_cost_by_service_dashboard.png" width="50%" type="thumbnail"/>
<img src="https://raw.githubusercontent.com/turbot/tailpipe-mod-gcp-cloud-billing-insights/main/docs/images/gcp_cloud_billing_insights_overview_dashboard.png" width="50%" type="thumbnail"/>

## Documentation

- **[Dashboards →](https://hub.powerpipe.io/mods/turbot/tailpipe-mod-gcp-cloud-billing-insights/dashboards)**

## Getting Started

Install Powerpipe from the [downloads](https://powerpipe.io/downloads) page:

```sh
# MacOS
brew install turbot/tap/powerpipe
```

```sh
# Linux or Windows (WSL)
sudo /bin/sh -c "$(curl -fsSL https://powerpipe.io/install/powerpipe.sh)"
```

This mod requires GCP Cloud Billing Reports to be collected using [Tailpipe](https://tailpipe.io) with the [GCP plugin](https://hub.tailpipe.io/plugins/turbot/gcp):

- [Get started with the GCP plugin for Tailpipe →](https://hub.tailpipe.io/plugins/turbot/gcp#getting-started)

Install the mod:

```sh
mkdir dashboards
cd dashboards
powerpipe mod install github.com/turbot/tailpipe-mod-gcp-cloud-billing-insights
```

### Browsing Dashboards

Start the dashboard server:

```sh
powerpipe server
```

Browse and view your dashboards at **http://localhost:9033**.