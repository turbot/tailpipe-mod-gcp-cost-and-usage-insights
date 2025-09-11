dashboard "cloud_billing_report_cost_by_label_dashboard" {
  title         = "GCP Cloud Billing Report: Cost by Label"
  documentation = file("./dashboards/docs/cloud_billing_report_cost_by_label_dashboard.md")

  tags = merge(local.gcp_cloud_billing_insights_common_tags, {
    type    = "Dashboard"
    service = "GCP/CloudBilling"
  })

  input "cloud_billing_report_cost_by_label_dashboard_projects" {
    title       = "Select project(s):"
    description = "Choose one or more GCP projects to analyze."
    type        = "multiselect"
    query       = query.cloud_billing_report_cost_by_label_dashboard_projects_input
    width       = 4
  }

  input "cloud_billing_report_cost_by_label_dashboard_label_type" {
    title       = "Select label type:"
    description = "Choose the type of label to analyze (project, resource, or system)."
    type        = "select"
    width       = 4

    option "project_labels" { label = "Project Labels" }
    option "labels" { label = "Resource Labels" }
    option "system_labels" { label = "System Labels" }
  }

  input "cloud_billing_report_cost_by_label_dashboard_label_key" {
    title       = "Select a label key:"
    description = "Select a label key to analyze costs by label values."
    type        = "select"
    query       = query.cloud_billing_report_cost_by_label_dashboard_label_key_input
    width       = 4
    args = {
      "project_ids" = self.input.cloud_billing_report_cost_by_label_dashboard_projects.value
      "label_type"  = self.input.cloud_billing_report_cost_by_label_dashboard_label_type.value
    }
  }

  container {
    card {
      width = 2
      query = query.cloud_billing_report_cost_by_label_dashboard_total_cost
      icon  = "attach_money"
      type  = "info"
      args = {
        "project_ids" = self.input.cloud_billing_report_cost_by_label_dashboard_projects.value
        "label_type"  = self.input.cloud_billing_report_cost_by_label_dashboard_label_type.value
        "label_key"   = self.input.cloud_billing_report_cost_by_label_dashboard_label_key.value
      }
    }

    card {
      width = 2
      query = query.cloud_billing_report_cost_by_label_dashboard_total_projects
      icon  = "folder"
      type  = "info"
      args = {
        "project_ids" = self.input.cloud_billing_report_cost_by_label_dashboard_projects.value
      }
    }
  }

  container {
    chart {
      title = "Monthly Cost by Label Value"
      type  = "column"
      width = 6
      query = query.cloud_billing_report_cost_by_label_dashboard_monthly_cost
      args = {
        "project_ids" = self.input.cloud_billing_report_cost_by_label_dashboard_projects.value
        "label_type"  = self.input.cloud_billing_report_cost_by_label_dashboard_label_type.value
        "label_key"   = self.input.cloud_billing_report_cost_by_label_dashboard_label_key.value
      }
      legend { display = "none" }
    }

    chart {
      title = "Top 10 Label Values"
      type  = "table"
      width = 6
      query = query.cloud_billing_report_cost_by_label_dashboard_top_10_label_values
      args = {
        "project_ids" = self.input.cloud_billing_report_cost_by_label_dashboard_projects.value
        "label_type"  = self.input.cloud_billing_report_cost_by_label_dashboard_label_type.value
        "label_key"   = self.input.cloud_billing_report_cost_by_label_dashboard_label_key.value
      }
    }
  }

  container {
    table {
      title = "Label Value Costs"
      width = 12
      query = query.cloud_billing_report_cost_by_label_dashboard_label_value_costs
      args = {
        "project_ids" = self.input.cloud_billing_report_cost_by_label_dashboard_projects.value
        "label_type"  = self.input.cloud_billing_report_cost_by_label_dashboard_label_type.value
        "label_key"   = self.input.cloud_billing_report_cost_by_label_dashboard_label_key.value
      }
    }
  }
}

