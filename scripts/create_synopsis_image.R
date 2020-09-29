library("magick")

processed_synopsis <- split_text_block(for_twitter$synopsis, 90, 1000)
annotation <- paste(for_twitter$title, processed_synopsis, sep = "\n")

image_annotate(image_blank(800, 500), annotation, font = 'times-new-roman', size = 20, gravity = "center") %>% 
  image_write(paste0("images/synopses/", paste(for_twitter$filename, fortwitter$isbn, sep = "_"), ".png"))
