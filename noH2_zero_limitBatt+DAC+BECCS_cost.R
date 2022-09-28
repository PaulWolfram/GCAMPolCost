# Script for reading CO2 abatement quantities and marginal abatement cost from a GCAM policy run and calculating policy costs
# Paul Wolfram
# 8/18/2022 

# you may need to install these packages:
# install.packages("xml2")
# install.packages('xlsx')     

# load libraries:
library(xlsx)   
library(xml2)
library(XML)
library(tidyverse)
library(dplyr)
library(readr)
library(tibble)

# set working direcyory: 
setwd("C:/Users/wolf184/stash/_h2valuenew/gcam-core/exe")

rm(list=ls()) # clear environment
cat("\014") # clear console

# read file: 
xml_dataset <- read_xml("cost_curvesnoH2_zero_limitBatt+DAC+BECCS_cost.xml") %>%
  xmlParse()

# define variables: 
df_all_x <- xmlToDataFrame(nodes = getNodeSet(xml_dataset, "//x")) # parse marginal abatement quantities as dataframe
df_all_y <- xmlToDataFrame(nodes = getNodeSet(xml_dataset, "//y")) # parse marginal abatement costs as dataframe
# x values are in Mt C and represent marginal abated emissions relative to a reference scenario at a given marginal carbon price 
# y values are in 1990$/t C


# combine both vectors:
df_all_xy <- cbind(df_all_x, df_all_y)  

colnames(df_all_xy) <- c('Abat Mt C','Price 1990$/t C')


# add Mt CO2 column:
conv <- rep(44/12, times = nrow(df_all_xy))
abat_MtCO2 <- as.numeric(df_all_xy$'Abat Mt C') * conv


# add 2019$/tCO2 column:
conv <- rep(12/44*1.81221, times = nrow(df_all_xy))
price_tCO2 <- as.numeric(df_all_xy$'Price 1990$/t C') * conv
df_all_xy <- cbind(df_all_xy,abat_MtCO2,price_tCO2) %>%   
  add_column(Year = "n/a") %>%
  rename('Price 2019$/t CO2' = price_tCO2) %>%
  rename('Abat Mt CO2' = abat_MtCO2)
# inflation factor taken from St. Louis Federal Reserve Bank: https://fred.stlouisfed.org/series/FPCPITOTLZGUSA

# remove vectors that are not needed anymore
rm(df_all_x, df_all_y)


# drop the last 704 rows which is a different dataset (regional cost curves by year, 22 time periods x 32 regions = 704 rows)
df_all_xy <- head(df_all_xy, -704)


# I am only interested in 2020-2050 costs so I am also dropping the time steps 2055-2100 (6 price data points x 32 regions x 10 time periods = 1920 rows)
df_all_xy <- head(df_all_xy, -1920)


# add the labels for time periods 2020-2050, start at the bottom, every time period spans 192 rows (6 price points x 32 regions)
df_all_xy$Year[(nrow(df_all_xy)-(192*1)+1):(nrow(df_all_xy)-(192*0))] = "2050"
df_all_xy$Year[(nrow(df_all_xy)-(192*2)+1):(nrow(df_all_xy)-(192*1))] = "2045"
df_all_xy$Year[(nrow(df_all_xy)-(192*3)+1):(nrow(df_all_xy)-(192*2))] = "2040"
df_all_xy$Year[(nrow(df_all_xy)-(192*4)+1):(nrow(df_all_xy)-(192*3))] = "2035"
df_all_xy$Year[(nrow(df_all_xy)-(192*5)+1):(nrow(df_all_xy)-(192*4))] = "2030"
df_all_xy$Year[(nrow(df_all_xy)-(192*6)+1):(nrow(df_all_xy)-(192*5))] = "2025"
df_all_xy$Year[(nrow(df_all_xy)-(192*7)+1):(nrow(df_all_xy)-(192*6))] = "2020"


# the remaining n/a values in the Year column are the time periods 1975-2015 which we can drop as well now 
df_all_xy <- subset(df_all_xy, Year != "n/a")


# check that the first row of every year starts with a zero (1st price point is always zero)
head(subset(df_all_xy, df_all_xy$Year=="2020"))
head(subset(df_all_xy, df_all_xy$Year=="2025"))
head(subset(df_all_xy, df_all_xy$Year=="2030"))
head(subset(df_all_xy, df_all_xy$Year=="2035"))
head(subset(df_all_xy, df_all_xy$Year=="2040"))
head(subset(df_all_xy, df_all_xy$Year=="2045"))
head(subset(df_all_xy, df_all_xy$Year=="2050"))