# --- Total Cost ---
query "cloud_billing_report_cost_by_label_dashboard_total_cost" {
  sql = <<-EOQ
    with filtered as (
      select 
        cost, 
        currency, 
        project_id, 
        project_labels, 
        labels, 
        system_labels
      from gcp_billing_report
      where ('all' in ($1) or project_id in $1)
    ),
    picked as (
      -- project labels
      select 
        f.cost, 
        f.currency,
        json_extract_string(f.project_labels, '$[' || i || '].value') as label_value
      from 
        filtered f,
        generate_series(0, 200) as gs(i)
      where $2 = 'project_labels'
        and f.project_labels is not null
        and i < json_array_length(f.project_labels)
        and json_extract_string(f.project_labels, '$[' || i || '].key') = $3

      union all

      -- resource labels
      select 
        f.cost, 
        f.currency,
        json_extract_string(f.labels, '$[' || i || '].value')
      from 
        filtered f,
        generate_series(0, 200) as gs(i)
      where $2 = 'labels'
        and f.labels is not null
        and i < json_array_length(f.labels)
        and json_extract_string(f.labels, '$[' || i || '].key') = $3

      union all

      -- system labels
      select 
        f.cost, 
        f.currency,
        json_extract_string(f.system_labels, '$[' || i || '].value')
      from 
        filtered f,
        generate_series(0, 200) as gs(i)
      where $2 = 'system_labels'
        and f.system_labels is not null
        and i < json_array_length(f.system_labels)
        and json_extract_string(f.system_labels, '$[' || i || '].key') = $3
    )
    select
      'Total Cost (' || max(currency) || ')' as label,
      round(sum(cost), 2) as value
    from 
      picked
    where 
      label_value is not null and label_value <> '';
  EOQ

  param "project_ids" {}
  param "label_type" {}
  param "label_key" {}

  tags = { folder = "Hidden" }
}

# --- Total Projects ---
query "cloud_billing_report_cost_by_label_dashboard_total_projects" {
  sql = <<-EOQ
    select
      'Projects' as label,
      count(distinct project_id) as value
    from gcp_billing_report
    where ('all' in ($1) or project_id in $1);
  EOQ

  param "project_ids" {}

  tags = {
    folder = "Hidden"
  }
}

# --- Monthly Cost by Label Value ---
query "cloud_billing_report_cost_by_label_dashboard_monthly_cost" {
  sql = <<-EOQ
    with filtered as (
      select 
        date_trunc('month', usage_start_time) as month,
        cost, 
        project_labels, 
        labels, 
        system_labels, 
        project_id
      from 
        gcp_billing_report
      where 
        ('all' in ($1) or project_id in $1)
    ),
    picked as (
      select 
        f.month, 
        f.cost,
        json_extract_string(f.project_labels, '$[' || i || '].value') as label_value
      from 
        filtered f, 
        generate_series(0, 200) as gs(i)
      where $2 = 'project_labels'
        and f.project_labels is not null
        and i < json_array_length(f.project_labels)
        and json_extract_string(f.project_labels, '$[' || i || '].key') = $3

      union all

      select 
        f.month, 
        f.cost,
        json_extract_string(f.labels, '$[' || i || '].value')
      from 
        filtered f, 
        generate_series(0, 200) as gs(i)
      where $2 = 'labels'
        and f.labels is not null
        and i < json_array_length(f.labels)
        and json_extract_string(f.labels, '$[' || i || '].key') = $3

      union all

      select 
        f.month, 
        f.cost,
        json_extract_string(f.system_labels, '$[' || i || '].value')
      from 
        filtered f, 
        generate_series(0, 200) as gs(i)
      where $2 = 'system_labels'
        and f.system_labels is not null
        and i < json_array_length(f.system_labels)
        and json_extract_string(f.system_labels, '$[' || i || '].key') = $3
    )
    select
      strftime(month, '%b %Y') as "Month",
      label_value              as "Series",
      round(sum(cost), 2)      as "Total Cost"
    from 
      picked
    where 
      label_value is not null and label_value <> ''
    group by 
      month, 
      label_value
    having 
      sum(cost) > 0
    order by 
      month, 
      sum(cost) desc;
  EOQ

  param "project_ids" {}
  param "label_type" {}
  param "label_key" {}

  tags = { folder = "Hidden" }
}

# --- Top 10 Label Values ---
query "cloud_billing_report_cost_by_label_dashboard_top_10_label_values" {
  sql = <<-EOQ
    with filtered as (
      select 
        cost, 
        project_labels, 
        labels, 
        system_labels, 
        project_id
      from 
        gcp_billing_report
      where 
        ('all' in ($1) or project_id in $1)
    ),
    picked as (
      select 
        json_extract_string(f.project_labels, '$[' || i || '].value') as label_value, 
        cost
      from 
        filtered f,
        generate_series(0, 200) as gs(i)
      where $2 = 'project_labels'
        and f.project_labels is not null
        and i < json_array_length(f.project_labels)
        and json_extract_string(f.project_labels, '$[' || i || '].key') = $3

      union all

      select 
        json_extract_string(f.labels, '$[' || i || '].value'),
        cost
      from 
        filtered f,
        generate_series(0, 200) as gs(i)
      where $2 = 'labels'
        and f.labels is not null
        and i < json_array_length(f.labels)
        and json_extract_string(f.labels, '$[' || i || '].key') = $3

      union all

      select 
        json_extract_string(f.system_labels, '$[' || i || '].value'), 
        cost
      from 
        filtered f, 
        generate_series(0, 200) as gs(i)
      where $2 = 'system_labels'
        and f.system_labels is not null
        and i < json_array_length(f.system_labels)
        and json_extract_string(f.system_labels, '$[' || i || '].key') = $3
    )
    select
      label_value         as "Label Value",
      round(sum(cost), 2) as "Total Cost"
    from 
      picked
    where 
      label_value is not null and label_value <> ''
    group by 
      label_value
    order by 
      sum(cost) desc
    limit 10;
  EOQ

  param "project_ids" {}
  param "label_type" {}
  param "label_key" {}

  tags = { folder = "Hidden" }
}

