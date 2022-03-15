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


filename <- "HUMAT_COVID_visitors_measure_wave11_100runs.csv"
# filename_7 <-"HUMAT_Mental_health_test.csv"

dat <- fread(file = filename, skip = 36, drop = 1)  # skip 23 or 7 depending on which behaviorspace csv file chosen
# dat <- fread(file = filename_7, skip = 7)
# dat <- dat[-1,]  # remove day 0

opinions_matrix <- data.matrix(dat[-1,])  # convert into matrix and remove day 0

n_epochs <- nrow(opinions_matrix)  # stores the number of epochs (= number of rows in matrix) 
n_runs <- ncol(opinions_matrix)  # stores number of runs

# print(opinion_matrix[1,])

########## Plot average opinion over time ####################

day_opinion <- replicate(n_runs,numeric(n_epochs/24)) 
mean_opinion <- replicate(1,numeric(n_epochs/24)) 
sd_opinion <- replicate(1,numeric(n_epochs/24)) 


for (n in 1:n_epochs/24) {
  day_opinion[n,] <- sort(opinions_matrix[n*24,])
  mean_opinion[n] <- mean(opinions_matrix[n*24,]) 
  sd_opinion[n] <- sd(opinions_matrix[n*24,])
}

new_df <- data.frame(mean_o = mean_opinion, sd_o = sd_opinion, days <-1:length(mean_opinion))



ggplot(data=new_df, 
       aes(x=days, y=mean_o)) + 
  geom_line(color = 'orangered4', size = 1.2) +
  ylim(0,100) + 
  ylab('Average opinion of 100 runs') + 
  xlab('Time (days)') +
  geom_ribbon(aes(ymin=mean_o-sd_o, ymax=mean_o+sd_o), linetype=2, fill='orangered4', alpha=0.3) +
  ggtitle("Average opinion of 100 HUMAT populations\n over time (100 runs)") +
  theme_bw() +
  theme(plot.background = element_rect(fill = "#BFD5E3"), plot.title = element_text(hjust = 0.5), text = element_text(size =20))






