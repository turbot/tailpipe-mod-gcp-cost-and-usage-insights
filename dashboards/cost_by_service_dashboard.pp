dashboard "cost_by_service_dashboard" {
  title         = "GCP Cost and Usage Report: Cost by Service"
  documentation = file("./dashboards/docs/cost_by_service_dashboard.md")

  tags = merge(local.gcp_cost_and_usage_insights_common_tags, {
    type = "Dashboard"
  })

  input "cost_by_service_dashboard_projects" {
    title       = "Select projects:"
    description = "Choose one or more GCP projects to analyze"
    type        = "multiselect"
    width       = 4
    query       = query.cost_by_service_dashboard_projects_input
  }

  container {
    # Combined card showing Total Cost with Currency
    card {
      width = 2
      query = query.cost_by_service_dashboard_total_cost
      icon  = "attach_money"
      type  = "info"

      args = {
        "project_ids" = self.input.cost_by_service_dashboard_projects.value
      }
    }

    card {
      width = 2
      query = query.cost_by_service_dashboard_total_projects
      icon  = "folder"
      type  = "info"

      args = {
        "project_ids" = self.input.cost_by_service_dashboard_projects.value
      }
    }

    card {
      width = 2
      query = query.cost_by_service_dashboard_total_services
      icon  = "layers"
      type  = "info"

      args = {
        "project_ids" = self.input.cost_by_service_dashboard_projects.value
      }
    }

    card {
      width = 2
      query = query.cost_by_service_dashboard_total_skus
      icon  = "category"
      type  = "info"

      args = {
        "project_ids" = self.input.cost_by_service_dashboard_projects.value
      }
    }
  }

  container {
    # Cost Trend Graphs
    chart {
      title = "Monthly Cost Trend"
      type  = "column"
      width = 6
      query = query.cost_by_service_dashboard_monthly_cost

      args = {
        "project_ids" = self.input.cost_by_service_dashboard_projects.value
      }

      legend {
        display = "none"
      }
    }

    chart {
      title = "Top 10 Services"
      type  = "table"
      width = 6
      query = query.cost_by_service_dashboard_top_10_services

      args = {
        "project_ids" = self.input.cost_by_service_dashboard_projects.value
      }
    }
  }

  container {
    # Detailed Table
    table {
      title = "Service Costs"
      width = 12
      query = query.cost_by_service_dashboard_service_costs

      args = {
        "project_ids" = self.input.cost_by_service_dashboard_projects.value
      }
    }
  }
}

# Query Definitions

query "cost_by_service_dashboard_total_cost" {
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

query "cost_by_service_dashboard_total_projects" {
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

query "cost_by_service_dashboard_total_services" {
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

query "cost_by_service_dashboard_total_skus" {
  sql = <<-EOQ
    select
      'SKUs' as label,
      count(distinct sku_id) as value
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

query "cost_by_service_dashboard_monthly_cost" {
  sql = <<-EOQ
    select
      date_trunc('month', usage_start_time)::timestamp as "Month",
      coalesce(service_description, 'N/A') as "Service",
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

query "cost_by_service_dashboard_top_10_services" {
  sql = <<-EOQ
    select
      coalesce(service_description, 'N/A') as "Service",
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

query "cost_by_service_dashboard_service_costs" {
  sql = <<-EOQ
    select
      project_id as "Project ID",
      project_name as "Project Name",
      coalesce(service_description, 'N/A') as "Service",
      service_id as "Service ID",
      sku_description as "SKU Description",
      coalesce(location.region, 'global') as "Region",
      round(sum(cost), 2) as "Total Cost",
      currency as "Currency"
    from
      gcp_billing_report
    where
      ('all' in ($1) or project_id in $1)
    group by
      project_id,
      project_name,
      service_description,
      service_id,
      sku_description,
      location.region,
      currency
    order by
      sum(cost) desc;
  EOQ

  param "project_ids" {}

  tags = {
    folder = "Hidden"
  }
}

query "cost_by_service_dashboard_projects_input" {
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
