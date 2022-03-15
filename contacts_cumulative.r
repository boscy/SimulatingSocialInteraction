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


filename <- "HUMAT_COVID_visitors_measure_FINAL contacts_cumulative100.csv"
# filename <- "HUMAT_COVID_visitors_measure_FINAL_single_run_contacts_wave6.csv"

dat <- fread(file = filename,drop=1, skip = 2) #, skip = 35, drop = 1)  # skip 23 or 7 depending on which behaviorspace csv file chosen

# dat[,0:2]

# avg1_dat = mean(dat[,1:2], dat[,2])


avg_dat <- dat[,1] # add column such that df knows the size

#add average of 100 runs for all VM strengths
avg_dat$avg1 <- rowMeans(dat[,1:100], na.rm=TRUE)
avg_dat$avg2 <- rowMeans(dat[,101:200], na.rm=TRUE)
avg_dat$avg3 <- rowMeans(dat[,201:300], na.rm=TRUE)
avg_dat$avg4 <- rowMeans(dat[,301:400], na.rm=TRUE)
avg_dat$avg5 <- rowMeans(dat[,401:500], na.rm=TRUE)
avg_dat$avg6 <- rowMeans(dat[,501:600], na.rm=TRUE)
avg_dat$avg7 <- rowMeans(dat[,601:700], na.rm=TRUE)
avg_dat$avg8 <- rowMeans(dat[,701:800], na.rm=TRUE)
avg_dat$avg9 <- rowMeans(dat[,801:900], na.rm=TRUE)
avg_dat$avg10 <- rowMeans(dat[,901:1000], na.rm=TRUE)

av_dat <- avg_dat[,2:11] # remove initial column

#take the value at the end of every day instead of every hour
avg_dat_per_day <- av_dat[seq(1, nrow(av_dat), 24),]/100

# avg_dat_per_day[50]

#plot the results
days = 1:100
ggplot(data=avg_dat_per_day,(aes(x=days, y =avg1, color = 'red'))) +

  geom_line(aes(x=days, y =avg1), color = '#E58700', size = 1.2) +
  
  geom_line(aes(x=days, y =avg2), color = '#edea49', size = 1.2) +
  
  geom_line(aes(x=days, y =avg3), color = '#a3a500', size = 1.2) +
  
  geom_line(aes(x=days, y =avg4), color = '#6bb100', size = 1.2) +
  
  geom_line(aes(x=days, y =avg5), color = '#00ba38', size = 1.2) +
  
  geom_line(aes(x=days, y =avg6), color = '#00b0f6', size = 1.2) +
  
  geom_line(aes(x=days, y =avg7), color = '#619cff', size = 1.2) +
  
  geom_line(aes(x=days, y =avg8), color = '#b983ff', size = 1.2) +
  
  geom_line(aes(x=days, y =avg9), color = '#fd61d1', size = 1.2) +
  
  geom_line(aes(x=days, y =avg10), color = 'red', size = 1.2) +
  
  theme_bw() +
  ylab('Number of contacts') + 
  xlab('Time (days)') +
  ggtitle("Cumulative number of contacts over time for per HUMAT (average of 100 runs)") +
  theme(plot.background = element_rect(fill = "#BFD5E3"), plot.title = element_text(hjust = 0.5), text = element_text(size=18), legend.position = 'bottom') +
  scale_color_manual("Allowed \ndaily visitors", limits=c('10', '9', '8', '7', '6', '5', '4', '3', '2', '1'), values = c("red", "#fd61d1","#b983ff","#619cff","#00b0f6","#00ba38","#6bb100","#a3a500","#edea49","#E58700")) +
  guides(colour = guide_legend(override.aes = list(pch = c(16, 21), alpha = 0.8, fill = c("red", "#fd61d1","#b983ff","#619cff","#00b0f6","#00ba38","#6bb100","#a3a500","#edea49","#E58700"))))



mean(as.numeric(dat[2400, 1:100]))
per_humat_dat = dat/100

#Find the standard deviations of the 100 runs
sd_list <- list()
sd_list <- append(sd_list, sd(as.numeric(per_humat_dat[2400, 1:100])))
sd_list <- append(sd_list, sd(as.numeric(per_humat_dat[2400, 101:200])))
sd_list <- append(sd_list, sd(as.numeric(per_humat_dat[2400, 201:300])))
sd_list <- append(sd_list, sd(as.numeric(per_humat_dat[2400, 301:400])))
sd_list <- append(sd_list, sd(as.numeric(per_humat_dat[2400, 401:500])))
sd_list <- append(sd_list, sd(as.numeric(per_humat_dat[2400, 501:600])))
sd_list <- append(sd_list, sd(as.numeric(per_humat_dat[2400, 601:700])))
sd_list <- append(sd_list, sd(as.numeric(per_humat_dat[2400, 701:800])))
sd_list <- append(sd_list, sd(as.numeric(per_humat_dat[2400, 801:900])))
sd_list <- append(sd_list, sd(as.numeric(per_humat_dat[2400, 901:1000])))


finaldat <- av_dat[2400]/100
bardat <- as.data.frame(t(finaldat))
bardat$sd <- as.numeric(sd_list)
bardat$VM <- c(1:10)

names(bardat) <- c("contacts_mean", "contacts_sd", "VM")

ggplot(data = bardat, aes(x = VM, y= V1)) +
  geom_col(fill = rev(c("red", "#fd61d1","#b983ff","#619cff","#00b0f6","#00ba38","#6bb100","#a3a500","#edea49","#E58700"))) +
  geom_errorbar(aes(ymin=V1-sd, ymax=V1+sd), width=.2,position=position_dodge(.9)) +
  theme_bw() +
  ggtitle("Total number of active contacts per HUMAT over 100 days") +
  xlab('Allowed visitors') +
  ylab('Number of contacts') +
  coord_cartesian(ylim= c(160, 240))+
  scale_x_discrete(limits=c(1:10)) +
  scale_y_continuous(breaks = seq(160, 240, by = 10))+
  scale_fill_manual(values=c("red", "#fd61d1","#b983ff","#619cff","#00b0f6","#00ba38","#6bb100","#a3a500","#edea49","#E58700"))+
  theme(plot.background = element_rect(fill = "#BFD5E3"), plot.title = element_text(hjust = 0.5), legend.key.size = unit(2.5, 'cm'),  text = element_text(size=15), legend.position = 'right')
  # 





