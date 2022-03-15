require(ggplot2)
require(foreign)
require(psych)
require(lme4)
require(multcomp)
require(languageR)
require(dplyr)

# install.packages("ggplot2")
install.packages("foreign", "languageR", "psych", "lme4","multcomp", "data.table", "plot3D", "dplyr")


install.packages(
  "ggplot2",
  repos = c("http://rstudio.org/_packages",
            "http://cran.rstudio.com")
)
# Call the packages with the library command. These are only essential packages but you will probably need more later

# library(tidyverse)
library(foreign)
library(languageR)
library(psych)
library(lme4)
library(multcomp)
library(data.table)
library(plot3D)
library(plyr)
library(ggplot2)



################# Setting directory and loading data file #################################
rm(list = ls())



setwd("C:/Users/oscy1/Documents/AI_Master_2020/Master_Project/Models/") # go to correct directory


filename <- "HUMAT_COVID_visitors_measure_FINAL_behaviour_spr.csv"
# filename <- "HUMAT_COVID_visitors_measure_FINAL_single_run_contacts_wave6.csv"

dat <- fread(file = filename, drop=1, skip = 35) #, skip = 35, drop = 1)  # skip 23 or 7 depending on which behaviorspace csv file chosen
dat <- dat[2400]

mean_list <- list()
mean_list <- append(mean_list, mean(as.numeric(unlist(dat[, 1:100]))))
mean_list <- append(mean_list, mean(as.numeric(unlist(dat[, 101:200]))))
mean_list <- append(mean_list, mean(as.numeric(unlist(dat[, 201:300]))))
mean_list <- append(mean_list, mean(as.numeric(unlist(dat[, 301:400]))))
mean_list <- append(mean_list, mean(as.numeric(unlist(dat[, 401:500]))))
mean_list <- append(mean_list, mean(as.numeric(unlist(dat[, 501:600]))))
mean_list <- append(mean_list, mean(as.numeric(unlist(dat[, 601:700]))))
mean_list <- append(mean_list, mean(as.numeric(unlist(dat[, 701:800]))))
mean_list <- append(mean_list, mean(as.numeric(unlist(dat[, 801:900]))))
mean_list <- append(mean_list, mean(as.numeric(unlist(dat[, 901:1000]))))

#Find the standard deviations of the 100 runs
sd_list <- list()
sd_list <- append(sd_list, sd(as.numeric(unlist(dat[, 1:100]))))
sd_list <- append(sd_list, sd(as.numeric(unlist(dat[, 101:200]))))
sd_list <- append(sd_list, sd(as.numeric(unlist(dat[, 201:300]))))
sd_list <- append(sd_list, sd(as.numeric(unlist(dat[, 301:400]))))
sd_list <- append(sd_list, sd(as.numeric(unlist(dat[, 401:500]))))
sd_list <- append(sd_list, sd(as.numeric(unlist(dat[, 501:600]))))
sd_list <- append(sd_list, sd(as.numeric(unlist(dat[, 601:700]))))
sd_list <- append(sd_list, sd(as.numeric(unlist(dat[, 701:800]))))
sd_list <- append(sd_list, sd(as.numeric(unlist(dat[, 801:900]))))
sd_list <- append(sd_list, sd(as.numeric(unlist(dat[, 901:1000]))))

bardat <- as.data.frame(c(1:10))
bardat$mean <- as.numeric(mean_list)
bardat$sd <- as.numeric(sd_list)
bardat$VM <- c(1:10)

ggplot(data = bardat, aes(x = VM, y= mean)) +
  geom_col(fill = rev(c("red", "#fd61d1","#b983ff","#619cff","#00b0f6","#00ba38","#6bb100","#a3a500","#edea49","#E58700"))) +
  geom_errorbar(aes(ymin=mean-sd, ymax=mean+sd), width=.2,position=position_dodge(.9)) +
  theme_bw() +
  ggtitle("Percentage of HUMATs with 'no-contact' behaviour during 100 days (mean of 100 runs) ") +
  xlab('Allowed visitors') +
  ylab("Percentage with 'no-contact'") +
  coord_cartesian(ylim= c(10, 70))+
  scale_x_discrete(limits=c(1:10)) +
  scale_y_continuous(breaks = seq(0,100, by = 10))+
  scale_fill_manual(values=c("red", "#fd61d1","#b983ff","#619cff","#00b0f6","#00ba38","#6bb100","#a3a500","#edea49","#E58700"))+
  theme(plot.background = element_rect(fill = "#BFD5E3"), plot.title = element_text(hjust = 0.5), legend.key.size = unit(2.5, 'cm'),  text = element_text(size=15), legend.position = 'right')