# create regions vector
Region <- rep(c("Africa_Eastern", 
                 "Africa_Northern", 
                 "Africa_Southern", 
                 "Africa_Western", 
                 "Argentina", 
                 "Australia_NZ", 
                 "Brazil", 
                 "Canada", 
                 "Central America and Caribbean", 
                 "Central Asia", 
                 "China", 
                 "Colombia", 
                 "EU-12", 
                 "EU-15", 
                 "Europe_Eastern", 
                 "Europe_Non_EU", 
                 "European Free Trade Association", 
                 "India", 
                 "Indonesia", 
                 "Japan", 
                 "Mexico", 
                 "Middle East", 
                 "Pakistan", 
                 "Russia", 
                 "South Africa", 
                 "South America_Northern", 
                 "South America_Southern", 
                 "South Asia", 
                 "South Korea", 
                 "Southeast Asia",
                 "Taiwan", 
                 "USA"), each=6)
Region <- rep(Region, times=7)


# create price level vector
Price_level<-rep(c('0%', '20%', '40%', '60%', '80%', '100%'),times=32)
Price_level<-rep((Price_level),times=7)


# bring all together into one dataframe
df_all_xy <- cbind(df_all_xy,Region,Price_level) 

# change order of columns
df_all_xy <- df_all_xy[,c(5,6,7,2,4,1,3)]


# create a dummy vector for calculating the deltas of abated emissions:
abat_MtCO2 <- df_all_xy$'Abat Mt CO2'
dummy <- abat_MtCO2[-c(nrow(df_all_xy))] 
dummy <- append(0,dummy)

df_all_xy <- cbind(df_all_xy,dummy)

delta <- df_all_xy$'Abat Mt CO2' - df_all_xy$dummy

df_all_xy <- cbind(df_all_xy,delta) %>%
  subset(select = -c(dummy))

df_all_xy$delta[df_all_xy$delta<0] <- 0


# new column: cost of abated emissions at each price level for each time step and each region in trillion 2019$
cost <- as.numeric(df_all_xy$delta) * as.numeric(df_all_xy$'Price 2019$/t CO2') / 1000000

df_all_xy <- cbind(df_all_xy,cost) %>%
  rename('Mit cost trill 2019$' = cost) %>%
  rename('Delta abat Mt CO2' = delta)


# improve readability of columns and make sure everything is in numeric format:
df_all_xy$'Delta abat Mt CO2' <- round(as.numeric(df_all_xy$'Delta abat Mt CO2'), digits=0)
df_all_xy$'Abat Mt CO2' <- round(as.numeric(df_all_xy$'Abat Mt CO2'), digits=0)
df_all_xy$'Abat Mt C' <- round(as.numeric(df_all_xy$'Abat Mt C'), digits=0)
df_all_xy$'Price 2019$/t CO2' <- round(as.numeric(df_all_xy$'Price 2019$/t CO2'), digits=0)
df_all_xy$'Price 1990$/t C' <- round(as.numeric(df_all_xy$'Price 1990$/t C'), digits=0)
df_all_xy$'Mit cost trill 2019$' <- round(as.numeric(df_all_xy$'Mit cost trill 2019$'), digits=2)



##########################
# National mitigation cost
##########################

mit_cost_country <- rowsum(df_all_xy$'Mit cost trill 2019$',rep((1:(nrow(df_all_xy)/6)), each=6))


region <- rep(c("Africa_Eastern", 
                "Africa_Northern", 
                "Africa_Southern", 
                "Africa_Western", 
                "Argentina", 
                "Australia_NZ", 
                "Brazil", 
                "Canada", 
                "Central America and Caribbean", 
                "Central Asia", 
                "China", 
                "Colombia", 
                "EU-12", 
                "EU-15", 
                "Europe_Eastern", 
                "Europe_Non_EU", 
                "European Free Trade Association", 
                "India", 
                "Indonesia", 
                "Japan", 
                "Mexico", 
                "Middle East", 
                "Pakistan", 
                "Russia", 
                "South Africa", 
                "South America_Northern", 
                "South America_Southern", 
                "South Asia", 
                "South Korea", 
                "Southeast Asia",
                "Taiwan", 
                "USA"), each=1)
