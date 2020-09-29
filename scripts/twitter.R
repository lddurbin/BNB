source("scripts/twitter_credentials.R")

# Prepare tweet text ------------------------------------------------------
for_twitter <- tweet_data_sample %>%
  mutate(title_tweet = str_trunc(title, 140, ellipsis = "[...]") %>% str_replace_all(" : ", ": ")) %>%
  distinct(isbn, .keep_all = TRUE)

publisher_twitter_handles <- read_csv("processed data/publishers.csv", col_types = "cnc") %>% select(publisher, publisher_twitter_handle = twitter_handle, -n)

for_twitter <- left_join(for_twitter, publisher_twitter_handles) %>% 
  mutate(publisher_tweet = case_when(
    !is.na(publisher_twitter_handle) ~ paste0("@", publisher_twitter_handle),
    is.na(publisher_twitter_handle) ~ publisher
  ))

# Prepare tweet images and post tweet ----------------------------------------------------
source("scripts/get_cover_images.R")
source("scripts/create_synopsis_image.R")

cover_filepath <- paste0("images/covers/", for_twitter %>% select(cover_filename))
cover_alt_text <- paste("Cover of the book called", for_twitter %>% distinct(title_tweet))
synopsis_filepath <- paste0("images/synopses/", list.files("images/synopses/"))
synopsis_alt_text <- for_twitter %>% distinct(synopsis) %>% str_trunc(995, ellipsis = "[...]")

media_ids <- mapply(twitter_prepare_image, c(synopsis_filepath, cover_filepath), c(synopsis_alt_text, cover_alt_text)) %>% 
  paste(collapse = ",")

tweet_status <- paste0(for_twitter$title_tweet, " (", for_twitter$publisher_tweet, ") ", for_twitter$info)
twitter_post_tweet(tweet_status, media_ids)

# Delete cover image and synopsis image, mark data as tweeted --------------------------------
unlink("images/covers/*")
unlink("images/synopses/*")

history_books %>%
  mutate(to_tweet = case_when(isbn == for_twitter$isbn ~ FALSE, to_tweet == TRUE ~ TRUE, to_tweet == FALSE ~ FALSE)) %>% 
  write_csv(path = "processed data/history_books.csv", col_names = TRUE)
