library(httr)
library(dplyr)
library(ggplot2)
library(hrbrthemes)
library(tidyr)

resp <- GET("https://data.covid19.go.id/public/api/update.json")
#header
headers(resp)

#extraction
covid_raw <- content(resp, as = "parsed", simplifyVector = TRUE) 
str(covid_raw)
length(covid_raw)
names(covid_raw)
#extract with new variable
covid_update <- covid_raw$update

lapply(covid_update,names)
#last updated data for 
covid_update$penambahan$tanggal
covid_update$penambahan$jumlah_sembuh
covid_update$penambahan$jumlah_meninggal
covid_update$total$jumlah_positif
covid_update$total$jumlah_meninggal
covid_update$total$jumlah_sembuh

covid_days <- covid_update$harian
str(covid_days)
new_covid_df <-
  covid_days %>% 
  select(-contains("key_as_string")) %>% 
  select(-contains("doc_count")) %>%
  select(-contains("jumlah_positif_kum")) %>% 
  select(-contains("jumlah_sembuh_kum")) %>%
  select(-contains("jumlah_meninggal_kum")) %>%
  select(-contains("jumlah_dirawat_kum")) %>%
  select(-contains("jumlah_dirawat")) %>%
  rename(
    date = key,
    deaths = jumlah_meninggal,
    healed = jumlah_sembuh,
    cases = jumlah_positif
  ) %>% 
  mutate(
    date = as.POSIXct(date / 1000, origin = "1970-01-01"),
    date = as.Date(date)
  )
head(new_covid_df)

ggplot(new_covid_df, aes(date, cases$value)) +
  geom_col(fill = "#FF0033") +
  labs(
    x = NULL,
    y = "Total Cases",
    title = "Total Positif Cases COVID-19 in Indonesia",
    caption = "Source: covid.19.go.id"
  ) +
  theme(plot.title.position = "plot")

ggplot(new_covid_df, aes(date, healed$value)) +
  geom_col(fill = "#0099FF") +
  labs(
    x = NULL,
    y = "Total Recovered",
    title = "Total Recovered from COVID-19 in Indonesia",
    caption = "Source: covid.19.go.id"
  ) +
  theme(plot.title.position = "plot")

ggplot(new_covid_df, aes(date, deaths$value)) +
  geom_col(fill = "#000033") +
  labs(
    x = NULL,
    y = "Total Death Cases",
    title = "Total Death Cases from COVID-19 in Indonesia",
    caption = "Source: covid.19.go.id"
  ) +
  theme(plot.title.position = "plot")

covid_sum <- 
  new_covid_df %>% 
  transmute(
    date,
    sum_active = cumsum(cases$value) - cumsum(healed$value) - cumsum(deaths$value),
    sum_recovered = cumsum(healed$value),
    sum_death = cumsum(deaths$value)
  )

tail(covid_sum)

covid_sum_pivot <- 
  covid_sum %>% 
  gather(
    key = "category",
    value = "total",
    -date
  ) %>% 
  mutate(
    category = sub(pattern = "sum_", replacement = "", category)
  )
glimpse(covid_sum_pivot)

ggplot(covid_sum_pivot,aes(date,total,colour=(category))) +
  geom_line(size=0.9) +
  scale_y_continuous(sec.axis = dup_axis(name = NULL)) +
  scale_colour_manual(
    values = c(
      "active" = "#FF0033",
      "death" = "#000033",
      "recovered" = "#0099FF"
    ),
    labels = c("Active Cases","Death Cases","Recovered Cases")
  ) +
  labs(
    x = NULL,
    y = "Total Cases",
    colour = NULL,
    title = "Dynamics of COVID-19 Cases in Indonesia",
    caption = "Source data: covid.19.go.id"
  ) +
  theme(
    plot.title = element_text(hjust = 0.5),
    legend.position = "top"
  )
