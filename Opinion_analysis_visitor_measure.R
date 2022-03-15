require(ggplot2)
require(foreign)
require(psych)
require(lme4)
require(multcomp)
require(languageR)
require(dplyr)
install.packages("data.table")
install.packages("dplyr")
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
library(dplyr)

install.packages(
  "ggplot2",
  repos = c("http://rstudio.org/_packages",
            "http://cran.rstudio.com")
)
library(ggplot2)

################# Setting directory and loading data file #################################
rm(list = ls())



setwd("C:/Users/oscy1/Documents/AI_Master_2020/Master_Project/Models/") # go to correct directory


filename <- "HUMAT_COVID_visitors_measure_FINAL 100_runs_average_visitor_measure.csv"
# filename_7 <-"HUMAT_Mental_health_test.csv"

dat <- fread(file = filename, skip=1, drop = 1)  # skip 23 or 7 depending on which behaviorspace csv file chosen
# dat <- fread(file = filename_7, skip = 7)
# dat <- dat[-1,]  # remove day 0

# newdat = list()
# # dat1 <- select(dat, c(1:100))
# daydat <- dat[]
# 
# 
# for (i in 1:10) {
#   begin_index = 100*(i-1) + 1
#   end_index = i*100
#   newdat[i] <- select(dat, c(begin_index:end_index))
# }
# 
# newdat[1]  




# Run this part, while varying vm from 1 to 10, to create new_df1-10 below, in order to get the different data for the plots

vm = 10
begin_index = 100*(vm-1) + 1
end_index = vm*100

opinions_matrix <- data.matrix(select(dat, c(begin_index:end_index)))  # convert into matrix and remove day 0

n_epochs <- nrow(opinions_matrix)  # stores the number of epochs (= number of rows in matrix) 
n_runs <- ncol(opinions_matrix)  # stores number of runs


day_opinion <- replicate(n_runs,numeric(n_epochs/24)) 
mean_opinion <- replicate(1,numeric(n_epochs/24)) 
sd_opinion <- replicate(1,numeric(n_epochs/24)) 


for (n in 1:n_epochs/24) {
  day_opinion[n,] <- sort(opinions_matrix[n*24,])
  mean_opinion[n] <- mean(opinions_matrix[n*24,]) 
  sd_opinion[n] <- sd(opinions_matrix[n*24,])
}



# new_df1 <- data.frame(mean_o = mean_opinion, sd_o = sd_opinion, days <-1:length(mean_opinion))
# new_df2 <- data.frame(mean_o = mean_opinion, sd_o = sd_opinion, days <-1:length(mean_opinion))
# new_df3 <- data.frame(mean_o = mean_opinion, sd_o = sd_opinion, days <-1:length(mean_opinion))
# new_df4 <- data.frame(mean_o = mean_opinion, sd_o = sd_opinion, days <-1:length(mean_opinion))
# new_df5 <- data.frame(mean_o = mean_opinion, sd_o = sd_opinion, days <-1:length(mean_opinion))
# new_df6 <- data.frame(mean_o = mean_opinion, sd_o = sd_opinion, days <-1:length(mean_opinion))
# new_df7 <- data.frame(mean_o = mean_opinion, sd_o = sd_opinion, days <-1:length(mean_opinion))
# new_df8 <- data.frame(mean_o = mean_opinion, sd_o = sd_opinion, days <-1:length(mean_opinion))
# new_df9 <- data.frame(mean_o = mean_opinion, sd_o = sd_opinion, days <-1:length(mean_opinion))
# new_df10 <- data.frame(mean_o = mean_opinion, sd_o = sd_opinion, days <-1:length(mean_opinion))



ggplot(data=dat, aes(x=days, y=mean_o, color = 'white')) + 
  # 
  # geom_ribbon(data= new_df1, aes(ymin=mean_o-sd_o, ymax=mean_o+sd_o), color = 'NA', linetype=6, fill='#E58700', alpha=0.3)+
  # geom_ribbon(data= new_df2, aes(ymin=mean_o-sd_o, ymax=mean_o+sd_o),color = 'NA', linetype=2, fill='#edea49', alpha=0.3)+
  # geom_ribbon(data= new_df3, aes(ymin=mean_o-sd_o, ymax=mean_o+sd_o),color = 'NA', linetype=2, fill='#a3a500', alpha=0.3)+
  # geom_ribbon(data= new_df4, aes(ymin=mean_o-sd_o, ymax=mean_o+sd_o),color = 'NA', linetype=2, fill='#6bb100', alpha=0.3)+
  # geom_ribbon(data= new_df5, aes(ymin=mean_o-sd_o, ymax=mean_o+sd_o),color = 'NA', linetype=2, fill='#00ba38', alpha=0.3)+
  # geom_ribbon(data= new_df6, aes(ymin=mean_o-sd_o, ymax=mean_o+sd_o),color = 'NA', linetype=2, fill='#00b0f6', alpha=0.3)+
  # geom_ribbon(data= new_df7, aes(ymin=mean_o-sd_o, ymax=mean_o+sd_o),color = 'NA', linetype=2, fill='#619cff', alpha=0.3)+
  # geom_ribbon(data= new_df8, aes(ymin=mean_o-sd_o, ymax=mean_o+sd_o),color = 'NA', linetype=2, fill='#b983ff', alpha=0.3)+
  # geom_ribbon(data= new_df9, aes(ymin=mean_o-sd_o, ymax=mean_o+sd_o),color = 'NA', linetype=2, fill='#fd61d1', alpha=0.3)+
  # geom_ribbon(data= new_df10, aes(ymin=mean_o-sd_o, ymax=mean_o+sd_o), linetype=0, fill='red', alpha=0.3)+
  # # 
  geom_line(data= new_df1, color = '#E58700', size = 1.2) +
 
  geom_line(data= new_df2, color = '#edea49', size = 1.2) +
  
  geom_line(data= new_df3, color = '#a3a500', size = 1.2) +
  
  geom_line(data= new_df4, color = '#6bb100', size = 1.2) +
  
  geom_line(data= new_df5, color = '#00ba38', size = 1.2) +
  
  geom_line(data= new_df6, color = '#00b0f6', size = 1.2) +
  
  geom_line(data= new_df7, color = '#619cff', size = 1.2) +
  
  geom_line(data= new_df8, color = '#b983ff', size = 1.2) +
  
  geom_line(data= new_df9, color = '#fd61d1', size = 1.2) +
  
  geom_line(data= new_df10, color = 'red', size = 1.2) +
  
  
  ylim(20,80) + 
  ylab('Mean Opinion of 100 runs') + 
  xlab('Time (days)') +
  ggtitle("Mean opinion over time per allowed number of daily visitors") +
  theme_bw() +
  theme(plot.background = element_rect(fill = "#BFD5E3"), plot.title = element_text(hjust = 0.5), text = element_text(size=15), legend.position = 'right') +
  scale_color_manual("Allowed \ndaily visitors", limits=c('10', '9', '8', '7', '6', '5', '4', '3', '2', '1'), values = c("red", "#fd61d1","#b983ff","#619cff","#00b0f6","#00ba38","#6bb100","#a3a500","#edea49","#E58700")) +
  guides(colour = guide_legend(override.aes = list(pch = c(16, 21), alpha = 0.8, fill = c("red", "#fd61d1","#b983ff","#619cff","#00b0f6","#00ba38","#6bb100","#a3a500","#edea49","#E58700"))))

        
  
