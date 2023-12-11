project_id = "rising-sector-360922"
image_tag  = "17f6b8515b256f2148f904bb0052a18b922dca2f"

label_config = [
  {
    name         = "Council Data DVR"
    label_id     = "council_data_dvr"
    bucket_name  = "council_data_dvr_new"
    days_to_keep = 10
  },
  {
    name         = "Council Data Sales"
    label_id     = "council_data_sales"
    bucket_name  = "council_data_sales_new"
    days_to_keep = 0
  }
]