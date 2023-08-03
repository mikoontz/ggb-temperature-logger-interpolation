# https://code.earthengine.google.com/5bfc6a20cc20e3f553af465cf21ef33a

library(googledrive)
library(rgee)

googledrive::drive_auth()
googledrive::drive_ls(path = "https://drive.google.com/drive/u/0/folders/1JaiRMY72RmWcNg5SPA8H1BT73F10Zj5m")

rgee::ee_Authenticate()

coords_gdrive <- 
  googledrive::as_id("1-04UrYIW7BdTKoAXIRuW_wvNAUmgBGho") |>
  googledrive::drive_get(id = _)

local_coords_path <- file.path(tempdir(), 'ggb-summit-coordinates.csv')

googledrive::drive_download(file = coords_gdrive, path = local_coords_path, overwrite = TRUE)

coords <- 
  read.csv(local_coords_path) |>
  sf::st_as_sf(coords = c("long", "lat"), crs = 4326, remove = FALSE)

sf::st_write(obj = coords, dsn = "data/ggb-summit-coordinates.shp", delete_dsn = TRUE)
