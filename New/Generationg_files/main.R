#-------------------------------------------------------------------------#
#                                                                         #
#                  Some examples to run phylo-website                     #
#                                                                         #
#-------------------------------------------------------------------------#



# Packages ----------------------------------------------------------------

library(stringr)

install.packages("stringr")
# Parenthetical format ----------------------------------------------------


cat("\014") # 
rm(list=ls())  # 

# source("Fn phylo R.R") # old original library
source("Fn_random_trees.R")

# A very simple example of a tree
# Obs: n is the number of taxa to use
n <- 5; taxa <- LETTERS[1:n]
x <- random_tree(taxa)


# A more interesting one
n <- 15; taxa <- gsub("\\s+", "", str_trim(paste("a",1:n)))
# x <- random_tree(taxa)
# review_Newick_format(x)
my_plot_tree(x,edge_wedth=2)
x <- random_tree(taxa,brach_lengths=F,discrete_lengths=T,interval_unif=c(1,10),
                        equidistance=T,total_bl=10,round_digits=2) 
my_plot_tree(x,edge_wedth=2)

x
paste0(x,collapse = "")

# Example of errase taxa --------------------------------------------------

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

# asoteh ------------------------------------------------------------------











