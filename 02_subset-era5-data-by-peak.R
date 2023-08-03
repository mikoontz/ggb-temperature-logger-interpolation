library(googledrive)
library(readxl)

googledrive::drive_auth()

data_status_gdrive <- googledrive::drive_get(path = "https://docs.google.com/spreadsheets/d/15Bo13oYpSo5PsjOoW0wHMRXSWnbdEC9I/edit#gid=936866508")

local_data_status_path <- file.path(tempdir(), 'GGB_data_status.xlsx')
googledrive::drive_download(file = data_status_gdrive, 
                            path = local_data_status_path,
                            overwrite = TRUE)

data_status <- readxl::read_xlsx(path = local_data_status_path, sheet = 2)

coords_gdrive <- 
  googledrive::as_id("1-04UrYIW7BdTKoAXIRuW_wvNAUmgBGho") |>
  googledrive::drive_get(id = _)

local_coords_path <- file.path(tempdir(), 'ggb-summit-coordinates.csv')

googledrive::drive_download(file = coords_gdrive, path = local_coords_path, overwrite = TRUE)

coords <- 
  read.csv(local_coords_path) |>
  sf::st_as_sf(coords = c("long", "lat"), crs = 4326, remove = FALSE) |>
  dplyr::mutate(target_region = c("lan", "wim", "wds", "wds", "wds", "wds", 
                                  "wim", "wim", "wim", "snd", "snd", "snd", 
                                  "snd", "swe", "swe", "swe", "cat", "cat", 
                                  "cat", "grb", "grb", "grb", "grb", "lan", 
                                  "lan", "lan", "lan", "dev", "dev", "dev", 
                                  "dev")) |>
  dplyr::arrange(target_region, peak) |>
  dplyr::mutate(peak_code = c("us_cat_fes", "us_cat_fpk", "us_cat_fsw",
                              "us_dev_ben", "us_dev_low", "us_dev_mid", "us_dev_tel",
                              "us_grb_bld", "us_grb_bck", "us_grb_pmd", "us_grb_wlr",
                              "us_lan_cfk", "us_lan_idr", "us_lan_lss", "us_lan_lws", NA,
                              "us_snd_374", "us_snd_332", "us_snd_357", "us_snd_grl",
                              "us_swe_bel", "us_swe_fry", "us_swe_whe",
                              "us_wds_cws", NA, "us_wds_pgs", "us_wds_sme",
                              "us_wim_bar", "us_wim_rna", "us_wim_shf", "us_wim_wmt")) |>
  sf::st_drop_geometry()

year_first_surveyed <- 
  data_status |>
  dplyr::group_by(peak_code) |>
  dplyr::summarize(year_first_surveyed = min(year)) |>
  # dplyr::mutate(years_elapsed = 2023 - year_first_surveyed + 1) |>
  # dplyr::arrange(year_first_surveyed) |>
  # dplyr::mutate(hours_elapsed = 8760 * years_elapsed) |>
  dplyr::left_join(coords) |>
  dplyr::select(peak_code, year_first_surveyed, peak)
  

year_first_surveyed

era5_data <- 
  data.table::fread("data/ee/ggb-summits-era5-land-temp-2m-c.csv")

era5_data[, `:=`('system:index' = NULL, '.geo' = NULL)]
era5_data[, `:=`(year = as.numeric(substr(datetime, start = 1, stop = 4)),
                 month = as.numeric(substr(datetime, start = 5, stop = 6)),
                 day = as.numeric(substr(datetime, start = 7, stop = 8)),
                 hour = as.numeric(substr(datetime, start = 10, stop = 11)))]


era5_subset <- merge(x = era5_data, y = year_first_surveyed, by = "peak")
era5_subset <- era5_subset[year >= year_first_surveyed, ]

era5_subset[, `:=`(datetime_zulu = lubridate::ymd_hm(paste0(year, "-", month, "-", day, " ", hour, ":00")))]

era5_subset[, `:=`(peak = NULL, datetime = NULL, year_first_surveyed = NULL)]

data.table::setcolorder(era5_subset, neworder = c("peak_code", "long", "lat", "datetime_zulu", "year", "month", "day", "hour", "temp_2m_c"))

data.table::fwrite(x = era5_subset, file = "data/ard/era5-land-temp-2m-c_ggb-summits.csv")