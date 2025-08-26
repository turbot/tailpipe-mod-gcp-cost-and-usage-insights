# dashboard "cost_by_label_dashboard" {
#   title         = "Cost and Usage Report: Cost by Label"
#   documentation = file("./dashboards/docs/cost_by_label_dashboard.md")

#   tags = merge(local.gcp_cost_and_usage_insights_common_tags, {
#     type = "Dashboard"
#   })

#   input "cost_by_label_dashboard_projects" {
#     title       = "Select projects:"
#     description = "Choose one or more GCP projects to analyze."
#     type        = "multiselect"
#     query       = query.cost_by_label_dashboard_projects_input
#     width       = 4
#   }

#   input "cost_by_label_dashboard_label_type" {
#     title       = "Select label type:"
#     description = "Choose the type of label to analyze (project, resource, or system)."
#     type        = "select"
#     width       = 4

#     option "project_labels" {
#       label = "Project Labels"
#     }
#     option "labels" {
#       label = "Resource Labels"
#     }
#     option "system_labels" {
#       label = "System Labels"
#     }
#   }

#   input "cost_by_label_dashboard_label_key" {
#     title       = "Select a label key:"
#     description = "Select a label key to analyze costs by label values."
#     type        = "select"
#     query       = query.cost_by_label_dashboard_label_key_input
#     width       = 4
#     args = {
#       "project_ids" = self.input.cost_by_label_dashboard_projects.value
#       "label_type"  = self.input.cost_by_label_dashboard_label_type.value
#     }
#   }

#   container {
#     # Combined card showing Total Cost with Currency
#     card {
#       width = 2
#       query = query.cost_by_label_dashboard_total_cost
#       icon  = "attach_money"
#       type  = "info"

#       args = {
#         "project_ids" = self.input.cost_by_label_dashboard_projects.value
#         "label_type"  = self.input.cost_by_label_dashboard_label_type.value
#         "label_key"   = self.input.cost_by_label_dashboard_label_key.value
#       }
#     }

#     card {
#       width = 2
#       query = query.cost_by_label_dashboard_total_projects
#       icon  = "folder"
#       type  = "info"

#       args = {
#         "project_ids" = self.input.cost_by_label_dashboard_projects.value
#       }
#     }

#     card {
#       width = 2
#       query = query.cost_by_label_dashboard_total_label_values
#       icon  = "label"
#       type  = "info"

#       args = {
#         "project_ids" = self.input.cost_by_label_dashboard_projects.value
#         "label_type"  = self.input.cost_by_label_dashboard_label_type.value
#         "label_key"   = self.input.cost_by_label_dashboard_label_key.value
#       }
#     }
#   }

#   container {
#     # Cost Trend and Key/Value Breakdown
#     chart {
#       title = "Monthly Cost by Label Value"
#       type  = "column"
#       width = 6
#       query = query.cost_by_label_dashboard_monthly_cost

#       args = {
#         "project_ids" = self.input.cost_by_label_dashboard_projects.value
#         "label_type"  = self.input.cost_by_label_dashboard_label_type.value
#         "label_key"   = self.input.cost_by_label_dashboard_label_key.value
#       }

#       legend {
#         display = "none"
#       }
#     }

#     chart {
#       title = "Top 10 Label Values"
#       type  = "table"
#       width = 6
#       query = query.cost_by_label_dashboard_top_10_label_values

#       args = {
#         "project_ids" = self.input.cost_by_label_dashboard_projects.value
#         "label_type"  = self.input.cost_by_label_dashboard_label_type.value
#         "label_key"   = self.input.cost_by_label_dashboard_label_key.value
#       }
#     }
#   }

#   container {
#     # Detailed Tables
#     table {
#       title = "Label Value Costs"
#       width = 12
#       query = query.cost_by_label_dashboard_label_value_costs

#       args = {
#         "project_ids" = self.input.cost_by_label_dashboard_projects.value
#         "label_type"  = self.input.cost_by_label_dashboard_label_type.value
#         "label_key"   = self.input.cost_by_label_dashboard_label_key.value
#       }
#     }
#   }
# }

# # Query Definitions

