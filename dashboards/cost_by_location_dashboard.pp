dashboard "cloud_billing_report_cost_by_location_dashboard" {
  title         = "GCP Cloud Billing Report: Cost by Location"
  documentation = file("./dashboards/docs/cloud_billing_report_cost_by_location_dashboard.md")

  tags = merge(local.gcp_cloud_billing_insights_common_tags, {
    type    = "Dashboard"
    service = "GCP/CloudBilling"
  })

  container {
    # Multi-select Project Input
    input "cloud_billing_report_cost_by_location_dashboard_projects" {
      title       = "Select project(s):"
      description = "Choose one or more GCP projects to analyze."
      type        = "multiselect"
      width       = 4
      query       = query.cloud_billing_report_cost_by_location_dashboard_projects_input
    }
  }

  container {
    # Combined cards showing various metrics
    card {
      width = 2
      query = query.cloud_billing_report_cost_by_location_dashboard_total_cost
      icon  = "attach_money"
      type  = "info"

      args = {
        "project_ids" = self.input.cloud_billing_report_cost_by_location_dashboard_projects.value
      }
    }

    card {
      width = 2
      query = query.cloud_billing_report_cost_by_location_dashboard_total_projects
      icon  = "folder"
      type  = "info"

      args = {
        "project_ids" = self.input.cloud_billing_report_cost_by_location_dashboard_projects.value
      }
    }

    card {
      width = 2
      query = query.cloud_billing_report_cost_by_location_dashboard_total_locations
      icon  = "globe"
      type  = "info"

      args = {
        "project_ids" = self.input.cloud_billing_report_cost_by_location_dashboard_projects.value
      }
    }

    card {
      width = 2
      query = query.cloud_billing_report_cost_by_location_dashboard_total_zones
      icon  = "location_on"
      type  = "info"

      args = {
        "project_ids" = self.input.cloud_billing_report_cost_by_location_dashboard_projects.value
      }
    }
  }

  container {
    # Cost Trend Graphs
    chart {
      title = "Monthly Cost Trend by Location"
      type  = "column"
      width = 6
      query = query.cloud_billing_report_cost_by_location_dashboard_monthly_cost

      args = {
        "project_ids" = self.input.cloud_billing_report_cost_by_location_dashboard_projects.value
      }

      legend {
        display = "none"
      }
    }

    chart {
      title = "Top 10 Locations"
      type  = "table"
      width = 6
      query = query.cloud_billing_report_cost_by_location_dashboard_top_10_locations

      args = {
        "project_ids" = self.input.cloud_billing_report_cost_by_location_dashboard_projects.value
      }
    }
  }

  container {
    # Detailed Table
    table {
      title = "Location Costs"
      width = 12
      query = query.cloud_billing_report_cost_by_location_dashboard_location_costs

      args = {
        "project_ids" = self.input.cloud_billing_report_cost_by_location_dashboard_projects.value
      }
    }
  }
}

# Query Definitions

query "cloud_billing_report_cost_by_location_dashboard_total_cost" {
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

query "cloud_billing_report_cost_by_location_dashboard_total_projects" {
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

query "cloud_billing_report_cost_by_location_dashboard_total_locations" {
  sql = <<-EOQ
    select
      'Locations' as label,
      count(distinct coalesce(location.region, 'global')) as value
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

query "cloud_billing_report_cost_by_location_dashboard_total_zones" {
  sql = <<-EOQ
    select
      'Zones' as label,
      count(distinct coalesce(location.zone, 'global')) as value
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

query "cloud_billing_report_cost_by_location_dashboard_monthly_cost" {
  sql = <<-EOQ
    select
      date_trunc('month', usage_start_time)::timestamp as "Month",
      coalesce(location.region, 'global') as "Location",
      round(sum(cost), 2) as "Total Cost"
    from
      gcp_billing_report
    where
      ('all' in ($1) or project_id in $1)
    group by
      date_trunc('month', usage_start_time),
      coalesce(location.region, 'global')
    order by
      date_trunc('month', usage_start_time),
      sum(cost) desc;
  EOQ

  param "project_ids" {}

  tags = {
    folder = "Hidden"
  }
}

query "cloud_billing_report_cost_by_location_dashboard_top_10_locations" {
  sql = <<-EOQ
    select
      coalesce(location.region, 'global') as "Location",
      location.zone as "Zone",
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

query "cloud_billing_report_cost_by_location_dashboard_location_costs" {
  sql = <<-EOQ
    select
      project_id as "Project",
      coalesce(location.region, 'global') as "Location",
      location.zone as "Zone",
      round(sum(cost), 2) as "Total Cost",
      currency as "Currency"
    from
      gcp_billing_report
    where
      ('all' in ($1) or project_id in $1)
    group by
      project_id,
      project_name,
      location.region,
      location.zone,
      currency
    order by
      sum(cost) desc;
  EOQ

  param "project_ids" {}

  tags = {
    folder = "Hidden"
  }
}

query "cloud_billing_report_cost_by_location_dashboard_projects_input" {
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
