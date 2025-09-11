dashboard "cloud_billing_report_overview_dashboard" {
  title         = "GCP Cloud Billing Report: Overview"
  documentation = file("./dashboards/docs/cloud_billing_report_overview_dashboard.md")

  tags = merge(local.gcp_cloud_billing_insights_common_tags, {
    type    = "Dashboard"
    service = "GCP/CloudBilling"
  })

  container {
    input "cloud_billing_report_overview_dashboard_projects" {
      title       = "Select project(s):"
      description = "Choose one or more GCP projects to analyze."
      type        = "multiselect"
      width       = 4
      query       = query.cloud_billing_report_overview_dashboard_projects_input
    }
  }

  container {
    # Summary Metrics
    card {
      width = 2
      query = query.cloud_billing_report_overview_dashboard_total_cost
      icon  = "attach_money"
      type  = "info"

      args = {
        "project_ids" = self.input.cloud_billing_report_overview_dashboard_projects.value
      }
    }

    card {
      width = 2
      query = query.cloud_billing_report_overview_dashboard_total_projects
      icon  = "folder"
      type  = "info"

      args = {
        "project_ids" = self.input.cloud_billing_report_overview_dashboard_projects.value
      }
    }

    card {
      width = 2
      query = query.cloud_billing_report_overview_dashboard_total_services
      icon  = "layers"
      type  = "info"

      args = {
        "project_ids" = self.input.cloud_billing_report_overview_dashboard_projects.value
      }
    }
  }

  container {
    # Graphs
    chart {
      title = "Monthly Cost Trend"
      type  = "column"
      width = 6
      query = query.cloud_billing_report_overview_dashboard_monthly_cost

      args = {
        "project_ids" = self.input.cloud_billing_report_overview_dashboard_projects.value
      }

      legend {
        display = "none"
      }
    }

    chart {
      title = "Daily Cost Trend"
      type  = "line"
      width = 6
      query = query.cloud_billing_report_overview_dashboard_daily_cost

      args = {
        "project_ids" = self.input.cloud_billing_report_overview_dashboard_projects.value
      }

      legend {
        display = "none"
      }
    }
  }

  container {
    # Tables
    chart {
      title = "Top 10 Projects"
      type  = "table"
      width = 6
      query = query.cloud_billing_report_overview_dashboard_top_10_projects

      args = {
        "project_ids" = self.input.cloud_billing_report_overview_dashboard_projects.value
      }
    }

    chart {
      title = "Top 10 Locations"
      type  = "table"
      width = 6
      query = query.cloud_billing_report_overview_dashboard_top_10_locations

      args = {
        "project_ids" = self.input.cloud_billing_report_overview_dashboard_projects.value
      }
    }

    chart {
      title = "Top 10 Services"
      type  = "table"
      width = 6
      query = query.cloud_billing_report_overview_dashboard_top_10_services

      args = {
        "project_ids" = self.input.cloud_billing_report_overview_dashboard_projects.value
      }
    }
  }
}

# Queries

query "cloud_billing_report_overview_dashboard_total_cost" {
  sql = <<-EOQ
    select
      'Total Cost (' || currency || ')' as label,
      round(sum(cost), 2) as value
    from
      gcp_billing_report
    where
      ('all' in ($1) or project_id in $1)
    group by
      currency;
  EOQ

  param "project_ids" {}

  tags = {
    folder = "Hidden"
  }
}

query "cloud_billing_report_overview_dashboard_total_projects" {
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

query "cloud_billing_report_overview_dashboard_total_services" {
  sql = <<-EOQ
    select
      'Services' as label,
      count(distinct service_id) as value
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

query "cloud_billing_report_overview_dashboard_monthly_cost" {
  sql = <<-EOQ
    select
      date_trunc('month', usage_start_time)::timestamp as "Month",
      round(sum(cost), 2) as "Total Cost"
    from
      gcp_billing_report
    where
      ('all' in ($1) or project_id in $1)
    group by
      date_trunc('month', usage_start_time)
    order by
      date_trunc('month', usage_start_time);
  EOQ

  param "project_ids" {}

  tags = {
    folder = "Hidden"
  }
}

query "cloud_billing_report_overview_dashboard_daily_cost" {
  sql = <<-EOQ
    select
      date_trunc('day', usage_start_time)::timestamp as "Date",
      round(sum(cost), 2) as "Total Cost"
    from
      gcp_billing_report
    where
      ('all' in ($1) or project_id in $1)
    group by
      date_trunc('day', usage_start_time)
    order by
      date_trunc('day', usage_start_time);
  EOQ

  param "project_ids" {}

  tags = {
    folder = "Hidden"
  }
}

query "cloud_billing_report_overview_dashboard_top_10_projects" {
  sql = <<-EOQ
    select
      project_id as "Project ID",
      round(sum(cost), 2) as "Total Cost"
    from
      gcp_billing_report
    where
      ('all' in ($1) or project_id in $1)
    group by
      project_id
    order by
      sum(cost) desc
    limit 10;
  EOQ

  param "project_ids" {}

  tags = {
    folder = "Hidden"
  }
}

query "cloud_billing_report_overview_dashboard_top_10_locations" {
  sql = <<-EOQ
    select
      coalesce(location.region, 'global') as "Region",
      coalesce(location.zone, '-') as "Zone",
      round(sum(cost), 2) as "Total Cost"
    from
      gcp_billing_report
    where
      ('all' in ($1) or project_id in $1)
    group by
      location.region,
      location.zone
    order by
      sum(cost) desc
    limit 10;
  EOQ

  param "project_ids" {}

  tags = {
    folder = "Hidden"
  }
}

query "cloud_billing_report_overview_dashboard_top_10_services" {
  sql = <<-EOQ
    select
      service_description as "Service",
      service_id as "Service ID",
      round(sum(cost), 2) as "Total Cost"
    from
      gcp_billing_report
    where
      ('all' in ($1) or project_id in $1)
    group by
      service_description,
      service_id
    order by
      sum(cost) desc
    limit 10;
  EOQ

  param "project_ids" {}

  tags = {
    folder = "Hidden"
  }
}

query "cloud_billing_report_overview_dashboard_projects_input" {
  sql = <<-EOQ
    with project_ids as (
      select
        distinct on(project_id)
        project_id || ' (' || coalesce(project_name, '') || ')' as label,
        project_id as value
      from
        gcp_billing_report
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
