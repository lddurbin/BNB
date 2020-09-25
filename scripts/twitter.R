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

# Send tweet, including cover image ---------------------------------------
source("scripts/get_cover_images.R")
cover_filepath <- paste0("images/covers/", for_twitter %>% select(cover_filename))
media_id <- twitter_media_upload(cover_filepath)

alt_text_data = paste("Cover of the book called", for_twitter %>% distinct(title_tweet))
twitter_add_alt_text(media_id, alt_text_data)

tweet_status <- paste0(for_twitter$title_tweet, " (", for_twitter$publisher_tweet, ") ", for_twitter$info)
twitter_post_tweet(tweet_status, media_id)

# Delete cover image, mark data as tweeted --------------------------------
unlink("images/covers/*")

history_books %>%
  mutate(to_tweet = case_when(isbn == for_twitter$isbn ~ FALSE, to_tweet == TRUE ~ TRUE, to_tweet == FALSE ~ FALSE)) %>% 
  write_csv(path = "processed data/history_books.csv", col_names = TRUE)
