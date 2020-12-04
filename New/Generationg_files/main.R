#-------------------------------------------------------------------------#
#                                                                         #
#                  Some examples to run phylo-website                     #
#                                                                         #
#-------------------------------------------------------------------------#



# Packages ----------------------------------------------------------------

library(stringr)

install.packages("stringr")



# OBSERVATIONS ------------------------------------------------------------

# The most important variable is "n" since it controls the unmber of taxa


# Parenthetical Simulation ------------------------------------------------

cat("\014") # 
rm(list=ls())  # 
# set.seed(42)

source("Fn_random_trees.R")
n <- 15 # n is the number of taxa to use
file_name <- "Parenthetical_file" # name of the output files
Sim_Parenthetical(n,file_name)


# Triplets Simulation -----------------------------------------------------

cat("\014") 
rm(list=ls())  
# set.seed(42)

# Obs: the triplet format is ===> 1 2 3 => ((1,2),3)
source("Fn_random_trees.R")

n <- 5
file_name <- "Triplets_file"

Sim_Triplets(n,file_name)


# asoteh ------------------------------------------------------------------











