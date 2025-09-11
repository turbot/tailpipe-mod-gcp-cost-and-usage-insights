dashboard "cloud_billing_report_cost_by_service_dashboard" {
  title         = "GCP Cloud Billing Report: Cost by Service"
  documentation = file("./dashboards/docs/cloud_billing_report_cost_by_service_dashboard.md")

  tags = merge(local.gcp_cloud_billing_insights_common_tags, {
    type    = "Dashboard"
    service = "GCP/CloudBilling"
  })

  container {
    input "cloud_billing_report_cost_by_service_dashboard_projects" {
      title       = "Select project(s):"
      description = "Choose one or more GCP projects to analyze"
      type        = "multiselect"
      width       = 4
      query       = query.cloud_billing_report_cost_by_service_dashboard_projects_input
    }
  }

  container {
    card {
      width = 2
      query = query.cloud_billing_report_cost_by_service_dashboard_total_cost
      icon  = "attach_money"
      type  = "info"

      args = {
        "project_ids" = self.input.cloud_billing_report_cost_by_service_dashboard_projects.value
      }
    }

    card {
      width = 2
      query = query.cloud_billing_report_cost_by_service_dashboard_total_projects
      icon  = "folder"
      type  = "info"

      args = {
        "project_ids" = self.input.cloud_billing_report_cost_by_service_dashboard_projects.value
      }
    }

    card {
      width = 2
      query = query.cloud_billing_report_cost_by_service_dashboard_total_services
      icon  = "layers"
      type  = "info"

      args = {
        "project_ids" = self.input.cloud_billing_report_cost_by_service_dashboard_projects.value
      }
    }
  }

  container {
    chart {
      title = "Monthly Cost Trend"
      type  = "column"
      width = 6
      query = query.cloud_billing_report_cost_by_service_dashboard_monthly_cost

      args = {
        "project_ids" = self.input.cloud_billing_report_cost_by_service_dashboard_projects.value
      }

      legend {
        display = "none"
      }
    }

    chart {
      title = "Top 10 Services"
      type  = "table"
      width = 6
      query = query.cloud_billing_report_cost_by_service_dashboard_top_10_services

      args = {
        "project_ids" = self.input.cloud_billing_report_cost_by_service_dashboard_projects.value
      }
    }
  }

  container {
    table {
      title = "Service Costs"
      width = 12
      query = query.cloud_billing_report_cost_by_service_dashboard_service_costs

      args = {
        "project_ids" = self.input.cloud_billing_report_cost_by_service_dashboard_projects.value
      }
    }
  }
}

# Queries

query "cloud_billing_report_cost_by_service_dashboard_total_cost" {
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

query "cloud_billing_report_cost_by_service_dashboard_total_projects" {
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

query "cloud_billing_report_cost_by_service_dashboard_total_services" {
  sql = <<-EOQ
    select
      'Services' as label,
      count(distinct service_description) as value
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

query "cloud_billing_report_cost_by_service_dashboard_monthly_cost" {
  sql = <<-EOQ
    select
      strftime(date_trunc('month', usage_start_time), '%b %Y') as "Month",
      service_description as "Service",
      round(sum(cost), 2) as "Total Cost"
    from
      gcp_billing_report
    where
      ('all' in ($1) or project_id in $1)
    group by
      date_trunc('month', usage_start_time),
      service_description
    order by
      date_trunc('month', usage_start_time),
      sum(cost) desc;
  EOQ

  param "project_ids" {}

  tags = {
    folder = "Hidden"
  }
}

query "cloud_billing_report_cost_by_service_dashboard_top_10_services" {
  sql = <<-EOQ
    select
      service_description as "Service",
      round(sum(cost), 2) as "Total Cost"
    from
      gcp_billing_report
    where
      ('all' in ($1) or project_id in $1)
    group by
      service_description
    order by
      sum(cost) desc
    limit 10;
  EOQ

  param "project_ids" {}

  tags = {
    folder = "Hidden"
  }
}

query "cloud_billing_report_cost_by_service_dashboard_service_costs" {
  sql = <<-EOQ
    select
      service_description as "Service",
      project_name as "Project",
      coalesce(location.region, 'global') as "Location",
      round(sum(cost), 2) as "Total Cost"
    from
      gcp_billing_report
    where
      ('all' in ($1) or project_id in $1)
    group by
      service_description,
      project_name,
      location.region
    order by
      sum(cost) desc;
  EOQ

  param "project_ids" {}

  tags = {
    folder = "Hidden"
  }
}

query "cloud_billing_report_cost_by_service_dashboard_projects_input" {
  sql = <<-EOQ
    with project_ids as (
      select
        distinct on(project_id)
        project_id ||
        case
          when project_name is not null then ' (' || project_name || ')'
          else ''
        end as label,
        project_id as value
      from
        gcp_billing_report
      order by
        label
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