# --- Detailed Table: Label Value Costs ---
query "cloud_billing_report_cost_by_label_dashboard_label_value_costs" {
  sql = <<-EOQ
    with filtered as (
      select 
        project_id, 
        project_name, 
        location.region as region,
        cost, 
        currency,
        project_labels, 
        labels, 
        system_labels
      from 
        gcp_billing_report
      where 
        ('all' in ($1) or project_id in $1)
    ),
    picked as (
      select 
        project_id, 
        project_name, 
        region, 
        currency, 
        cost,
        json_extract_string(f.project_labels, '$[' || i || '].value') as label_value
      from 
        filtered f, 
        generate_series(0, 200) as gs(i)
      where $2 = 'project_labels'
        and f.project_labels is not null
        and i < json_array_length(f.project_labels)
        and json_extract_string(f.project_labels, '$[' || i || '].key') = $3

      union all

      select 
        project_id, 
        project_name, 
        region, 
        currency,
        cost,
        json_extract_string(f.labels, '$[' || i || '].value')
      from 
        filtered f, 
        generate_series(0, 200) as gs(i)
      where $2 = 'labels'
        and f.labels is not null
        and i < json_array_length(f.labels)
        and json_extract_string(f.labels, '$[' || i || '].key') = $3

      union all

      select 
        project_id, 
        project_name, 
        region, 
        currency, 
        cost,
        json_extract_string(f.system_labels, '$[' || i || '].value')
      from 
        filtered f, 
        generate_series(0, 200) as gs(i)
      where $2 = 'system_labels'
        and f.system_labels is not null
        and i < json_array_length(f.system_labels)
        and json_extract_string(f.system_labels, '$[' || i || '].key') = $3
    )
    select
      label_value                as "Label Value",
      project_id                 as "Project ID",
      project_name               as "Project Name",
      coalesce(region, 'global') as "Region",
      round(sum(cost), 2)        as "Total Cost",
      max(currency)              as "Currency"
    from 
      picked
    where 
      label_value is not null and label_value <> ''
    group by 
      label_value, 
      project_id, 
      project_name, 
      region
    order by 
      sum(cost) desc;
  EOQ

  param "project_ids" {}
  param "label_type" {}
  param "label_key" {}

  tags = { folder = "Hidden" }
}

# --- Projects Input ---
query "cloud_billing_report_cost_by_label_dashboard_projects_input" {
  sql = <<-EOQ
    with project_ids as (
      select
        project_id,
        max(project_name) as project_name
      from 
        gcp_billing_report
      group by 
        project_id
    ),
    labeled as (
      select
        project_id || ' (' || coalesce(project_name, '') || ')' as label,
        project_id as value
      from 
        project_ids
    )
    select 
      'All' as label, 
      'all' as value
    union all
    select 
      label, 
      value
    from 
      labeled
    order by 
      label;
  EOQ

  tags = { folder = "Hidden" }
}

# --- Label Key Input ---
query "cloud_billing_report_cost_by_label_dashboard_label_key_input" {
  sql = <<-EOQ
    with filtered as (
      select project_id, project_labels, labels, system_labels
      from gcp_billing_report
      where ('all' in ($1) or project_id in $1)
    ),
    keys as (
      -- project label keys
      select distinct json_extract_string(f.project_labels, '$[' || i || '].key') as label_key
      from filtered f, generate_series(0, 200) as gs(i)
      where $2 = 'project_labels'
        and f.project_labels is not null
        and i < json_array_length(f.project_labels)

      union
      -- resource label keys
      select distinct json_extract_string(f.labels, '$[' || i || '].key')
      from filtered f, generate_series(0, 200) as gs(i)
      where $2 = 'labels'
        and f.labels is not null
        and i < json_array_length(f.labels)

      union
      -- system label keys
      select distinct json_extract_string(f.system_labels, '$[' || i || '].key')
      from filtered f, generate_series(0, 200) as gs(i)
      where $2 = 'system_labels'
        and f.system_labels is not null
        and i < json_array_length(f.system_labels)
    )
    select
      label_key as label,
      label_key as value
    from keys
    where label_key is not null and label_key <> ''
    order by label;
  EOQ

  param "project_ids" {}
  param "label_type" {}

  tags = { folder = "Hidden" }
}
