# Unprocessed Files -------------------------------------------------------
# Get the .zip files that haven't yet been processed #
unprocessed_files <- function(processed_data_file){
  if(file.exists(processed_data_file)) {
    zip_files <- list.files("raw data/zipped", pattern = ".zip$") %>% str_replace("[.zip]*$","") %>% str_to_lower()
    gzip_files <- list.files("raw data/zipped", pattern = ".rdf.gz$") %>% str_replace("[.rdf.gz]*$","") %>% str_to_lower()
    setdiff(zip_files, gzip_files)
  } else {
    list.files("raw data/zipped", pattern = ".zip$") %>% str_replace("[.zip]*$","") %>% str_to_lower()
  }
}

# Unzip and Gzip ----------------------------------------------------------
# Extract all .zip files in a directory then recompress them as .gz files #
unzip_and_gzip <- function(zipped_files) {
  walk(zipped_files, unzip, exdir = "raw data/zipped")
  lapply(list.files("raw data/zipped", pattern = ".rdf$", full.names = TRUE), R.utils::gzip, ext = "gz", remove = TRUE)
}

# Process BNB Data --------------------------------------------------------
# Prepare a BNB RDF file for analysis #
process_BNB_data <- function(rdf_file) {
  topic_exclusions <- c("--Fiction", "--Juvenile fiction", "--21st century") %>% paste(collapse = "|")
  
  use_virtuoso(rdf_file) %>%
    setNames(c("basic", "contributors", "creators", "topics", "publisher", "issued", "forthcoming", "isbn")) %>%
    join_tibbles(c("id", "Dewey", "title")) %>%
    mutate(forthcoming = case_when(is.na(forthcoming) ~ FALSE, !is.na(forthcoming) ~ TRUE), filename = str_remove(basename(rdf_file), ".rdf.gz")) %>% 
    filter(!str_detect(topic, topic_exclusions))
}

# Use Virtuoso ------------------------------------------------------------
# Create, query, then delete a Virtuoso database #
use_virtuoso <- function(rdf_file) {
  vos_import(vos_connect(), rdf_file)
  rdf_tibbles <- lapply(paste(prefixes, sparql_queries), query_rdf)
  vos_delete_db(ask = FALSE)
  
  return(rdf_tibbles)
}

# Query RDF ---------------------------------------------------------------
# Run a SPARQL query in Virutoso, convert output to tibble #
query_rdf <- function(sparql_query) {
  vos_query(vos_connect(), sparql_query) %>% 
    as_tibble()
}

# Join Tibbles ------------------------------------------------------------
# Join tibbles together by common variable(s) #
join_tibbles <- function(tibbles, joins) {
  tibbles %>% reduce(left_join, by = joins)
}

# Prepare to Save --------------------------------------------------------
# Bind new data with existing data in order to to write it to a file #
prepare_to_save <- function(target_dest, column_types, new_data) {
  if(file.exists(target_dest)) {
    existing_data <- read_csv(target_dest, col_types = column_types)
    bind_rows(existing_data, setdiff(new_data, existing_data))
  } else {
    return(new_data)
  }
}

# Query Google Books ------------------------------------------------------
# Query Google Books API based on ISBN, convert result into tibble #
query_google_books <- function(isbn, fields) {
  source("scripts/google_credentials.R")
  
  GET(url = "https://www.googleapis.com/books/v1/volumes?", 
                 query = list(
                   key = Google_key,
                   q = paste("isbn", isbn, sep = ":"),
                   maxResults = "1",
                   fields = fields)
  ) %>% 
    google_books_transform() %>% 
    mutate(isbn = isbn)
}

# Google Books Transform --------------------------------------------------
# Transform content from Google Books into a tibble #
google_books_transform <- function(request) {
  rawToChar(request$content) %>%
    jsonlite::fromJSON() %>% 
    unlist_it(3)
}

# Unlist It ---------------------------------------------------------------
# Unlist nested lists #
unlist_it <- function(x, cycles) {
  i <- 1
  
  while (i < (cycles+1)) {
    i <- i + 1
    x <- unlist(x, recursive = FALSE)
  }
  
  as_tibble(x)
}

# Twitter Media Upload ----------------------------------------------------
# Upload media item to Twitter and return its ID #
twitter_media_upload <- function(media_item) {
  media2upload <- httr::upload_file(media_item)
  rurl <- "https://upload.twitter.com/1.1/media/upload.json"
  
  media_response <- httr::POST(rurl, body = list(media = media2upload), token)
  httr::content(media_response) %>%
    as_tibble() %>%
    distinct(as.character(media_id_string)) %>%
    pull()
}

# Twitter Add Alt Text ----------------------------------------------------
# Add alt text to images uploaded to Twitter #
twitter_add_alt_text <- function(media_id, alt_text_data) {
  rurl <- "https://upload.twitter.com/1.1/media/metadata/create.json"
  httr::POST(rurl, body = paste0('{"media_id":"', media_id, '", "alt_text": {"text":"', alt_text_data, '"}}'), token, encode = "raw")
}

# Twitter Post Tweet ------------------------------------------------------
# Post a tweet to Twitter #
twitter_post_tweet <- function(tweet_status, media_ids) {
  rurl <- "https://api.twitter.com/1.1/statuses/update.json"
  httr::POST(rurl, query = list(status = tweet_status, media_ids = media_ids), token)
}

# Twitter Prepare Image ---------------------------------------------------
# Upload an image to Twitter with alt text #
twitter_prepare_image <- function(image, alt_text) {
  media_id <- twitter_media_upload(image)
  twitter_add_alt_text(media_id, alt_text)
  
  return(media_id)
}

# Split Text Block -----------------------------------------------------------
# Split a block of text into separate lines #
split_text_block <- function(text_block, line_limit, text_limit) {
  text_length <- str_length(text_block)
  concatenated_extracts <- ""
  
  while(text_length > line_limit) {
    text_extract <- str_match(str_trunc(text_block, line_limit), "(^.+)\\s")[, 2]
    extract_length <- str_length(text_extract)
    text_block <- str_sub(text_block, extract_length+2)
    text_length <- str_length(text_block)
    
    concatenated_extracts <- paste(concatenated_extracts, text_extract, sep = "\n")
  }
  
  processed_text_block <- paste(concatenated_extracts, text_block, sep = "\n")
  return(str_trunc(processed_text_block, text_limit, ellipsis = "[...]"))
}
