
library(tidyverse)
library(FredR)
library(zoo)

# Obtaining the data ------------------------------------------------------

# Download the S&P 500 data
sp500 <- read_csv("https://stooq.com/q/d/l/?s=^spx&i=d", col_types = 
                    cols(
                    Date   = col_date(format = "%Y-%m-%d"),
                    Open   = col_double(),
                    High   = col_double(),
                    Low    = col_double(),
                    Close  = col_double(),
                    Volume = col_double()))  %>%
  select(Date, sp500 = Close)

# Get 10 year breakevens (nominal - indexed Treasury bond yields) from Fred
api_key <- "yourkeyhere" # register an API key with Fred first and insert here
fred    <- FredR(api_key)

fred$series.observations(series_id = "T10YIE") %>%
  select(Date = date, be = value) %>%
  mutate(Date = as.Date(Date),
         be = ifelse(be == ".", NA, as.numeric(be))) %>%
  full_join(., sp500, by = "Date") -> df

gr_back <- function(series, freq) {
  # Calculate backward-looking growth rate in percentage points.
  #
  #   series:   the series to be adjusted
  #   freq:     the frequency by which to take the growth rate. Take 1 if you 
  #             want calculate the growth rate from subsequent observations. 
  #             For quarterly take 4 and for monthly take 12.
  
  truncLen <- (length(series) - freq)
  gr       <- 100 * diff(series, freq) / series[1:truncLen]
  gr       <- c(rep(NA, freq), gr)
}

# Delete missing values and calculate daily growth rates
df <- df %>%
  na.omit() %>%
  mutate(sp500_gr = gr_back(sp500, 1),  
         be_gr    = gr_back(be, 1))

# Inspecting the series ---------------------------------------------------

# Normalize the series for comparison
df <- df %>%
  mutate(sp500_norm = sp500 / df$sp500[df$Date   == "2011-05-02"],
         be_norm    = be    / df$be[df$Date      == "2011-05-02"])

stDate  <- as.Date("2003-01-02")
enDate  <- as.Date("2017-06-29")
stPaper <- as.Date("2009-07-01")
enPaper <- as.Date("2013-05-31")

ggplot(subset(df, (Date >= stDate) & (Date <= enDate)), aes(x = Date)) +
  geom_line(aes(y = be_norm,    color = "10-year inflation breakeven")) +
  geom_line(aes(y = sp500_norm, color = "S&P 500")) +
  geom_vline(xintercept = as.numeric(stPaper), 
             size       = 1, 
             color      = "black",
             linetype   = "dotted") + 
  geom_vline(xintercept = as.numeric(enPaper), 
             size       = 1, 
             color      = "black",
             linetype   = "dotted") + 
  labs(x        = "Days",
       y        = "Normalized values",
       title    = "Comparing inflation breakeven and stock market performance",
       subtitle = paste(stDate, "to", enDate, "(normalized to 2011-05-02)"),
       caption  = paste0("Vertical dotted lines are ", stPaper, " and ", 
                        enPaper, ".")) +
         theme_minimal()
