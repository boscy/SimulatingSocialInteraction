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

wave <- 11
filename <- paste("HUMAT_COVID_visitors_measure_FINAL_single_run_contacts_wave", wave,".csv", sep= "")
# filename <- "HUMAT_COVID_visitors_measure_FINAL_single_run_contacts_wave6.csv"

dat <- fread(file = filename, skip = 61)  # skip 23 or 7 depending on which behaviorspace csv file chosen



################# Transforming Netlogo data to a matrix of values  #################################

# Netlogo Vector to R list:
vals_list <- lapply(dat$V2 ,function(x){    # Note that V2 could be V11, depending on Behaviorspace output
  y <- gsub("\\[|\\]", "", x)
  unlist(as.numeric(unlist(strsplit(y, " "))), recursive = TRUE)
})


n_agents <- length(vals_list[[1]])  # stores the number of agents
n_epochs <- length(vals_list)  # stores the number of epochs (= number of rows in matrix) 


opinions_matrix <- matrix(unlist(vals_list), ncol = n_agents, byrow = TRUE) # R list to matrix
max_value <- max(opinions_matrix)


# Create a matrix of 0's. Each row represents an epoch, which will be a histogram of the data
hist_count_list <- replicate(max_value+1, numeric(n_epochs/24))  #creates a 101 by 100 matrix of 0's
colnames(hist_count_list) = c(0:max_value)  #change column names to digits of opinion value
sum_contacts <- replicate(1, numeric(n_epochs/24))   #creates a matrix

# Fill the matrix with corresponding frequencies of opinion values for each epoch
for (i in 1:n_epochs/24) {
  counts_test_z <- plyr::count(opinions_matrix[i*24,])  # matrix to counts data for histogram
  sum_contacts[i,1] <- sum(opinions_matrix[i*24,])
  # loop over
  for (j in 1:length(counts_test_z$x)) {
    opinion_value <- counts_test_z$x[j]
    frequency_of_value <- counts_test_z$freq[j]
    hist_count_list[i, opinion_value+1] <- frequency_of_value  # +1 since R counts from 1 (even though column name is 0)
  }
}

# 
sum_frame <- as.data.frame(sum_contacts)
min_val <- min(sum_frame)
max_val <- max(sum_frame)

# Bar+Line plot
ggplot(data = sum_frame, aes(x =c(1:99), y=as.numeric(V1))) +
  geom_bar(stat="identity", fill = 'forestgreen') +
  geom_smooth(color = 'red', se = FALSE, fill = 'pink', size =2)+
  theme_bw() +
  ggtitle("Total number of active contacts per day") +
  xlab('Time (Days)') +
  ylab('Number of contacts') +
  coord_cartesian(ylim= c(200,500))+
  theme(plot.background = element_rect(fill = "#BFD5E3"), plot.title = element_text(hjust = 0.5), legend.key.size = unit(2.5, 'cm'),  text = element_text(size=15), legend.position = 'right')

# 
# library(tidyverse)
# # Tile plot:

# hist_count_list %>%
#   as.data.frame() %>%
#   rownames_to_column("Day") %>%
#   pivot_longer(-c(Day), names_to = "contacts", values_to = "frequency") %>%
#   ggplot(aes(x=as.numeric(contacts), y=as.numeric(Day), fill=frequency)) +
#   geom_tile() +
#   theme_bw() +
#   ggtitle("Distribution of number of active contacts per day") +
#   ylab('Time (Days)') +
#   xlab('Number of contacts') +
#   # scale_fill_viridis_c() +
#   # scale_fill_gradient(low = "blue4", high = "deepskyblue")+
#   scale_fill_gradientn(colours = c("gray","blue", "red", "green"))+
#   theme(plot.background = element_rect(fill = "#BFD5E3"), plot.title = element_text(hjust = 0.5), legend.key.size = unit(2.5, 'cm'),  text = element_text(size=15), legend.position = 'right')



########################## Plotting the histogram of opinions over time #################
# ########################## NOTE: might take some time to fully load the graph ###########
# mycols <- colorRampPalette(c("white","blue", "red", "green")) #, "yellow"))
# hist3D(z=t(hist_count_list),
#        bty = "g",
#        # col = jet.col(100, alpha = 0.5),
#        expand = 0.4,                        # height should be somewhat smaller in the ratio
#        col = mycols(256),
#        scale = T,
#        x = 0:max_value,
#        y= 1:length(hist_count_list[,1]),
#        theta = 20,
#        NAcol = "white",
#        phi = 40,
#        # space = 0.15,
#        # d = 3,
#        colkey = T,
#        ticktype = "detailed",
#        # rasterImage = TRUE,
#        # axes = TRUE,
#        lighting=TRUE,
#        # light="diffuse",
#        shade=0.5,
#        main = "Distribution of number of active contacts per day",
#        xlab = "Number of contacts",
#        ylab = "Time (days)",
#        zlab = "Frequency"
# )





