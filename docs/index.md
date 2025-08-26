# GCP Cost and Usage Insights Mod for Powerpipe

Cost and usage analysis dashboards for GCP Cloud Billing Reports.

## References

[GCP Cloud Billing Reports](https://cloud.google.com/billing/docs/reports) provide detailed cost and usage data for your Google Cloud resources. This data includes:

- Project-level cost breakdowns
- Service and SKU-level usage details
- Location-based cost analysis
- Resource labels and system labels
- Credits and adjustments

## Dashboards

The GCP Cost and Usage Insights Mod includes the following dashboards:

- [Overview Dashboard](overview_dashboard.md) - Get a high-level view of your GCP costs, including trends and top spending areas.
- [Cost by Project Dashboard](cost_by_project_dashboard.md) - Analyze costs by GCP project.
- [Cost by Location Dashboard](cost_by_location_dashboard.md) - Break down costs by GCP regions and zones.
- [Cost by Service Dashboard](cost_by_service_dashboard.md) - Examine costs by GCP services and SKUs.
- [Cost by Label Dashboard](cost_by_label_dashboard.md) - Analyze costs using project labels, resource labels, and system labels.

## Requirements

- GCP Cloud Billing Reports must be configured and collected using Tailpipe with the GCP plugin.
- Powerpipe must be installed and configured to access the collected data.

## Usage

1. Install Powerpipe (if not already installed):
   ```sh
   brew tap turbot/tap
   brew install powerpipe
   ```

2. Clone or download this repository.

3. Install the mod:
   ```sh
   cd /path/to/dashboards
   powerpipe mod init
   powerpipe mod install github.com/turbot/tailpipe-mod-gcp-cost-and-usage-insights
   ```

4. Open the dashboard:
   ```sh
   powerpipe server
   ```

5. Visit [http://localhost:9033](http://localhost:9033) to access your dashboards.

## Getting Started

The dashboards require your GCP Cloud Billing Reports data to be collected using Tailpipe. Follow these steps:

1. [Install and configure Tailpipe](https://tailpipe.io/downloads)
2. [Configure the GCP plugin](https://hub.tailpipe.io/plugins/turbot/gcp)
3. Configure Cloud Billing Reports collection
4. Run Tailpipe to collect the data
5. Launch the dashboards using Powerpipe

For detailed setup instructions, please see the [Getting Started Guide](https://powerpipe.io/docs/getting-started).

## Open Source & Contributing

This repository is published under the [Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0). Please see our [code of conduct](https://github.com/turbot/.github/blob/main/CODE_OF_CONDUCT.md). We look forward to collaborating with you!

- [Contributing Guide](https://github.com/turbot/.github/blob/main/CONTRIBUTING.md)
- [Security Policy](https://github.com/turbot/steampipe/security/policy)
- [License](LICENSE)