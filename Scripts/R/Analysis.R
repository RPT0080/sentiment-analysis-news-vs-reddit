
# ================ 0) LIBRARIES & SETUP ================
suppressPackageStartupMessages({
  library(dplyr)
  library(lubridate)
  library(tidyr)
  
})
#-----------------------------------------FOR AUTOMATION--------------------------------

# optional: show current working dir so paths are predictable
cat("WD:", getwd(), "\n")

# Define folder paths
data_dir   <- "Data/raw_data"
clean_dir  <- "Data/cleaned_data"


# Get latest Reddit file (by date in name or by modified time)
reddit_file <- list.files(data_dir, pattern = "reddit_themes.*\\.csv", full.names = TRUE)
reddit_file <- reddit_file[which.max(file.info(reddit_file)$mtime)]

newsapi_file <- list.files(data_dir, pattern = "newsapi_themes.*\\.csv", full.names = TRUE)
newsapi_file <- newsapi_file[which.max(file.info(newsapi_file)$mtime)]




#-------------------------- Section 1 -------------------------------

df_red <- read.csv(reddit_file)

df_news <- read.csv(newsapi_file)

summary(df_news)
summary(df_red)



#-------Section 2--------------- done
# News: rename to common column and add source
df_newscleaned <- df_news[, c("theme", "title", "sentiment", "created_utc")]
names(df_newscleaned)[names(df_newscleaned) == "published_at"] <- "created_utc"
df_newscleaned$source <- "newsapi"

# Reddit: keep the same set of columns and add source
df_redcleaned <- df_red[, c("theme", "title", "sentiment", "created_utc")]
df_redcleaned$source <- "reddit"

# IMPORTANT: make created_utc the SAME TYPE before combining
df_newscleaned$created_utc <- as.character(df_newscleaned$created_utc)
df_redcleaned$created_utc  <- as.character(df_redcleaned$created_utc)

# Combine
combined_df <- dplyr::bind_rows(df_newscleaned, df_redcleaned)



#-------------------section3-----cleaning date formats--------------
#---- Section 3: Clean created_utc formats ----
  
  # Convert all epoch timestamps (Reddit + NewsAPI) → POSIXct
  combined_df$created_utc <- suppressWarnings(as.POSIXct(
    as.numeric(combined_df$created_utc),
    origin = "1970-01-01", tz = "UTC"
  ))

# Extract just the date
combined_df$date <- as.Date(combined_df$created_utc)

# Report how many failed
cat(" Failed to parse timestamps:", sum(is.na(combined_df$created_utc)), "\n")




# Drop rows with missing created_utc
combined_df <- combined_df %>% filter(!is.na(created_utc))
cat("Remaining rows after dropping bad timestamps:", nrow(combined_df), "\n")


unique(sapply(combined_df$created_utc, class))

# Peek at ranges
range(combined_df$created_utc, na.rm = TRUE)
table(combined_df$source, substr(as.character(combined_df$created_utc), 1, 10)) # count per date



#-----------------------Section 4-------------------------------done

sum(duplicated(combined_df))#sanity check flags rows that are exact copies of prev
combined_df <- combined_df[!duplicated(combined_df), ]

# How many exact duplicate rows?
sum(duplicated(combined_df))# should now be zero after removing duplcaite rows in prev

# Count NAs per column
colSums(is.na(combined_df))# counts how many nas per coloumn


# Trim whitespace and lowercase
combined_df$theme <- trimws(tolower(combined_df$theme))#more housekeeping trims empty begning space and makes lowercase


#------------------------section 5 theme cleaning-------------------------------------- 

# Map synonyms to your canonical names 

