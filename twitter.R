library("rtweet") # do I still need this?

source("twitter_credentials.R")

for_twitter <- tweet_data %>%
  mutate(
    title_tweet = str_trunc(title, 140, ellipsis = "[...]"),
    title_tweet = str_replace_all(title_tweet, " : ", ": "),
    creator_tweet = trimws(str_replace_all(creator, "[[:digit:][-]]", ""), whitespace = ", "),
    creator_tweet = trimws(gsub("\\s*\\([^\\)]+\\)","", creator_tweet), whitespace = "\\.")
  ) %>%
  distinct(isbn, .keep_all = TRUE)

# I GOT THIS CODE FROM THE RTWEET PACKAGE SOURCE CODE BECAUSE IT DOESN'T HAVE A FUNCTION FOR UPLOADING MEDIA AND ATTACHING ALT TEXT
if(!is.na(tweet_data %>% distinct(cover_thumbnail))) {
  source("get_cover_images.R")
  
  cover_filepath <- paste0("images/covers/", for_twitter %>% select(cover_filename))
  tweet_status <- paste0(for_twitter$title_tweet, " (", for_twitter$publisher, ") ", for_twitter$info)
  
  media2upload <- httr::upload_file(cover_filepath)
  rurl <- "https://upload.twitter.com/1.1/media/upload.json"
  media_response <- httr::POST(rurl, body = list(media = media2upload), token)
  
  media_id <- httr::content(media_response) %>% as_tibble() %>% distinct(as.character(media_id_string)) %>% pull()
  
  rurl <- "https://api.twitter.com/1.1/statuses/update.json"
  tweet_response <- httr::POST(rurl, query = list(status = tweet_status, media_ids = media_id), token)
} else {
  # BEWARE OR BOOKS WITH NO AUTHORS
  tweet_status <- paste0(for_twitter$title_tweet, " (", for_twitter$publisher, ")")
  
  rurl <- "https://api.twitter.com/1.1/statuses/update.json"
  tweet_response <- httr::POST(rurl, query = list(status = tweet_status), token)
}

# alt_text_data = paste("Cover of the book called", for_twitter %>% distinct(title_tweet))
# 
# rurl <- "https://upload.twitter.com/1.1/media/metadata/create.json"
# alt_text_response <- httr::POST(rurl, body = list(media_id = media_id, alt_text = list(text = alt_text_data)), token)
# 
# httr::content(alt_text_response)


# delete the cover images from local directory if all went well
unlink("images/covers/*")

# stop this book from being tweeted again
history_books %>%
  mutate(to_tweet = case_when(isbn == for_twitter$isbn ~ FALSE, to_tweet == TRUE ~ TRUE, to_tweet == FALSE ~ FALSE)) %>% 
  write_csv(path = "processed data/history_books.csv", col_names = TRUE)
