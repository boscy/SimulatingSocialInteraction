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


filename <- "HUMAT_COVID_visitors_measure_wave11_single_run.csv"
# filename_7 <-"HUMAT_Mental_health_test.csv"

dat <- fread(file = filename, skip = 36)  # skip 23 or 7 depending on which behaviorspace csv file chosen
# dat <- fread(file = filename_7, skip = 7)
dat <- dat[-1,]  # remove day 0



################# Transforming Netlogo data to a matrix of values  #################################

# Netlogo Vector to R list:
vals_list <- lapply(dat$V2 ,function(x){    # Note that V2 could be V11, depending on Behaviorspace output
  y <- gsub("\\[|\\]", "", x)
  unlist(as.numeric(unlist(strsplit(y, " "))), recursive = TRUE)
})


n_agents <- length(vals_list[[1]])  # stores the number of agents
n_epochs <- length(vals_list)  # stores the number of epochs (= number of rows in matrix) 


opinions_matrix <- matrix(unlist(vals_list), ncol = n_agents, byrow = TRUE) # R list to matrix



# Create a matrix of 0's. Each row represents an epoch, which will be a histogram of the data
hist_count_list <- replicate(101, numeric(n_epochs/24))  #creates a 101 by 100 matrix of 0's
colnames(hist_count_list) = c(0:100)  #change column names to digits of opinion value

# Fill the matrix with corresponding frequencies of opinion values for each epoch
for (i in 1:n_epochs/24) {
  counts_test_z <- count(opinions_matrix[i*24,])  # matrix to counts data for histogram
  # loop over
  for (j in 1:length(counts_test_z$x)) {
    opinion_value <- counts_test_z$x[j]
    frequency_of_value <- counts_test_z$freq[j]
    hist_count_list[i, opinion_value+1] <- frequency_of_value  # +1 since R counts from 1 (even though column name is 0)
  }
}



# sum(hist_count_list[1,])
# sum(hist_count_list[2,])
# hist_count_list[1,]
# hist_count_list[80,]

########################## Plotting the histogram of opinions over time #################
########################## NOTE: might take some time to fully load the graph ###########
# mycols <- colorRampPalette(c("white","blue", "red", "green")) #, "yellow"))
# hist3D(z=t(hist_count_list), 
#        bty = "g",
#        # col = jet.col(100, alpha = 0.5),
#        expand = 0.34,                        # height should be somewhat smaller in the ratio
#        col = mycols(256),
#        scale = T,
#        x = 0:100,
#        y= 1:length(hist_count_list[,1]),
#        theta = 20,
#        NAcol = "white",
#        phi = 30,
#        # space = 0.15,
#        # d = 3, 
#        colkey = T,
#        ticktype = "detailed", 
#        # rasterImage = TRUE, 
#        # axes = TRUE, 
#        lighting=TRUE,
#        # light="diffuse",
#        shade=0.5,
#        main = "Opinion of HUMATS over time",
#        xlab = "Opinion",
#        ylab = "Time (days)",
#        zlab = "Frequency"
# )


########## Plot average opinion over time ####################

day_opinion <- replicate(n_agents,numeric(n_epochs/24)) 
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
  geom_line(color = 'cyan4', size = 1.2) +
  ylim(0,100) + 
  ylab('Mean opinion of HUMATs') + 
  xlab('Time (days)') +
  geom_ribbon(aes(ymin=mean_o-sd_o, ymax=mean_o+sd_o), linetype=2, fill='cyan4', alpha=0.3) +
  ggtitle("Mean opinion of 1 HUMAT population over time") +
  theme_bw() +
  theme(plot.background = element_rect(fill = "#BFD5E3"), plot.title = element_text(hjust = 0.5), text = element_text(size =20))

  




     