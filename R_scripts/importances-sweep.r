require(ggplot2)
require(foreign)
require(psych)
require(lme4)
require(multcomp)
require(languageR)
require(dplyr)

# install.packages("ggplot2")
install.packages("foreign", "languageR", "psych", "lme4","multcomp", "data.table", "plot3D", "dplyr")


# Call the packages with the library command. These are only essential packages but you will probably need more later

# library(ggplot2)
library(foreign)
library(languageR)
library(psych)
library(lme4)
library(multcomp)
library(data.table)
library(plot3D)
library(plyr)

install.packages(
  "ggplot2",
  repos = c("http://rstudio.org/_packages",
            "http://cran.rstudio.com")
)
library(ggplot2)

################# Setting directory and loading data file #################################
rm(list = ls())



setwd("C:/Users/oscy1/Documents/AI_Master_2020/Master_Project/Models/") # go to correct directory


filename <- "HUMAT_COVID_visitors_measure_FINAL importances_sweep_100_runs.csv"
# filename_7 <-"HUMAT_Mental_health_test.csv"

dat <- fread(file = filename, skip = 6)  # skip some rows that result from behaviorspace

#extract important columns
important_dat <- dat[,c("experiential-importance-parameter", "values-importance-parameter",
                        "allowed_contacts_per_day", "average_contacts_per_day_per_humat", 
                        "average_dilemmas_per_day_per_humat", "average_opinion_sd_over_time",
                        "average_opinion_mean_over_time")]


#column name change to avoid errors with naming 
colnames(important_dat) <- c("experiential_importance_parameter", "values_importance_parameter",
                             "allowed_contacts_per_day", "average_contacts_per_day_per_humat", 
                             "average_dilemmas_per_day_per_humat", "average_opinion_sd_over_time",
                             "average_opinion_mean_over_time")

head(important_dat)
summary(important_dat)


#aggregate the data to get the average of all the runs
agg  = aggregate(important_dat,
                 by = list(important_dat$experiential_importance_parameter, important_dat$values_importance_parameter,
                           important_dat$allowed_contacts_per_day),
                 FUN = mean)

#removes the added 'group' columns
agg <- agg[, c("experiential_importance_parameter", "values_importance_parameter",
               "allowed_contacts_per_day", "average_contacts_per_day_per_humat", 
               "average_dilemmas_per_day_per_humat", "average_opinion_sd_over_time",
               "average_opinion_mean_over_time")]

install.packages('tidyverse')
require(tidyverse)
library(tidyverse)

vm2data <- subset(agg, allowed_contacts_per_day=='2')
vm4data <- subset(agg, allowed_contacts_per_day=='4')
vm6data <- subset(agg, allowed_contacts_per_day=='6')


install.packages("viridis")
library(viridis)


# Select which vmdata you want to make plots for (vm2data, vm4data, vm6data -> number of allowed visitors)
data_for_visualization <- vm6data

#Average contacts per day
ggplot(data_for_visualization, aes(x = experiential_importance_parameter, y = values_importance_parameter, fill = average_contacts_per_day_per_humat)) +
  geom_tile(color = "white", lwd = 1,linetype = 1)+
  geom_text(aes(label = round(average_contacts_per_day_per_humat,2)), color = "white", size = 5) +
  ylab('Values Importance') + 
  xlab('Experiential Importance') +
  ggtitle("Average active contacts per day per HUMAT \nfor different importance configurations of the HUMAT population") +
  scale_x_continuous(breaks = seq(0, 1.0, len = 6)) +
  scale_y_continuous(breaks = seq(0, 1.0, len = 6)) +
  # scale_fill_continuous(limits=c(1.3, 1.8), breaks=seq(1.3, 1.8,by=0.05))+
  theme_bw() +
  coord_fixed() +
  # scale_fill_viridis(option = "E")+
  scale_fill_gradient(low = "blue4", high = "deepskyblue")+
  theme(plot.background = element_rect(fill = "#BFD5E3"), plot.title = element_text(hjust = 0.5), legend.key.size = unit(2.5, 'cm'), legend.title = element_blank(), text = element_text(size=15), legend.position = 'right') 
  
#Average dilemmas per day
ggplot(data_for_visualization, aes(x = experiential_importance_parameter, y = values_importance_parameter, fill = average_dilemmas_per_day_per_humat)) +
  geom_tile(color = "white", lwd = 0.5,linetype = 1)+
  geom_text(aes(label = round(average_dilemmas_per_day_per_humat,2)), color = "white", size = 5) +
  ylab('Values Importance') + 
  xlab('Experiential Importance') +
  ggtitle("Average number of dilemmas per day per HUMAT \nfor different importance configurations of the HUMAT population") +
  scale_x_continuous(breaks = seq(0, 1.0, len = 6)) +
  scale_y_continuous(breaks = seq(0, 1.0, len = 6)) +
  # scale_fill_continuous(limits=c(0, 1), breaks=seq(0,1,by=0.1))+
  theme_bw() +
  coord_fixed() +
  # scale_fill_viridis(option = "D")+
  scale_fill_gradient(low = "red3", high = "orange1")+
  theme(plot.background = element_rect(fill = "#BFD5E3"), plot.title = element_text(hjust = 0.5), legend.key.size = unit(2.5, 'cm'), legend.title = element_blank(), text = element_text(size=15), legend.position = 'right') 

#Mean opinion during the run
ggplot(data_for_visualization, aes(x = experiential_importance_parameter, y = values_importance_parameter, fill = average_opinion_mean_over_time)) +
  geom_tile(color = "white", lwd = 0.5,linetype = 1)+
  geom_text(aes(label = round(average_opinion_mean_over_time,2)), color = "white", size = 5) +
  ylab('Values Importance') + 
  xlab('Experiential Importance') +
  ggtitle("Mean opinion during the run \nfor different importance configurations of the HUMAT population") +
  scale_x_continuous(breaks = seq(0, 1.0, len = 6)) +
  scale_y_continuous(breaks = seq(0, 1.0, len = 6)) +
  scale_fill_continuous(limits=c(0, 1), breaks=seq(0,1,by=0.1))+
  theme_bw() +
  coord_fixed() +
  # scale_fill_viridis(option = "G")+
  scale_fill_gradient(low = "darkgreen", high = "chartreuse1")+
  theme(plot.background = element_rect(fill = "#BFD5E3"), plot.title = element_text(hjust = 0.5), legend.key.size = unit(2.5, 'cm'), legend.title = element_blank(), text = element_text(size=15), legend.position = 'right') 

#Mean sd during the run
ggplot(data_for_visualization, aes(x = experiential_importance_parameter, y = values_importance_parameter, fill = average_opinion_sd_over_time)) +
  geom_tile(color = "white", lwd = 0.5,linetype = 1)+
  geom_text(aes(label = round(average_opinion_sd_over_time,2)), color = "white", size = 5) +
  ylab('Values Importance') + 
  xlab('Experiential Importance') +
  ggtitle("Average standard deviation of opinion \nfor different importance configurations of the HUMAT population") +
  scale_x_continuous(breaks = seq(0, 1.0, len = 6)) +
  scale_y_continuous(breaks = seq(0, 1.0, len = 6)) +
  scale_fill_continuous(limits=c(0, 1), breaks=seq(0,1,by=0.1))+
  theme_bw() +
  coord_fixed() +
  scale_fill_gradient(low = "darkorchid4", high = "pink")+
  theme(plot.background = element_rect(fill = "#BFD5E3"), plot.title = element_text(hjust = 0.5), legend.key.size = unit(2.5, 'cm'), legend.title = element_blank(), text = element_text(size=15), legend.position = 'right') 


