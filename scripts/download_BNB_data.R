library("rvest") # Reads HTML pages, for downloading RDF files

slug <- "/britishlibrary/~/media/bl/global/services/collection metadata/pdfs/bnb records rdf/"
local_zips <- list.files("raw data/zipped", pattern = ".zip*") %>% str_to_lower()

BNB_page <- read_html("https://www.bl.uk/collection-metadata/new-bnb-records")

BNB_urls_truncated <- BNB_page %>%
  html_elements(".grid_39") %>% 
  html_elements("ul:last-child") %>% 
  html_elements("li") %>% 
  html_text2() %>% 
  word(2) %>% 
  str_sub(2) %>% 
  str_to_lower()

BNB_urls_hashed <- BNB_page %>%
  html_elements(".grid_39") %>% 
  html_elements("ul:last-child") %>% 
  html_elements("a") %>% 
  html_attr("href") %>% 
  paste0("https://www.bl.uk/collection-metadata/", .)

BNB_unmatched_indexes <- which(!BNB_urls_truncated %in% local_zips)

if(length(BNB_unmatched_indexes) > 0) {
  target_slugs <- BNB_urls_hashed[BNB_unmatched_indexes]
  target_urls <- lapply(target_slugs, URLencode) %>% unlist()
  target_filenames <- BNB_urls_truncated[BNB_unmatched_indexes]
  
  download.file(target_urls, destfile = paste0("raw data/zipped/", target_filenames), method = "libcurl")
}
