setwd("/Users/leedurbin/Code/BNB") # for cron

library("tidyverse")

source("functions.R")

source("download_BNB_data.R")

new_zip_files <- unprocessed_files("processed data/BNB_history_books.csv")

if(length(new_zip_files) > 0) {
  source("query_BNB_data.R")
  source("enrich_BNB_data.R")
}

history_books <- read_csv("processed data/history_books.csv", col_types = "cccccccclcclDcccc")

tweet_data <- history_books %>%
  filter(to_tweet == TRUE & str_detect(str_to_lower(topic), "history") == TRUE & !is.na(cover_thumbnail)) %>% #include more filters (categories, use "biograph" etc.)
  mutate(sample_id = group_indices(.,isbn)) %>%
  subset(sample_id %in% sample(unique(.$sample_id), 1))

if(nrow(tweet_data) > 0) {
  source("twitter.R")
}