# query "cost_by_label_dashboard_total_cost" {
#   sql = <<-EOQ
#     with labeled_resources as (
#       select 
#         cost,
#         currency,
#         case
#           when $2 = 'project_labels' then json_extract(project_labels, '$.' || $3)
#           when $2 = 'labels' then json_extract(labels, '$.' || $3)
#           when $2 = 'system_labels' then json_extract(system_labels, '$.' || $3)
#         end as label_value
#       from 
#         gcp_billing_report
#       where 
#         ('all' in ($1) or project_id in $1)
#         and case
#           when $2 = 'project_labels' then project_labels is not null and json_extract(project_labels, '$.' || $3) is not null
#           when $2 = 'labels' then labels is not null and json_extract(labels, '$.' || $3) is not null
#           when $2 = 'system_labels' then system_labels is not null and json_extract(system_labels, '$.' || $3) is not null
#         end
#     )
#     select
#       'Total Cost (' || max(currency) || ')' as label,
#       round(sum(cost), 2) as value
#     from
#       labeled_resources
#     where
#       label_value is not null;
#   EOQ

#   param "project_ids" {}
#   param "label_type" {}
#   param "label_key" {}

#   tags = {
#     folder = "Hidden"
#   }
# }

# query "cost_by_label_dashboard_total_projects" {
#   sql = <<-EOQ
#     select
#       'Projects' as label,
#       count(distinct project_id) as value
#     from
#       gcp_billing_report
#     where
#       ('all' in ($1) or project_id in $1);
#   EOQ

#   param "project_ids" {}

#   tags = {
#     folder = "Hidden"
#   }
# }

# query "cost_by_label_dashboard_total_label_values" {
#   sql = <<-EOQ
#     with label_values as (
#       select distinct
#         case
#           when $2 = 'project_labels' then json_extract(project_labels, '$.' || $3)
#           when $2 = 'labels' then json_extract(labels, '$.' || $3)
#           when $2 = 'system_labels' then json_extract(system_labels, '$.' || $3)
#         end as label_value
#       from
#         gcp_billing_report
#       where
#         ('all' in ($1) or project_id in $1)
#         and case
#           when $2 = 'project_labels' then project_labels is not null and json_extract(project_labels, '$.' || $3) is not null
#           when $2 = 'labels' then labels is not null and json_extract(labels, '$.' || $3) is not null
#           when $2 = 'system_labels' then system_labels is not null and json_extract(system_labels, '$.' || $3) is not null
#         end
#     )
#     select
#       'Label Values' as label,
#       count(*) as value
#     from
#       label_values
#     where
#       label_value is not null;
#   EOQ

#   param "project_ids" {}
#   param "label_type" {}
#   param "label_key" {}

#   tags = {
#     folder = "Hidden"
#   }
# }

# query "cost_by_label_dashboard_monthly_cost" {
#   sql = <<-EOQ
#     with labeled_resources as (
#       select
#         date_trunc('month', usage_start_time) as month,
#         cost,
#         case
#           when $2 = 'project_labels' then json_extract(project_labels, '$.' || $3)
#           when $2 = 'labels' then json_extract(labels, '$.' || $3)
#           when $2 = 'system_labels' then json_extract(system_labels, '$.' || $3)
#         end as label_value
#       from
#         gcp_billing_report
#       where
#         ('all' in ($1) or project_id in $1)
#         and case
#           when $2 = 'project_labels' then project_labels is not null and json_extract(project_labels, '$.' || $3) is not null
#           when $2 = 'labels' then labels is not null and json_extract(labels, '$.' || $3) is not null
#           when $2 = 'system_labels' then system_labels is not null and json_extract(system_labels, '$.' || $3) is not null
#         end
#     )
#     select
#       month::timestamp as "Month",
#       label_value as "Series",
#       round(sum(cost), 2) as "Total Cost"
#     from
#       labeled_resources
#     where
#       label_value is not null
#     group by
#       month,
#       label_value
#     having
#       sum(cost) > 0
#     order by
#       month,
#       sum(cost) desc;
#   EOQ

#   param "project_ids" {}
#   param "label_type" {}
#   param "label_key" {}

#   tags = {
#     folder = "Hidden"
#   }
# }

