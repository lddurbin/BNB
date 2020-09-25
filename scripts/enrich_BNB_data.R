if(length(new_BNB) > 0) {
  source("query_google_books.R")
  
  new_GoogleBooks <- GoogleBooks_data %>%
    select(4:9) %>% 
    filter(!is.na(info)) %>% 
    distinct(info, isbn, .keep_all = TRUE)
  
  joined_data <- left_join(new_BNB, new_GoogleBooks, by = "isbn")
  prepare_to_save("processed data/history_books.csv", "cccccccclcclDcccc", joined_data) %>% 
    write_csv(path = "processed data/history_books.csv", col_names = TRUE)
}
