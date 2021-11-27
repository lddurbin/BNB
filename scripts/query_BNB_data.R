library("virtuoso") # Virtuoso increases performance compared to querying the RDF files directly

source("scripts/prefixes.R")
source("scripts/sparql.R") # we use multiple SPARQL queries instead of OPTIONAL due to performance issues

gzipped_rdfs <- unzip_and_gzip(paste0("raw data/zipped/", new_zip_files, ".zip")) %>% map(1)

vos_install() # only need to do this once
vos_start()

new_BNB <- lapply(gzipped_rdfs, process_BNB_data) %>%
  bind_rows() %>% 
  distinct(Dewey, title, creator, contributor, topic, .keep_all = TRUE) %>% 
  select(id, Dewey, title, contributor, creator, topic, publisher, issued, forthcoming, isbn, filename) %>% 
  mutate(to_tweet = case_when(forthcoming == TRUE ~ TRUE, forthcoming == FALSE ~ FALSE)) # forthcoming books to be tweeted

vos_kill() # we don't want Virtuoso running all the time, do we? 

prepare_to_save("processed data/BNB_history_books.csv", "cccccccclccl", new_BNB) %>% 
  write_csv(file = "processed data/BNB_history_books.csv", col_names = TRUE)