theme_map <- c(
  # Mental Health
  "mental health" = "mental_health",
  "mental_health" = "mental_health",
  "mental health OR mindfulness OR coping skills OR anxiety OR therapy OR psychology OR self-help" = "mental_health",
  
  # Global Conflict
  "global_conflict" = "global_conflict",
  "war OR protest OR refugee OR diplomacy OR international relations OR united nations" = "global_conflict",
  
  # Crime & Justice
  "crime justice" = "crime_justice",
  "crime_justice" = "crime_justice",
  "crime OR trial OR community safety OR police OR justice OR public safety OR legal reform" = "crime_justice",
  
  # Climate
  "climate" = "climate",
  "climate OR wildfire OR climate change OR sustainability OR environment OR conservation OR renewable energy" = "climate",
  
  # Economy & Jobs
  "economy jobs" = "economy_jobs",
  "economy_jobs" = "economy_jobs",
  "job search OR unemployment OR hiring OR layoffs OR economic growth OR career OR economy OR inflation OR workforce OR cost of living" = "economy_jobs",
  
  # Education & Learning
  "education learning" = "education_learning",
  "education_learning" = "education_learning",
  "education OR school OR college OR tuition OR university OR learning OR studying OR degree OR literacy OR higher education" = "education_learning",
  
  # Wellness & Growth
  "wellness growth" = "wellness_growth",
  "wellness_growth" = "wellness_growth",
  "wellness OR well-being OR self-care OR self improvement OR habits OR journaling OR meditation OR growth mindset OR lifestyle" = "wellness_growth",
  
  # Tech & Innovation
  "tech innovation" = "tech_innovation",
  "tech_innovation" = "tech_innovation",
  "innovation OR research OR breakthrough OR GPT-4 OR space OR quantum computing OR AI development OR clean tech OR robotics OR future technology" = "tech_innovation",
  
  # Culture & Media
  "culture media" = "culture_media",
  "culture_media" = "culture_media",
  "film OR television OR pop culture OR music OR art OR media OR entertainment OR literature OR fashion OR social media" = "culture_media"
)


# Apply theme mapping
idx <- combined_df$theme %in% names(theme_map)
combined_df$theme[idx] <- theme_map[combined_df$theme[idx]]


#saving to csv before u start making ur analysis on it in case u want to retrace!!! very important
# Create timestamp
timestamp <- format(Sys.time(), "%Y%m%d_%H%M")
# Build file path with timestamp
outfile <- file.path(clean_dir, paste0("combined_cleaned_", timestamp, ".csv"))

# Save
write.csv(combined_df, outfile, row.names = FALSE)

cat(" Saved file:", outfile, "\n")

#-----------------------------------Section 5----------------- 
  

#Average sentiment per theme

theme_sentiment <- combined_df %>%
  group_by(theme) %>%
  summarise(avg_sentiment = mean(sentiment, na.rm = TRUE),
            count = n()) %>%
  arrange(desc(avg_sentiment))

print(theme_sentiment)


# Posts per theme by day
volume_theme_day <- combined_df %>%
  group_by(date = as.Date(created_utc), theme) %>%
  summarise(count = n())


# Which source produces more content per theme
source_theme <- combined_df %>%
  group_by(theme, source) %>%
  summarise(count = n()) %>%
  arrange(desc(count))

print(source_theme)

# Same-day sentiment gap
sentiment_gap <- combined_df %>%
  group_by(date = as.Date(created_utc), source) %>%
  summarise(avg_sentiment = mean(sentiment, na.rm = TRUE)) %>%
  tidyr::pivot_wider(names_from = source, values_from = avg_sentiment) %>%
  mutate(gap = reddit - newsapi)

print(head(sentiment_gap))


# bot like pattern detection
# 1. Posting time regularity
combined_df$hour <- format(as.POSIXct(combined_df$created_utc), "%H")

posting_time_summary <- combined_df %>%
  group_by(source, hour) %>%
  summarise(posts = n(), .groups = "drop") %>%
  arrange(source, hour)

print("Posting Time Regularity (counts per hour):")
print(posting_time_summary)

# 2. Title overlap between Reddit and NewsAPI
title_overlap_count <- sum(
  tolower(combined_df$title[combined_df$source == "reddit"]) %in%
    tolower(combined_df$title[combined_df$source == "newsapi"])
)

