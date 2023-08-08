project_id = "rising-sector-360922"
image_tag = "5a94dec9955970524c44bddda0e674e031057490"

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