# Optional visual QA using a locally installed Chrome; analysis remains in R.
# Static copies preserve each slide's actual HTML/CSS while avoiding headless
# captures during slideshow compositing. They are temporary review artifacts.
set.seed(42)
suppressPackageStartupMessages(library(tidyverse))
here::i_am("scripts/preview_html.R")
browser <- Sys.which("google-chrome")
if(!nzchar(browser)) stop("Chrome is needed only for this optional visual review.")
qa_dir <- file.path(tempdir(),"ipl_visual_review"); dir.create(qa_dir,showWarnings=FALSE)
original <- paste(readLines(here::here("presentation","slides.html")),collapse="\n")
paths <- character()
for(i in seq_len(13)) {
  html <- xml2::read_html(original)
  xml2::xml_remove(xml2::xml_find_all(html,"//script"))
  xml2::xml_set_attr(xml2::xml_find_first(html,"//body"),"class","loaded")
  slides <- xml2::xml_find_all(html,"//slide")
  content <- slides[!str_detect(replace_na(xml2::xml_attr(slides,"class"),""),"backdrop")]
  selected <- content[[i]]
  xml2::xml_set_attr(selected,"class","current")
  xml2::xml_set_attr(selected,"data-slide-num",as.character(i))
  xml2::xml_set_attr(selected,"data-total-slides","13")
  xml2::xml_remove(content[-i]); xml2::xml_remove(xml2::xml_find_all(html,"//slide[contains(@class,'backdrop')]"))
  static <- file.path(qa_dir,paste0("slide_",i,".html")); png <- file.path(qa_dir,paste0("slide_",i,".png"))
  xml2::write_html(html,static)
  status <- system2(browser,c("--headless","--no-sandbox","--disable-gpu","--disable-dev-shm-usage",
    "--disable-background-networking","--no-first-run","--no-default-browser-check",
    paste0("--user-data-dir=",file.path(qa_dir,paste0("profile_",i))),"--window-size=1440,1000",
    "--virtual-time-budget=3000",paste0("--screenshot=",png),paste0("file://",static)),stdout=FALSE,stderr=FALSE)
  if(status!=0 || !file.exists(png)) stop("Preview failed for slide ",i)
  paths <- c(paths,png)
}
report_png <- file.path(qa_dir,"report.png")
stopifnot(system2(browser,c("--headless","--no-sandbox","--disable-gpu","--disable-dev-shm-usage",
  "--disable-background-networking","--no-first-run","--no-default-browser-check",
  paste0("--user-data-dir=",file.path(qa_dir,"profile_report")),"--window-size=1440,1000",
  "--virtual-time-budget=3000",paste0("--screenshot=",report_png),paste0("file://",here::here("report","final_report.html"))),stdout=FALSE,stderr=FALSE)==0)
# Copy only PNG review artifacts out of the session tempdir before R exits.
review <- here::here(".runtime","visual_review")
dir.create(review,recursive=TRUE,showWarnings=FALSE)
file.copy(c(paths,report_png),review,overwrite=TRUE)
cat("Visual previews saved in ",review,"\n",sep="")
