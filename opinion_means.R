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


filename <- "HUMAT_COVID_visitors_measure_FINAL_mean_opinion.csv"
dat <- fread(file = filename, skip = 3, drop = 1)  # skip 23 or 7 depending on which behaviorspace csv file chosen

dat<-dat[2400]
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

bardat$final_opinions_mean <- as.numeric(mean_list)
bardat$final_opinions_sd <- as.numeric(sd_list)

# bardat <- as.data.frame(c(1:10))
# bardat$mean <- as.numeric(mean_list)
# bardat$sd <- as.numeric(sd_list)
# bardat$VM <- c(1:10)

ggplot(data = bardat, aes(x = VM, y= mean)) +
  geom_col(fill = rev(c("red", "#fd61d1","#b983ff","#619cff","#00b0f6","#00ba38","#6bb100","#a3a500","#edea49","#E58700"))) +
  geom_errorbar(aes(ymin=mean-sd, ymax=mean+sd), width=.2,position=position_dodge(.9)) +
  theme_bw() +
  ggtitle("Mean opinion of 100 HUMATs during 100 days") +
  xlab('Allowed visitors') +
  ylab('Mean Opinion') +
  coord_cartesian(ylim= c(25, 75))+
  scale_x_discrete(limits=c(1:10)) +
  scale_y_continuous(breaks = seq(20,75, by = 10))+
  scale_fill_manual(values=c("red", "#fd61d1","#b983ff","#619cff","#00b0f6","#00ba38","#6bb100","#a3a500","#edea49","#E58700"))+
  theme(plot.background = element_rect(fill = "#BFD5E3"), plot.title = element_text(hjust = 0.5), legend.key.size = unit(2.5, 'cm'),  text = element_text(size=15), legend.position = 'right')
# 




########## OPINIONS + CONTACTS ##########
library(scales)

bardat <- fread(file = 'bardat.csv')  # skip 23 or 7 depending on which behaviorspace csv file chosen
bardat$contacts_mean <- bardat$contacts_mean/100
bardat$contacts_sd <- bardat$contacts_sd/100


scaleFactor <-  max(bardat$final_opinions_mean) / max(bardat$contacts_mean) 

ggplot(bardat, aes(x=VM, width=0.4)) +
   geom_col(aes(y = contacts_mean*scaleFactor), fill = "darkgreen",position = position_nudge(x = .2)) +
  geom_errorbar(aes(ymin=(contacts_mean-contacts_sd)*scaleFactor, ymax=(contacts_mean+contacts_sd)*scaleFactor), width=.2,position = position_nudge(x = .2), color = "#00ba42") +
  geom_col(aes(y = final_opinions_mean), fill = "red", position = position_nudge(x = -.2)) +
  geom_errorbar(aes(ymin=final_opinions_mean-final_opinions_sd, ymax=final_opinions_mean+final_opinions_sd), width=.2,position = position_nudge(x = -.2)) +
  ggtitle("Number of contacts per day per HUMAT and mean opinion after 100 days") +
  xlab('Allowed visitors') +
  theme_bw()+
  theme(axis.title.y.left=element_text(color="red"),
             axis.text.y.left=element_text(color="red"),
             axis.title.y.right=element_text(color="darkgreen"),
             axis.text.y.right=element_text(color="darkgreen"),
        plot.background = element_rect(fill = "#BFD5E3"), plot.title = element_text(hjust = 0.5),  text = element_text(size=17)) +
  scale_x_discrete(limits=c(1:10)) +
  coord_cartesian(ylim= c(0, 100))+
  scale_y_continuous(breaks = seq(0,100, by = 10),name="Mean Opinion of the HUMATS after 100 days", sec.axis=sec_axis(~./scaleFactor, name="Number of contacts per day per HUMAT\n",breaks = seq(0,3, by = 0.5))) 




# 
# ggplot(bardat, aes(x=VM, width=0.4)) +
#   geom_col(aes(y = contacts_mean), fill = "darkgreen") +
#   geom_errorbar(aes(ymin=contacts_mean-contacts_sd, ymax=contacts_mean+contacts_sd), width=.2,position=position_dodge(.9), color = "#00ba42") +
#   geom_col(aes(y = final_opinions_mean* scaleFactor), fill = "red", position = position_nudge(x = .4)) +
#   geom_errorbar(aes(ymin=final_opinions_mean* scaleFactor-final_opinions_sd, ymax=final_opinions_mean*scaleFactor+final_opinions_sd), width=.2,position = position_nudge(x = .4)) +
#   ggtitle("Number of contacts and mean opinion after 100 days") +
#   xlab('Allowed visitors') +
#   theme_bw()+
#   theme(axis.title.y.left=element_text(color="darkgreen"),
#         axis.text.y.left=element_text(color="darkgreen"),
#         axis.title.y.right=element_text(color="red"),
#         axis.text.y.right=element_text(color="red"),
#         plot.background = element_rect(fill = "#BFD5E3"), plot.title = element_text(hjust = 0.5),  text = element_text(size=17)) +
  # scale_x_discrete(limits=c(1:10)) +
  # coord_cartesian(ylim= c(70, 240))+
  # scale_y_continuous(breaks = seq(70,240, by = 20), name="Number of contacts per HUMAT", sec.axis=sec_axis(~./scaleFactor, name="Mean Opinion on day 100",breaks = seq(20,80, by = 10)))