print(paste("Reddit titles that exactly match NewsAPI:", title_overlap_count))

# 3. Uniform sentiment (variance by theme + source)
sentiment_variance <- combined_df %>%
  group_by(theme, source) %>%
  summarise(var_sentiment = var(sentiment, na.rm = TRUE),
            n = n(), .groups = "drop") %>%
  arrange(var_sentiment)

print("Themes with lowest sentiment variance (possible bot-like uniformity):")
print(head(sentiment_variance, 10))


sentiment_time <- combined_df %>%
  filter(!is.na(date), !is.na(sentiment)) %>%
  group_by(date, source) %>%
  summarise(avg_sentiment = mean(sentiment, na.rm = TRUE), .groups = "drop")

#Lag analysis (does Reddit react 1 day after NewsAPI?)
reddit_shifted <- sentiment_time %>%
  filter(source == "reddit") %>%
  rename(reddit_sent = avg_sentiment) %>%
  mutate(date = date - 1)  # shift Reddit back by 1 day

lag_analysis <- sentiment_time %>%
  filter(source == "newsapi") %>%
  rename(newsapi_sent = avg_sentiment) %>%
  left_join(reddit_shifted, by = "date")

print("Lag analysis (Reddit sentiment vs NewsAPI 1 day earlier):")
print(head(lag_analysis))



#sentiment buckets

combined_df$sentiment_bucket <- cut(
  combined_df$sentiment,
  breaks = c(-Inf, -0.2, 0.2, Inf),
  labels = c("Negative", "Neutral", "Positive")
)
table(combined_df$sentiment_bucket, combined_df$source)

#weekday patterns
combined_df$weekday <- weekdays(combined_df$date)
table(combined_df$weekday, combined_df$source)

#clickbait detection
clickbait_words <- c("shocking", "you won’t believe", "surprising", "this is what", "you need to see")
combined_df$is_clickbait <- grepl(paste(clickbait_words, collapse="|"), combined_df$title, ignore.case=TRUE)
table(combined_df$is_clickbait, combined_df$source)

#theme grouping

combined_df$theme_category <- ifelse(
  combined_df$theme %in% c("mental_health", "wellness_growth"),
  "Wellbeing",
  ifelse(combined_df$theme %in% c("climate_disaster", "global_conflict"),
         "Global Issues", "Other")
)

#focused theme analysiss
combined_df %>%
  filter(theme == "global_conflict") %>%
  mutate(source = tolower(source)) %>%
  group_by(date, source) %>%
  summarise(avg_sentiment = mean(sentiment, na.rm = TRUE), .groups = "drop") %>%
  tidyr::pivot_wider(names_from = source, values_from = avg_sentiment) %>%
  # Ensure both columns exist
  mutate(
    newsapi = ifelse(!"newsapi" %in% names(.), NA, newsapi),
    reddit  = ifelse(!"reddit"  %in% names(.), NA, reddit),
    diff    = ifelse(!is.na(newsapi) & !is.na(reddit), newsapi - reddit, NA)
  ) %>%
  arrange(date)



# row theme source volatility
volatility <- combined_df %>%
  group_by(theme, source) %>%
  summarise(sd_sentiment = sd(sentiment, na.rm = TRUE), .groups = "drop")

combined_df <- combined_df %>%
  left_join(volatility, by = c("theme", "source"))

#per theme correlation
alignment <- combined_df %>%
  group_by(theme, date, source) %>%
  summarise(avg_sent = mean(sentiment, na.rm = TRUE), .groups = "drop") %>%
  tidyr::pivot_wider(names_from = source, values_from = avg_sent) %>%
  group_by(theme) %>%
  summarise(
    correlation = if (sum(complete.cases(newsapi, reddit)) > 1) {
      cor(newsapi, reddit, use = "complete.obs")
    } else {
      NA_real_
    },
    .groups = "drop"
  )
