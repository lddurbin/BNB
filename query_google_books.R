library("httr") # For connecting to the API

isbns <- new_BNB %>%
  filter(forthcoming == TRUE) %>% 
  distinct(isbn) %>%
  filter(!is.na(isbn)) %>% 
  pull()

if(length(isbns) > 0) {
  fields <- "items/volumeInfo(title, subtitle, authors, publishedDate, description, imageLinks/thumbnail, canonicalVolumeLink, categories)"
  
  GoogleBooks_API_result <- lapply(isbns, query_google_books, fields) %>% 
    bind_rows()
  
  GoogleBooks_data <- GoogleBooks_API_result %>%
    select(title = items.volumeInfo.title, subtitle = items.volumeInfo.subtitle, author = items.volumeInfo.authors, publication_date = items.volumeInfo.publishedDate, synopsis = items.volumeInfo.description, categories = items.volumeInfo.categories, cover_thumbnail = items.volumeInfo.imageLinks.thumbnail, info = items.volumeInfo.canonicalVolumeLink, isbn = isbn) %>% 
    mutate(publication_date = as.Date(publication_date, "%Y-%M-%d")) %>% 
    distinct(author, isbn, info, .keep_all = TRUE)
  
    prepare_to_save("processed data/google_books.csv", "cccDccccc", GoogleBooks_data) %>%
      write_csv(path = "processed data/google_books.csv", col_names = TRUE)
}
