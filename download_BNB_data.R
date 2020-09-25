library("rvest") # Reads HTML pages, for downloading RDF files

slug <- "/britishlibrary/~/media/bl/global/services/collection metadata/pdfs/bnb records rdf/"
local_zips <- list.files("raw data/zipped", pattern = ".zip*") %>% str_to_lower()

BNB_page <- read_html("https://www.bl.uk/collection-metadata/new-bnb-records")
BNB_urls_hashed <- BNB_page %>%
  html_nodes("li") %>%
  html_nodes("a") %>%
  html_attr("href") %>% 
  str_subset("/bnbrdf_n") 

BNB_urls_truncated <- BNB_urls_hashed %>% str_replace("[^.zip]*$","")
BNB_unmatched_indexes <- which(!BNB_urls_truncated %in% paste(slug, local_zips, sep = ""))

if(length(BNB_unmatched_indexes) > 0) {
  target_slugs <- BNB_urls_hashed[BNB_unmatched_indexes]
  target_urls <- lapply(paste0("https://www.bl.uk", target_slugs), URLencode) %>% unlist()
  target_filenames <- basename(target_slugs) %>% str_replace("[^.zip]*$","")
  
  download.file(target_urls, destfile = paste0("raw data/zipped/", target_filenames), method = "libcurl")
}
