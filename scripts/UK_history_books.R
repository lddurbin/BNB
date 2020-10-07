setwd("/Users/leedurbin/Code/BNB") # for cron

library("tidyverse")

source("scripts/functions.R")

source("scripts/download_BNB_data.R")

new_zip_files <- unprocessed_files("processed data/BNB_history_books.csv")

if(length(new_zip_files) > 0) {
  source("scripts/query_BNB_data.R")
  source("scripts/enrich_BNB_data.R")
}

history_books <- read_csv("processed data/history_books.csv", col_types = "cccccccclcclDcccc")

tweet_data <- history_books %>%
  filter(to_tweet == TRUE & (!is.na(synopsis) | !is.na(cover_thumbnail)))

if(nrow(tweet_data) > 0) {
  tweet_data_sample <- tweet_data %>% 
    group_by(isbn) %>% 
    mutate(sample_id = cur_group_id()) %>%
    ungroup() %>% 
    subset(sample_id %in% sample(unique(.$sample_id), 1))
  
  source("scripts/twitter.R")
}
