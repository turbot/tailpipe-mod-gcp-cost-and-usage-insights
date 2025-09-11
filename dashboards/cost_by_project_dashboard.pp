dashboard "cloud_billing_report_cost_by_project_dashboard" {
  title         = "GCP Cloud Billing Report: Cost by Project"
  documentation = file("./dashboards/docs/cloud_billing_report_cost_by_project_dashboard.md")

  tags = merge(local.gcp_cloud_billing_insights_common_tags, {
    type    = "Dashboard"
    service = "GCP/CloudBilling"
  })

  container {
    # Multi-select Project Input
    input "cloud_billing_report_cost_by_project_dashboard_projects" {
      title       = "Select project(s):"
      description = "Choose one or more GCP projects to analyze."
      type        = "multiselect"
      width       = 4
      query       = query.cloud_billing_report_cost_by_project_dashboard_projects_input
    }
  }

  container {
    # Combined card showing Total Cost with Currency
    card {
      width = 2
      query = query.cloud_billing_report_cost_by_project_dashboard_total_cost
      icon  = "attach_money"
      type  = "info"

      args = {
        "project_ids" = self.input.cloud_billing_report_cost_by_project_dashboard_projects.value
      }
    }

    card {
      width = 2
      query = query.cloud_billing_report_cost_by_project_dashboard_total_projects
      icon  = "folder"
      type  = "info"

      args = {
        "project_ids" = self.input.cloud_billing_report_cost_by_project_dashboard_projects.value
      }
    }
  }

  container {
    # Cost Trend Charts
    chart {
      title = "Monthly Cost Trend"
      type  = "column"
      width = 12
      query = query.cloud_billing_report_cost_by_project_dashboard_monthly_cost

      args = {
        "project_ids" = self.input.cloud_billing_report_cost_by_project_dashboard_projects.value
      }

      legend {
        display = "none"
      }
    }
  }

  container {
    # Detailed Table
    table {
      title = "Project Costs"
      width = 12
      query = query.cloud_billing_report_cost_by_project_dashboard_project_costs

      args = {
        "project_ids" = self.input.cloud_billing_report_cost_by_project_dashboard_projects.value
      }
    }
  }
}

# Query Definitions

query "cloud_billing_report_cost_by_project_dashboard_total_cost" {
  sql = <<-EOQ
    select
      'Total Cost (' || currency || ')' as label,
      round(sum(cost), 2) as value
    from
      gcp_billing_report
    where
      ('all' in ($1) or project_id in $1)
    group by
      currency
    limit 1;
  EOQ

  param "project_ids" {}

  tags = {
    folder = "Hidden"
  }
}

query "cloud_billing_report_cost_by_project_dashboard_total_projects" {
  sql = <<-EOQ
    select
      'Projects' as label,
      count(distinct project_id) as value
    from
      gcp_billing_report
    where
      ('all' in ($1) or project_id in $1);
  EOQ

  param "project_ids" {}

  tags = {
    folder = "Hidden"
  }
}

query "cloud_billing_report_cost_by_project_dashboard_monthly_cost" {
  sql = <<-EOQ
    select
      strftime(date_trunc('month', usage_start_time), '%b %Y') as "Month",
      project_id as "Project",
      round(sum(cost), 2) as "Total Cost"
    from
      gcp_billing_report
    where
      ('all' in ($1) or project_id in $1)
    group by
      date_trunc('month', usage_start_time),
      project_id
    order by
      date_trunc('month', usage_start_time),
      sum(cost) desc;
  EOQ

  param "project_ids" {}

  tags = {
    folder = "Hidden"
  }
}

query "cloud_billing_report_cost_by_project_dashboard_project_costs" {
  sql = <<-EOQ
    select
      project_name as "Project",
      round(sum(cost), 2) as "Total Cost"
    from
      gcp_billing_report
    where
      ('all' in ($1) or project_id in $1)
    group by
      project_name
    order by
      sum(cost) desc;
  EOQ

  param "project_ids" {}

  tags = {
    folder = "Hidden"
  }
}

query "cloud_billing_report_cost_by_project_dashboard_projects_input" {
  sql = <<-EOQ
    with project_ids as (
      select
        distinct on(project_id)
        project_id || ' (' || coalesce(project_name, '') || ')' as label,
        project_id as value
      from
        gcp_billing_report
      where
        project_id is not null and project_id != ''
        and project_name is not null and project_name != ''
      order by label
    )
    select
      'All' as label,
      'all' as value
    union all
    select
      label,
      value
    from
      project_ids;
  EOQ

  tags = {
    folder = "Hidden"
  }
}
