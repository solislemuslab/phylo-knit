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

# Parenthetical format ----------------------------------------------------

cat("\014") # 
rm(list=ls())  # 
# set.seed(42)

source("Fn_random_trees.R")


n <- 15 # n is the number of taxa to use
file_name <- "Parenthetical_file" # name of the output files

Sim_Parenthetical(n,file_name)

# Example of triplets -----------------------------------------------------


cat("\014") # borra consola 
rm(list=ls())  # Borra todo
# set.seed(421)

# Obs: the triplet format is ===> 1 2 3 => ((1,2),3)

# source("Fn phylo R.R") # old original library
source("Fn_random_trees.R")


n <- 5; taxa <- LETTERS[1:n]
n <- 5; taxa <- LETTERS[1:n]

# A more interesting one
# n <- 20; taxa <- gsub("\\s+", "", str_trim(paste("a",1:n)))

x <- random_tree(taxa,brach_lengths=F)
paste(x,collapse = "")
my_plot_tree(x,edge_wedth=2)
# x <- special_random_tree_n_taxa(n)
triplets <- brute_force_triplet_search(x)



vec_raw_triplets <- matrix("",nrow(triplets),3)

for(i in 1:nrow(triplets)) {
  taxa_row_i <- only_taxa_of_Newick_format(triplets[i,])
  if(triplets[i,2]=="(") taxa_row_i <- taxa_row_i[c(3,1,2)]
  vec_raw_triplets[i,] <- taxa_row_i
}
triplets
vec_raw_triplets


name_of_file <- "Triplets_file.txt"

write.table(vec_raw_triplets, file=name_of_file, append = F, sep = " ", dec = ".",
            row.names = F, col.names = F, quote = FALSE)


# Saving results ----------------------------------------------------------



cat("\014") # borra consola 
rm(list=ls())  # Borra todo
# set.seed(421)

# Obs: the triplet format is ===> 1 2 3 => ((1,2),3)

# source("Fn phylo R.R") # old original library
source("Fn_random_trees.R")


n <- 5; taxa <- LETTERS[1:n]
n <- 5; taxa <- LETTERS[1:n]



file_name <- "Triplets_file"
Sim_Triplets(n,file_name)

# Saving results ----------------------------------------------------------


write.table(text_invariance_Julia_programm, file="Test.txt", append = F, sep = "", dec = ".",
            row.names = F, col.names = F, quote = FALSE)


# asoteh ------------------------------------------------------------------











