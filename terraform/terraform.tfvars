project_id = "rising-sector-360922"
image_tag = "330d632cf268242ad26de89e929f64ffddb08cb0"

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