project_id = "rising-sector-360922"
image_tag = "26c5d06539744d11ab1abcd76087b305d682f94a"

label_config = [
  {
    name         = "Council Data DVR"
    label_id     = "council_data_dvr"
    bucket_name  = "council_data_dvr"
    days_to_keep = 10
  },
  {
    name         = "Council Data Sales"
    label_id     = "council_data_sales"
    bucket_name  = "council_data_sales"
    days_to_keep = 0
  }
]