#heatmaps
heatmap_summary <- combined_df %>%
  group_by(theme, weekday, source) %>%
  summarise(avg_sentiment_weekday = mean(sentiment, na.rm = TRUE), .groups = "drop")

combined_df <- combined_df %>%
  left_join(heatmap_summary, by = c("theme", "weekday", "source"))
# lagged reaction 
sentiment_time <- combined_df %>%
  group_by(date, source, theme) %>%
  summarise(avg_sentiment = mean(sentiment, na.rm = TRUE), .groups = "drop")

reddit_shifted <- sentiment_time %>%
  filter(source == "reddit") %>%
  mutate(date = date - 1) %>%
  rename(reddit_lag_sent = avg_sentiment)

reaction_time <- sentiment_time %>%
  filter(source == "newsapi") %>%
  rename(news_sentiment = avg_sentiment) %>%
  left_join(reddit_shifted, by = c("date", "theme")) %>%
  mutate(reaction_gap = reddit_lag_sent - news_sentiment)

combined_df <- combined_df %>%
  left_join(reaction_time %>% select(date, theme, reaction_gap), by = c("date", "theme"))
# clickbait tone vs sentiment
clickbait_summary <- combined_df %>%
  group_by(is_clickbait, source) %>%
  summarise(clickbait_avg_sent = mean(sentiment, na.rm = TRUE), .groups = "drop")

combined_df <- combined_df %>%
  left_join(clickbait_summary, by = c("is_clickbait", "source"))


# ----------------- Extra Analysis -----------------

# 1. Flag extreme polarity per row
combined_df <- combined_df %>%
  mutate(extreme_flag = abs(sentiment) > 0.5)

# (optional summary table: extreme_counts)
extreme_counts <- combined_df %>%
  group_by(theme) %>%
  summarise(
    pct_extreme = mean(extreme_flag, na.rm = TRUE),
    avg_sentiment = mean(sentiment, na.rm = TRUE),
    sd_sentiment = sd(sentiment, na.rm = TRUE),
    n = n()
  ) %>%
  arrange(desc(pct_extreme))


#2. Emotionally charged news effect (volatility difference)
theme_sd <- combined_df %>%
  group_by(theme, source) %>%
  summarise(sd_sentiment = sd(sentiment, na.rm = TRUE), .groups = "drop") %>%
  tidyr::pivot_wider(names_from = source, values_from = sd_sentiment) %>%
  # Now columns will be "newsapi" and "reddit"
  mutate(spike_effect = reddit - newsapi)

combined_df <- combined_df %>%
  left_join(theme_sd %>% select(theme, spike_effect), by = "theme")

# 3. Negative headline flags per row
combined_df <- combined_df %>%
  mutate(
    news_negative   = ifelse(source == "newsapi", sentiment < 0, NA),
    reddit_negative = ifelse(source == "reddit", sentiment < 0, NA)
  )


# 4. Mirroring flag (both sources negative on same theme/date)
mirror_flags <- combined_df %>%
  group_by(theme, date, source) %>%
  summarise(avg_sent = mean(sentiment, na.rm = TRUE), .groups = "drop") %>%
  tidyr::pivot_wider(names_from = source, values_from = avg_sent) %>%
  mutate(mirror_flag = (newsapi < 0 & reddit < 0)) %>%
  select(theme, date, mirror_flag)

combined_df <- combined_df %>%
  left_join(mirror_flags, by = c("theme", "date"))

# (optional summary table: pct mirrored by theme)
mirror_summary <- mirror_flags %>%
  group_by(theme) %>%
  summarise(pct_mirrored = mean(mirror_flag, na.rm = TRUE))

# Save with timestamp for weekly automation
outfile <- file.path(clean_dir, paste0("combined_finalstats_", format(Sys.time(), "%Y%m%d_%H%M"), ".csv"))
write.csv(combined_df, outfile, row.names = FALSE)