region <- rep(region, times=7)


year <- rep(c("2020",
            "2025",
            "2030",
            "2035",
            "2040",
            "2045",
            "2050"), each=32)

mit_cost_country <- cbind(mit_cost_country,region,year)
mit_cost_country <- as.data.frame(mit_cost_country)
colnames(mit_cost_country) <-  c("Mit cost trill 2019$","Region", "Time period")

# change order of columns
mit_cost_country$'Mit cost trill 2019$' <- round(as.numeric(mit_cost_country$'Mit cost trill 2019$'), digits=2)


# add an NPV column at a discount factor of 5% (change discount_fact if needed)
t <- rep(c(2020), each=224)
discount_period <- as.numeric(year) - t
discount_fact <- rep(c(0.05), each=224)
npv <- mit_cost_country$'Mit cost trill 2019$' / ((1+discount_fact)^discount_period)

mit_cost_country <- cbind(mit_cost_country,discount_period,npv) %>%
  rename('Discounting period' = discount_period) %>%
  rename('NPV trill 2019$' = npv)

mit_cost_country$'NPV trill 2019$' <- round(as.numeric(mit_cost_country$'NPV trill 2019$'), digits=2)

# change order of columns
mit_cost_country <- mit_cost_country[,c(3,4,2,1,5)]



########################
# Global mitigation cost
########################

mit_cost_global <- rowsum(mit_cost_country$'Mit cost trill 2019$',rep((1:(nrow(mit_cost_country)/32)), each=32)) 
mit_cost_global <- as.data.frame(mit_cost_global)

periods <- rep(c("2020",
                 "2025",
                 "2030",
                 "2035",
                 "2040",
                 "2045",
                 "2050"), each=1)


mit_cost_global <- cbind(mit_cost_global,periods)
mit_cost_global <- as.data.frame(mit_cost_global)
colnames(mit_cost_global) <-  c("Mit cost trill 2019$", "Time period")
mit_cost_global <- mit_cost_global[,c(2,1)]
mit_cost_global$'Mit cost trill 2019$' <- round(as.numeric(mit_cost_global$'Mit cost trill 2019$'), digits=2)

# add an NPV column at a discount factor of 5% (change the discount rate if needed)

t <- rep(c(2020), each=7)
discount_period <- as.numeric(periods) - t
discount_fact <- rep(c(0.05), each=7)
npv_glob <- mit_cost_global$'Mit cost trill 2019$' / ((1+discount_fact)^discount_period)


# add GDP column in million 1990$ for the time periods 2020-2050
gdp_1990_mill <- c(57074729.3,
             65626284.6,
             73315481.9,
             84911449,
             94815600,
             104982937,
             115199310)
                
gdp_2019_trill <-gdp_1990_mill / 1000000 * 1.81221

mit_cost_global_gdp <- as.numeric(mit_cost_global$'Mit cost trill 2019$') / as.numeric(gdp_2019_trill) * 100
npv_global_gdp <- as.numeric(npv_glob) / as.numeric(gdp_2019_trill) * 100

mit_cost_global <- cbind(mit_cost_global, gdp_2019_trill, mit_cost_global_gdp, npv_glob, npv_global_gdp) %>%
  rename('GDP trill 2019$' = gdp_2019_trill) %>%
  rename('Mit cost % GDP' = mit_cost_global_gdp) %>%
  rename('NPV trill 2019$' = npv_glob) %>%
  rename('NPV % GDP' = npv_global_gdp)

mit_cost_global$'GDP trill 2019$' <- round(as.numeric(mit_cost_global$'GDP trill 2019$'), digits=0)
mit_cost_global$'Mit cost % GDP' <- round(as.numeric(mit_cost_global$'Mit cost % GDP'), digits=2)
mit_cost_global$'NPV trill 2019$' <- round(as.numeric(mit_cost_global$'NPV trill 2019$'), digits=2)
mit_cost_global$'NPV % GDP' <- round(as.numeric(mit_cost_global$'NPV % GDP'), digits=2)


write.xlsx(mit_cost_global, file = "C:/Users/wolf184/OneDrive - PNNL/Documents/Projects/HFTO/__value_paper/outputs/pol_cost.xlsx", sheetName = "#3.5", append=TRUE, col.names = TRUE, row.names = TRUE)
