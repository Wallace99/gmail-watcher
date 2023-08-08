project_id = "rising-sector-360922"
image_tag  = "bdf8da97f3a8c109a6d83aa6b1bdbe4dfe11900f"

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