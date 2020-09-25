# Get the .zip files that haven't yet been processed
unprocessed_files <- function(processed_data_file){
  if(file.exists(processed_data_file)) {
    zip_files <- list.files("raw data/zipped", pattern = ".zip$") %>% str_replace("[.zip]*$","") %>% str_to_lower()
    gzip_files <- list.files("raw data/zipped", pattern = ".rdf.gz$") %>% str_replace("[.rdf.gz]*$","") %>% str_to_lower()
    
    setdiff(zip_files, gzip_files)
  } else {
    list.files("raw data/zipped", pattern = ".zip$") %>% str_replace("[.zip]*$","") %>% str_to_lower()
  }
}

# Unlist nested lists
unlist_it <- function(x, cycles) {
  i <- 1
  
  while (i < (cycles+1)) {
    i <- i + 1
    x <- unlist(x, recursive = FALSE)
  }
  
  as_tibble(x)
}

# Extract all .zip files in a directory then recompress them as .gz files in another directory
unzip_and_gzip <- function(zipped_files) {
  walk(zipped_files, unzip, exdir = "raw data/zipped")
  lapply(list.files("raw data/zipped", pattern = ".rdf$", full.names = TRUE), R.utils::gzip, ext = "gz", remove = TRUE)
}

# Run a SPARQL query in Virutoso, convert output to tibble
query_rdf <- function(sparql_query) {
  vos_query(vos_connect(), sparql_query) %>% 
    as_tibble()
}

# Join tibbles together by common variable(s)
join_tibbles <- function(tibbles, joins) {
  tibbles %>% reduce(left_join, by = joins)
}

# Create, query, and delete a Virtuoso database
use_virtuoso <- function(rdf_file) {
  vos_import(vos_connect(), rdf_file)
  rdf_tibbles <- lapply(paste(prefixes, sparql_queries), query_rdf)
  vos_delete_db(ask = FALSE)
  
  return(rdf_tibbles)
}

# Prepare a BNB RDF file for analysis
process_BNB_data <- function(rdf_file) {
  topic_exclusions <- c("--Fiction", "--Juvenile fiction", "--21st century") %>%
    paste(collapse = "|")
  
  use_virtuoso(rdf_file) %>%
    setNames(c("basic", "contributors", "creators", "topics", "publisher", "issued", "forthcoming", "isbn")) %>%
    join_tibbles(c("id", "Dewey", "title")) %>%
    mutate(
      forthcoming = case_when(is.na(forthcoming) ~ FALSE, !is.na(forthcoming) ~ TRUE),
      filename = str_remove(basename(rdf_file), ".rdf.gz")
      ) %>% 
    filter(!str_detect(topic, topic_exclusions))
}

# Query Google Books API based on ISBN, convert result into tibble
query_google_books <- function(isbn, fields) {
  source("google_credentials.R")
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

# Transform content from Google Books  into a tibble
google_books_transform <- function(request) {
  rawToChar(request$content) %>%
    jsonlite::fromJSON() %>% 
    unlist_it(3)
}

# Bind new data with existing data in order to to write it to a file
prepare_to_save <- function(target_dest, column_types, new_data) {
  if(file.exists(target_dest)) {
    existing_data <- read_csv(target_dest, col_types = column_types)
    bind_rows(existing_data, setdiff(new_data, existing_data))
  } else {
    return(new_data)
  }
}