# query "cost_by_label_dashboard_top_10_label_values" {
#   sql = <<-EOQ
#     with labeled_resources as (
#       select
#         cost,
#         case
#           when $2 = 'project_labels' then json_extract(project_labels, '$.' || $3)
#           when $2 = 'labels' then json_extract(labels, '$.' || $3)
#           when $2 = 'system_labels' then json_extract(system_labels, '$.' || $3)
#         end as label_value
#       from
#         gcp_billing_report
#       where
#         ('all' in ($1) or project_id in $1)
#         and case
#           when $2 = 'project_labels' then project_labels is not null and json_extract(project_labels, '$.' || $3) is not null
#           when $2 = 'labels' then labels is not null and json_extract(labels, '$.' || $3) is not null
#           when $2 = 'system_labels' then system_labels is not null and json_extract(system_labels, '$.' || $3) is not null
#         end
#     )
#     select
#       label_value as "Label Value",
#       round(sum(cost), 2) as "Total Cost"
#     from
#       labeled_resources
#     where
#       label_value is not null
#     group by
#       label_value
#     order by
#       sum(cost) desc
#     limit 10;
#   EOQ

#   param "project_ids" {}
#   param "label_type" {}
#   param "label_key" {}

#   tags = {
#     folder = "Hidden"
#   }
# }

# query "cost_by_label_dashboard_label_value_costs" {
#   sql = <<-EOQ
#     with labeled_resources as (
#       select
#         project_id,
#         project_name,
#         location.region,
#         cost,
#         currency,
#         case
#           when $2 = 'project_labels' then json_extract(project_labels, '$.' || $3)
#           when $2 = 'labels' then json_extract(labels, '$.' || $3)
#           when $2 = 'system_labels' then json_extract(system_labels, '$.' || $3)
#         end as label_value
#       from
#         gcp_billing_report
#       where
#         ('all' in ($1) or project_id in $1)
#         and case
#           when $2 = 'project_labels' then project_labels is not null and json_extract(project_labels, '$.' || $3) is not null
#           when $2 = 'labels' then labels is not null and json_extract(labels, '$.' || $3) is not null
#           when $2 = 'system_labels' then system_labels is not null and json_extract(system_labels, '$.' || $3) is not null
#         end
#     )
#     select
#       label_value as "Label Value",
#       project_id as "Project ID",
#       project_name as "Project Name",
#       coalesce(region, 'global') as "Region",
#       round(sum(cost), 2) as "Total Cost",
#       currency as "Currency"
#     from
#       labeled_resources
#     where
#       label_value is not null
#     group by
#       label_value,
#       project_id,
#       project_name,
#       region,
#       currency
#     order by
#       sum(cost) desc;
#   EOQ

#   param "project_ids" {}
#   param "label_type" {}
#   param "label_key" {}

#   tags = {
#     folder = "Hidden"
#   }
# }

# query "cost_by_label_dashboard_projects_input" {
#   sql = <<-EOQ
#     with project_ids as (
#       select
#         distinct on(project_id)
#         project_id || ' (' || coalesce(project_name, '') || ')' as label,
#         project_id as value
#       from
#         gcp_billing_report
#       order by label
#     )
#     select
#       'All' as label,
#       'all' as value
#     union all
#     select
#       label,
#       value
#     from
#       project_ids;
#   EOQ

#   tags = {
#     folder = "Hidden"
#   }
# }

# query "cost_by_label_dashboard_label_key_input" {
#   sql = <<-EOQ
#     with label_keys as (
#       select distinct
#         unnest(
#           case
#             when $2 = 'project_labels' then json_keys(project_labels)
#             when $2 = 'labels' then json_keys(labels)
#             when $2 = 'system_labels' then json_keys(system_labels)
#           end
#         ) as label_key
#       from
#         gcp_billing_report
#       where
#         ('all' in ($1) or project_id in $1)
#         and case
#           when $2 = 'project_labels' then project_labels is not null
#           when $2 = 'labels' then labels is not null
#           when $2 = 'system_labels' then system_labels is not null
#         end
#     )
#     select
#       label_key as label,
#       label_key as value
#     from
#       label_keys
#     where
#       label_key is not null
#       and label_key <> ''
#     order by
#       label_key;
#   EOQ

#   param "project_ids" {}
#   param "label_type" {}

#   tags = {
#     folder = "Hidden"
#   }
# }
