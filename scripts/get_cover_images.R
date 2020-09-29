covers <- for_twitter %>%
  filter(!is.na(cover_thumbnail)) %>%
  mutate(cover_image_filename = paste(filename, isbn, sep = "_")) %>% 
  select(cover_image_filename, cover_thumbnail)

urls <- covers %>% pull(cover_thumbnail)
destinations <- paste0("images/covers/", covers %>% pull(cover_image_filename), ".jpg")

download.file(urls, destinations, method = "libcurl")

# Get ISBNs from cover image filenames
cover_images <- list.files("images/covers") %>%
  as_tibble_col(column_name = "cover_filename") %>% 
  mutate(isbn = str_sub(cover_filename, -17, -5))

for_twitter <- left_join(for_twitter, cover_images, by = "isbn")
