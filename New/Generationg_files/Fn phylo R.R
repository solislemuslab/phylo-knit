#-------------------------------------------------------------------------#
#                                                                         #
#                           NOMBRE DE ARCHIVO                             #
#                                                                         #
#-------------------------------------------------------------------------#

# V1 FECHA
# V08 20feb20 lines 947
# V10 21feb20 lines 1037
# V13 24feb20 lines 1354
# V14 01mar20 lines 1886
# V15 02mar20 lines 1971
# V16 17Apr20 lines 2884 changing index z and n
# V17 04May20 lines 3608 

#-------------------------------------------------------------------------#
# General comments:

# 1. Bla bla bla
# 2. Bla bla bla
# 3. Bla bla bla
#
#-------------------------------------------------------------------------#


# USED PACKAGES -----------------------------------------------------------

library(ape)
# library(readtext)


# Functions ---------------------------------------------------------------


#' Number of all possible combinations of unrooted trees
#' See Huson(2010) Book Phylogenetic Networks
#'
#' @param n number of taxa
#'
#' @return the number of possible unrooted trees with n taxa
#' @export
#'
#' @examples
number_unrooted_trees <- function(n) {
  factorial(2*n-5)/2^(n-3)/factorial(n-3)
}


#' Number of all possible combinations of rooted trees
#' See Huson(2010) Book Phylogenetic Networks
#'
#' @param n number of taxa
#'
#' @return the number of possible rooted trees with n taxa
#' @export
#'
#' @examples
number_rooted_trees <- function(n) {
  factorial(2*n-3)/2^(n-2)/factorial(n-2)
}


#' All new possible trees that one gets by chanlling the taxa taxa_to_change
#' with all combinations of the values of taxa in possible_selections
#'
#' @param current_tree
#' @param taxa_to_change
#' @param possible_selections
#'
#' @return
#' @export
#'
#' @examples
add_bifurcation <- function(current_tree,taxa_to_change,possible_selections) {
  current_tree <- c(current_tree,rep("",4))
  position_of_change = which(current_tree==taxa_to_change)
  new_trees <- matrix(0,length(possible_selections),length(current_tree)+4)
  for(i in 1:length(possible_selections)) {
    new_trees[i,] <- c(current_tree[1:(position_of_change-1)],
                       "(",taxa_to_change,",",possible_selections[i],")",
                       current_tree[(position_of_change+1):length(current_tree)])
  }
  return(new_trees[,1:length(current_tree),drop=FALSE])
}

#' Print the Newick format in a compact way
#'
#' @param tree a string with the values of the Newick format
#'
#' @return do not return, but print in the console the Newick format 
#' @export
#'
#' @examples
print_tree <- function(tree) {
  if(is.null(nrow(tree))) {
    cat(paste(x,collapse=""),"\n")
  } else for(i in 1:nrow(tree)) {
    cat(paste0(tree[i,]),"\n")
  }
}



#' Sonting the Newick format
#'
#'Obs: New version with the possibility of ending semicolon
#'
#' @param x vector of characters with the Newick format; eg x=c("(","B",",","A",")")
#'
#' @return a vector of characters with the Newick format of x but sorted in alphabetic order
#' @export
#'
#' @examples
#' 
#' x <- c("(","B",",","A",")")
#' x <- c("(","(","A",",","B",")",",","C",")") # cama central en i=7
#' x <- c("(","(","C",",","B",")",",","A",")") # cama central en i=7
ordering_Newick <- function(x) {
  
  if(x[length(x)]==";") {
    x <- x[-length(x)]
    flag_with_semicolon = TRUE
  } else flag_with_semicolon = FALSE
  
  print_info <- F # only for testing
  if(print_info) cat("Call for ordering_Newick: x=", x,"\n")
  # Case of only one taxa
  if(length(x)==1) {
    if(print_info) cat("length 1: return x=", x,"\n")
    return(x)
  }
  # Case of two taxa
  if(length(x)==5) {
    aux <- sort(x[c(2,4)])
    x <- c("(",aux[1],",",aux[2],")")
    if(print_info) cat("length 5: return x=", x,"\n")
    return(x)
  }
  
  # We need to find the place of the comma that divides the tree
  aux <- (x==")")*1 - (x=="(")*1
  aux <- aux[c(-1,-length(aux))]
  central_comma_place <- min(which(cumsum(aux)==0)) + 2
  
  # Stuff of the left tree
  left_tree <- x[2:(central_comma_place-1)]
  left_taxa <- left_tree[left_tree!="(" & left_tree!="," & left_tree!=")"]
  min_left <- min(left_taxa)
  left_tree <- ordering_Newick(left_tree)
  
  # Stuff of the right tree
  right_tree <- x[(central_comma_place+1):(length(x)-1)]
  right_taxa <- right_tree[right_tree!="(" & right_tree!="," & right_tree!=")"]
  min_right <- min(right_taxa)
  right_tree <- ordering_Newick(right_tree)
  
  # If the right tree has a alphanumeric smaller taxa, the next if corrects it
  if(min_right < min_left) {
    x <- c("(",right_tree,",",left_tree,")")
  }else x <- c("(",left_tree,",",right_tree,")")
  
  if(flag_with_semicolon) x = c(x,";")
  return(x)
}


#' Multiple sorting of Newick format
#'
#' @param X a matrix wich rows are in Newick format
#'
#' @return the same matrix X but with each row sorted using the ordering_Newick function
#' @export
#'
#' @examples
ordering_Newick_matrix <- function(X) {
  # To keep track of the sorting we print the progress bar
  vec_para_for <- 1:nrow(X)
  pb <- txtProgressBar(min = 1, max = length(vec_para_for), style = 3, width = 60)
  
  for(i in vec_para_for){
    X[i,] <- ordering_Newick(X[i,])
    setTxtProgressBar(pb, i)
  }
  close(pb)
  print("\n")
  return(X)
}

#' Adding one taxa to each of the curren trees
#'
#' @param list_phylo 
#'
#' @return
#' @export
#'
#' @examples
add_1_node <- function(list_phylo) {
  
  n <- list_phylo$n
  taxa <- list_phylo$taxa
  possible_trees <- list_phylo$possible_trees
  used__taxa <- list_phylo$used__taxa
  unused_tax <- list_phylo$unused_tax
  
  final_tree <- matrix("",nrow(possible_trees)*ncol(used__taxa)*ncol(unused_tax),
                       ncol(possible_trees)+4)
  index_aux <- 1
  # for each tree (row of possible_trees) and each taxa not used for this tree in
  # each row in possible_trees, we will add to possible_trees
  for(i_tree in 1:nrow(possible_trees)) {
    for(i_taxa in 1:length(used__taxa[i_tree,])){
      current_tree <- possible_trees[i_tree,]
      taxa_to_change <- used__taxa[i_tree,i_taxa]
      possible_selections <- unused_tax[i_tree,,drop=FALSE]
      new_trees <- add_bifurcation(current_tree,taxa_to_change,possible_selections)
      final_tree[index_aux:(index_aux + nrow(new_trees) -1),] <- new_trees
      index_aux <- index_aux + nrow(new_trees)
    }
  }
  
  # final_tree
  index_aux
  # Sorting the Newick formats
  for(i in 1:nrow(final_tree)) {
    final_tree[i,] <- ordering_Newick(final_tree[i,])
  }
  
  # Errasing repeated rows
  final_tree <- unique(final_tree,MARGIN = 1)
  
  # Finding taxa used and unused for each tree
  final_used__taxa <- matrix("",nrow(final_tree),ncol(used__taxa)+1)
  if(ncol(unused_tax)>1)  final_unused_tax <- matrix("",nrow(final_tree),ncol(unused_tax)-1)
  for(i in 1:nrow(final_tree)) {
    tree <- final_tree[i,]
    taxa_of_tree <- sort(tree[tree!="(" & tree!="," & tree!=")"])
    final_used__taxa[i,] <- taxa_of_tree
    if(ncol(unused_tax)>1) final_unused_tax[i,] <- setdiff(taxa,taxa_of_tree)
  }
  
  list_phylo$possible_trees <- final_tree
  list_phylo$used__taxa <- final_used__taxa
  if(ncol(unused_tax)>1) {
    list_phylo$unused_tax <- final_unused_tax
  } else list_phylo$unused_tax <- "All taxa is used"
  
  return(list_phylo)
}



add_all_nodes <- function(list_phylo) {
  if(ncol(list_phylo$unused_tax)==1) {
    list_phylo <- add_1_node(list_phylo)
    return(list_phylo)
  }
  
  vec_para_for <- 1:ncol(list_phylo$unused_tax)
  pb <- txtProgressBar(min = 1, max = length(vec_para_for), style = 3, width = 60)
  
  for(i in vec_para_for){
    list_phylo <- add_1_node(list_phylo)
    setTxtProgressBar(pb, i)
  }
  
  close(pb)
  print("\n")
  return(list_phylo)
}


#' Initialize e list with the variables for the taxa
#' 
#' @param taxa vector of strings that each entry is the name of a taxa
#'
#' @return a list list_phylo with: n = number of taxa, taxa=names of taxa, possible_trees= all
#' possible trees with these taxa, 
#' @export
#'
#' @examples
initialize_list_phylo <- function(taxa) {
  # n is the number of taxa
  n <- length(taxa)
  # couples is a two-column matrix with all possible pars of taxa
  couples <- t(combn(taxa,2))
  # possible_trees matris that collects the values of all posible trees
  # We start this matrix with all possible coubles of taxa values
  possible_trees  <- matrix(c(rep("(",nrow(couples)),couples[,1], 
                              rep(",",nrow(couples)),couples[,2],
                              rep(")",nrow(couples))),nrow = nrow(couples))
  # used__taxa matrix that shows that its i row shows the already taken taxa for i row of possible_trees
  used__taxa <- couples
  
  # unused_tax matrix that shows that its i row shows the not taken taxa for i row of possible_trees
  unused_tax <- t(apply(function(x){setdiff(taxa,x)},X =  used__taxa,MARGIN = 1))
  if(nrow(unused_tax)==1) unused_tax <- t(unused_tax)
  
  list_phylo <- list(n=n,
                     taxa=taxa,
                     possible_trees=possible_trees,
                     used__taxa=used__taxa,
                     unused_tax=unused_tax)
  
  list_phylo <- add_all_nodes(list_phylo) 
  return(list_phylo)
}



#' Review of Newick farmat
#'
#' @param x Newick format vector; eg x <- strsplit("(A,(C,B))","")[[1]]
#'
#' @return bolean of the review of the vector and prints the errors of Newick format
#' @export
#'
#' @examples
#' x <- strsplit("(A,(C,B))","")[[1]]
#' x <- c("(","(","A",",","C",")",",","(","C",",","D",")",")") # Error: repeated taxa
#' x <- c("(","(","A",",","B",")",")",",","(","C",",","D",")",")") # Error: unequal parenthesis
review_Newick_format <- function(x) {
  
  # In case of a string we expand it to look at it
  if(length(x)==1) x <- expand_Newick_format(x)
  ok_taxa <- T
  
  # Ending with semicolon
  if(x[length(x)]!=";") {
    print("Error in Newick format: the string should end in semicolon.")
    ok_taxa <- F
  }
  # not repeated taxa
  only_taxa <- only_taxa_of_Newick_format(x)
  if(length(only_taxa)!=length(unique(only_taxa))) {
    print("Error in taxa: repeated taxa")
    ok_taxa <- F
  }
  
  # Equal number of "(" and ")"
  error_non_equal_left_right <- sum((x=="(")*1 - (x==")")*1)
  if(error_non_equal_left_right != 0) {
    print("Error in taxa: unequal number of left and right parenthesis")
    ok_taxa <- F
  }
  
  # Each parenthesis close
  aux <- cumsum((x=="(")*1 - (x==")")*1)
  aux
  all_closes <- all(aux[-c(length(aux)-3,length(aux)-2,length(aux)-1,length(aux))]>0)
  all_closes
  if(!all_closes) {
    print("Error in taxa: not all parenthesis close")
    ok_taxa <- F
  }
  
  # places of taxa
  (idx_taxa <- which(x %in% only_taxa))
  
  # Each taxa should be followed by a colon
  idx_colon <- idx_taxa + 1
  if(!all(x[idx_colon]==":"))  {
    print("Error in Newick format: not all taxa is followed by a colon.")
    ok_taxa <- F
  }
  
  # Each colon should be followed by a numeric value
  idx_bl <- idx_taxa + 2
  if(!all(suppressWarnings(!is.na(as.numeric(x[idx_bl]))))) {
    print("Error in Newick format: not all colon is followed by a numeric value.")
    ok_taxa <- F
  }
  
  # places of taxa
  (idx_right_parenthesis <- which(x == ")"))
  
  # Each left parenthesis is followed by a colon
  idx_colon_after_rp <- idx_right_parenthesis+1
  if(!all(x[idx_colon_after_rp]==":"))  {
    print("Error in Newick format: not al left parenthesis is followed by a colon.")
    ok_taxa <- F
  }
  
  # Each colon after a right parenthesis is followed by a numeric value
  idx_bl_after_rp <- idx_right_parenthesis+2
  if(!all(suppressWarnings(!is.na(as.numeric(x[idx_bl_after_rp]))))) {
    print("Error in Newick format: not all colon after a right parenthesis is followed by a numeric value.")
    ok_taxa <- F
  }
  return(ok_taxa)
}


#' Simple plot of a tree
#'
#' @param x tree in the Newick format as vector
#' @param edge_wedth parameter of edge wedth for the printing
#'
#' @return
#' @export
#'
#' @examples
my_plot_tree <- function(x,edge_wedth=2) {
  if(length(x)>1) x <- paste0(x,collapse = "")
  if(substr(x,nchar(x),nchar(x))!=";") {
    cat("my_plot_tree: this tree does not ends with ';'.\n")
    return(-1)
  }
  # text.string <- paste(c(x,";"),collapse = "")
  text.string <- x
  vert.tree<-read.tree(text=text.string)
  plot(vert.tree,no.margin=TRUE,edge.width=edge_wedth,direction = "downwards",srt = 90)
}


#' Errase a taxa from a tree
#'
#' @param x tree in newick format
#' @param taxa_to_eliminate name of the taxa to eliminate
#'
#' @return the tree without that taxa
#' @export
#'
#' @examples
#' x <- c("(","(","(","A",",","B",")",",","(","C",",","D",")",")",",","E",")")
#' x <- strsplit("(A,(C,B))","")[[1]] # ok for: B
#' x <- strsplit("(((A,B),(D,(C,X))),(M,L))","")[[1]]
#' x <- c("(","(","A",",","B",")",",","(","C",",","D",")",")") # ok
#' x <- strsplit("(((A,B),((C,X),D)),(M,L))","")[[1]]
#' x <- "E"
#' x <- "M"
#' x <- "L"
#' x <- "B"
#' x <- "C"
#' x <- "D"
#' x <- "A"
#' x <- "X"
errase_taxa <- function(x,taxa_to_eliminate) {
  # cat("-------------------------------Normal x that enters= ",x,"\n")
  
  if(length(x)==1) x <- expand_Newick_format(x)
  taxa_place <- which(x==taxa_to_eliminate)
  taxa_place
  # cat("taxa_place=",taxa_place,"\n")
  
  if(length(taxa_place)==0) {
    print("You try to eliminate a not existing taxa")
    return(x)
  }
  if(taxa_place==length(x)-1) {
    # cat("x for ordering Newick= ",x[2:(length(x)-3)],"\n")
    x <- ordering_Newick(x[2:(length(x)-3)])
    return(x)
  }
  if(taxa_place==2) {
    # cat(" ----------- Entering if(taxa_place==2)  of fn. errase_taxa \n")
    # x <- ordering_Newick(x[4:(length(x)-1)]) # BEFORE WITH -1
    x <- c(ordering_Newick(x[4:(length(x)-2)]),";")
    return(x)
  }
  # Errase with comma at the right of taxa to eliminate
  if(x[taxa_place+1]==",") {
    # We need to find the place of the comma that divides the tree
    sub_tree <- x[(taxa_place+2):length(x)]
    aux <- cumsum((sub_tree==")")*1 - (sub_tree=="(")*1)
    i_second_parenthesis <- taxa_place + which(aux==0)[1]+2
    x <- x[c(1:(taxa_place-2),
             (taxa_place+2):(i_second_parenthesis-1),
             min(i_second_parenthesis+1,length(x)):length(x))]
  } else if(x[taxa_place-1]==",") { 
    # Errase with comma at the left of taxa to eliminate
    # review_Newick_format(x)
    matrix(c(1:length(x),x),2,byrow = T)
    if(x[taxa_place-2]!=")") {
      x <- x[c(1:(taxa_place-4),taxa_place-2,(taxa_place+2):length(x))]
    } else {
      i2_subtree <- taxa_place -2
      flip_sub_tree <- x[(taxa_place-2):1]
      flip_sub_tree
      aux <- rev(cumsum((flip_sub_tree=="(")*1 - (flip_sub_tree==")")*1))-1
      i_parenthesis <- which(aux==0)
      i1_subtree <- max(i_parenthesis)+1
      sub_tree <- x[i1_subtree:i2_subtree]
      x <- x[c(1:(i1_subtree-2),i1_subtree:i2_subtree,(taxa_place+2):length(x))]
    }
  }
  # x <- ordering_Newick(x) # NEW COMMENTED VERSION
  return(x)
}

#' Multiple elimination of taxa 
#' see function errase_taxa
#'
#' @param x vector in Newick format
#' @param vec_taxa_to_eliminate vector of taxa to elininate
#'
#' @return the Nf without the taxa
#' @export
#'
#' @examples
#' x <- strsplit("(((A,B),((C,X),D)),(M,L))","")[[1]]; n <- 7 
#' vec_taxa_to_eliminate <- c("C","X","L")
#' errase_k_taxa(x,vec_taxa_to_eliminate)
errase_k_taxa <- function(x,vec_taxa_to_eliminate) {
  x_reduced = x
  for(taxa_to_eliminate in vec_taxa_to_eliminate) {
    # cat("taxa_to_eliminate=",taxa_to_eliminate,"\n")
    # cat(x_reduced,"\n")
    x_reduced <- errase_taxa(x_reduced,taxa_to_eliminate)
  }
  return(x_reduced)
}


# x_reduced <- c("(","D",",","(","B",",","(","C",",","E",")",")",")",";")
# taxa_to_eliminate = "D"
# x_reduced <- errase_taxa(x_reduced,taxa_to_eliminate)



#' Generate the 15x12 matrix for 4-taxa species 3-taxa gene trees
#'
#' @param st_taxa vector of species taxa
#' @param gt_taxa vector of gene taxa
#'
#' @return a LaTeX table with all the possible triplet trees and they probabilities 
#' of a by considering four taxa as species tree (this funcion is easy to understand
#' by runing the example)
#' @export
#'
#' @examples
#' st_n <- 4
#' st_taxa <- LETTERS[1:st_n]
#' gt_n <- 3
#' gt_taxa <- LETTERS[1:gt_n]
#' mat_prob <- generate_table_st4gt3(st_taxa,gt_taxa) 
generate_table_st4gt3 <- function(st_taxa,gt_taxa) {
  require(xtable)
  if(length(st_taxa)!=4 | length(gt_taxa)!=3) {
    print("generate_table_st4gt3: error in the lengths of taxa")
    return(-1)
  }
  
  st_list_phylo <- initialize_list_phylo(st_taxa) 
  gt_list_phylo <- initialize_list_phylo(gt_taxa) 
  
  gt_names <- c("((A,C),B)","(A,(B,C))","((A,B),C)",
                "((B,D),C)","(B,(C,D))","((B,C),D)",
                "((A,D),B)","(A,(B,D))","((A,B),D)",
                "((A,D),C)","(A,(C,D))","((A,C),D)")
  
  st_col_name <- nrow(st_list_phylo$possible_trees)
  for(i in 1:nrow(st_list_phylo$possible_trees)) {
    st_col_name[i] <- paste(st_list_phylo$possible_trees[i,],collapse = "")
  }
  
  mat_prob <- matrix("",nrow(st_list_phylo$possible_trees),length(gt_names))
  
  colnames(mat_prob) <- gt_names
  rownames(mat_prob) <- st_col_name
  
  mat_prob
  i <- 2
  j <- 1
  
  taxa <- LETTERS[1:4]
  
  for(j in 1:ncol(mat_prob)) {
    triplet <- ordering_Newick(strsplit(colnames(mat_prob)[j],split = "")[[1]])
    triplet
    taxa_to_eliminate <- (c("D","D","D","A","A","A","C","C","C","B","B","B"))[j]
    cat(" -- j=",j," gene triplet=",paste(triplet,collapse = ""),
        " taxa_to_eliminate=",taxa_to_eliminate,"\n")
    for(i in 1:nrow(mat_prob)) {
      quartet <- ordering_Newick(strsplit(rownames(mat_prob)[i],split = "")[[1]])
      quartet
      quartet_subset <- errase_taxa(quartet,taxa_to_eliminate)
      quartet_subset
      
      # Now we find the adequate exponent depending on the eliminated taxa and topology
      x <- quartet
      only_taxa <- x[x!="(" & x!="," & x!=")"]
      only_topo <- paste(x[x=="(" | x=="," | x==")"],collapse = "") 
      # case of symmetric tree
      if(only_topo=="((,),(,))") {
        if(taxa_to_eliminate %in% only_taxa[c(1,2)]) expo_ij <- "-t_2" else expo_ij <- "-t_1"
      }
      
      # Case 1 of canterpilla
      if(only_topo == "(((,),),)"){
        if(taxa_to_eliminate %in% only_taxa[c(1,2)]) expo_ij <- "-t_2" 
        if(taxa_to_eliminate %in% only_taxa[3]) expo_ij <- "-(t_1+t_2)" 
        if(taxa_to_eliminate %in% only_taxa[4]) expo_ij <- "-t_1" 
      }
      
      # Case 2 of canterpilla
      if(only_topo =="((,(,)),)"){
        if(taxa_to_eliminate %in% only_taxa[c(2,3)]) expo_ij <- "-t_2" 
        if(taxa_to_eliminate %in% only_taxa[1]) expo_ij <- "-(t_1+t_2)" 
        if(taxa_to_eliminate %in% only_taxa[4]) expo_ij <- "-t_1" 
      }
      
      # Case 3 of canterpilla
      if(only_topo =="(,((,),))"){
        if(taxa_to_eliminate %in% only_taxa[c(2,3)]) expo_ij <- "-t_2" 
        if(taxa_to_eliminate %in% only_taxa[1]) expo_ij <- "-t_1" 
        if(taxa_to_eliminate %in% only_taxa[4]) expo_ij <- "-(t_1+t_2)" 
      }
      
      # expo_ij <- "-t_ij"
      if(all(quartet_subset == triplet)) {
        # mat_prob[i,j] <- paste(c("1-dfrac{2}{3}e^{",expo_ij,"}"),collapse="")
        mat_prob[i,j] <- paste(c("1-2e^{",expo_ij,"}/3"),collapse="")
      } else {
        # mat_prob[i,j] <- paste(c("dfrac{1}{3}e^{",expo_ij,"}"),collapse="")
        mat_prob[i,j] <- paste(c("e^{",expo_ij,"}/3"),collapse="")
      }
      cat("i=",i," species quartet=",paste(quartet,collapse = ""),
          " quartet_subset=",paste(quartet_subset,collapse = ""),
          " prob=",mat_prob[i,j],all(quartet_subset == triplet),"\n")
    }
  }
  print(xtable(mat_prob,file="Table s4 g3.tex"))
  return(mat_prob)
}

#' Number of all triplet-trees with n taxa
#' See Hudson(2010) Phylogenetic Networks book
#'
#' @param n integer of number of taxa
#'
#' @return number of possible triplet-trees for n taxa
#' @export
#'
#' @examples
number_triplets_n_taxa <- function(n){
  n^3/2 -3*n^2/2 + n
}


#' Generate all triplets of a taxa
#'
#' @param taxa 
#'
#' @return a matrix with all possible triplets. Each row is a triplet.
#' @export
#'
#' @examples
#' n <- 10
#' taxa <- LETTERS[1:n]
#' 
#' n <- 60;taxa <- as.character(1:n)
#' 
#' all_triplets <- generate_all_triplets(taxa)
#' all_triplets_unique <- unique(all_triplets,MARGIN = 1)
#' nrow(all_triplets)==nrow(all_triplets_unique)
#' all(all_triplets==all_triplets_unique)
generate_all_triplets <- function(taxa) {
  
  all_triplets <- matrix("",number_triplets_n_taxa(n),3)
  
  index <- 1
  for(i1 in 1:(n-1)) for(i2 in (i1+1):n) {
    # cat("x1=",taxa[i1]," x2=",taxa[i2],"\n")
    all_triplets[index:(index+n-3),] <- matrix(c(rep(taxa[i1],n-2),
                                                 rep(taxa[i2],n-2),
                                                 taxa[-c(i1,i2)]),ncol = 3,nrow = n-2)
    index <- index+n-2 #nrow(aca)
  }
  all_triplets <- cbind(rep("(",number_triplets_n_taxa(n)),
                        rep("(",number_triplets_n_taxa(n)),
                        all_triplets[,1],
                        rep(",",number_triplets_n_taxa(n)),
                        all_triplets[,2],
                        rep(")",number_triplets_n_taxa(n)),
                        rep(",",number_triplets_n_taxa(n)),
                        all_triplets[,3],
                        rep(")",number_triplets_n_taxa(n)))
  
  all_triplets <- ordering_Newick_matrix(all_triplets)
  return(all_triplets)
}



#' Random tree given a set of taxa
#'
#' @param taxa vector with the names of the taxa
#' @param brach_lengths if the branches lengths appear
#' @param discrete_lengths if the branches are discrete uniform distributed
#' @param interval_unif interval to where the branches are distributed
#' @param equidistance if the tree is ultrametric
#' @param total_bl tatal branch length in the case of ultrametric
#' @param round_digits number of digits for the branches
#'
#' @return a random tree in Newick format with this taxa. The current distribution is uniform
#' @export
#'
#' @examples
#' n <- 10; taxa <- LETTERS[1:n]
#' random_tree(taxa)
#' n <- 300; taxa <- as.character(1:n)
#' library(stringr) # to use the function str_trim
#' n <- 30; taxa <- gsub("\\s+", "", str_trim(paste("a",1:n)))
#' x <- random_tree(taxa)
#' review_Newick_format(x)
#' my_plot_tree(x,edge_wedth=2)
random_tree <- function(taxa,brach_lengths=T,discrete_lengths=T,interval_unif=c(1,10),
                        equidistance=T,total_bl=10,round_digits=2) {
  # First we made it without branch lengths
  (x <- c("(",taxa[1],",",taxa[2],")"))
  i <- 3
  if(length(taxa)>2) for(i in 3:length(taxa)) {
    # cat("x=",x,"\n")
    (taxa_to_change <- sample(only_taxa_of_Newick_format(x),1))
    # cat("taxa_to_change=",taxa_to_change," taxa[i]=",taxa[i],"\n")
    (position_of_change = which(x==taxa_to_change))
    (x <- c(x[1:(position_of_change-1)],
            "(",taxa_to_change,",",taxa[i],")",
            x[(position_of_change+1):length(x)]))
  }
  (x <- ordering_Newick(x))
  (x <- c(x,";"))
  
  if(brach_lengths) {
    (idx_right_parenthesis <- which(x==")"))
    (taxa <- only_taxa_of_Newick_format(x))
    (idx_taxa <- which(x %in% taxa))
    (idx_taxa_and_right_p <- rev(sort(c(idx_taxa,idx_right_parenthesis))))
    paste(x,collapse = "")
    for(i in idx_taxa_and_right_p) {
      if(discrete_lengths) bl <- sample(interval_unif[1]:interval_unif[2],1,replace = T)
      if(!discrete_lengths) bl <- round(runif(1,interval_unif[1],interval_unif[2]),digits = round_digits)
      x <- c(x[1:i],
             ":",bl,
             x[(i+1):length(x)])
    }
    x <- paste0(x,collapse = "")
    if(equidistance) {
      (x <- expand_Newick_format(x))
      x <- balance_a_tree(x,total_bl) 
      x <- paste0(x,collapse = "")
    }
  } # THIS BRACKET WAS BEFORE THE IF OF EQUIDISTANCE (IE THE THAT IF WAS OUTSIDE)
  return(x)
}



#' Random tree give the number of taxa to have
#'
#' @param n number of taxa
#'
#' @return a random tree with the first n letters of the alphabet as taxa names
#' @export
#'
#' @examples
special_random_tree_n_taxa <- function(n) {
  if(n<27) taxa <- LETTERS[1:n] else taxa <- as.character(1:n)
  return(random_tree(taxa))
}


#' All the possible triplets by using a two-for loop
#'
#' @param x a Newick format tree
#'
#' @return matrix such that each row corresponds to a triplet of x
#' @export
#'
#' @examples
#' n <- 7
#' x <- special_random_tree_n_taxa(n)
#' brute_force_triplet_search(x)
brute_force_triplet_search <- function(x) {
  # taxa <- x[x!="(" & x!="," & x!=")"]
  taxa <- only_taxa_of_Newick_format(x)
  n <- length(taxa)
  triplets <- matrix("",choose(n,3),9)
  triplets <- matrix("",choose(n,3),10)
  index_to_add <- 1
  for(i1 in 1:(length(taxa)-2)) for(i2 in (i1+1):(length(taxa)-1)) for(i3 in (i2+1):length(taxa)) {
    vec_taxa_to_eliminate <- taxa[-c(i1,i2,i3)]
    
    # cat("vec_taxa_to_eliminate=",vec_taxa_to_eliminate,"\n")
    # OBS: currently there is an error on the triples since,
    # some triplets lenght are of lenght 11 an other of size 9.
    # This depends of if is in the format ((A,B),C) or (A,(B,C))
    # THe first is oyf size
    
    triple_bad_format <- errase_k_taxa(x,vec_taxa_to_eliminate)
    
    # cat("triple_bad_format=",triple_bad_format,"\n")
    # OBS: to remedy the problem of different lengths we do the next 
    # cheap trick with an if statement
    if(length(triple_bad_format)==11) {
      # cat("length(triple_bad_format) == 11\n")
      triplets[index_to_add,] <- triple_bad_format[-1] 
    } else {
      # cat("length(triple_bad_format)=",triple_bad_format,"\n")
      # cat("length(triplets[index_to_add,])=",length(triplets[index_to_add,]),"\n")
      triplets[index_to_add,] <- triple_bad_format
    }
    index_to_add <- index_to_add+1
  }
  
  
  return(triplets)
}


#' Given a number of taxa n, it returns a vector of strings with name for the taxa
#'
#' @param n number of taxa
#'
#' @return a vector with taxa name as the first letters of the alphabet or if n is 
#' bigger than 27 a vector with entries like "Li" for i in 1:n
#' @export
#'
#' @examples
named_taxa_given_n <- function(n) {
  if(n<27) taxa <- LETTERS[1:n] else taxa <- paste0("L",1:n)
  return(taxa)
}


#' Given a vector or matrix of taxa, it returns the collapsed version
#' 
#' 
#' @param x vector or matrix in Newick format; in the case of a matrix each 
#' row has a Nowick format
#'
#' @return
#' @export
#'
#' @examples
#' n <- 20
#' taxa <- named_taxa_given_n(n)
#' all_triplets <- generate_all_triplets(taxa)
#' x <- special_random_tree_n_taxa(n)
#' collaps_Newick_format(x)
#' collaps_Newick_format(all_triplets)
collaps_Newick_format <- function(x) {
  if(is.null(dim(x))) return(paste(x,collapse = ""))
  all_triplets_collaps <- rep("",nrow(x))
  for(i in 1:nrow(x)) {
    all_triplets_collaps[i] <- paste(x[i,],collapse = "")
  }
  return(all_triplets_collaps)
}




#' Return a vector with the counts
#'
#' @param x vector that represents a tree in Newick format
#' @param all_triplets_collapsed vector of all triplets 
#'
#' @return
#' @export
#'
#' @examples
triplets_counts_1_tree <- function(x,all_triplets_collapsed) {
  x_triplets <- brute_force_triplet_search(x)
  x_triplets_collapsed <- collaps_Newick_format(x_triplets)
  # index_triplets are the indexes of each of the x triplets w.r.t. all triplets 
  index_triplets <- match(x_triplets_collapsed, all_triplets_collapsed)
  counts_of_triplets_of_x <- rep(0,length(all_triplets_collapsed))
  counts_of_triplets_of_x[index_triplets] <- 1
  return(counts_of_triplets_of_x)
}


#' For a given gene forest returns its counts of triplets
#'
#' @param X matrix which rows are trees in Newick format (without branch lengths)
#' @param all_triplets_collapsed a vector with all possible combinations of triplets for the current taxa
#'
#' @return
#' @export
#'
#' @examples
triplets_counts_k_tree <- function(X,all_triplets_collapsed) {
  counts_of_triplets_of_X <- rep(0,length(all_triplets_collapsed))
  for(i in 1:nrow(X)) {
    # X_i_non_empty <- X[i,X[i,]!=""]
    counts_of_triplets_of_X <- counts_of_triplets_of_X + triplets_counts_1_tree(X[i,],all_triplets_collapsed)
  }
  return(counts_of_triplets_of_X)
}

#' Length of the Newick format for n taxa (without branch lengths)
#'
#' @param n number of taxa
#'
#' @return the length of the Newick format of a tree with n as is number of taxa
#' @export
#'
#' @examples
length_Newick_format_n_taxa <- function(n){ 5 + (n-2)*4}


#' Random fores give the number of taxa to have
#'
#' @param n number of taxa of each tree
#' @param k number of trees
#'
#' @return a matrix X with each row a random tree with n taxa
#' @export
#'
#' @examples
special_random_forest_n_taxa <- function(n,k) {
  X <- matrix("",k,length_Newick_format_n_taxa(n))
  for(i in 1:k) {
    x <- special_random_tree_n_taxa(n)
    X[i,] <- x
  }
  return(X)
}


#' Allowed non taxa characters
#'
#' @return all the non taxa characters that are allowed to be in a 
#' Newick format vector
#' @export
#'
#' @examples
non_taxa_characters <- function() {
  return(c("(",",",")",":",";"," "))
}

#' A code for the not taxa characters
#'
#' @return a vector with the coding of the non taxa entries. This is
#' useful to seach in the tree
#' @export
#'
#' @examples
code_of_non_taxa_characters <- function() {
  vec_non_taxa <- -1:-6
  names(vec_non_taxa) <- c("(",")",",",":",";"," ")
  return(vec_non_taxa)
}


#' Given an string with the Newick format this function returns a properly splited version
#'
#' @param x a one string Newick farmat 
#'
#' @return a vector of the same tree 
#' @export
#'
#' @examples
#' x <- "(cow:1, pig:2):3;"
#' x <- "(((((((cow, pig),whale),(bat,(lemur,human))),(robin,iguana)),coelacanth),gold_fish),shark);"
expand_Newick_format <- function(x) {
  (split_x_all <- strsplit(x,"")[[1]])
  (split_x_all <- split_x_all[split_x_all!=" "])
  i <- 1
  while(i < length(split_x_all)) {
    if(all(split_x_all[i] != non_taxa_characters()) & all(split_x_all[i+1] != non_taxa_characters())) {
      split_x_all[i] <- paste(c(split_x_all[i],split_x_all[i+1]),collapse = "") 
      split_x_all <- split_x_all[-(i+1)]
      i <- i - 1
    }
    i <- i + 1
  }
  return(split_x_all)
}


#' Given a string or a vector of Newick format, it returns the taxa in it
#'
#' @param x a one entry Newick format string
#'
#' @return a vector of the taxa that this tree has
#' @export
#'
#' @examples
#' x <- "(cow:1, pig:2):3;"
#' x <- "(((((((cow, pig),whale),(bat,(lemur,human))),(robin,iguana)),coelacanth),gold_fish),shark);"
only_taxa_of_Newick_format <- function(x) {
  if(length(x)==1) x <- expand_Newick_format(x)
  (only_taxa <- x[suppressWarnings(is.na(as.numeric(x))) & !(x %in% non_taxa_characters())])
  return(only_taxa)
}


#' Given a string or a vector of Newick format, it returns the branch lengths
#'
#' @param x a one entry Newick format string
#'
#' @return the values of the branch lengths
#' @export
#'
#' @examples
only_branch_lengths_of_Newick_format <- function(x) {
  if(length(x)==1) x <- expand_Newick_format(x)
  
  (bl <- x[suppressWarnings(!is.na(as.numeric(x)))])
  if(length(bl)==0) {
    cat("This string does not have branch lengths.\n")
    return(-1)
  }
  return(bl)
}


#' Balanced version of the tree topology with total length total_bl
#' This function uses recursion to return the ultrametric version of the tree
#'
#' @param x vector of tree
#' @param total_bl total branch lengths
#'
#' @return transformation in to a ultrametric tree of x with the total branch lenght given
#' @export
#'
#' @examples
balance_a_tree <- function(x,total_bl) {
  # Case of only one taxa, eg x=(A);
  if(length(x)==4) {
    x[3] <- total_bl
    return(x)
  }
  print_info <- F # only for testing
  if(print_info) cat("Call for balancing: x=", x,"\n")
  # Case of two taxa
  if(length(x)==12) {
    partition <- runif(1)
    x <- c(x[1:3],total_bl*partition,x[5:7],total_bl*partition,x[9:10],total_bl*(1-partition),x[12])
    if(print_info) cat("length 5: return x=", x,"\n")
    return(x)
  }
  # We need to find the place of the comma that divides the tree
  (aux <- (x==")")*1 - (x=="(")*1)
  (aux <- aux[c(-1,-length(aux))])
  (central_comma_place <- min(which(cumsum(aux)==0)) + 4)
  # Stuff of the left tree
  (left_tree <- c(x[2:(central_comma_place-1)],";"))
  partition <- runif(1)
  (left_tree <- balance_a_tree(left_tree,total_bl*partition))
  # Stuff of the right tree
  (right_tree <- c(x[(central_comma_place+1):(length(x)-4)],";"))
  right_tree[length(right_tree)-1] <- left_tree[length(left_tree)-1]
  # right_tree
  (right_tree <- balance_a_tree(right_tree,total_bl*partition))
  x <- c("(",left_tree[-length(left_tree)],",",right_tree[-length(right_tree)],")",":",total_bl*(1-partition),";")
  return(x)
}


#' Given a vector of characters this function gives the position of the other parenthesis
#' This function is used to find the closing parentesis given the possition of the opening parenthesis
#'
#' @param x vector of characters
#' @param ind_parenthesis index of the oppener parenthesis
#'
#' @return index of the parenthesis that close 
#' @export
#'
#' @examples
#' x <- "(()((())))()"
#' (x <- strsplit(x,"")[[1]])
#' ind_parenthesis <- 1 ; find_clousure_parenthesis(x,ind_parenthesis) 
#' ind_parenthesis <- 11; find_clousure_parenthesis(x,ind_parenthesis) 
#' ind_parenthesis <- 3; find_clousure_parenthesis(x,ind_parenthesis) 
#' ind_parenthesis <- 9; find_clousure_parenthesis(x,ind_parenthesis) 
find_clousure_parenthesis <- function(x,ind_parenthesis) {
  # Case: ind_parenthesis gives "("
  if(x[ind_parenthesis]=="(") {
    x_sub <- x[ind_parenthesis:length(x)]
    aux <- cumsum((x_sub=="(")*1 - (x_sub==")")*1)
    (ind_closure <- ind_parenthesis + min(which(aux==0))-1)
  } else if(x[ind_parenthesis]==")") {
    (x_sub <- x[(ind_parenthesis):1])
    (aux <- rev(cumsum((x_sub=="(")*1 - (x_sub==")")*1)))
    (ind_closure <- max(which(aux==0)))
  } else {
    cat("Error in find_clousure_parenthesis: ind_parenthesis is not an index of parenthesis in x.\n ")
  }
  
  x[ind_parenthesis]
  x[ind_closure]
  x[min(ind_closure,ind_parenthesis):max(ind_closure,ind_parenthesis)]
  return(ind_closure)
}


#' Vector of type of triplet
#'
#' @param x string with the Newick format
#'
#' @return a vector of ones and twos; type one is A|BC and type two is AB|C this
#'   vector is of each triplet of x, sorted as they appear in the Newick format
#'   of x. This order is given by the function generates_vec_possible_triplets
#'
#' @export
#'
#' @examples
#' n <- 20
#' taxa <- named_taxa_given_n(n)
#' brach_lengths=T
#' discrete_lengths=T
#' interval_unif=c(1,10)
#' equidistance <- T
#' total_bl <- 10
#' (x <- random_tree(taxa,brach_lengths,discrete_lengths,interval_unif,equidistance,total_bl) )
#' generates_vec_type_triplet(x)
#' generates_vec_possible_triplets(x)
#' 
#' 
#' # set.seed(42)
#' cat("\014") #' borra consola 
#' rm(list=ls())  #' Borra todo
#' source("Fn phylo R.R")
#' n <- 10
#' taxa <- named_taxa_given_n(n)
#' brach_lengths=T
#' discrete_lengths=T
#' interval_unif=c(1,10)
#' equidistance <- T
#' total_bl <- 10
#' (x <- random_tree(taxa,brach_lengths,discrete_lengths,interval_unif,equidistance,total_bl) )
#' 
#' my_plot_tree(x)
#' vec_type_of_triplet <- generates_vec_type_triplet(x)
#' vec_possible_triplets <- generates_vec_possible_triplets(x)
#' 
#' 
#' x <- expand_Newick_format(x)
#' taxa_as_Newick <- only_taxa_of_Newick_format(x)
#' 
#' j1 <- 5;j2 <- 6;j3 <- 7 #' n <- 7 set.seed(41)
#' j1 <- 1;j2 <- 3;j3 <- 4 #' n <- 7set.seed(41)
#' 
#' 
#' (jss <- sort(sample(1:n,3,replace = F)))
#' j1 <- jss[1]
#' j2 <- jss[2]
#' j3 <- jss[3]
#' 
#' 
#' t1 <- taxa_as_Newick[j1]
#' i1 <-  which(x==t1)
#' 
#' t2 <- taxa_as_Newick[j2]
#' i2 <-  which(x==t2) 
#' 
#' t3 <- taxa_as_Newick[j3]
#' i3 <-  which(x==t3) 
#' (t1t2t3 <- paste(c(t1,t2,t3),collapse = ""))
#' (type_triplet <- vec_type_of_triplet[t1t2t3==vec_possible_triplets])
generates_vec_type_triplet <- function(x) {
  if(length(x)==1) x <- expand_Newick_format(x)
  # x <- expand_Newick_format(x)
  taxa_as_Newick <- only_taxa_of_Newick_format(x)
  vec_type_of_triplet <- rep(2,choose(n,3))
  # vec_type_of_triplet <- rep(2,number_triplets_n_taxa(length(taxa_as_Newick)))
  idx_vec_type <- 1
  
  vec_para_for <- 1:(n-2)
  pb <- txtProgressBar(min = 1, max = length(vec_para_for), style = 3, width = 60)
  
  for(j1 in 1:(n-2)) {
    setTxtProgressBar(pb, j1)
    
    t1 <- taxa_as_Newick[j1]
    i1 <-  which(x==t1)
    for(j2 in (j1+1):(n-1)) {
      t2 <- taxa_as_Newick[j2]
      i2 <-  which(x==t2) # se podria solo buscar en x[i1:length(x)] y sumar i1-1
      (aux_L <- x[i1:i2])
      (aux_L_open_parenthesis <- which(aux_L=="(")+i1-1)
      for(j3 in (j2+1):n) {
        t3 <- taxa_as_Newick[j3]
        i3 <-  which(x==t3) # se podria solo buscar en x[i2:length(x)] y sumar i2-1
        type_triplet <- 2 # type 2 is a|bc
        for(ind_parenthesis in aux_L_open_parenthesis) {
          if(find_clousure_parenthesis(x,ind_parenthesis)>i3) {
            type_triplet <- 1 # type 2 is a|bc
            vec_type_of_triplet[idx_vec_type] <- 1
            break;
          }
        }
        idx_vec_type <- idx_vec_type +1
        # if(type_triplet==1) cat(t1,"|",t2,t3,"\n")
        # if(type_triplet==2) cat(t1,t2,"|",t3,"\n")
      }
    }
  }
  
  close(pb)
  cat("\n")
  # type_triplet
  # (s1 <- (cumsum(((aux_L=="(")*1 - (aux_L==")")*1)))*(aux_L=="(")*1)
  return(vec_type_of_triplet)
  
}


#' Vector of ordered triplet
#'
#' @param x a string with the Newick format
#'
#' @return a vector of strings of all possible triplets of x in the order that
#'   they appear with respect to the Newick format of x
#'
#' @export
#'
#' @examples
#' n <- 20
#' taxa <- named_taxa_given_n(n)
#' brach_lengths=T
#' discrete_lengths=T
#' interval_unif=c(1,10)
#' equidistance <- T
#' total_bl <- 10
#' (x <- random_tree(taxa,brach_lengths,discrete_lengths,interval_unif,equidistance,total_bl) )
#' generates_vec_possible_triplets(x)
generates_vec_possible_triplets <- function(x) {
  if(length(x)==1) x <- expand_Newick_format(x)
  # x <- expand_Newick_format(x)
  taxa_as_Newick <- only_taxa_of_Newick_format(x)
  idx_vec_type <- 1
  vec_possible_triplets <- rep("",choose(n,3))
  for(j1 in 1:(n-2)) {
    t1 <- taxa_as_Newick[j1]
    for(j2 in (j1+1):(n-1)) {
      t2 <- taxa_as_Newick[j2]
      for(j3 in (j2+1):n) {
        t3 <- taxa_as_Newick[j3]
        vec_possible_triplets[idx_vec_type] <- paste(c(t1,t2,t3),collapse = "")
        idx_vec_type <- idx_vec_type +1
        # if(type_triplet==1) cat(t1,"|",t2,t3,"\n")
        # if(type_triplet==2) cat(t1,t2,"|",t3,"\n")
      }
    }
  }
  return(vec_possible_triplets)
}


#' Given two index of taxa it returs the smallest index of parenthesis that
#' covers them
#'
#' @param x vector with Newick format
#' @param i1 index in x of the first (and more left) taxa
#' @param i2 index in x of the second (and more rigth) taxa
#'
#' @return index of the left and rigth parenthesis
#' @export
#'
#' @examples
index_min_parenthesis_for_two_taxa <- function(x,i1,i2) {
  if(i1>=i2) {
    print("index_min_parenthesis_for_two_taxa: the index of taxa should be i1<i2.")
    return(-1)
  }
  (left_parenthesis_to_t1 <- which(x[1:(i1-1)]=="("))
  for(left_parenthesis in rev(left_parenthesis_to_t1)) {
    rigth_parenthesis <- find_clousure_parenthesis(x,left_parenthesis)
    if(rigth_parenthesis > i2) break;
  }
  i_min_parenthesis_t1t2 <- c(left_parenthesis,rigth_parenthesis)
  return(i_min_parenthesis_t1t2)
}


#' Max index of parenthesis that contains the two taxa that are near
#'
#' @param x
#' @param type_triplet scalar:  type 1 of a triplet is A|BC, and type 2 of a
#'   triplet is AB|C
#' @param i1 index of the first taxa with respec to their appear at the Newick format
#' @param i2 index of the second taxa with respec to their appear at the Newick format
#' @param i3 index of the third taxa with respec to their appear at the Newick format
#'
#' @return
#' @export
#'
#' @examples
#' #' set.seed(42)
#' cat("\014") #' borra consola 
#' rm(list=ls())  #' Borra todo
#' source("Fn phylo R.R")
#' 
#' n <- 7
#' n <- 15
#' taxa <- named_taxa_given_n(n)
#' brach_lengths=T
#' discrete_lengths=T
#' interval_unif=c(1,10)
#' equidistance <- T
#' total_bl <- 10
#' (x <- random_tree(taxa,brach_lengths,discrete_lengths,interval_unif,equidistance,total_bl) )
#' 
#' my_plot_tree(x)
#' vec_type_of_triplet <- generates_vec_type_triplet(x)
#' vec_possible_triplets <- generates_vec_possible_triplets(x)
#' 
#' 
#' x <- expand_Newick_format(x)
#' taxa_as_Newick <- only_taxa_of_Newick_format(x)
#' 
#' 
#' (jss <- sort(sample(1:n,3,replace = F)))
#' j1 <- jss[1]
#' j2 <- jss[2]
#' j3 <- jss[3]
#' 
#' 
#' t1 <- taxa_as_Newick[j1]
#' i1 <-  which(x==t1)
#' 
#' t2 <- taxa_as_Newick[j2]
#' i2 <-  which(x==t2) 
#' 
#' t3 <- taxa_as_Newick[j3]
#' i3 <-  which(x==t3) 
#' (t1t2t3 <- paste(c(t1,t2,t3),collapse = ""))
#' (type_triplet <- vec_type_of_triplet[t1t2t3==vec_possible_triplets])
#' 
#' x
#' t1t2t3
#' index_max_parentresis_taxa_together(x,type_triplet,i1, i2, i3)
#' type_triplet
index_max_parentresis_taxa_together <- function(x,type_triplet,i1, i2, i3) {
  
  # type 1 of a triplet is A|BC
  if(type_triplet == 1) {
    (i_min_parenthesis_taxa_together <- index_min_parenthesis_for_two_taxa(x,i2,i3))
    (rigth_parenthesis_to_t3 <- i_min_parenthesis_taxa_together[2]+
        which(x[i_min_parenthesis_taxa_together[2]:length(x)]==")")-1)
    
    if(length(rigth_parenthesis_to_t3)==1) {
      i_max_parenthesis_taxa_together <- i_min_parenthesis_taxa_together
    } else {
      for(i in 1:length(rigth_parenthesis_to_t3)) {
        left_parenthesis <- find_clousure_parenthesis(x,rigth_parenthesis_to_t3[i])
        # cat("x=",x[left_parenthesis_to_t1[i]:rigth_parenthesis],"\n")
        if(left_parenthesis < i1) break;
      }
      rigth_parenthesis <- rigth_parenthesis_to_t3[i-1]
      left_parenthesis <- find_clousure_parenthesis(x,rigth_parenthesis)
    }
    
  } else if(type_triplet == 2) { # type 2 of a triplet is AB|C
    
    (i_min_parenthesis_taxa_together <- index_min_parenthesis_for_two_taxa(x,i1,i2))
    (left_parenthesis_to_t1 <- which(x[1:i_min_parenthesis_taxa_together[1]]=="("))
    
    if(length(left_parenthesis_to_t1)==1) {
      i_max_parenthesis_taxa_together <- i_min_parenthesis_taxa_together
    } else {
      for(i in (length(left_parenthesis_to_t1)):1) {
        rigth_parenthesis <- find_clousure_parenthesis(x,left_parenthesis_to_t1[i])
        # cat("x=",x[left_parenthesis_to_t1[i]:rigth_parenthesis],"\n")
        if(rigth_parenthesis > i3) break;
      }
      
      left_parenthesis <- left_parenthesis_to_t1[i+1]
      rigth_parenthesis <- find_clousure_parenthesis(x,left_parenthesis)
    }
  }
  # x
  # t1t2t3
  # cat("x=",x[left_parenthesis:rigth_parenthesis],"\n")
  (i_max_parenthesis_taxa_together <- c(left_parenthesis,rigth_parenthesis))
  return(i_max_parenthesis_taxa_together)
}

#' Extrancting gene tree data from folder
#'
#' @param num_sub_folder depending of this number is the gene trees data
#'   extracted (see the variable sub_folders)
#'
#' @return
#' @export
#'
#' @examples
data_example_PhyloNetworks <- function(num_sub_folder) {
  cat("Data from: https://github.com/crsl4/PhyloNetworks.jl/wiki/Example-Data\n")
  file_data <- "data_results/baseline.gamma0.3_n30/input/1_seqgen.in"
  sub_folders <- c("baseline.gamma0.3_n30",
                   "baseline.gamma0.3_n100",
                   "baseline.gamma0.3_n300",
                   "baseline.gamma0.3_n1000",
                   "n6.gamma0.30.2_n300",
                   "n15.gamma0.30.20.2_n300")
  cat("Sub folder:",sub_folders[num_sub_folder],"\n")
  file_data <- paste0("data_results/",sub_folders[num_sub_folder], "/input/1_seqgen.in")
  data <- read.table(file_data, header = FALSE, sep = "\n")
  return(data)
}

#' Recursion to get postorder traversal for internal nodes
#'
#' @param list_pt 
#' @param print_recursion_path 
#'
#' @return
#' @export
#'
#' @examples
clade_postorder <- function(list_pt,print_recursion_path=F) {
  if(print_recursion_path) cat("list_pt$current_pointer=",list_pt$current_pointer,"\n")
  # po_clades <- list_pt$po_clades
  # i_po_clades <- list_pt$i_po_clades
  current_pointer <- list_pt$current_pointer
  # unused_clades <- list_pt$unused_clades
  # taxa_to_check <- list_pt$taxa_to_check
  # all_edges <- list_pt$all_edges
  
  # if(current_pointer %in% taxa_to_check) return(list_pt)
  
  # i_po_clades <- i_po_clades+1
  children <- list_pt$all_edges[list_pt$all_edges[,1] == list_pt$current_pointer,]
  
  # Make left child leaf
  if(!children[1,2] %in% list_pt$taxa_to_check) {
    list_pt$current_pointer <- children[1,2]
    # list_pt$i_po_clades <- list_pt$i_po_clades+1
    list_pt <- clade_postorder(list_pt)
  }
  
  # Make right child leaf
  if(!children[2,2] %in% list_pt$taxa_to_check) {
    list_pt$current_pointer <- children[2,2]
    # list_pt$i_po_clades <- list_pt$i_po_clades+1
    # return(list_pt)
    list_pt <- clade_postorder(list_pt)
  }
  
  # if enter this case is because both children are leaves
  # if(all(children[,2] %in% taxa_to_check)) {
  
  if(print_recursion_path) cat("Yes all(children[,2] %in% taxa_to_check), i_po_clades=",i_po_clades,
                               " current_pointer=",current_pointer,"\n")
  list_pt$visit_order <- c(list_pt$visit_order,current_pointer)
  
  # First, we save the new value that should have this node
  list_pt$po_clades[list_pt$i_po_clades,] <- c(current_pointer,list_pt$unused_clades[1])
  # Since this value is used, we erase their value of the list of internal nodes
  list_pt$unused_clades <- list_pt$unused_clades[-1]
  # We erase its branches
  # all_edges <- all_edges[all_edges[,1] != current_pointer,]
  # We made the edges that enter the current to point the leaf "one"
  # all_edges[all_edges[,2]==current_pointer,2] <- 1
  
  # i_po_clades <- i_po_clades+1
  
  # taxa_to_check <- c(taxa_to_check,current_pointer)
  
  # current_pointer <- children[1,1]
  
  return(list_pt)
}



#' Postorder traversal of nodes
#'
#' @param x a newick format vector
#'
#' @return a list with the visits of the post-order taxa 
#' @export
#'
#' @examples
postorder_traversal_of_Newick_format <- function(x) {
  vert.tree<-read.tree(text=x,methods="post")
  n <- length(only_taxa_of_Newick_format(x))
  
  all_edges <- vert.tree[["edge"]]
  
  (unused_clades <- 1:(n-1))
  (taxa_to_check <- 1:n)
  
  (current_pointer <- all_edges[1,1])
  
  po_clades <- matrix(0,ncol = 2,nrow = n-1)
  i_po_clades <- 1
  
  visit_order <- c(NULL)
  
  postorder_mat <- matrix(0,n-2,2)
  postedge_to_preleaves <- matrix(0,n,2)
  list_pt <- initialize_list_pt(po_clades,
                                i_po_clades,
                                current_pointer,
                                unused_clades,
                                taxa_to_check,
                                all_edges, 
                                visit_order,
                                n,
                                postorder_mat,
                                postedge_to_preleaves) 
  
  list_pt <- clade_postorder(list_pt) 
  
  list_pt$all_edges
  mat_order <- matrix(c(list_pt$visit_order,1:(n-1),ncol=2))
  # two column matrix where each row represents an internal edge of the preorder 
  (internal_edges_phyt <- list_pt$all_edges[!list_pt$all_edges[,2] %in% 1:list_pt$n,])
  
  (vec <- internal_edges_phyt[,1])
  # Clever trick that gives the interaction between preorder nodes and postorder
  # nodes; it uses indexes to find out this relationship
  list_pt$postorder_mat <- matrix(c(rep(0,n),order(list_pt$visit_order))[internal_edges_phyt],ncol = 2)
  
  return(list_pt)
  
}



#' Generation of descendant matrix R and S
#'
#' @param list_pt the list of parameters given by the function
#'   postorder_traversal_of_Newick_format
#'
#' @return since both S and R are generated in the same way (given a
#'   phylogenetic tree), it returns the decendant matrix the tree stored in
#'   list_pt
#' @export
#'
#' @examples
#' set.seed(41)
#' cat("\014") #' borra consola
#' rm(list=ls())  #' Borra todo
#' source("Fn phylo R.R")
#' x <- "((A,(B,C)),((D,E),(F,G)));" # Species tree of Degman
#' x <- "((A,B),(C,((D,F),(E,G))));" # Gne     tree of Degman
#' my_plot_tree(x)
#' (list_pt <- postorder_traversal_of_Newick_format(x))
#' extract_descendant_mat(list_pt)
extract_descendant_mat <- function(list_pt) {
  descendant_mat <- matrix(0,list_pt$n-2,list_pt$n-2)
  # The next loop uses the previous children to get the children of a subsequent node
  for(node in 1:(list_pt$n-2)) {
    # Find if the node has direct children
    (direct_children <- list_pt$postorder_mat[list_pt$postorder_mat[,1]==node,2])
    # if the node has direct children we...
    if(length(direct_children)>0) {
      # Put a one for each direct children
      descendant_mat[node,direct_children] <- 1
      # Add the children of its children
      descendant_mat[node,] <- descendant_mat[node,] + colSums(descendant_mat[direct_children,,drop=F])
    }
  }
  list_pt$descendant_mat <- descendant_mat
  return(list_pt)
}


#' Initialization of a list
#'
#' @param po_clades a matrix that should had the postorder edges
#' @param i_po_clades a couter to keep track of the row that should be written
#'   by the recursion in the matrix po_clades
#' @param current_pointer pointer of the current node that is worked by the
#'   recursion
#' @param unused_clades variable of the unused clades by the recursion
#' @param taxa_to_check variable that should be needed to check in the recursion
#'   steps
#' @param all_edges all edges given in the way that phylotools obtains them: the
#'   leaves are the numbers 1 to n, and the rest is in preorder
#' @param visit_order the way that the phylotools edges visit by a postorder
#'   escursion; for instace visit_order=c(10,9,12,13,11,8) means that the node
#'   label by 10 in the phylotool fuction read.tree should be visited first
#'   (usig postorder traversal), the node 9 should be visited second, etc, etc.
#'   This equivalence is used to construct the postorder_mat
#' @param n number of taxa
#' @param postorder_mat matrix whos rows are the internal nodes as in Degnan's
#'   article
#' @param postedge_to_preleaves nodes in the postorder to the leaves in the
#'   order given by preorder
#'
#' @return a list with this variables
#' @export
#'
#' @examples
#'
#'
#' set.seed(41)
#' cat("\014") #' borra consola
#' rm(list=ls())  #' Borra todo
#' source("Fn phylo R.R")
#' x <- "((A,B),(C,((D,F),(E,G))));" # Gne     tree of Degman
#' x <- "((A,(B,C)),((D,E),(F,G)));" # Species tree of Degman
#' my_plot_tree(x)
#' vert.tree<-read.tree(text=x,methods="post")
#' n <- length(only_taxa_of_Newick_format(x))
#' all_edges <- vert.tree[["edge"]]
#' (unused_clades <- 1:(n-1))
#' (taxa_to_check <- 1:n)
#'
#' (current_pointer <- all_edges[1,1])
#'
#' po_clades <- matrix(0,ncol = 2,nrow = n-1)
#' i_po_clades <- 1
#'
#' visit_order <- c(NULL)
#'
#' list_pt <- initialize_list_pt(po_clades,
#'                               i_po_clades,
#'                               current_pointer,
#'                               unused_clades,
#'                               taxa_to_check,
#'                               all_edges,
#'                               visit_order,
#'                               n) 
initialize_list_pt <- function(po_clades,
                               i_po_clades,
                               current_pointer,
                               unused_clades,
                               taxa_to_check,
                               all_edges, 
                               visit_order,
                               n,
                               postorder_mat,
                               postedge_to_preleaves) {
  
  list_pt <- list(po_clades=po_clades,
                  i_po_clades=i_po_clades,
                  current_pointer=current_pointer,
                  unused_clades=unused_clades,
                  taxa_to_check=taxa_to_check,
                  all_edges=all_edges, # has the edges given by phylotools: the leaves are the numbers f
                  visit_order=visit_order,
                  n=n,
                  postedge_to_preleaves=postedge_to_preleaves)
  return(list_pt)
}


#' The edges between postorder nodes and leaves in preorder
#'
#' @param list_pt 
#'
#' @return
#' @export
#'
#' @examples
post_to_leaves <- function(list_pt) {
  postedge_to_preleaves <- list_pt$all_edges[list_pt$all_edges[,2] %in% 1:list_pt$n,]
  
  colnames(postedge_to_preleaves) <- c("postorder edges","preorder leaves")
  
  postedge_to_preleaves[,1] <- c(rep(0,list_pt$n),order(list_pt$visit_order))[postedge_to_preleaves[,1]]
  postedge_to_preleaves
  
  list_pt$postedge_to_preleaves <- postedge_to_preleaves
  return(list_pt)
}


#' Matrix that connects leaves to nodes in postorder
#'
#' @param list_pt 
#'
#' @return
#' @export
#'
#' @examples
#' set.seed(41)
#' cat("\014") # borra consola
#' rm(list=ls())  # Borra todo
#' source("Fn phylo R.R")
#' x <- "((A,(B,C)),((D,E),(F,G)));" #' Species tree of Degman
#' x <- "((A,B),(C,((D,F),(E,G))));" #' Gene    tree of Degman
#' my_plot_tree(x)
#' (list_pt <- postorder_traversal_of_Newick_format(x))
#' post_order_ancestors <- matrix(0,list_pt$n-1,2)
#' list_pt <- post_to_leaves(list_pt)
ancestors_to_leaves <- function(list_pt) {
  descendant_leaves_mat <- matrix(0,list_pt$n-2,list_pt$n)
  for(node in 1:(list_pt$n-2)) {
    # Find the leaves connected to this node, and if they exist we add a one to the entries
    (node_to_leave <- list_pt$postedge_to_preleaves[list_pt$postedge_to_preleaves[,1]==node,2])
    if(length(node_to_leave)>0) descendant_leaves_mat[node,node_to_leave] <- 1
    
    # Find the other nodes connected to this node, and if they exist we add a one to the entries
    (node_to_node <- list_pt$postorder_mat[list_pt$postorder_mat[,1]==node,2])
    if(length(node_to_node)>0) {
      # This auxiliar is used to not erase the note_te_leaves ones
      aux <- colSums(descendant_leaves_mat[node_to_node,,drop=F])
      descendant_leaves_mat[node,aux==1] <- 1
    }
  }
  list_pt$descendant_leaves_mat <- descendant_leaves_mat
  return(list_pt)
}


#' Given the gene tree and the species tree returns all the needed varibles to
#' calculate their likelihood
#'
#' @param st species tree in Newick format
#' @param gt gene    tree in Newick format
#'
#' @return a list with the variables to calculate the likelihood of gt given sp
#' @export
#'
#' @examples
#' gt <- "((A,B),(C,((D,F),(E,G))));" # Gene    tree of Degman
#' st <- "((A,(B,C)),((D,E),(F,G)));" # Species tree of Degman
#' matrices_M_R_S(st,gt) 
matrices_M_R_S <- function(st,gt) {
  # Species tree
  list_pt_st <- postorder_traversal_of_Newick_format(st)
  list_pt_st <- post_to_leaves(list_pt_st)
  list_pt_st <- ancestors_to_leaves(list_pt_st)
  list_pt_st <- extract_descendant_mat(list_pt_st)
  order_st <- order(only_taxa_of_Newick_format(st))
  S_mat <- list_pt_st$descendant_mat
  
  # gt <- "((C,((D,F),(E,G))),(A,B));" # Gene    tree PROBLEMS!!!!!!!
  only_taxa_of_Newick_format(gt)
  order_gt <- order(only_taxa_of_Newick_format(gt))
  list_pt_gt <- postorder_traversal_of_Newick_format(gt)
  list_pt_gt <- post_to_leaves(list_pt_gt)
  list_pt_gt <- extract_descendant_mat(list_pt_gt)
  list_pt_gt <- ancestors_to_leaves(list_pt_gt)
  
  R_mat <- list_pt_gt$descendant_mat
  
  list_pt_st$descendant_leaves_mat
  # Since the taxa in gene tree could be not appear in the same orde as in the species tree
  # order_st[order_gt]
  # order_gt[order_st] # falta corriger el orden general de las columnas,
  # gt <- "((C,((D,F),(E,G))),(A,B));" # Gene    tree of Degman
  list_pt_gt$descendant_leaves_mat <- list_pt_gt$descendant_leaves_mat[,order_st[order_gt]]
  
  # list_pt_gt$descendant_leaves_mat <- list_pt_gt$descendant_leaves_mat[order_st[order_gt],order_st[order_gt]]
  
  M_mat <- matrix(0,list_pt_st$n-2,list_pt_st$n-2)
  i <- 3
  for(i in 1:(list_pt_st$n-2)) {
    (mat_dif <- matrix(rep(list_pt_st$descendant_leaves_mat[i,],list_pt_st$n-2),list_pt_st$n-2,byrow = T) -
       list_pt_gt$descendant_leaves_mat)
    (M_mat[i,] <- apply(mat_dif,MARGIN = 1,FUN = function(x) all(x>=0))*1)
  }
  
  list_MRS <- list(n=list_pt_st$n,M_mat=M_mat,S_mat=S_mat,R_mat=R_mat,
                   list_pt_gt=list_pt_gt,list_pt_st=list_pt_st)
  return(list_MRS)
}


#' From eq (5) of Degnan
#'
#' @param list_MRS 
#'
#' @return
#' @export
#'
#' @examples
#' gt <- "((A,B),(C,((D,F),(E,G))));" # Gene    tree of Degman
#' st <- "((A,(B,C)),((D,E),(F,G)));" # Species tree of Degman
#' list_MRS <- matrices_M_R_S(st,gt) 
#' gen_delta_b(list_MRS)
gen_delta_b <- function(list_MRS) {
  delta_b <- rep(0,list_MRS$n-2)
  delta_b[1] <- 2
  for(b in 2:(list_MRS$n-2)) delta_b[b] <- 2 + sum(list_MRS$S_mat[b,1:(b-1)])
  return(delta_b)
}



#' Title
#'
#' @param h 
#' @param list_MRS 
#'
#' @return
#' @export
#'
#' @examples
#' h <- c(2,5,5,6,6)
#' gt <- "((A,B),(C,((D,F),(E,G))));" # Gene    tree of Degman
#' st <- "((A,(B,C)),((D,E),(F,G)));" # Species tree of Degman
#' list_MRS <- matrices_M_R_S(st,gt) 
#' delta_b <- gen_delta_b(list_MRS)
gen_u_b <- function(h,list_MRS) {
  u_b <- rep(0,list_MRS$n-2)
  for(b in 1:(list_MRS$n-2)) {
    aux <- 0
    for(y in 1:(b-1)) {
      (sum_ind_hk_y_Sby <- sum(list_MRS$S_mat[b,h==y]))
      aux <- aux + sum_ind_hk_y_Sby
    }
    u_b[b] <- delta_b[b] - aux
  }
  return(u_b)
}


#' Title
#'
#' @param h 
#' @param list_MRS 
#'
#' @return
#' @export
#'
#' @examples
#' h <- c(2,5,5,6,6) ## fig 2a
#' h <- c(2,5,6,6,6) ## fig 2b
#' h <- c(2,6,6,6,6) ## fig 2c
#' h <- c(6,6,6,6,6) ## fig 2d
#' gt <- "((A,B),(C,((D,F),(E,G))));" # Gene    tree of Degman
#' st <- "((A,(B,C)),((D,E),(F,G)));" # Species tree of Degman
#' list_MRS <- matrices_M_R_S(st,gt) 
#' delta_b <- gen_delta_b(list_MRS)
#' u_b <- gen_u_b(h,list_MRS)
gen_v_b <- function(h,u_b,list_MRS) {
  v_b <- rep(0,list_MRS$n-2)
  for(b in 1:(list_MRS$n-2)) {
    v_b[b] <- u_b[b] - sum(h==b)
  }
  return(v_b)
}


gen_c_b <- function(u_b,v_b) {
  c_b <- u_b - v_b
  return(c_b)
}



#' Given list of a gene tree this generates the R matrix as Ch 4
#'
#' @param list_pt 
#'
#' @return
#' @export
#'
#' @examples
gen_R_mat <- function(list_pt) {
  (descendant_mat <- matrix(0,list_pt$n-1,list_pt$n-1))
  # The next loop uses the previous children to get the children of a subsequent node
  for(node in 1:(list_pt$n-1)) {
    # Find if the node has direct children
    (direct_children <- list_pt$postorder_mat[list_pt$postorder_mat[,1]==node,2])
    # if the node has direct children we...
    if(length(direct_children)>0) {
      # Put a one for each direct children
      descendant_mat[node,direct_children] <- 1
      # Add the children of its children
      descendant_mat[node,] <- descendant_mat[node,] + colSums(descendant_mat[direct_children,,drop=F])
    }
  }
  descendant_mat
  list_pt$R_mat <- descendant_mat
  return(list_pt)
}

#' list for gene tree with the R matrix in list_pt$R_mat
#'
#' @param x 
#'
#' @return
#' @export
#'
#' @examples
#' x <- "(((H1,((H2,H3),(C1,C2))),G1),O1);" #_ gene tree Ch4 pp 62
#' my_plot_tree(x)
#' list_pt <- gen_list_gt(x)
#' list_pt$R_mat
gen_list_gt <- function(x) {
  (list_pt <- postorder_traversal_of_Newick_format(x))
  list_pt <- postorder_traversal_of_Newick_format(x)
  list_pt <- gen_postedge_to_preleaves(list_pt)
  list_pt <- extract_descendant_mat(list_pt)
  list_pt <- gen_R_mat(list_pt)
  return(list_pt)
}



gen_postedge_to_preleaves <- function(list_pt) {
  postedge_to_preleaves <- list_pt$all_edges[list_pt$all_edges[,2] %in% 1:list_pt$n,]
  colnames(postedge_to_preleaves) <- c("postorder edges","preorder leaves")
  
  postedge_to_preleaves[,1] <- c(rep(0,list_pt$n),order(list_pt$visit_order))[postedge_to_preleaves[,1]]
  postedge_to_preleaves
  
  list_pt$postedge_to_preleaves <- postedge_to_preleaves
  return(list_pt)
}



#' Given list of a species tree this generates the R matrix as Ch 4
#'
#' @param list_pt 
#'
#' @return
#' @export
#'
#' @examples
gen_S_mat <- function(list_pt) {
  (descendant_mat <- matrix(0,list_pt$n-1,list_pt$n-1))
  # The next loop uses the previous children to get the children of a subsequent node
  for(node in 1:(list_pt$n-1)) {
    # Find if the node has direct children
    (direct_children <- list_pt$postorder_mat[list_pt$postorder_mat[,1]==node,2])
    # if the node has direct children we...
    if(length(direct_children)>0) {
      # Put a one for each direct children
      descendant_mat[node,direct_children] <- 1
      # Add the children of its children
      descendant_mat[node,] <- descendant_mat[node,] + colSums(descendant_mat[direct_children,,drop=F])
    }
  }
  descendant_mat
  list_pt$S_mat <- descendant_mat
  return(list_pt)
}

#' list for species tree with the R matrix in list_pt$R_mat
#'
#' @param x 
#'
#' @return
#' @export
#'
#' @examples
#' x <- "(((H1,((H2,H3),(C1,C2))),G1),O1);" #_ gene tree Ch4 pp 62
#' my_plot_tree(x)
#' list_pt <- gen_list_gt(x)
#' list_pt$R_mat
#' x <- "(((H,C),G),O);" #_ species tree Ch4 pp 62
#' gen_list_st(x)
#' my_plot_tree(x)
gen_list_st <- function(x) {
  # Tris is a trick to obtain S matrix as Ch 4
  x <- expand_Newick_format(x)
  (only_taxa <- only_taxa_of_Newick_format(x))
  for(taxa in only_taxa) {
    i_taxa <- which(x==taxa)
    new_text <- c("(",paste(c(taxa,"1"),collapse = ""),",",paste(c(taxa,"2"),collapse = ""),")")
    (x <- c(x[1:(i_taxa-1)],new_text,x[(i_taxa+1):length(x)]))
  }
  # end of trick
  
  (list_pt <- postorder_traversal_of_Newick_format(x))
  list_pt <- postorder_traversal_of_Newick_format(x)
  list_pt <- gen_postedge_to_preleaves(list_pt)
  list_pt <- extract_descendant_mat(list_pt)
  list_pt <- gen_S_mat(list_pt)
  return(list_pt)
}




prin_eq_CF <- function(eq_type,exp_t,gam,CF_index,in_Z=F) {
  if(!in_Z) exp_t <- paste(c("e^{",exp_t,"}"),collapse = "")
  
  
  if(eq_type==CF_index) {
    text_proba <- paste(c("1-\\dfrac{2}{3}",exp_t),collapse = "")
    
    if(gam!="none") {
      text_proba <- paste(c(gam,"\\left(",text_proba,"\\right)"),collapse = "")
    }
  } else {
    text_proba <- paste(c("\\dfrac{1}{3}",exp_t),collapse = "")
    
    if(gam!="none") {
      text_proba <- paste(c(gam,text_proba),collapse = "")
    }
  }
  
  return(text_proba)
}

CF_TeX_text <- function(eq_gamm,t_gamma,gam,CF_index,eq_1_ga,t_1_gam,eq_Tree,t__Tree,in_Z,a_index) {
  text_proba_gam <- prin_eq_CF(eq_gamm,t_gamma,gam,CF_index,in_Z)
  
  text_prob_1gam <- prin_eq_CF(eq_1_ga,t_1_gam,paste(c("(1-",gam,")"),collapse = ""),CF_index,in_Z)
  
  if(a_index=="none") {
    text_probab__T <- prin_eq_CF(eq_Tree,t__Tree,"none",CF_index,in_Z)
  } else text_probab__T <- paste(c("a",a_index," "),collapse = "")
  
  
  
  text_CF_index <- paste(c(text_proba_gam,"+",text_prob_1gam,"&=",text_probab__T),collapse = "")
  return(text_CF_index)
}




print_all_CF <- function(mat_k4,mat_k4_Hybrid,mat_k4_NTree_vr_Tree,gam,in_Z,a_index="none") {
  cat("**begin{align}\n")
  
  a_index <- eq_NTree_vr_Tree(mat_k4_NTree_vr_Tree,Math0_TeX1=1,a_index)
  
  for(i in 1:nrow(mat_k4)) for(CF_index in 2:4) {
    text_CF_index <- CF_TeX_text(mat_k4[i,2],mat_k4[i,1],gam,CF_index,
                                 mat_k4[i,4],mat_k4[i,3],mat_k4[i,6],
                                 mat_k4[i,5],in_Z,a_index)
    if(a_index!="none") a_index <- a_index+1
    cat(text_CF_index,"****","\n")
  }
  for(i in 1:nrow(mat_k4_Hybrid)) for(CF_index in 2:4) {
    text_CF_index <- CF_TeX_text_2hybrid(mat_k4_Hybrid[i,1],mat_k4_Hybrid[i,2],
                                         mat_k4_Hybrid[i,3],mat_k4_Hybrid[i,4],
                                         mat_k4_Hybrid[i,5],mat_k4_Hybrid[i,6],
                                         mat_k4_Hybrid[i,7],mat_k4_Hybrid[i,8],
                                         mat_k4_Hybrid[i,9],mat_k4_Hybrid[i,10],
                                         gam,CF_index,in_Z,a_index) 
    if(a_index!="none") a_index <- a_index+1
    if(i==nrow(mat_k4_Hybrid) & CF_index==4) cat(text_CF_index,"\n") else cat(text_CF_index,"****","\n")
    # cat(text_CF_index,"****","\n")
  }
  cat("**end{align}")
}



#' Title
#'
#' @param eq_type 
#' @param z 
#' @param gam 
#' @param CF_index 
#'
#' @return
#' @export
#'
#' @examples
#' z <-"z0"
#' gam <- "gam"
#' CF_index <- 4
#' eq_type <- 4
#' prin_eq_CF_Mathematica(eq_type,z,gam,CF_index)
#' gam <- "none"
#' CF_index <- 4
#' eq_type <- 4
#' z <-"z0"
#' prin_eq_CF_Mathematica(eq_type,z,gam,CF_index)
prin_eq_CF_Mathematica <- function(eq_type,z,gam="none",CF_index) {
  if(eq_type==CF_index) text_proba <- paste(c("1-2*",z,"/3"),collapse = "")
  if(eq_type!=CF_index) text_proba <- paste(c("1*",z,"/3"),collapse = "")
  if(gam!="none") text_proba <- paste(c(gam,"*(",text_proba,")"),collapse = "")
  return(text_proba)
}


eq_CF_Mathematica <- function(z_gamma,eq_gamm,z_1_gam,eq_1_ga,w__Tree,eq_Tree,gam,CF_index,a_index="none") {
  text_proba_gam <- prin_eq_CF_Mathematica(eq_gamm,z_gamma,gam,CF_index)
  text_prob_1gam <- prin_eq_CF_Mathematica(eq_1_ga,z_1_gam,paste(c("(1-",gam,")"),collapse = ""),CF_index)
  if(a_index=="none") {
    text_probab__T <- prin_eq_CF_Mathematica(eq_Tree,w__Tree,"none",CF_index)
  } else text_probab__T <- paste(c("a",a_index," "),collapse = "")
  text_CF_index <- paste(c(text_proba_gam,"+",text_prob_1gam,"==",text_probab__T),collapse = "")
  return(text_CF_index)
}


eq_NTree_vr_Tree <- function(mat_k4_NTree_vr_Tree,Math0_TeX1,a_index="none") {
  if(a_index=="none") {
    if(Math0_TeX1==0)  for(i in 1:nrow(mat_k4_NTree_vr_Tree)) {
      cat(mat_k4_NTree_vr_Tree[i,1],"==",mat_k4_NTree_vr_Tree[i,2],",\n")
    } 
    if(Math0_TeX1==1)  for(i in 1:nrow(mat_k4_NTree_vr_Tree)) {
      cat(mat_k4_NTree_vr_Tree[i,1],"&=",mat_k4_NTree_vr_Tree[i,2],"****","\n")
    }
  } else {
    if(Math0_TeX1==0)  for(i in 1:nrow(mat_k4_NTree_vr_Tree)) {
      text_ai <- paste(c("a",a_index),collapse = "")
      cat(mat_k4_NTree_vr_Tree[i,1],"== ",text_ai,",\n")
      a_index <- a_index +1
    } 
    if(Math0_TeX1==1)  for(i in 1:nrow(mat_k4_NTree_vr_Tree)) {
      text_ai <- paste(c("a",a_index),collapse = "")
      cat(mat_k4_NTree_vr_Tree[i,1],"&= ",text_ai,"****","\n")
      a_index <- a_index +1
    }
  }
  return(a_index)
}

print_all_CF_Mathematica <- function(mat_k4,mat_k4_Hybrid,mat_k4_NTree_vr_Tree,
                                     gam,var_z,var_w,a_index="none") {
  
  # cat("Assuming[{\n")
  # 
  # if(a_index!="none") {
  #   text_var_a <- paste0("a",1:45)
  #   cat(paste(c(paste(c(var_z,text_var_a,gam),collapse = ">0,"),">0,"),collapse = ""),"\n")
  #   cat(paste(c(paste(c(var_z,text_var_a),collapse = "<1,"),"<1,",gam,"<1"),collapse = ""),"},\n")
  # } else {
  #   cat(paste(c(paste(c(gam,var_z),collapse = ">0,"),">0,",gam,"<1"),collapse = ""),"},\n")
  # }
  
  cat("Solve[{\n")
  
  # if(a_index!="none") {
  #   text_var_a <- paste0("a",1:45)
  #   cat(paste(c(paste(c(var_z,text_var_a,gam),collapse = ">0,"),">0,"),collapse = ""),"\n")
  #   cat(paste(c(paste(c(var_z,text_var_a),collapse = "<1,"),"<1,",gam,"<1"),collapse = ""),",\n")
  # } else {
  #   cat(paste(c(paste(c(gam,var_z),collapse = ">0,"),">0,",gam,"<1"),collapse = ""),",\n")
  # }
  
  # Tree vr tree case
  a_index <- eq_NTree_vr_Tree(mat_k4_NTree_vr_Tree,Math0_TeX1=0,a_index) 
  
  for(i in 1:nrow(mat_k4)) for(CF_index in 2:4) {
    text_CF_index <- eq_CF_Mathematica(mat_k4[i,1],mat_k4[i,2],
                                       mat_k4[i,3],mat_k4[i,4],
                                       mat_k4[i,5],mat_k4[i,6],gam,CF_index,a_index) 
    
    if(a_index!="none") a_index <- a_index+1
    # if(i==nrow(mat_k4) & CF_index==4) cat(text_CF_index,"\n") else cat(text_CF_index,",\n")
    cat(text_CF_index,",\n")
  }
  
  for(i in 1:nrow(mat_k4_Hybrid)) for(CF_index in 2:4) {
    text_CF_index <- eq_CF_Mathematica_2hybrid(mat_k4_Hybrid[i,1],mat_k4_Hybrid[i,2],
                                               mat_k4_Hybrid[i,3],mat_k4_Hybrid[i,4],
                                               mat_k4_Hybrid[i,5],mat_k4_Hybrid[i,6],
                                               mat_k4_Hybrid[i,7],mat_k4_Hybrid[i,8],
                                               mat_k4_Hybrid[i,9],mat_k4_Hybrid[i,10],
                                               gam,CF_index,a_index) 
    if(a_index!="none") a_index <- a_index+1
    # if(i==nrow(mat_k4_Hybrid) & CF_index==4) cat(text_CF_index,"\n") else cat(text_CF_index,"****","\n")
    if(i==nrow(mat_k4_Hybrid) & CF_index==4) cat(text_CF_index,"\n") else cat(text_CF_index,",\n")
  }
  
  if(a_index!="none") {
    text_var_a <- paste(paste0("a",1:a_index),collapse = ",")
    cat("},{",paste(c(var_z,text_var_a,gam),collapse = ","),"}]\n")
  } else cat("},{",paste(c(var_z,var_w,gam),collapse = ","),"}]\n")
  
}


CF_TeX_text_2hybrid <- function(t___gam2,eq___gam2,
                                t___1ga2,eq___1ga2,
                                t_ga1ga1,eq_ga1ga1,
                                t_ga1ga2,eq_ga1ga2,
                                t___Tree,eq___Tree,
                                gam,CF_index,in_Z,a_index) {
  # prin_eq_CF <- function(eq_type,exp_t,gam,CF_index,in_Z=F)
  text_proba_ga2 <- prin_eq_CF(eq___gam2,t___gam2,paste(c(gam,"^2 "),collapse = ""),CF_index,in_Z)
  text_prob_1ga2 <- prin_eq_CF(eq___1ga2,t___1ga2,paste(c("(1-",gam,")^2"),collapse = ""),CF_index,in_Z)
  text_pr_ga1ga1 <- prin_eq_CF(eq_ga1ga1,t_ga1ga1,paste(c(gam,"(1-",gam,")"),collapse = ""),CF_index,in_Z)
  text_pr_ga1ga2 <- prin_eq_CF(eq_ga1ga2,t_ga1ga2,paste(c(gam,"(1-",gam,")"),collapse = ""),CF_index,in_Z)
  
  if(a_index=="none") {
    text_probab__T <- prin_eq_CF(eq___Tree,t___Tree,"none",CF_index,in_Z)
  } else text_probab__T <- paste(c("a",a_index," "),collapse = "")
  
  text_CF_index <- paste(c(text_proba_ga2,"+",
                           text_prob_1ga2,"+",
                           text_pr_ga1ga1,"+",
                           text_pr_ga1ga2,"&=",text_probab__T),collapse = "")
  return(text_CF_index)
}


eq_CF_Mathematica_2hybrid <- function(t___gam2,eq___gam2,
                                      t___1ga2,eq___1ga2,
                                      t_ga1ga1,eq_ga1ga1,
                                      t_ga1ga2,eq_ga1ga2,
                                      t___Tree,eq___Tree,
                                      gam,CF_index,a_index) {
  
  text_proba_ga2 <- prin_eq_CF_Mathematica(eq___gam2,t___gam2,paste(c(gam,"^2 "),collapse = ""),CF_index)
  text_prob_1ga2 <- prin_eq_CF_Mathematica(eq___1ga2,t___1ga2,paste(c("(1-",gam,")^2 "),collapse = ""),CF_index)
  text_pr_ga1ga1 <- prin_eq_CF_Mathematica(eq_ga1ga1,t_ga1ga1,paste(c(gam,"(1-",gam,")"),collapse = ""),CF_index)
  text_pr_ga1ga2 <- prin_eq_CF_Mathematica(eq_ga1ga2,t_ga1ga2,paste(c(gam,"(1-",gam,")"),collapse = ""),CF_index)
  
  if(a_index=="none") {
    text_probab__T <- prin_eq_CF_Mathematica(eq___Tree,t___Tree,"none",CF_index)
  } else text_probab__T <- paste(c("a",a_index," "),collapse = "")
  
  
  text_CF_index <- paste(c(text_proba_ga2,"+",
                           text_prob_1ga2,"+",
                           text_pr_ga1ga1,"+",
                           text_pr_ga1ga2,"==",text_probab__T),collapse = "")
  
  # text_proba_gam <- prin_eq_CF_Mathematica(eq_gamm,z_gamma,gam,CF_index)
  # text_prob_1gam <- prin_eq_CF_Mathematica(eq_1_ga,z_1_gam,paste(c("(1-",gam,")"),collapse = ""),CF_index)
  # text_probab__T <- prin_eq_CF_Mathematica(eq_Tree,w__Tree,"none",CF_index)
  # text_CF_index <- paste(c(text_proba_gam,"+",text_prob_1gam,"==",text_probab__T),collapse = "")
  return(text_CF_index)
}



print_CF_TeX_k2 <- function(mat_k2,gam,in_Z,a_index="none") {
  cat("\\begin{align}\n")
  for(i in 1:nrow(mat_k2)) for(CF_index in 2:4) {
    text_CF_index <- CF_TeX_text(mat_k2[i,2],mat_k2[i,1],gam,CF_index,
                                 mat_k2[i,4],mat_k2[i,3],mat_k2[i,6],
                                 mat_k2[i,5],in_Z,a_index) 
    if(a_index!="none") a_index <- a_index+1
    if(i==nrow(mat_k2) & CF_index==4) cat(text_CF_index,"\n") else cat(text_CF_index,"\\\\ \n")
  }
  
  cat("\\end{align}\n")
}


#' Mathematica solutions for the case k=2
#'
#' @param mat_k2 
#' @param gam 
#' @param var_z 
#' @param var_w 
#' @param a_index 
#'
#' @return
#' @export
#'
#' @examples
print_CF_Mathematica_k2 <- function(mat_k2,gam,var_z,var_w,a_index="none") {
  cat("Assuming[{\n")
  if(a_index!="none") {
    text_var_a <- paste0("a",1:3)
    cat(paste(c(paste(c(var_z,text_var_a,gam),collapse = ">0,"),">0,"),collapse = ""),"\n")
    cat(paste(c(paste(c(var_z,text_var_a),collapse = "<1,"),"<1,",gam,"<1"),collapse = ""),"},\n")
  } else {
    cat(paste(c(paste(c(gam,var_z),collapse = ">0,"),">0,",gam,"<1"),collapse = ""),"},\n")
  }
  cat("Solve[{\n")
  for(i in 1:nrow(mat_k2)) for(CF_index in 2:4) {
    text_CF_index <- eq_CF_Mathematica(mat_k2[i,1],mat_k2[i,2],
                                       mat_k2[i,3],mat_k2[i,4],
                                       mat_k2[i,5],mat_k2[i,6],gam,CF_index,a_index) 
    if(a_index!="none") a_index <- a_index+1
    if(i==nrow(mat_k2) & CF_index==4) cat(text_CF_index,"\n") else cat(text_CF_index,",\n")
  }
  if(a_index!="none") {
    text_var_a <- paste(paste0("a",1:a_index),collapse = ",")
    cat("},{",paste(c(var_z,text_var_a,gam),collapse = ","),"}]]\n")
  } else cat("},{",paste(c(var_z,var_w,gam),collapse = ","),"}]]\n")
}




print_CF_k3_LaTeX <- function(mat_k3,mat_k3_Hybrid,mat_k4_NTree_vr_Tree,a_index) {
  
  # NTree vr Tree
  cat("**begin{align}\n")
  a_index <- eq_NTree_vr_Tree(mat_k4_NTree_vr_Tree,Math0_TeX1=1,a_index) 
  cat("**end{align}\n\n")
  
  # Only one taxa from hybrid
  for(i in 1:nrow(mat_k3)) {
    cat("**begin{align}\n")
    for(CF_index in 2:4) {
      text_CF_index <- CF_TeX_text(mat_k3[i,2],mat_k3[i,1],gam,CF_index,
                                   mat_k3[i,4],mat_k3[i,3],mat_k3[i,6],
                                   mat_k3[i,5],in_Z,a_index)
      if(a_index!="none") a_index <- a_index+1
      if(CF_index!=4) cat(text_CF_index,"****\n") else cat(text_CF_index,"\n")
    }
    cat("**end{align}\n\n")
  }
  # Two taxa from hybrid
  cat("**begin{align}\n")
  for(i in 1:nrow(mat_k3_Hybrid)) for(CF_index in 2:4) {
    text_CF_index <- CF_TeX_text_2hybrid(mat_k3_Hybrid[i,1],mat_k3_Hybrid[i,2],
                                         mat_k3_Hybrid[i,3],mat_k3_Hybrid[i,4],
                                         mat_k3_Hybrid[i,5],mat_k3_Hybrid[i,6],
                                         mat_k3_Hybrid[i,7],mat_k3_Hybrid[i,8],
                                         mat_k3_Hybrid[i,9],mat_k3_Hybrid[i,10],
                                         gam,CF_index,in_Z,a_index) 
    if(a_index!="none") a_index <- a_index+1
    if(i==nrow(mat_k3_Hybrid) & CF_index==4) cat(text_CF_index,"\n") else cat(text_CF_index,"****","\n")
  }
  cat("**end{align}")
}


print_CF_Mathematica_k3 <- function(mat_k,mat_k_Hybrid,mat_NTree_vr_Tree,
                                    gam,var_z,var_w,a_index="none") {
  
  cat("Assuming[{\n")
  if(a_index!="none") {
    text_var_a <- paste0("a",1:16)
    cat(paste(c(paste(c(var_z,text_var_a,gam),collapse = ">0,"),">0,"),collapse = ""),"\n")
    cat(paste(c(paste(c(var_z,text_var_a),collapse = "<1,"),"<1,",gam,"<1"),collapse = ""),"},\n")
  } else {
    # cat(paste(c(paste(c(gam,var_z,var_w),collapse = ">0,"),">0,",gam,"<1"),collapse = ""),"},\n")
    
    cat(paste(c(paste(c(var_z,var_w,gam),collapse = ">0,"),">0,"),collapse = ""),"\n")
    cat(paste(c(paste(c(var_z,var_w),collapse = "<1,"),"<1,",gam,"<1"),collapse = ""),"},\n")
  }
  cat("Solve[{\n")
  
  # Tree vr tree case
  a_index <- eq_NTree_vr_Tree(mat_NTree_vr_Tree,Math0_TeX1=0,a_index) 
  
  # Not two hybrid equations 
  for(i in 1:nrow(mat_k)) for(CF_index in 2:4) {
    text_CF_index <- eq_CF_Mathematica(mat_k[i,1],mat_k[i,2],
                                       mat_k[i,3],mat_k[i,4],
                                       mat_k[i,5],mat_k[i,6],gam,CF_index,a_index) 
    
    if(a_index!="none") a_index <- a_index+1
    cat(text_CF_index,",\n")
  }
  
  for(i in 1:nrow(mat_k_Hybrid)) for(CF_index in 2:4) {
    text_CF_index <- eq_CF_Mathematica_2hybrid(mat_k_Hybrid[i,1],mat_k_Hybrid[i,2],
                                               mat_k_Hybrid[i,3],mat_k_Hybrid[i,4],
                                               mat_k_Hybrid[i,5],mat_k_Hybrid[i,6],
                                               mat_k_Hybrid[i,7],mat_k_Hybrid[i,8],
                                               mat_k_Hybrid[i,9],mat_k_Hybrid[i,10],
                                               gam,CF_index,a_index) 
    if(a_index!="none") a_index <- a_index+1
    if(i==nrow(mat_k_Hybrid) & CF_index==4) cat(text_CF_index,"\n") else cat(text_CF_index,",\n")
  }
  
  if(a_index!="none") {
    # text_var_a <- paste(paste0("a",1:(a_index-1)),collapse = ",")
    cat("},{",paste(c(var_z,text_var_a,gam),collapse = ","),"}]]\n")
  } else cat("},{",paste(c(var_z,var_w,gam),collapse = ","),"}]]\n")
  
}



#' Function that tronsfors a vector of numbers t_vec in to the needed text variables
#' for index of Z
#' 
#' For instance, t_vec=c(1,12,10) returs z_{1}z_{12}z_{10}
#'
#'
#' THIS FUNCTION HAS AN ERROR, IT SHOUD ALSO NEED TO HAVE A "K" IMPUT SINCE IT USESE THE VARIABLE "K" IN THE SECOND LINE
#' THIS FUNCTION HAS AN ERROR, IT SHOUD ALSO NEED TO HAVE A "K" IMPUT SINCE IT USESE THE VARIABLE "K" IN THE SECOND LINE
#' THIS FUNCTION HAS AN ERROR, IT SHOUD ALSO NEED TO HAVE A "K" IMPUT SINCE IT USESE THE VARIABLE "K" IN THE SECOND LINE
#' THIS FUNCTION HAS AN ERROR, IT SHOUD ALSO NEED TO HAVE A "K" IMPUT SINCE IT USESE THE VARIABLE "K" IN THE SECOND LINE
#' THIS FUNCTION HAS AN ERROR, IT SHOUD ALSO NEED TO HAVE A "K" IMPUT SINCE IT USESE THE VARIABLE "K" IN THE SECOND LINE
#'
#' @param t_vec 
#' @param Z0_t1 
#' @param TeX0_Mat1 
#'
#' @return
#' @export
#'
#' @examples
e_text <- function(t_vec,K,Z0_t1,TeX0_Mat1) {
  
  # sin this function e_text only works over the index of z and w, we made N0_Z1_W2=1
  N0_Z1_W2 <- 1
  if(TeX0_Mat1==0) t_vec <- change_index_k(K,N0_Z1_W2,t_vec)
  
  if(Z0_t1==0) {
    if(TeX0_Mat1==0) return(paste0("z_{",paste(t_vec,collapse = "}z_{"),"}"))
    if(TeX0_Mat1==1) return(paste0("z",paste(t_vec,collapse = " *z")))
  }
  if(Z0_t1==1) {
    if(TeX0_Mat1==0) return(paste0("e^{",paste0("-t_{",paste(t_vec,collapse = "}-t_{"),"}"),"}"))
  }
  return("Error in exponent_text")
}

#' Function that tronsfors a vector of numbers t_vec in to the needed text variables
#' for index of W
#' 
#' For instance, t_vec=c(1,12,10) returs w_{1}w_{12}w_{10}
#' @param t_vec 
#' @param Z0_t1 
#' @param TeX0_Mat1 
#'
#' @return
#' @export
#'
#' @examples
e_text2 <- function(K,t_vec,Z0_t1,TeX0_Mat1) {
  
  # sin this function e_text2 only works over the index of W and w, we made N0_Z1_W2=2
  N0_Z1_W2 <- 2
  if(TeX0_Mat1==0) t_vec <- change_index_k(K,N0_Z1_W2,t_vec)
  
  if(Z0_t1==0) {
    if(TeX0_Mat1==0) return(paste0("w_{",paste(t_vec,collapse = "}w_{"),"}"))
    if(TeX0_Mat1==1) return(paste0("w",paste(t_vec,collapse = " *w")))
  }
  if(Z0_t1==1) {
    if(TeX0_Mat1==0) return(paste0("e^{",paste0("-u_{",paste(t_vec,collapse = "}-u_{"),"}"),"}"))
  }
  return("Error in e_text2")
}



#' Print equation of CF TeX as page 2 of sup mat
#'
#' @param n_type type of quartet as in sup material page 2
#' @param t1 length of t1
#' @param t2 (if it exist)s
#' @param t3 
#' @param t4 
#' @param Z0_t1 in terms of z or t
#'
#' @return
#' @export
#'
#' @examples
#'in_Z <- F
#'gam <- "\\gamma"
#'
#'TeX0_Mat1 <- 0
#'Z0_t1 <- 1
#'Z0_t1 <- 0
#'
#'
#'t1 <- 11
#'t2 <- 22
#'t3 <- 33
#'t3 <- c(33,32)
#'t4 <- 44
#'
#'uu <- 11
#'uu <- c(2,11)
#'Z0_t1 <- 0
#'Z0_t1 <- 1
TeX_CF_Net <- function(n_type,gam,t1,t2,t3,t4,Z0_t1,uu,n_vec,rep_equations,a_index="none",
                       prin_as_table=F) {
  TeX0_Mat1 <- 0
  if(n_type==1) {
    L1 <- c("(1-",gam,")^2\\left(1-\\dfrac{2}{3}",e_text(c(t1,t2),K,Z0_t1,TeX0_Mat1),"\\right)",
            "+2",gam,"(1-",gam,")\\left(1-",e_text(t1,K,Z0_t1,TeX0_Mat1),"+\\dfrac{1}{3}",e_text(c(t1,t3),K,Z0_t1,TeX0_Mat1),"\\right)",
            "+",gam,"^2\\left(1-\\dfrac{2}{3}",e_text(c(t1,t4),K,Z0_t1,TeX0_Mat1),"\\right)")
    L2 <- c("(1-",gam,")^2\\dfrac{1}{3}",e_text(c(t1,t2),K,Z0_t1,TeX0_Mat1),
            "+",gam,"(1-",gam,")",e_text(t1,K,Z0_t1,TeX0_Mat1),"\\left(1-\\dfrac{1}{3}",e_text(t3,K,Z0_t1,TeX0_Mat1),"\\right)",
            "+",gam,"^2\\dfrac{1}{3}",e_text(c(t1,t4),K,Z0_t1,TeX0_Mat1))
  }
  
  # My type 2 quartet
  if(n_type==2) {
    L1 <- c("(1-",gam,")\\left(1-\\dfrac{2}{3}",e_text(t1,K,Z0_t1,TeX0_Mat1),"\\right)",
            "+",gam,"\\left(1-\\dfrac{2}{3}",e_text(t2,K,Z0_t1,TeX0_Mat1),"\\right)")
    L2 <- c("(1-",gam,")\\dfrac{1}{3}",e_text(t1,K,Z0_t1,TeX0_Mat1),
            "+",gam,"\\dfrac{1}{3}",e_text(t2,K,Z0_t1,TeX0_Mat1))
  }
  
  if(n_type==3) {
    L1 <- c("(1-",gam,")\\left(1-\\dfrac{2}{3}",e_text(t1,K,Z0_t1,TeX0_Mat1),"\\right)",
            "+",gam,"\\dfrac{1}{3}",e_text(t2,K,Z0_t1,TeX0_Mat1))
    L2 <- c("(1-",gam,")\\dfrac{1}{3}",e_text(t1,K,Z0_t1,TeX0_Mat1),
            "+",gam,"\\left(1-\\dfrac{2}{3}",e_text(t2,K,Z0_t1,TeX0_Mat1),"\\right)")
    L3 <- c("(1-",gam,")\\dfrac{1}{3}",e_text(t1,K,Z0_t1,TeX0_Mat1),
            "+",gam,"\\dfrac{1}{3}",e_text(t2,K,Z0_t1,TeX0_Mat1))
  }
  
  if(n_type==4) {
    L1 <- c("(1-",gam,")^2\\left(1-\\dfrac{2}{3}",e_text(c(t1,t2,t3),K,Z0_t1,TeX0_Mat1),"\\right)",
            "+2",gam,"(1-",gam,")\\left(1-\\dfrac{2}{3}",e_text(c(t1,t2),K,Z0_t1,TeX0_Mat1),"\\right)",
            "+",gam,"^2\\left(1-\\dfrac{2}{3}",e_text(c(t1,t2,t4),K,Z0_t1,TeX0_Mat1),"\\right)")
    L2 <- c("(1-",gam,")^2\\dfrac{1}{3}",e_text(c(t1,t2,t3),K,Z0_t1,TeX0_Mat1),
            "+2",gam,"(1-",gam,")\\dfrac{1}{3}",e_text(c(t1,t2),K,Z0_t1,TeX0_Mat1),
            "+",gam,"^2\\dfrac{1}{3}",e_text(c(t1,t2,t4),K,Z0_t1,TeX0_Mat1))
  }
  
  if(n_type==5) {
    L1 <- c("1-\\dfrac{2}{3}",e_text(t1,K,Z0_t1,TeX0_Mat1))
    L2 <- c("\\dfrac{1}{3}",e_text(t1,K,Z0_t1,TeX0_Mat1))
  }
  # Except of quartet 3, all quartets the Concordance factor 2 and 3 are equal
  if(n_type!=3) L3 <- L2
  
  
  if(a_index=="none") {
    R1 <- c("1-\\dfrac{2}{3}",e_text2(K,uu,Z0_t1,TeX0_Mat1))
    R2 <- c("\\dfrac{1}{3}",e_text2(K,uu,Z0_t1,TeX0_Mat1))
    R3 <- R2
  } else {
    # for the type 5 we have only one equation
    (R1 <- paste0("a",a_index))
    a_index <- a_index+1
    
    # Before
    # if(n_type==3 ) { # for the type 3 we have 3 different equations
    if(n_type==3 || rep_equations) { # for the type 3 we have 3 different equations
      (R2 <- paste0("a",a_index))
      a_index <- a_index+1
      (R3 <- paste0("a",a_index))
      a_index <- a_index+1
    } else { # for the types 1,2,4 we have 2 different equations
      (R2 <- paste0("a",a_index))
      a_index <- a_index+1
    }
  }
  
  # The next lines handle the printing
  
  # Change the index of n_vec to the new index order
  # n_vec <- new_index_n(n_vec,K)
  # cat("\n\n",n_vec,"\n\n")
  
  if(rep_equations) {
    if(!prin_as_table) {
      cat("n=",n_vec," Type of network=",n_type,"\n",
          "\\begin{align}\n",paste(c(L1,"&=",R1),collapse = ""),"\\\\ \n",
          paste(c(L2,"&=",R2),collapse = ""),"\\\\ \n",
          paste(c(L3,"&=",R3),collapse = "")," \n",
          "\\end{align}\n") 
    } else {
      cat("$",n_vec,"$ & $",n_type,"$ & $",L1,"$ & $",R1,"$ \\\\ \n",
          " & & $",L2,"$ & $",R2,"$ \\\\ \n",
          " & & $",L3,"$ & $",R3,"$ \\\\ \\hline\n")
    }
    
    # Before
    # cat("n=",n_vec," Type of network=",n_type,"\n",
    #     "\\begin{align}\n",paste(c(L1,"&=",R1),collapse = ""),"\\\\ \n",
    #     paste(c(L2,"&=",R2),collapse = ""),"\\\\ \n",
    #     paste(c(L3,"&=",R3),collapse = "")," \n",
    #     "\\end{align}\n")
    
  } else {
    if(n_type==5) {# for the type 5 we have only one equation
      if(!prin_as_table) {
        cat("n=",n_vec," Type of network=",n_type,"\n",
            "\\begin{align}\n",paste(c(L1,"&=",R1),collapse = "")," \n",
            "\\end{align}\n")
      } else {
        cat("$",n_vec,"$ & $",n_type,"$ & $",L1,"$ & $",R1,"$ \\\\ \\hline\n")
      }
      
    } else if(n_type==3) { # for the type 3 we have 3 different equations
      if(!prin_as_table) {
        cat("n=",n_vec," Type of network=",n_type,"\n",
            "\\begin{align}\n",paste(c(L1,"&=",R1),collapse = ""),"\\\\ \n",
            paste(c(L2,"&=",R2),collapse = ""),"\\\\ \n",
            paste(c(L3,"&=",R3),collapse = "")," \n",
            "\\end{align}\n")
      } else {
        cat("$",n_vec,"$ & $",n_type,"$ & $",L1,"$ & $",R1,"$ \\\\ \n",
            " & & $",L2,"$ & $",R2,"$ \\\\ \n",
            " & & $",L3,"$ & $",R3,"$ \\\\ \\hline\n")
        
      }
    } else { # for the types 1,2,4 we have 2 different equations
      if(!prin_as_table) {
        cat("n=",n_vec," Type of network=",n_type,"\n",
            "\\begin{align}\n",paste(c(L1,"&=",R1),collapse = ""),"\\\\ \n",
            paste(c(L2,"&=",R2),collapse = "")," \n",
            "\\end{align}\n")
      } else {
        cat("$",n_vec,"$ & $",n_type,"$ & $",L1,"$ & $",R1,"$ \\\\ \n",
            " & & $",L2,"$ & $",R2,"$ \\\\ \\hline\n")
      }
    }
  }
  return(a_index)
}



Mat_CF_Net <- function(n_type,gam,t1,t2,t3,t4,uu,rep_equations,a_index,system_eq_for_R=F,
                       grobel_mathematica=F,all_1_but3_2=F) {
  Z0_t1 <- 0
  TeX0_Mat1 <- 1
  if(n_type==1) {
    L1 <- c("(1-",gam,")^2*(1-(2/3)*",e_text(c(t1,t2),K,Z0_t1,TeX0_Mat1),")",
            "+2*",gam,"*(1-",gam,")*(1-",e_text(t1,K,Z0_t1,TeX0_Mat1),"+(1/3)*",e_text(c(t1,t3),K,Z0_t1,TeX0_Mat1),")",
            "+",gam,"^2*(1-(2/3)*",e_text(c(t1,t4),K,Z0_t1,TeX0_Mat1),")")
    L2 <- c("(1-",gam,")^2*(1/3)*",e_text(c(t1,t2),K,Z0_t1,TeX0_Mat1),
            "+",gam,"*(1-",gam,")*",e_text(t1,K,Z0_t1,TeX0_Mat1),"*(1-(1/3)*",e_text(t3,K,Z0_t1,TeX0_Mat1),")",
            "+",gam,"^2*(1/3)*",e_text(c(t1,t4),K,Z0_t1,TeX0_Mat1))
  }
  
  # My type two quartet
  if(n_type==2) {
    L1 <- c("(1-",gam,")*(1-(2/3)*",e_text(t1,K,Z0_t1,TeX0_Mat1),")",
            "+",gam,"*(1-(2/3)*",e_text(t2,K,Z0_t1,TeX0_Mat1),")")
    L2 <- c("(1-",gam,")*(1/3)*",e_text(t1,K,Z0_t1,TeX0_Mat1),
            "+",gam,"*(1/3)*",e_text(t2,K,Z0_t1,TeX0_Mat1))
  }
  
  # As the paper
  # if(n_type==2) {
  #   L1 <- c("(1-",gam,")(1-(2/3)",e_text(t1,Z0_t1,TeX0_Mat1),")",
  #           "+",gam,"(1-(2/3)",e_text(c(t1,t2),Z0_t1,TeX0_Mat1),")")
  #   L2 <- c("(1-",gam,")(1/3)",e_text(t1,Z0_t1,TeX0_Mat1),
  #           "+",gam,"(1/3)",e_text(c(t1,t2),Z0_t1,TeX0_Mat1))
  # }
  
  
  if(n_type==3) {
    L1 <- c("(1-",gam,")*(1-(2/3)*",e_text(t1,K,Z0_t1,TeX0_Mat1),")",
            "+",gam,"*(1/3)*",e_text(t2,K,Z0_t1,TeX0_Mat1))
    L2 <- c("(1-",gam,")*(1/3)*",e_text(t1,K,Z0_t1,TeX0_Mat1),
            "+",gam,"*(1-(2/3)*",e_text(t2,K,Z0_t1,TeX0_Mat1),")")
    L3 <- c("(1-",gam,")*(1/3)*",e_text(t1,K,Z0_t1,TeX0_Mat1),
            "+",gam,"*(1/3)*",e_text(t2,K,Z0_t1,TeX0_Mat1))
  }
  
  if(n_type==4) {
    L1 <- c("(1-",gam,")^2*(1-(2/3)*",e_text(c(t1,t2,t3),K,Z0_t1,TeX0_Mat1),")",
            "+2*",gam,"*(1-",gam,")*(1-(2/3)*",e_text(c(t1,t2),K,Z0_t1,TeX0_Mat1),")",
            "+",gam,"^2*(1-(2/3)*",e_text(c(t1,t2,t4),K,Z0_t1,TeX0_Mat1),")")
    L2 <- c("(1-",gam,")^2*(1/3)*",e_text(c(t1,t2,t3),K,Z0_t1,TeX0_Mat1),
            "+2*",gam,"*(1-",gam,")*(1/3)*",e_text(c(t1,t2),K,Z0_t1,TeX0_Mat1),
            "+",gam,"^2*(1/3)*",e_text(c(t1,t2,t4),K,Z0_t1,TeX0_Mat1))
  }
  
  if(n_type==5) {
    L1 <- c("1-(2/3)*",e_text(t1,K,Z0_t1,TeX0_Mat1))
    L2 <- c("(1/3)*",e_text(t1,K,Z0_t1,TeX0_Mat1))
  }
  # Except of quartet 3, all quartets the Concordance factor 2 and 3 are equal
  if(n_type!=3) L3 <- L2
  
  
  if(a_index=="none") {
    R1 <- c("1-(2/3)*",e_text2(K,uu,Z0_t1,TeX0_Mat1))
    R2 <- c("(1/3)*",e_text2(K,uu,Z0_t1,TeX0_Mat1))
    R3 <- R2
  } else {
    
    if(all_1_but3_2) {
      if(n_type==3 ) { # for the type 3 we have 3 different equations
        (R1 <- paste0("a",a_index))
        a_index <- a_index+1
        (R2 <- paste0("a",a_index))
        a_index <- a_index+1
      } else {
        (R1 <- paste0("a",a_index))
        a_index <- a_index+1
      }
    } else {
      
      if(n_type==3 || rep_equations) { # for the type 3 we have 3 different equations
        (R1 <- paste0("a",a_index))
        a_index <- a_index+1
        (R2 <- paste0("a",a_index))
        a_index <- a_index+1
        if(!only_one_eq_Mat) {
          (R3 <- paste0("a",a_index))
          a_index <- a_index+1
        }
      } else if(n_type==5) {# for the type 5 we have only one equation
        (R1 <- paste0("a",a_index))
        a_index <- a_index+1
        # Before
        # } else if(n_type==3) { # for the type 3 we have 3 different equations
      } else { # for the types 1,2,4 we have 2 different equations
        (R1 <- paste0("a",a_index))
        a_index <- a_index+1
        if(!only_one_eq_Mat) {
          (R2 <- paste0("a",a_index))
          a_index <- a_index+1
        }
      }
    }
    
    
  }
  
  if(system_eq_for_R) {
    text_equality="->" 
    end_coma <- ""
  } else {
    text_equality="==" 
    end_coma <- ","
  }
  if(grobel_mathematica) {
    text_equality="-" 
    end_coma <- ","
  }
  
  if(only_one_eq_Mat || all_1_but3_2) {
    if(n_type==3) { # for the type 3 we have two equations
      cat(paste(c(L1,text_equality,R1),collapse = ""),end_coma,"\n",
          paste(c(L2,text_equality,R2),collapse = ""))
      # paste(c(L2,text_equality,R2),collapse = ""),"\n") # befor it had a last \n
    } else { # for the types 1,2,4,5 we have only one equation
      # cat(paste(c(L1,text_equality,R1),collapse = "")," \n")
      # cat(paste(c(L1,text_equality,R1),collapse = "")) # menos viejo
      cat(paste(c(L2,text_equality,R1),collapse = ""))
    }
    return(a_index)
  }
  
  if(rep_equations) {
    cat(paste(c(L1,text_equality,R1),collapse = ""),end_coma,"\n",
        paste(c(L2,text_equality,R2),collapse = ""),end_coma,"\n",
        paste(c(L3,text_equality,R3),collapse = ""))
    # paste(c(L3,text_equality,R3),collapse = ""),"\n")
    
  } else {
    if(n_type==5) {# for the type 5 we have only one equation
      cat(paste(c(L1,text_equality,R1),collapse = ""))
      # cat(paste(c(L1,text_equality,R1),collapse = "")," \n")
    } else if(n_type==3) { # for the type 3 we have 3 different equations
      cat(paste(c(L1,text_equality,R1),collapse = ""),end_coma,"\n",
          paste(c(L2,text_equality,R2),collapse = ""),end_coma,"\n",
          paste(c(L3,text_equality,R3),collapse = ""))
      # paste(c(L3,text_equality,R3),collapse = ""),"  \n")
    } else { # for the types 1,2,4 we have 2 different equations
      cat(paste(c(L1,text_equality,R1),collapse = ""),end_coma,"\n",
          paste(c(L2,text_equality,R2),collapse = ""))
      # paste(c(L2,text_equality,R2),collapse = ""),"  \n")
    }
  }
  if(system_eq_for_R) cat("\n")
  return(a_index)
}


print_eq_xlsx_N_vr_T <- function(K,Z0_t1,TeX0_Mat1,rep_equations,a_index,
                                 prin_as_table=F,only_one_eq_Mat=F,system_eq_for_R=F,
                                 grobel_mathematica=F,all_1_but3_2=F,N=NULL,Macaulay2=T) {
  
  
  # (file <- paste0("K_",K,"_all_n.xlsx")) # Modificado en gmail
  # eq_k8 <- read.xlsx(xlsxFile = file, skipEmptyRows = FALSE,colNames = T)
  
  l_var <- Initialize_l_var(K,Z0_t1)
  eq_k8 <- l_var$eq_k
  
  
  # Restrictions of possible vectors of N
  if(length(N)!= c(-1,-1,3,4,-1,-1,-1,5)[K] & !is.null(N)) {
    print("Error with the length of N, is different than K; fun print_eq_xlsx_N_vr_T")
    return(-1)
  }
  if(!is.null(N)) {
    if(K==3) eq_k8 <- eq_k8[eq_k8[,1]<=N[1] & eq_k8[,2]<=N[2] & eq_k8[,3]<=N[3],]
    if(K==4) eq_k8 <- eq_k8[eq_k8[,1]<=N[1] & eq_k8[,2]<=N[2] & eq_k8[,3]<=N[3] & eq_k8[,4]<=N[4],,drop=FALSE]
    if(K==8) eq_k8 <- eq_k8[eq_k8[,1]<=N[1] & eq_k8[,2]<=N[2] &eq_k8[,3]<=N[3] & eq_k8[,4]<=N[4] & eq_k8[,5]<=N[5],]
  }
  
  # Parameter gamma to use
  if(TeX0_Mat1==0) gam <- "\\gamma"
  if(TeX0_Mat1==1) gam <- "gam"
  
  # To work for all k, we add this variable
  col_n_type <- ncol(eq_k8)-5
  if(prin_as_table & TeX0_Mat1==0) {
    cat("\\begin{longtable}{@{\\extracolsep{\\fill}}|l|l|l|l|@{}}\n	\\hline\n $ n $ & Type & CF Network  & CF Tree \\\\ \\hline\n")
  } 
  # Before for Mathemathica plot
  # else if(TeX0_Mat1==1 & !system_eq_for_R & !grobel_mathematica) cat("Timing[Solve[{\n")
  
  if(grobel_mathematica & !Macaulay2) cat("LocalTime[] \nTiming[GroebnerBasis[{\n")
  
  
  if(Macaulay2) {
    
    load(file = "mat_index_az.RData")
    if(all_1_but3_2) how_many_eq <- "_sub" else how_many_eq <- "_all"
    K_text <- as.character(K)
    N_text <- paste(N,collapse = "") 
    all_1_but3_2_text <- if(all_1_but3_2) "T" else "F"
    (possible_row <- mat_index_az[mat_index_az[,1]==K_text &
                                    mat_index_az[,2]==N_text &
                                    mat_index_az[,3]==all_1_but3_2_text,,drop=FALSE])
    
    if(nrow(possible_row)==0) {
      var_z_start <- paste0("z",1:4)
      var_a_start <- paste0("a",1:4)
      print("Se recomienda correr una vez mas")
    } else {
      var_z_start <- mat_index_az[mat_index_az[,1]==K_text &
                                    mat_index_az[,2]==N_text &
                                    mat_index_az[,3]==all_1_but3_2_text,4]
      var_a_start <- mat_index_az[mat_index_az[,1]==K_text &
                                    mat_index_az[,2]==N_text &
                                    mat_index_az[,3]==all_1_but3_2_text,5]
    }
    
    text_file_name <- paste0("K",K,how_many_eq,"N",paste(N,collapse = ""),".m2")
    text_to_run <-  paste0("cat ",text_file_name," | M2 &> K",
                           K,how_many_eq,"N",paste(N,collapse = ""),"_out")
    title <- paste0("--------------------------------------------------------\n",
                    "-- Parameters identifiability for the general network --\n",
                    "--------------------------------------------------------\n",
                    "-- file name = ",text_file_name,
                    "\n-- K = ",K,
                    "\n-- How many equations: ",how_many_eq,
                    "\n-- Date of creation: ",format(Sys.time(), "%a %b %d %X %Y"),
                    "\n-- To run in console: ",text_to_run,"\n\n",
                    "\nR = QQ[",gam,",",var_a_start,",",var_z_start,"]
                    \nI = ideal(")
    cat(title)
  }
  
  # SE NECESITA CORREGI ESTA PARTE PARA INCORPORAR LATEX TABLE 
  # SE NECESITA CORREGI ESTA PARTE PARA INCORPORAR LATEX TABLE 
  # SE NECESITA CORREGI ESTA PARTE PARA INCORPORAR LATEX TABLE 
  # SE NECESITA CORREGI ESTA PARTE PARA INCORPORAR LATEX TABLE 
  # SE NECESITA CORREGI ESTA PARTE PARA INCORPORAR LATEX TABLE 
  # SE NECESITA CORREGI ESTA PARTE PARA INCORPORAR LATEX TABLE 
  # SE NECESITA CORREGI ESTA PARTE PARA INCORPORAR LATEX TABLE 
  # SE NECESITA CORREGI ESTA PARTE PARA INCORPORAR LATEX TABLE 
  if(F) { # Test Test Test Test Test Test Test
    
    
    # The next for loops over the rows of the excel file
    i <- 1
    for(i in 1:nrow(eq_k8)) {
      
      # Vector of quartets taken
      n_vec_numbers <- eq_k8[i,1:(col_n_type-1)]
      # print(n_vec_numbers)
      if(TeX0_Mat1==0) n_vec_numbers <- new_index_n(n_vec_numbers,K)
      # print(n_vec_numbers)
      (n_vec <- paste(c("(",paste(n_vec_numbers,collapse=","),")"),collapse = ""))
      
      # Type of network
      n_type <- as.numeric(eq_k8[i,col_n_type],"[,]")
      if(!any(n_type == 1:5)) return("Error: !any(n_type == 1:5)")
      # All types had t1
      t1 <- as.numeric(unlist(strsplit(eq_k8[i,col_n_type+1],"[,]")))
      
      if(n_type %in% c(1,2,3,4)) { # except 5
        t2 <- as.numeric(unlist(strsplit(eq_k8[i,col_n_type+2],"[,]")))
      } else t2 <- "-"
      
      if(n_type %in% c(1,4)) { # only type 1 and 4 had t3 and t4
        t3 <- as.numeric(unlist(strsplit(eq_k8[i,col_n_type+3],"[,]")))
        t4 <- as.numeric(unlist(strsplit(eq_k8[i,col_n_type+4],"[,]")))
      } else {t3 <- "-"; t4 <- "-"}
      # For the tree
      (uu <- as.numeric(unlist(strsplit(eq_k8[i,col_n_type+5],"[,]"))))
      # cat("t1=",t1,"t2=",t2,"t3=",t3,"t4=",t4,"\n")
      
      if(TeX0_Mat1==0){
        a_index <- TeX_CF_Net(n_type,gam,t1,t2,t3,t4,Z0_t1,uu,n_vec,rep_equations,a_index,prin_as_table)
      } 
      if(TeX0_Mat1==1){
        a_index <- Mat_CF_Net(n_type,gam,t1,t2,t3,t4,uu,rep_equations,a_index,
                              system_eq_for_R,grobel_mathematica,all_1_but3_2)
        if(i < nrow(eq_k8)) {
          if(system_eq_for_R) {
            # cat("\n")
          }else {
            cat(",\n")
          }
        }
      }
    }
    
  } # END Test Test Test Test Test Test Test
  # END Test Test Test Test Test Test Test
  # END Test Test Test Test Test Test Test
  # END Test Test Test Test Test Test Test
  # END Test Test Test Test Test Test Test
  
  
  
  # Antes no estaba  comentado, se cambio a mas abajo
  # if(TeX0_Mat1==1) {
  if(K==3) {
    if(only_one_eq_Mat) a_length <- 6 else a_length <- 11
    var_z <- c("z0","z1","z2","z10","z11","z12")
    var_w <- c("w0","w1","w2")
  }
  if(K==4) {
    if(only_one_eq_Mat) a_length <- 19 else a_length <- 33
    var_z <- c("z0","z1","z2","z3","z10","z11","z12","z13")
    var_w <- c("w0","w1","w2","w10","w11","w12","w13")
  }
  if(K==8) {
    if(only_one_eq_Mat) a_length <- 49 else a_length <- 75
    var_z <- c("z0","z1","z2","z3","z4","z5","z6","z7",
               "z10","z11","z12","z13","z17")
    var_w <- c("w0","w1","w3","w4","w5","w6","w7",
               "w10","w11","w12","w13","w17")
  }
  
  # Before
  # var_a <- gsub("\\s+", "", str_trim(paste("a",1:a_length)))
  if(a_index!="none") var_a <- gsub("\\s+", "", str_trim(paste("a",1:(a_index-1))))
  
  if(a_index=="none") var_extra <- var_w else var_extra <- var_a
  
  # Nuevo lugar del if
  if(TeX0_Mat1==1) {
    
    if(!system_eq_for_R & !grobel_mathematica & !Macaulay2) {
      
      l_var <- Gen_eq_mat_text(K,0) 
      l_var$all_1_but3_2 <- all_1_but3_2
      l_var$N <- N
      l_var$N_text <- paste(N,collapse = "") 
      
      l_var <- Gen_SUB_eq_mat_text_AND_SUB_mat_az(l_var)
      
      
      # Starting text
      starting_text <-  paste0('{"K=',K,',  N=',l_var$N_text,'",\n',"Solve[{\n")
      # Paste the needed signs and end-of-line-jumps
      text_eq <- paste(l_var$sub_mat_eq_text[,5],"==",l_var$sub_mat_eq_text[,7],",\n")
      # We take the comma of the last equation
      text_eq[length(text_eq)] <- str_replace( text_eq[length(text_eq)], ",", "")
      
      # Text_eq_Mat_Topo_this_N <- paste(c("Timing[Solve[{\n",text_eq,
      #                                    "},\n{",paste(c(l_var$z_text_in_this_N,"gam"),collapse = ","),
      #                                    "}]]\n"),collapse = "")
      
      if(K==3) this_extra_line_Math_to_TeX <- l_var$Extra_line_Math_to_TeX_K3
      if(K==4) this_extra_line_Math_to_TeX <- l_var$Extra_line_Math_to_TeX_K4
      if(K==8) this_extra_line_Math_to_TeX <- l_var$Extra_line_Math_to_TeX_K8
      end_text <-  paste(c("},\n{",paste(c(l_var$z_text_in_this_N,l_var$w_text_in_this_N,"gam"),collapse = ","),
                           "}]\n",this_extra_line_Math_to_TeX,"}"),collapse = "")
      
      
      l_var$var_w
      
      # l_var$Text_eq_Mat_Topo_this_N <- paste0('Print["K=',K,',  N=',l_var$N_text,'"]\n',Text_eq_Mat_Topo_this_N)
      
      # 'Print["K=',K,',  N=',l_var$N_text,"]'
      
      
      # l_var$Text_eq_Mat_Topo_this_N <- paste0("(* K=",K,", N=",l_var$N_text,"*)\n",Text_eq_Mat_Topo_this_N)
      
      # complete_text <- paste(c(starting_text,text_eq,end_text))
      
      l_var$Text_eq_Mat_Topo_this_N <- paste(c(starting_text,text_eq,end_text))
      cat(l_var$Text_eq_Mat_Topo_this_N)
      
      # cat("---- extra ----\n\n", complete_text)
      
      return(l_var)
    }
    if(grobel_mathematica & !Macaulay2) {
      cat("},{",paste(c(var_z,var_extra,gam),collapse = ","),"},{",
          paste(c(var_z,gam),collapse = ","),"}]]\n")
    }
    
  }
  if(prin_as_table & TeX0_Mat1==0) {
    cat("\\end{longtable}")
  }
  if(Macaulay2) {
    var_z_text <- paste(var_z,collapse = ",")
    cat(");\n\n",
        "G = eliminate(I,{",gam,",",var_z_text,"})\n",
        "dim G")
  }
  
  # saving index for a and z
  
  load(file = "mat_index_az.RData")
  K_text <- as.character(K)
  N_text <- paste(N,collapse = "") 
  all_1_but3_2_text <- if(all_1_but3_2) "T" else "F"
  (possible_row <- mat_index_az[mat_index_az[,1]==K_text &
                                  mat_index_az[,2]==N_text &
                                  mat_index_az[,3]==all_1_but3_2_text,,drop=FALSE])
  # Antes no tenia este if 
  if(a_index!="none") {
    var_a <- gsub("\\s+", "", str_trim(paste("a",1:(a_index-1))))
    var_a_text <- paste(var_a,collapse = ",")
    var_z_text <- paste(var_z,collapse = ",")
  }
  
  if(nrow(possible_row)==0) {
    new_row <- c(K_text,N_text,all_1_but3_2_text,var_z_text,var_a_text)
    mat_index_az <- rbind(mat_index_az,new_row)
  } else {
    mat_index_az[mat_index_az[,1]==K_text &
                   mat_index_az[,2]==N_text &
                   mat_index_az[,3]==all_1_but3_2_text,4:5] <- c(var_z_text,var_a_text)
  }
  rownames(mat_index_az) <- NULL
  mat_index_az
  
  l_var$mat_index_az <- mat_index_az
  # salvado de variables, esto sirve para actualizar el archivo mat_index_az.RData
  cat("\nSaving file mat_index_az.RData\n")
  save(mat_index_az, file = "mat_index_az.RData")
  return(l_var)
}




generate_csv_file <- function(K) {
  
  # if(K==3) n <- expand.grid(0:2,0:2,0:2) 
  if(K==4) n <- expand.grid(0:2,0:2,0:2,0:2) 
  if(K==5) n <- expand.grid(0:2,0:2,0:2,0:2,0:2) 
  n <- as.matrix(n)
  
  indic_sum_4 <- rep(0,nrow(n))
  for(i in 1:nrow(n)) indic_sum_4[i] <- sum(n[i,])==4
  indic_sum_4 <- which(indic_sum_4==1)
  sum(indic_sum_4)
  n <- n[indic_sum_4,]
  
  names_extra_columns <- c("Network type","t1","t2","t3","t4","Tree")
  n_col_extra_trayectorias <- length(names_extra_columns)
  mat_tray <- matrix(rep("-",nrow(n)*n_col_extra_trayectorias),ncol = n_col_extra_trayectorias)
  # colnames(mat_tray) <- c("g","1-g","g2","(1-g)2","g(1-g)","1","Tree")
  colnames(mat_tray) <- names_extra_columns
  
  colnames(n) <- gsub("\\s+", "", str_trim(paste("n",0:(ncol(n)-1))))
  
  n <- cbind(n,mat_tray)
  n <- as.data.frame(n)
  # View(n)
  (file <- paste0("K_",K,"_all_n.csv")) # Modificado en gmail
  
  # Uncomment to make the restart the file
  write_csv(n, path = file)
  cat("The file ",file," was generated")
}


#' Transformation of the idex for K=3,4,8
#'
#' @param K 
#' @param N0_Z1 indicator of changing N or Z with values 0 and 1
#' @param i index that is wanted to be chanlled 
#'
#' @return
#' @export
#'
#' @examples
#' K <- 3
#' K <- 4
#' K <- 8
#' if(K==3) mat_test <- matrix(c(0,0,
#'                               0,1,
#'                               0,2,
#'                               1,0,
#'                               1,1,
#'                               1,2,
#'                               1,10,
#'                               1,11,
#'                               1,12),ncol = 2,byrow = T)
#' if(K==4) mat_test <- matrix(c(0,0,
#'                               0,1,
#'                               0,2,
#'                               0,3,
#'                               1,0,
#'                               1,1,
#'                               1,2,
#'                               1,3,
#'                               1,10,
#'                               1,11,
#'                               1,12,
#'                               1,13),ncol = 2,byrow = T)
#' if(K==8) mat_test <- matrix(c(0,0,
#'                               0,1,
#'                               0,2,
#'                               0,3,
#'                               0,4,
#'                               0,5,
#'                               0,6,
#'                               0,7,
#'                               1,0,
#'                               1,1,
#'                               1,2,
#'                               1,3,
#'                               1,4,
#'                               1,5,
#'                               1,6,
#'                               1,7,
#'                               1,10,
#'                               1,11,
#'                               1,12,
#'                               1,13,
#'                               1,14,
#'                               1,15,
#'                               1,16,
#'                               1,17),ncol = 2,byrow = T)
#' for(ii in 1:nrow(mat_test)) {
#'   print(change_index(K,mat_test[ii,1],mat_test[ii,2]))
#' }
change_index <- function(K,N0_Z1_W2,i) {
  if(K==3) {
    if(N0_Z1_W2==0) {
      return(c(2,1,0)[i+1])
    }
    if(N0_Z1_W2==1) {
      if(i %in% 0:2) return(c("1,2","0,1","0,2")[i+1]) else return(c(2,1,0)[i-9])
    }
    if(N0_Z1_W2==2) { # only for K=3 we have different index for W than the ones for Z
      return(c(2,1,0)[i+1]) 
    }
  }
  if(K==4) {
    if(N0_Z1_W2==0) {
      return(c(2,3,1,0)[i+1])
    }
    if(N0_Z1_W2 %in% 1:2) {
      if(i %in% 0:3) return(c("2,3","1,3","0,1","0,2")[i+1]) else return(c(2,3,1,0)[i-9])
    }
  }
  if(K==8) {
    if(N0_Z1_W2==0) {
      return(c(3,1,0,2,4,6,7,5)[i+1])
    }
    if(N0_Z1_W2 %in% 1:2) {
      if(i %in% 0:7) return(c("1,3","0,1","0,2","2,4","4,6","6,7","5,7","3,5")[i+1]) else return(c(1,0,2,4,6,7,5,3)[i-9])
    }
  }
}


#' Multiple calls of change_index function
#'
#' @param K 
#' @param N0_Z1_W2 
#' @param i_vec 
#'
#' @return
#' @export
#'
#' @examples
change_index_k <- function(K,N0_Z1_W2,i_vec) {
  text_vec <- rep(-1,length(i_vec))
  for(i in 1:length(i_vec)) text_vec[i] <- change_index(K,N0_Z1_W2,i_vec[i])
  return(text_vec)
}



#' Change of a vector n to the new index scheme
#'
#' @param n 
#' @param K 
#'
#' @return
#' @export
#'
#' @examples
new_index_n <- function(n,K) {
  if(K==3) new_order_n <- c(3,2,1)
  if(K==4) new_order_n <- c(4,3,1,2)
  if(K==8) new_order_n <- c(3,2,4,1,5)
  return(n[new_order_n])
}


#' Function to save matrix on RData files
#'
#' @param file_name name of the file where the matrix is saved
#' @param name_matrix mane of the matrix, of instance in the example is name_matrix <- "my_variable"
#' @param vec_identifier vector of the columns to identify
#' @param vec_to_save vector of variables that are saved for the identifiers
#'
#' @return
#' @export
#'
#' @examples
#' file_name <- "test_to_save.RData"
#' name_matrix <- "my_variable"
#' vec_identifier <- c(1,4,7)
#' vec_identifier <- c(1,4,17)
#' vec_to_save <- rep(1,4)
#' 
#' #' para pruebas
#' (my_variable <- matrix(1:21,3,7))
#' save(my_variable,file=file_name)
#' load(file_name)
#' my_variable
#' 
#' upgrade_save(file_name,name_matrix,vec_identifier,vec_to_save)
#' 
#' load(file_name)
#' my_variable
upgrade_save <- function(file_name,name_matrix,vec_identifier,vec_to_save,index_to_substitute=NULL) {
  load(file_name)
  eval(parse(text=paste0("m <- ",name_matrix)))
  # if(ncol(m)!=length(vec_identifier)+length(vec_to_save)) {
  #   print("Error in lengths, ncol(m)!=length(vec_identifier)+length(vec_to_save); upgrade_save")
  #   return(-1)
  # }
  row_to_change <- apply(m[,1:length(vec_identifier)],1,function(x){all(x==vec_identifier)})
  if(any(row_to_change)) m[row_to_change,index_to_substitute] <- vec_to_save else {
    print("falta hacer este caso")
    print(vec_identifier)
    m <- rbind(m,c(vec_identifier,vec_to_save))
  }
  eval(parse(text=paste0(name_matrix," <- m")))
  eval(parse(text=paste0("save(",name_matrix,",file=file_name)")))
}


TeX_CF_Net_v2 <- function(K,l_var,n_type,t1,t2,t3,t4,uu,n_vec) {
  gam <- "\\gamma"
  TeX0_Mat1 <- 0
  Z0_t1 <- l_var$Z0_t1
  if(n_type==1) {
    L1 <- c("(1-",gam,")^2\\left(1-\\dfrac{2}{3}",e_text(c(t1,t2),K,Z0_t1,TeX0_Mat1),"\\right)",
            "+2",gam,"(1-",gam,")\\left(1-",e_text(t1,K,Z0_t1,TeX0_Mat1),"+\\dfrac{1}{3}",e_text(c(t1,t3),K,Z0_t1,TeX0_Mat1),"\\right)",
            "+",gam,"^2\\left(1-\\dfrac{2}{3}",e_text(c(t1,t4),K,Z0_t1,TeX0_Mat1),"\\right)")
    L2 <- c("(1-",gam,")^2\\dfrac{1}{3}",e_text(c(t1,t2),K,Z0_t1,TeX0_Mat1),
            "+",gam,"(1-",gam,")",e_text(t1,K,Z0_t1,TeX0_Mat1),"\\left(1-\\dfrac{1}{3}",e_text(t3,K,Z0_t1,TeX0_Mat1),"\\right)",
            "+",gam,"^2\\dfrac{1}{3}",e_text(c(t1,t4),K,Z0_t1,TeX0_Mat1))
    
  }
  
  # My type 2 quartet
  if(n_type==2) {
    L1 <- c("(1-",gam,")\\left(1-\\dfrac{2}{3}",e_text(t1,K,Z0_t1,TeX0_Mat1),"\\right)",
            "+",gam,"\\left(1-\\dfrac{2}{3}",e_text(t2,K,Z0_t1,TeX0_Mat1),"\\right)")
    L2 <- c("(1-",gam,")\\dfrac{1}{3}",e_text(t1,K,Z0_t1,TeX0_Mat1),
            "+",gam,"\\dfrac{1}{3}",e_text(t2,K,Z0_t1,TeX0_Mat1))
  }
  
  if(n_type==3) {
    L1 <- c("(1-",gam,")\\left(1-\\dfrac{2}{3}",e_text(t1,K,Z0_t1,TeX0_Mat1),"\\right)",
            "+",gam,"\\dfrac{1}{3}",e_text(t2,K,Z0_t1,TeX0_Mat1))
    L2 <- c("(1-",gam,")\\dfrac{1}{3}",e_text(t1,K,Z0_t1,TeX0_Mat1),
            "+",gam,"\\left(1-\\dfrac{2}{3}",e_text(t2,K,Z0_t1,TeX0_Mat1),"\\right)")
    L3 <- c("(1-",gam,")\\dfrac{1}{3}",e_text(t1,K,Z0_t1,TeX0_Mat1),
            "+",gam,"\\dfrac{1}{3}",e_text(t2,K,Z0_t1,TeX0_Mat1))
  }
  
  if(n_type==4) {
    L1 <- c("(1-",gam,")^2\\left(1-\\dfrac{2}{3}",e_text(c(t1,t2,t3),K,Z0_t1,TeX0_Mat1),"\\right)",
            "+2",gam,"(1-",gam,")\\left(1-\\dfrac{2}{3}",e_text(c(t1,t2),K,Z0_t1,TeX0_Mat1),"\\right)",
            "+",gam,"^2\\left(1-\\dfrac{2}{3}",e_text(c(t1,t2,t4),K,Z0_t1,TeX0_Mat1),"\\right)")
    L2 <- c("(1-",gam,")^2\\dfrac{1}{3}",e_text(c(t1,t2,t3),K,Z0_t1,TeX0_Mat1),
            "+2",gam,"(1-",gam,")\\dfrac{1}{3}",e_text(c(t1,t2),K,Z0_t1,TeX0_Mat1),
            "+",gam,"^2\\dfrac{1}{3}",e_text(c(t1,t2,t4),K,Z0_t1,TeX0_Mat1))
  }
  
  if(n_type==5) {
    L1 <- c("1-\\dfrac{2}{3}",e_text(t1,K,Z0_t1,TeX0_Mat1))
    L2 <- c("\\dfrac{1}{3}",e_text(t1,K,Z0_t1,TeX0_Mat1))
  }
  # Except of quartet 3, all quartets the Concordance factor 2 and 3 are equal
  if(n_type!=3) L3 <- L2
  
  L1 <- gsub("\\s+", "", str_trim(L1))
  L2 <- gsub("\\s+", "", str_trim(L2))
  L3 <- gsub("\\s+", "", str_trim(L3))
  
  l_var$mat_eq_text[l_var$i_mat_eq_text,4] <- paste(L1,collapse = "")
  l_var$mat_eq_text[l_var$i_mat_eq_text+1,4] <- paste(L2,collapse = "")
  l_var$mat_eq_text[l_var$i_mat_eq_text+2,4] <- paste(L3,collapse = "")
  
  R1 <- c("1-\\dfrac{2}{3}",e_text2(K,uu,Z0_t1,TeX0_Mat1))
  R2 <- c("\\dfrac{1}{3}",e_text2(K,uu,Z0_t1,TeX0_Mat1=0))
  R3 <- R2
  
  R1 <- gsub("\\s+", "", str_trim(R1))
  R2 <- gsub("\\s+", "", str_trim(R2))
  R3 <- gsub("\\s+", "", str_trim(R3))
  l_var$mat_eq_text[l_var$i_mat_eq_text,6] <- paste(R1,collapse = "")
  l_var$mat_eq_text[l_var$i_mat_eq_text+1,6] <- paste(R2,collapse = "")
  l_var$mat_eq_text[l_var$i_mat_eq_text+2,6] <- paste(R3,collapse = "")
  # Adding z index
  zIndex <- paste(unique(sort(c(t1,t2,t3,t4,"-"))),collapse = ",")
  zIndex <- substr(zIndex,3,nchar(zIndex))
  
  zs <- paste(paste0("z",sort(as.numeric(unlist(strsplit(zIndex, split=',', fixed=TRUE))))),collapse = ",")
  zIndex = paste(sort(as.numeric(unlist(strsplit(zIndex, split=',', fixed=TRUE)))),collapse = ",")
  # Adding w index
  # wIndex <- paste(unique(c(t1,t2,t3,t4,"-")),collapse = ",")
  # wIndex <- substr(wIndex,1,nchar(wIndex)-2)
  ws <- paste(paste0("w",sort(uu)),collapse = ",")
  wIndex <- paste(sort(uu),collapse = ",")
  
  # print(wIndex)
  # print(zIndex)
  l_var$mat_eq_text[(l_var$i_mat_eq_text):(l_var$i_mat_eq_text+l_var$eq_x_type-1),10] <- zs
  l_var$mat_eq_text[(l_var$i_mat_eq_text):(l_var$i_mat_eq_text+l_var$eq_x_type-1),11] <- zIndex
  l_var$mat_eq_text[(l_var$i_mat_eq_text):(l_var$i_mat_eq_text+l_var$eq_x_type-1),12] <- ws
  l_var$mat_eq_text[(l_var$i_mat_eq_text):(l_var$i_mat_eq_text+l_var$eq_x_type-1),13] <- wIndex
  return(l_var)
}


Mat_CF_Net_v2 <- function(K,l_var,n_type,t1,t2,t3,t4,uu,n_vec) {
  Z0_t1 <- 0
  TeX0_Mat1 <- 1
  gam <- "gam"
  if(n_type==1) {
    L1 <- c("(1-",gam,")^2*(1-(2/3)*",e_text(c(t1,t2),K,Z0_t1,TeX0_Mat1),")",
            "+2*",gam,"*(1-",gam,")*(1-",e_text(t1,K,Z0_t1,TeX0_Mat1),"+(1/3)*",e_text(c(t1,t3),K,Z0_t1,TeX0_Mat1),")",
            "+",gam,"^2*(1-(2/3)*",e_text(c(t1,t4),K,Z0_t1,TeX0_Mat1),")")
    L2 <- c("(1-",gam,")^2*(1/3)*",e_text(c(t1,t2),K,Z0_t1,TeX0_Mat1),
            "+",gam,"*(1-",gam,")*",e_text(t1,K,Z0_t1,TeX0_Mat1),"*(1-(1/3)*",e_text(t3,K,Z0_t1,TeX0_Mat1),")",
            "+",gam,"^2*(1/3)*",e_text(c(t1,t4),K,Z0_t1,TeX0_Mat1))
  }
  
  # My type two quartet
  if(n_type==2) {
    L1 <- c("(1-",gam,")*(1-(2/3)*",e_text(t1,K,Z0_t1,TeX0_Mat1),")",
            "+",gam,"*(1-(2/3)*",e_text(t2,K,Z0_t1,TeX0_Mat1),")")
    L2 <- c("(1-",gam,")*(1/3)*",e_text(t1,K,Z0_t1,TeX0_Mat1),
            "+",gam,"*(1/3)*",e_text(t2,K,Z0_t1,TeX0_Mat1))
  }
  
  
  if(n_type==3) {
    L1 <- c("(1-",gam,")*(1-(2/3)*",e_text(t1,K,Z0_t1,TeX0_Mat1),")",
            "+",gam,"*(1/3)*",e_text(t2,K,Z0_t1,TeX0_Mat1))
    L2 <- c("(1-",gam,")*(1/3)*",e_text(t1,K,Z0_t1,TeX0_Mat1),
            "+",gam,"*(1-(2/3)*",e_text(t2,K,Z0_t1,TeX0_Mat1),")")
    L3 <- c("(1-",gam,")*(1/3)*",e_text(t1,K,Z0_t1,TeX0_Mat1),
            "+",gam,"*(1/3)*",e_text(t2,K,Z0_t1,TeX0_Mat1))
  }
  
  if(n_type==4) {
    L1 <- c("(1-",gam,")^2*(1-(2/3)*",e_text(c(t1,t2,t3),K,Z0_t1,TeX0_Mat1),")",
            "+2*",gam,"*(1-",gam,")*(1-(2/3)*",e_text(c(t1,t2),K,Z0_t1,TeX0_Mat1),")",
            "+",gam,"^2*(1-(2/3)*",e_text(c(t1,t2,t4),K,Z0_t1,TeX0_Mat1),")")
    L2 <- c("(1-",gam,")^2*(1/3)*",e_text(c(t1,t2,t3),K,Z0_t1,TeX0_Mat1),
            "+2*",gam,"*(1-",gam,")*(1/3)*",e_text(c(t1,t2),K,Z0_t1,TeX0_Mat1),
            "+",gam,"^2*(1/3)*",e_text(c(t1,t2,t4),K,Z0_t1,TeX0_Mat1))
  }
  
  if(n_type==5) {
    L1 <- c("1-(2/3)*",e_text(t1,K,Z0_t1,TeX0_Mat1))
    L2 <- c("(1/3)*",e_text(t1,K,Z0_t1,TeX0_Mat1))
  }
  # Except of quartet 3, all quartets the Concordance factor 2 and 3 are equal
  if(n_type!=3) L3 <- L2
  
  L1 <- gsub("\\s+", "", str_trim(L1))
  L2 <- gsub("\\s+", "", str_trim(L2))
  L3 <- gsub("\\s+", "", str_trim(L3))
  
  l_var$mat_eq_text[l_var$i_mat_eq_text,5] <- paste(L1,collapse = "")
  l_var$mat_eq_text[l_var$i_mat_eq_text+1,5] <- paste(L2,collapse = "")
  l_var$mat_eq_text[l_var$i_mat_eq_text+2,5] <- paste(L3,collapse = "")
  
  R1 <- c("1-(2/3)*",e_text2(K,uu,Z0_t1,TeX0_Mat1))
  R2 <- c("(1/3)*",e_text2(K,uu,Z0_t1,TeX0_Mat1))
  R3 <- R2
  
  R1 <- gsub("\\s+", "", str_trim(R1))
  R2 <- gsub("\\s+", "", str_trim(R2))
  R3 <- gsub("\\s+", "", str_trim(R3))
  
  l_var$mat_eq_text[l_var$i_mat_eq_text,7] <- paste(R1,collapse = "")
  l_var$mat_eq_text[l_var$i_mat_eq_text+1,7] <- paste(R2,collapse = "")
  l_var$mat_eq_text[l_var$i_mat_eq_text+2,7] <- paste(R3,collapse = "")
  return(l_var)
} 

index_of_z_and_w <- function(l_var) {
  if(l_var$K==3) {
    l_var$var_z <- c("z0","z1","z2","z10","z11","z12")
    l_var$var_w <- c("w0","w1","w2")
  }
  if(l_var$K==4) {
    l_var$var_z <- c("z0","z1","z2","z3","z10","z11","z12","z13")
    l_var$var_w <- c("w0","w1","w2","w10","w11","w12","w13")
  }
  if(l_var$K==8) {
    l_var$var_z <- c("z0","z1","z2","z3","z4","z5","z6","z7",
                     "z10","z11","z12","z13","z17")
    l_var$var_w <- c("w0","w1","w3","w4","w5","w6","w7",
                     "w10","w11","w12","w13","w17")
  }
  return(l_var)
}


#' Initialization of the list l_var
#'
#' @param K number of nodes in the hybrid cycle
#' @param Z0_t1 parametrization; if it is 0 is in terms of z, if is 1 is in terms of t
#'
#' @return returns the list l_var with the variables:
#'     possible_N_K3,4,8 = a matrix with all the possible combinations of taxa comming from each node
#'         of the hybrid cycle to form a quartet
#'    file_tasks = file of xlsx with the tasks to do
#'    list_m2_files = existing Maculay2 files
#'    eq_k = information from the xlsx file with all the possible quartet equations; this gives the type of
#'         quartet and the branch length for each quartet
#'    Extra_line_Math_to_TeX_K3,4,8 = extra lines to add to Mathematica files to run the Solve function
#' @export
#'
#' @examples
Initialize_l_var <- function(K,Z0_t1) {
  l_var <- list(Z0_t1=Z0_t1,K=K)
  l_var$possible_N_K3 <- matriz_possible_N(3)
  l_var$possible_N_K4 <- matriz_possible_N(4)
  l_var$possible_N_K8 <- matriz_possible_N(8)
  
  
  l_var$mat_N_quartet_allowed <- matrix(c(1,1,1,2,
                                          1,1,2,2,
                                          1,2,2,2,
                                          2,2,2,2),ncol=4,byrow = T)
  
  # Finding the path of where tu put the Macalay2 files
  rutas_prueba <- c("/Users/arrigocoen/Dropbox","/Users/useradmin/Dropbox","","")
  eleccion_compu <- which(file.exists(rutas_prueba))
  l_var$folder_Macaulay2 <- c("/Users/arrigocoen/Dropbox/1 Phylogenetics/2019/Ransanec/Mathematica/macaulay2/",
                              "/Users/useradmin/Dropbox/1 Phylogenetics/2019/Ransanec/Mathematica/macaulay2/",
                              "",
                              "")[eleccion_compu]
  
  l_var$file_tasks <- paste0(l_var$folder_Macaulay2,"Tasks_organizer.xlsx")
  l_var$list_m2_files <- list.files(l_var$folder_Macaulay2,pattern="*.m2")
  
  # Xlsx files
  (text_fileName <- paste0("K_",K,"_all_n.xlsx")) # Modificado en gmail
  (text_sheetName <- paste0("K_",K,"_all_n"))
  # eq_k <- read.xlsx(text_fileName, sheetName = text_sheetName,skipEmptyRows = FALSE,colNames = T)
  l_var$eq_k <- read.xlsx(text_fileName, sheetName = text_sheetName)
  
  # Extra line to transform from Mathematica to TeX
  l_var$Extra_line_Math_to_TeX_K3 <- "/.{gam-> \\[Gamma],w0->Subscript[w, 2],w1->Subscript[w, 1],w2->Subscript[w, 0],z0-> Subscript[z, 1,2],z1-> Subscript[z, 0,1],z2-> Subscript[z, 0,2],z10-> Subscript[z, 2],z11-> Subscript[z, 1],z12-> Subscript[z, 0]}"
  l_var$Extra_line_Math_to_TeX_K4 <- "/.{gam-> \\[Gamma],
w0-> Subscript[w, 2,3],w1-> Subscript[w, 1,3],w2-> Subscript[w, 0,1],w3-> Subscript[w, 0,2],
w10-> Subscript[w, 2],w11-> Subscript[w, 3],w12-> Subscript[w, 1],w13-> Subscript[w, 0],
z0-> Subscript[z, 2,3],z1-> Subscript[z, 1,3],z2-> Subscript[z, 0,1],z3-> Subscript[z, 0,2],
z10-> Subscript[z, 2],z11-> Subscript[z, 3],z12-> Subscript[z, 1],z13-> Subscript[z, 0]}"
  l_var$Extra_line_Math_to_TeX_K8 <- "/.{gam -> \\[Gamma],
 w0 -> Subscript[w, 1, 3], w1 -> Subscript[w, 0, 1], 
 w2 -> Subscript[w, 0, 2], w3 -> Subscript[w, 2, 4], 
 w4 -> Subscript[w, 4, 6], w5 -> Subscript[w, 6, 7], 
 w6 -> Subscript[w, 5, 7], w7 -> Subscript[w, 3, 5],
 w10 -> Subscript[w, 1], w11 -> Subscript[w, 0], 
 w12 -> Subscript[w, 2], w13 -> Subscript[w, 4], 
 w14 -> Subscript[w, 6], w15 -> Subscript[w, 7], 
 w16 -> Subscript[w, 5], w17 -> Subscript[w, 3],
 z0 -> Subscript[z, 1, 3], z1 -> Subscript[z, 0, 1], 
 z2 -> Subscript[z, 0, 2], z3 -> Subscript[z, 2, 4], 
 z4 -> Subscript[z, 4, 6], z5 -> Subscript[z, 6, 7], 
 z6 -> Subscript[z, 5, 7], z7 -> Subscript[z, 3, 5],
 z10 -> Subscript[z, 1], z11 -> Subscript[z, 0], 
 z12 -> Subscript[z, 2], z13 -> Subscript[z, 4], 
 z14 -> Subscript[z, 6], z15 -> Subscript[z, 7], 
 z16 -> Subscript[z, 5], z17 -> Subscript[z, 3]}"
  
  return(l_var)
}

#' Generation of the equations of TeX and Mathematica
#'
#' @param K number of nodes in the hybrid cycle; could be 3,4 or 8.
#' @param Z0_t1 if its 0 then the equations are in terms of the z variables, and if its 1 are 
#' in terms of the t variables. In particular, z=e^-t where t is the branch lengths.
#'
#' @return a list named l_var with all the information needed for the quartet equations (see 
#' function Initialize_l_var), and in particular with the matrix l_var$mat_eq_text in which the
#' columns are:
#'        "i" = index of the equation
#'        "n" = number of taxa comming from each of the k nodes to form the quartet
#'        "EqType" = type of he equation   
#'        "EqNetTex" = Equations for the network in TeX notation
#'        "EqNetMat" = Equations for the network in Mathematica y Maculay2 notation
#'        "EqTreTeX" = Equations for the tree in TeX notation
#'        "EqTreMat" = Equations for the tree in Mathematica y Maculay2 notation
#'        "aTeX"     = variable of the concordance factor in TeX notation
#'        "aMat"     = variable of the concordance factor in Mathematica y Maculay2 notation
#'        "z's"      = Variables z involved on the network
#'        "zIndex"   = Index of the variables z involved on the network
#'        "w's"      = Variables w involved on the tree
#'        "wIndex"   = Index of the variables w involved on the tree
#'        
#' @export
#'
#' @examples
Gen_eq_mat_text <- function(K,Z0_t1) {
  # Names of the needed xlsx files
  (text_fileName <- paste0("K_",K,"_all_n.xlsx")) 
  (text_sheetName <- paste0("K_",K,"_all_n"))
  # In case of not having the proper Excel version, uncomment these next lines
  # file.exists(text_fileName)
  # eq_k <- read.xlsx(text_fileName, sheetName = text_sheetName,skipEmptyRows = FALSE,colNames = T)
  # In case of desktop use this
  eq_k <- read.xlsx(text_fileName, sheetName = text_sheetName)
  # In case of laptop work use this
  # eq_k <- read.xlsx(text_fileName)
  eq_x_type <- 3
  col_names_mat_eq_text <- c("i","n","EqType","EqNetTex","EqNetMat","EqTreTeX","EqTreMat","aTeX","aMat","z's","zIndex","w's","wIndex")
  # Each quartet has 3 equations (eq_x_type is for future quintets of sixtets or n-tets)
  
  mat_eq_text <- matrix("",nrow(eq_k)*eq_x_type,length(col_names_mat_eq_text))
  colnames(mat_eq_text) <- col_names_mat_eq_text
  i_mat_eq_text <- 1
  # To work for all k, we add this variable
  col_n_type <- ncol(eq_k)-5
  a_index <- 1
  l_var <- Initialize_l_var(K,Z0_t1)
  l_var$mat_eq_text <- mat_eq_text
  l_var$i_mat_eq_text <- 1
  l_var$eq_x_type <- eq_x_type
  l_var <- index_of_z_and_w(l_var)
  
  for(i in 1:nrow(eq_k)) {
    # print(i)
    # Vector of quartets taken
    (n_vec_numbers <- eq_k[i,1:(col_n_type-1)])
    
    # OJO ANTES ERA ASI, NO SE POR QUE SOLO LO LAMBIABA PARA TEX Y NO PARA MAT
    # if(TeX0_Mat1==0) n_vec_numbers <- new_index_n(n_vec_numbers,K)
    # if(TeX0_Mat1==0) n_vec_numbers <- new_index_n(n_vec_numbers,K)
    # if(TeX0_Mat1==0) n_vec_numbers <- new_index_n(n_vec_numbers,K)
    # AHORA ES ASI (CAMBIO EL INDICE DE N TANTO PARA TEX COMO PARA MAT)
    n_vec_numbers <- new_index_n(n_vec_numbers,K)
    
    # print(n_vec_numbers)
    (n_vec <- paste(c("(",paste(n_vec_numbers,collapse=","),")"),collapse = ""))
    
    # Type of network
    n_type <- as.numeric(eq_k[i,col_n_type],"[,]")
    if(!any(n_type == 1:5)) return("Error: !any(n_type == 1:5)")
    # All types had t1
    t1 <- as.numeric(unlist(strsplit(eq_k[i,col_n_type+1],"[,]")))
    
    if(n_type %in% c(1,2,3,4)) { # except 5
      t2 <- as.numeric(unlist(strsplit(eq_k[i,col_n_type+2],"[,]")))
    } else t2 <- "-"
    
    if(n_type %in% c(1,4)) { # only type 1 and 4 had t3 and t4
      t3 <- as.numeric(unlist(strsplit(eq_k[i,col_n_type+3],"[,]")))
      t4 <- as.numeric(unlist(strsplit(eq_k[i,col_n_type+4],"[,]")))
    } else {t3 <- "-"; t4 <- "-"}
    # For the tree
    (uu <- as.numeric(unlist(strsplit(eq_k[i,col_n_type+5],"[,]"))))
    # cat("t1=",t1,"t2=",t2,"t3=",t3,"t4=",t4,"\n")
    l_var$mat_eq_text[l_var$i_mat_eq_text:(l_var$i_mat_eq_text+l_var$eq_x_type-1),1] <- l_var$i_mat_eq_text:(l_var$i_mat_eq_text+l_var$eq_x_type-1)
    l_var$mat_eq_text[l_var$i_mat_eq_text:(l_var$i_mat_eq_text+l_var$eq_x_type-1),2] <- n_vec
    l_var$mat_eq_text[l_var$i_mat_eq_text:(l_var$i_mat_eq_text+l_var$eq_x_type-1),3] <- n_type
    l_var <- TeX_CF_Net_v2(K,l_var,n_type,t1,t2,t3,t4,uu,n_vec)
    l_var <- Mat_CF_Net_v2(K,l_var,n_type,t1,t2,t3,t4,uu,n_vec)
    # Saving index z and w
    l_var$i_mat_eq_text <- l_var$i_mat_eq_text+l_var$eq_x_type
  }    
  l_var$mat_eq_text[,8] <- paste0("a_{",1:nrow(l_var$mat_eq_text),"}")
  l_var$mat_eq_text[,9] <- paste0("a",1:nrow(l_var$mat_eq_text))
  return(l_var)
}


Get_text_eq <- function(l_var) {
  # sub_mat_eq_text considers a subset of rows depending on the parameters
  (l_var$sub_mat_eq_text <- l_var$mat_eq_text)
  
  if(l_var$all_1_but3_2) {
    # Subset of one eq for types 1,2,4,5 and two for type 3
    (valid_i <- rep(F,nrow(l_var$sub_mat_eq_text)))
    i <- 1; while(i < nrow(l_var$sub_mat_eq_text)) {
      if(l_var$sub_mat_eq_text[i,3]!="3") valid_i[i:(i+2)] <- c(F,T,F) else valid_i[i:(i+2)] <- c(F,T,T)
      i <- i+3
    }
    (l_var$sub_mat_eq_text <- l_var$sub_mat_eq_text[valid_i,])
  }
  
  # Subset of vectors n that are less than N
  if(!is.null(l_var$N)) {
    if(length(l_var$N)!=l_var$K & K %in% 3:4) { print("Error length(l_var$N)!=l_var$K; Get_text_eq"); return(l_var)}
    if(length(l_var$N)!=5 & K ==8) { print("Error length(l_var$N)!=l_var$K; Get_text_eq"); return(l_var)}
    valid_i <- rep(F,nrow(l_var$sub_mat_eq_text))
    for(i in 1:nrow(l_var$sub_mat_eq_text)) {
      # substr(l_var$sub_mat_eq_text[i,2],2,nchar(l_var$sub_mat_eq_text[i,2])-1)
      (n_nureric <- as.numeric(unlist(strsplit(substr(l_var$sub_mat_eq_text[i,2],2,nchar(l_var$sub_mat_eq_text[i,2])-1), "[,]")) ))
      # l_var$N
      valid_i[i] <- all(n_nureric<=l_var$N)
    }
    l_var$sub_mat_eq_text <- l_var$sub_mat_eq_text[valid_i,,drop=F]
  }
  
  length(l_var$sub_mat_eq_text)
  
  if(l_var$text_type == "Macaulay2") {
    if(l_var$all_1_but3_2) how_many_eq <- "_sub" else how_many_eq <- "_all"
    K_text <- as.character(l_var$K)
    N_text <- paste(l_var$N,collapse = "") 
    all_1_but3_2_text <- if(l_var$all_1_but3_2) "T" else "F"
    text_file_name <- paste0("K",l_var$K,how_many_eq,"N",paste(l_var$N,collapse = ""),".m2")
    text_to_run <-  paste0("cat ",text_file_name," | M2 &> K",
                           l_var$K,how_many_eq,"N",paste(l_var$N,collapse = ""),"_out.txt")
    (a_text_in_this_eq <- paste(l_var$sub_mat_eq_text[,9],collapse = ","))
    
    (z_text_in_this_eq <- paste(l_var$sub_mat_eq_text[,11],collapse = ","))
    z_text_in_this_eq <- paste(paste0("z",sort(unique(as.numeric(unlist(strsplit(z_text_in_this_eq, split=',', fixed=TRUE)))))),collapse = ",")
    # (z_text_in_this_eq <- paste0("z",(l_var$sub_mat_eq_text[,11])))
    
    ini_text <- paste0("--------------------------------------------------------\n",
                       "-- Parameters identifiability for the general network --\n",
                       "--------------------------------------------------------\n",
                       "-- file name = ",text_file_name,
                       "\n-- K = ",K,
                       "\n-- How many equations: ",how_many_eq,
                       "\n-- Date of creation: ",format(Sys.time(), "%a %b %d %X %Y"),
                       "\n-- To run in console: ",text_to_run,
                       "\n-- For K = ",K," are ",nrow(l_var$mat_eq_text)," equations but we only consider here ",nrow(l_var$sub_mat_eq_text),
                       "\n-- a's = ",a_text_in_this_eq,
                       "\n-- z's = ",z_text_in_this_eq,
                       "\n\n",
                       "\nR = QQ[gam",",",a_text_in_this_eq,",",z_text_in_this_eq,"]
                    \nI = ideal(")
    
    eqs_text <- paste(paste0(l_var$sub_mat_eq_text[,5],"-",l_var$sub_mat_eq_text[,9],",\n"),collapse = "")
    eqs_text <- substr(eqs_text,1,nchar(eqs_text)-2) # this line erases the last coma
    fin_text <- paste0(");\n\n",
                       "G = eliminate(I,{gam",",",paste(z_text_in_this_eq,collapse=","),"})\n",
                       "dim G ")
    
    (l_var$text_to_save <- c(ini_text,eqs_text,fin_text))
    # cat(l_var$text_to_save)
    # Generating Macaulay2 file 
    (l_var$folder_Macaulay2_file <- paste0(l_var$folder_Macaulay2,text_file_name))
    fileConn<-file(l_var$folder_Macaulay2_file)
    writeLines(l_var$text_to_save, fileConn)
    close(fileConn)
    # cat("The file ",text_file_name," is saved on ",l_var$folder_Macaulay2_file,"\n")
    cat("The file ",text_file_name," is saved \n")
  }
  
  if(l_var$text_type == "TeXTable") {
    
  }
  
  return(l_var)
}


Gen_All_Macalay2 <- function(K,Z0_t1=0) {
  # Starting the list of variables
  l_var <- Gen_eq_mat_text(K,Z0_t1) 
  l_var$text_type <- "Macaulay2"
  
  # Depending of how long N is...
  if(l_var$K==3)  l <- list(n0 = 1:2, n1 = 1:2, n2 = 1:2)
  if(l_var$K==4)  l <- list(n0 = 1:2, n1 = 1:2, n2 = 1:2, n3 = 1:2)
  if(l_var$K==8)  l <- list(n0 = 1:2, n1 = 1:2, n2 = 1:2, n3 = 1:2, n4 = 1:2)
  # Matrix which rows are all possibel combinations for N
  N_posible_mat <- as.matrix(expand.grid(l))[-1,] # eliminate the case with only ones
  
  
  for(all_1_but3_2 in c(T,F)) {
    l_var$all_1_but3_2 <- all_1_but3_2
    # The null case # not needed anymore since is equivalent to all 2s
    # l_var$N <- NULL
    # l_var <- Get_text_eq(l_var)
    
    # The non-null cases
    # Possible with one 1
    for(i in 1:nrow(N_posible_mat)) {
      # Changing the place of the one
      l_var$N <- N_posible_mat[i,]
      l_var <- Get_text_eq(l_var)
    }
  }
  cat("In the path ",l_var$folder_Macaulay2,"\n")
  return(l_var)
}

# Gen_All_Macalay2_K348 <- function(Z0_t1=0) {
#   for(K in c(3,4,8)) l_var <- Gen_All_Macalay2(K,Z0_t1) 
#   return(l_var)
# }

transform_ideal_text <- function(new_ideal) {
  if(new_ideal=="o3 = ideal ()") return("\\item o3 = ideal ()\n")
  (new_ideal <- new_ideal)
  (new_ideal <- gsub("\\s+", "", str_trim(new_ideal)))
  (new_ideal <- substr(new_ideal,10,nchar(new_ideal)-1))
  
  (vec_new_ideal <- unlist(strsplit(new_ideal, "[,]")) )
  
  i <- 1
  # aux_max_number helps to find out the possible larger index of a's,
  matches <- regmatches(new_ideal, gregexpr("[[:digit:]]+", new_ideal)) # sin "+" se regresa un vector con cada dígito
  aux_max_number <- max(as.numeric(unlist(matches)))
  
  for(i in 1:length(vec_new_ideal)) {
    
    
    for(number_to_change in aux_max_number:1) {
      a_old <- paste0("a",number_to_change)
      a_new <- paste0("a_{",number_to_change,"}")
      # how_many_commas <- which(strsplit(B, "")[[1]]=="a")
      
      vec_new_ideal[i] <- str_replace_all(vec_new_ideal[i], a_old,a_new)
      # new_ideal <- str_replace(a_old,a_new,new_ideal)
    }
  }
  (new_ideal <- paste("\\item $",vec_new_ideal,"$ \n"))
  return(new_ideal)
}


transform_dim_G_text <- function(dim_G) {
  new_dim_G <- dim_G
  new_dim_G <- gsub("\\s+", "", str_trim(new_dim_G))
  new_dim_G <- substr(new_dim_G,4,nchar(new_dim_G))
  return(new_dim_G)
}


#' Title
#'
#' @param K 
#' @param N 
#' @param all_1_but3_2 
#' @param Locally0_Terminal1 
#'
#' @return
#' @export
#'
#' @examples
#' 
#' Locally0_Terminal1 <- 0
#' 
#' K <- 3
#' N <- 112
#' all_1_but3_2 <- F
#' all_1_but3_2 <- T
print_commands_terminal <- function(K,N,all_1_but3_2,Locally0_Terminal1) {
  rutas_prueba <- c("/Users/arrigocoen/Dropbox","/Users/useradmin/Dropbox","","")
  eleccion_compu <- which(file.exists(rutas_prueba))
  folder_Macaulay2 <- c("/Users/arrigocoen/Dropbox/1 Phylogenetics/2019/Ransanec/Mathematica/macaulay2/",
                        "/Users/useradmin/Dropbox/1 Phylogenetics/2019/Ransanec/Mathematica/macaulay2/",
                        "",
                        "")[eleccion_compu]
  
  if(all_1_but3_2) how_many_eq <- "_sub" else how_many_eq <- "_all"
  
  if(Locally0_Terminal1==0) {
    (text_file_name <- paste0("K",K,how_many_eq,"N",paste(N,collapse = "")))
    text_to_run <-  paste0("cat ",text_file_name,".m2 | M2 &> ",text_file_name,"_out.txt")
    
    cat("cd","\"")
    cat(folder_Macaulay2)
    cat("\"","\n")
    cat(text_to_run,"\n")
  }
  
  if(Locally0_Terminal1==1) {
    if(all_1_but3_2) how_many_eq2 <- "sub" else how_many_eq2 <- "all"
    text_shell_N <- paste0("\n```shell\nscreen -S K",K,how_many_eq2,"N",N,
                           "\nmodule load M2-1.14",
                           "\ncat K",K,"_",how_many_eq2,"N",N,".m2 | M2 &> K",K,"_",how_many_eq2,"N",N,"_out.txt",
                           "\n```\nStart on ",format(Sys.time(), "%a %b %d"),
                           "\n```shell\nscreen -r K",K,how_many_eq2,"N",N,
                           "\n```")
    cat(text_shell_N)
  }
}



#' Title
#'
#' @param K 
#'
#' @return
#' @export
#'
#' @examples
#' matriz_possible_N(3)
matriz_possible_N <- function(K) {
  # Depending of how long N is...
  if(K==3)  l <- list(n0 = 1:2, n1 = 1:2, n2 = 1:2)
  if(K==4)  l <- list(n0 = 1:2, n1 = 1:2, n2 = 1:2, n3 = 1:2)
  if(K==8)  l <- list(n0 = 1:2, n1 = 1:2, n2 = 1:2, n3 = 1:2, n4 = 1:2)
  # Matrix which rows are all possibel combinations for N
  N_posible_mat <- as.matrix(expand.grid(l))[-1,] # eliminate the case with only ones
  return(N_posible_mat)
}


#' Title
#'
#' @param K 
#' @param all_1_but3_2 
#' @param Locally0_Terminal1 
#'
#' @return
#' @export
#'
#' @examples
#' Locally0_Terminal1 <- 0
#' K <- 3
#' all_1_but3_2 <- F
#' all_1_but3_2 <- T
print_for_all_N_commands_terminal <- function(K,all_1_but3_2,Locally0_Terminal1) {
  mat_N <- matriz_possible_N(K)
  
  if(Locally0_Terminal1==1) {
    text_shell_N <- paste0("\n```shell",
                           "\nssh acoencoria@solislemus-001.discovery.wisc.edu",
                           "\ncd /mnt/dv/wid/projects1/SolisLemus-ArrigoCC/",
                           "\n```")
    cat(text_shell_N)
  }  
  for(i in 1:nrow(mat_N)) {
    cat("\n-----------\nN =",paste(mat_N[i,],collapse=""),"\n\n")
    print_commands_terminal(K,paste(mat_N[i,],collapse=""),all_1_but3_2,Locally0_Terminal1)
  }
}


#' Title
#'
#' @param all_1_but3_2 
#'
#' @return
#' @export
#'
#' @examples
#' Locally0_Terminal1 <- 1
#' Locally0_Terminal1 <- 0
#' K <- 8
#' K <- 4
#' K <- 3
#' 
#' all_1_but3_2 <- F
#' all_1_but3_2 <- T
print_all_local_fast_files <- function(all_1_but3_2,fast) {
  rutas_prueba <- c("/Users/arrigocoen/Dropbox","/Users/useradmin/Dropbox","","")
  eleccion_compu <- which(file.exists(rutas_prueba))
  folder_Macaulay2 <- c("/Users/arrigocoen/Dropbox/1 Phylogenetics/2019/Ransanec/Mathematica/macaulay2/",
                        "/Users/useradmin/Dropbox/1 Phylogenetics/2019/Ransanec/Mathematica/macaulay2/",
                        "",
                        "")[eleccion_compu]
  
  if(all_1_but3_2) how_many_eq <- "_sub" else how_many_eq <- "_all"
  
  for(K in c(3,4,8)) {
    if(fast) {
      cat("cd","\"")
      cat(folder_Macaulay2)
      cat("\"",";","\n")
      if(K==3) mat_N_fast <- c(112,121,122,211,212,221) 
      if(K==4) mat_N_fast <- c(1112,1121,1211,2111,1122,1212,1221,2112,1222)
      if(K==8) mat_N_fast <- c(11112,11121,11122,11211,11212,11221,11222,12111,12112,12211,12212)
    } else {
      if(K==3) mat_N_fast <- 222 
      if(K==4) mat_N_fast <- c(2121,2211,2122,2212,2221,2222)
      if(K==8) mat_N_fast <- c(12121,12122,12221,12222,21111,21112,21121,21122,21211,21212,
                               21221,21222,22111,22112,22121,22122,22211,22212,22221,22222)
    }
    
    
    
    for(N in mat_N_fast) {
      if(!fast) {
        cat("cd","\"")
        cat(folder_Macaulay2)
        cat("\"",";","\n")
      }
      (text_file_name <- paste0("K",K,how_many_eq,"N",paste(N,collapse = "")))
      text_to_run <-  paste0("cat ",text_file_name,".m2 | M2 &> ",text_file_name,"_out.txt;")
      cat(text_to_run,"\n")
    }
    cat("\n\n")
  }
}

#' Title
#'
#' @param l_var 
#'
#' @return
#' @export
#'
#' @examples
#' 0_t1 <- 0
# TeX0_Mat1 <- 0
# TeX0_Mat1 <- 1
#' 
#' 
#' K <- 8
#' l_var <- Gen_eq_mat_text(K,0) 
#' l_var$all_1_but3_2 <- T
#' l_var$N <- c(2,2,2,2,2)
#' 
#' K <- 4
#' l_var <- Gen_eq_mat_text(K,0) 
#' l_var$all_1_but3_2 <- T
#' l_var$N <- c(2,1,2,2)
#' l_var$N <- c(2,1,2,2)
#' l_var$N <- c(2,2,2,2)
#' 
#' 
#' K <- 3
#' l_var <- Gen_eq_mat_text(K,0) 
#' l_var$all_1_but3_2 <- T
#' l_var$N <- c(2,2,1)
#' l_var$N <- c(2,2,2)
#' l_var$mat_eq_text
#' 
#' l_var <- Gen_SUB_eq_mat_text_AND_SUB_mat_az(l_var)
#' l_var$sub_mat_eq_text
#' 
#' 
#' l_var$a_text_in_this_eq 
#' l_var$z_text_in_this_eq 
#' dim(l_var$sub_mat_eq_text)
Gen_SUB_eq_mat_text_AND_SUB_mat_az <- function(l_var) {
  l_var$sub_mat_eq_text <- l_var$mat_eq_text
  
  if(l_var$all_1_but3_2) {
    # Subset of one eq for types 1,2,4,5 and two for type 3
    (valid_i <- rep(F,nrow(l_var$sub_mat_eq_text)))
    i <- 1; while(i < nrow(l_var$sub_mat_eq_text)) {
      if(l_var$sub_mat_eq_text[i,3]!="3") valid_i[i:(i+2)] <- c(F,T,F) else valid_i[i:(i+2)] <- c(F,T,T)
      i <- i+3
    }
    l_var$sub_mat_eq_text <- l_var$sub_mat_eq_text[valid_i,]
  }
  
  # Subset of vectors n that are less than N
  if(!is.null(l_var$N)) {
    if(length(l_var$N)!=l_var$K & K %in% 3:4) { print("Error length(l_var$N)!=l_var$K; Get_text_eq"); return(l_var)}
    if(length(l_var$N)!=5 & K ==8) { print("Error length(l_var$N)!=l_var$K; Get_text_eq"); return(l_var)}
    valid_i <- rep(F,nrow(l_var$sub_mat_eq_text))
    for(i in 1:nrow(l_var$sub_mat_eq_text)) {
      # substr(l_var$sub_mat_eq_text[i,2],2,nchar(l_var$sub_mat_eq_text[i,2])-1)
      (n_nureric <- as.numeric(unlist(strsplit(substr(l_var$sub_mat_eq_text[i,2],2,nchar(l_var$sub_mat_eq_text[i,2])-1), "[,]")) ))
      # l_var$N
      valid_i[i] <- all(n_nureric<=l_var$N)
    }
    l_var$sub_mat_eq_text <- l_var$sub_mat_eq_text[valid_i,,drop=F]
  }
  (a_text_in_this_eq <- paste(l_var$sub_mat_eq_text[,9],collapse = ","))
  
  
  (z_text_in_this_eq <- paste(l_var$sub_mat_eq_text[,10],collapse = ","))
  (z_text_in_this_eq <- unique(unlist(strsplit(z_text_in_this_eq, split=',', fixed=TRUE))))
  (z_text_in_this_eq <- paste(z_text_in_this_eq, collapse=","))
  
  
  
  (w_text_in_this_eq <- paste(l_var$sub_mat_eq_text[,12],collapse = ","))
  (w_text_in_this_eq <- unique(unlist(strsplit(w_text_in_this_eq, split=',', fixed=TRUE))))
  (w_text_in_this_eq <- paste(w_text_in_this_eq, collapse=","))
  
  
  l_var$a_text_in_this_N <- a_text_in_this_eq
  l_var$z_text_in_this_N <- z_text_in_this_eq
  l_var$w_text_in_this_N <- w_text_in_this_eq
  
  return(l_var)
}



#' Transformation of text from Macaulay to Julia
#' 
#' We do the next changes:
#' - The numbers at the beggining of a monomial does not have an asterix after them; eg 3a8 -> 3*a8
#' - Exponents are between parenthesis should be changed to curly brackets: 3a8^(2) -> 3a8^{2}
#' - The name of the vector of 'a' in Julia is a_vec: a -> a_vec
#' - Index of 'a's are only to the left of 'a's, and should be put between square 
#'   brackets: 8a30 -> 8a[30]
#'
#' @param text_Macaulay 
#'
#' @return
#' @export
#'
#' @examples
#' text_Macaulay <- "3a8*a30^{3}+a8-a23-a32,a23*a29+2a23*a30+a29*a32-a30*a32-a32,3a8*a29-2a8+2a23-a32" 
#' (text_Julia <- text_Macaulay_TO_text_Julia(text_Macaulay) )
#' 
text_Macaulay_TO_text_Julia <- function(text_Macaulay) {
  
  # In the cases of "" and "Uncomputed" we do nothing
  if(text_Macaulay %in% c("","Uncomputed")) return(text_Macaulay)
  
  numbers_in_text <- regmatches(text_Macaulay, gregexpr("[[:digit:]]+", text_Macaulay)) # el símbolo "+" hace que se haga un solo número
  (numbers_in_text <- rev(sort(unique(as.numeric(unlist(numbers_in_text))))))
  
  
  # a_max <- 200
  a_old <- gsub("\\s+", "", str_trim(paste("a",numbers_in_text)))
  (a_new <- gsub("\\s+", "", str_trim(paste("a_vec[",numbers_in_text,"]"))))
  
  (number_follow_by_a_old <- gsub("\\s+", "", str_trim(paste(numbers_in_text,"a"))))
  (number_follow_by_a_new <- gsub("\\s+", "", str_trim(paste(numbers_in_text,"*a"))))
  
  
  old_notation <- c("\\{","\\}",a_old,"\\)a",number_follow_by_a_old)
  new_notation <- c("(",")",a_new,")*a",number_follow_by_a_new)
  text_Julia <- text_Macaulay
  
  print_for <- F
  for(i in 1:length(old_notation)) {
    if(print_for) cat("Cambiando ", new_notation[i],"\n")
    # cat(text_Julia,"\n")
    text_Julia <- str_replace_all(text_Julia, old_notation[i], new_notation[i])
    if(print_for) cat(text_Julia,"\n")
  }
  
  # text_Julia
  # text_Macaulay
  
  return(text_Julia)
}


#' Title
#'
#' @param mat_ideal 
#'
#' @return
#' @export
#'
#' @examples
#' only_K <- 4
#' load(paste0("Mat_ideal_K",only_K,".RData"))
#' 
From_mat_ideal_TO_mat_ideal_Julia <- function(mat_ideal) {
  colnames_mat_ideal_Julia <- c("N","All ideal as Julia text")
  mat_ideal_Julia <- matrix("",nrow = nrow(mat_ideal),length(colnames_mat_ideal_Julia))
  colnames(mat_ideal_Julia) <- colnames_mat_ideal_Julia
  for(i in 1:nrow(mat_ideal)) {
    N <- mat_ideal[i,1]
    text_Macaulay <- mat_ideal[i,2]
    (text_Julia <- text_Macaulay_TO_text_Julia(text_Macaulay) )
    mat_ideal_Julia[i,1] <- N
    mat_ideal_Julia[i,2] <- text_Julia
    # print(text_Macaulay)
    # print(text_Julia)
  }
  return(mat_ideal_Julia)
}



#' Title
#'
#' @param line_mat_ideal_Julia 
#'
#' @return
#' @export
#'
#' @examples
#' only_K <- 4
#' load(paste0("Mat_ideal_K",only_K,".RData"))
#' mat_ideal_Julia <- From_mat_ideal_TO_mat_ideal_Julia(mat_ideal) 
#' i <- 3
#' line_mat_ideal_Julia <- mat_ideal_Julia[i,]
#' text_one_if_Julia <- gen_text_one_if_Julia(line_mat_ideal_Julia) 
#' cat(text_one_if_Julia)
gen_text_one_if_Julia <- function(line_mat_ideal_Julia) {
  # Extraccion of N vector: eg N=[2 2 1 1]
  N_vec_Julia <- paste(c(strsplit(line_mat_ideal_Julia[1], "")[[1]]),collapse=" ")
  # Vector with the invariants as Julia text, but not separated
  separate_Julia_inv <- unlist(strsplit(line_mat_ideal_Julia[2], split=',', fixed=TRUE))
  
  # First we construct the Inv1, Inv2, etc, text vector
  text_Inv_i <- gsub("\\s+", "", str_trim(paste("Inv",1:length(separate_Julia_inv))))
  # We also made the text to asing to "vec_invariants" all values
  text_vec_invariants_asignation <- paste("\tvec_invariants = [",paste(text_Inv_i,collapse = " "),"]")
  # Next we paste the invariants to each Inv text
  # text_Inv_i <- paste("\t",text_Inv_i," = ",separate_Julia_inv,"\n")
  text_Inv_i <- paste("\t",text_Inv_i," = ",separate_Julia_inv)
  # Construction of the beggining of the if sentence
  text_if_start <- paste0("if(N==[",N_vec_Julia,"])")
  text_end <- "end"
  
  if(length(separate_Julia_inv)==0) {
    text_return <- "\treturn [ ]"
    text_one_if_Julia <- c(text_if_start,'\t println("No invariants for this N=$(N)")',text_return,text_end)
    return(text_one_if_Julia)
  }
  if(all(separate_Julia_inv=="Uncomputed")) {
    text_return <- "\treturn missing"
    text_one_if_Julia <- c(text_if_start,'\t println("The invariants for this N=$(N) are not computed")',text_return,text_end)
    return(text_one_if_Julia)
  }
  
  
  text_return <- "\treturn vec_invariants"
  # Put all together
  text_one_if_Julia <- c(text_if_start,text_Inv_i,text_vec_invariants_asignation,text_return,text_end)
  return(text_one_if_Julia)
}



#' Title
#'
#' @param mat_ideal_Julia 
#' @param only_K 
#'
#' @return
#' @export
#'
#' @examples
#' only_K <- 4
#' load(paste0("Mat_ideal_K",only_K,".RData"))
#' mat_ideal_Julia <- From_mat_ideal_TO_mat_ideal_Julia(mat_ideal) 
#' only_K
#' gen_text_all_if_Julia(mat_ideal_Julia,only_K) 
gen_text_all_if_Julia <- function(mat_ideal_Julia,only_K) {
  # Name al path of Julia file
  test_paths_Dropbox <- c("/Users/arrigocoen/Dropbox/","/Users/useradmin/Dropbox/","","")
  particular_folder <- "1 Phylogenetics/2019/Ransanec/Julia/Simulations/"
  path_Julia <- paste0(test_paths_Dropbox[which(file.exists(test_paths_Dropbox))],particular_folder)
  file_Julia <- paste0(path_Julia,"Fn_invariants_K",only_K,".jl")
  # file.exists(file_Julia)
  text_version_control <- paste("#\t Invariants equations function for K",only_K,
                                "\n#\tThis file was made by 'CF_networks.R' and 'Fn phylo R.R' on the date",
                                format(Sys.time(), "%a %b %d %X %Y"),"\n\n")
  
  text_start <- "function evaluate_invariants(a_vec,N)"
  text_all_if_Julia <- NULL
  for(i in 1:nrow(mat_ideal_Julia)) {
    line_mat_ideal_Julia <- mat_ideal_Julia[i,]
    text_one_if_Julia <- gen_text_one_if_Julia(line_mat_ideal_Julia) 
    text_all_if_Julia <- c(text_all_if_Julia,text_one_if_Julia)
  }
  # cat(text_all_if_Julia)
  
  text_all_if_Julia <- paste("\t",text_all_if_Julia)
  text_end <- "end"
  text_invariance_Julia_programm <- c(text_version_control,text_start,text_all_if_Julia,text_end)
  
  write.table(text_invariance_Julia_programm, file=file_Julia, append = F, sep = "", dec = ".",
              row.names = F, col.names = F, quote = FALSE)
  cat("The file Fn_invariants_K",only_K,".jl was created in this path:\n",
      file_Julia,"\n")
}


#' Generates mat_info, mat_ideal and also the txt file with all the info from the Macaulay 
#' files to past them into TeX
#'
#' @param K 
#'
#' @return
#' @export
#'
#' @examples
Gen_mat_info_Y_mat_ideal <- function(K,print_info=F) {
  
  Z0_t1 <- 0
  
  only_sub <- F
  only_sub <- T
  
  print_file_name <- F
  print_file_name <- T
  
  only_K <- K
  if(K=="all") {
    cat("We need to review for the case K='all'")
    return(-1)
  }
  
  # This file will have all the info taked from the .m2 files
  file_Ivariance_info_for_TeX_K <-  paste0("Files_txt/Ivariance_info_for_TeX_K",only_K,".txt")
  text_version_control <- paste0("\n% This text was copy from Ivariance_info_for_TeX_K",only_K,".txt",
                                 "\n% This file was made by the function Gen_mat_info_Y_mat_ideal of 'CF_networks.R' and 'Fn phylo R.R' on the date ",
                                 format(Sys.time(), "%a %b %d %X %Y"),"\n\n")
  
  l_var <- Gen_eq_mat_text(K,0) 
  
  list_out_files <- list.files(l_var$folder_Macaulay2,pattern="_out.txt")
  
  if(only_K!="all") list_out_files <- list_out_files[substr(list_out_files,2,2)==only_K]
  
  if(only_sub) list_out_files <- list_out_files[substr(list_out_files,4,6)=="sub"]
  
  # vector_of_index_for_for <- 5 # for testing
  vector_of_index_for_for <- 1:length(list_out_files)
  
  col_names_mat_info_output <- c("K","N","All0 Sub1.","No. eq","No. parametes","No. invariants","Dim G" )
  mat_info <- matrix(-1,length(vector_of_index_for_for),length(col_names_mat_info_output))
  colnames(mat_info) <- col_names_mat_info_output
  
  text_to_print <- rep("",length(vector_of_index_for_for))
  
  ncol_mat_ideal <- 30
  col_mat_ideal <- c("N","All ideal as text")
  mat_ideal <- matrix("",length(vector_of_index_for_for),length(col_mat_ideal))
  colnames(mat_ideal) <- col_mat_ideal
  
  contador_ideal <- 0
  
  for(i in vector_of_index_for_for) {
    if(print_info) cat("\n\n")
    file_name <- list_out_files[i]
    (K_of_file <- substr(file_name,2,2))
    length_of_N <- as.numeric(K_of_file)
    if(K_of_file=="8") length_of_N <- 5
    (N <- substr(file_name,8,7+length_of_N))
    (file_m2_path <- paste0(l_var$folder_Macaulay2,file_name))
    
    # mydata = read.table(file_m2_path, fill = T, header = FALSE , sep = "\t")
    mydata = read.table(file_m2_path, fill = F, header = FALSE , sep = "\t")
    unlist_mydata <- unlist(mydata)
    names(unlist_mydata) <- NULL
    
    # Counting phrase ideal
    phrase_to_look_at <- "o3 = ideal"
    length_phrase <- nchar(phrase_to_look_at)
    if(any(substr(unlist_mydata,1,length_phrase)==phrase_to_look_at)) {
      contador_ideal <- contador_ideal+1  
    } else {
      for(jjj in 1:10) if(print_info) cat("------------------------------------------------ Error --------------------")
    }
    
    # Text of number of equations
    row_nu_eq <- 13
    (nu_eq <- as.character(mydata[row_nu_eq,]))
    (nu_eq <- substr(nu_eq,62,nchar(nu_eq)))
    
    (row_R_QQ <- which(substr(unlist_mydata,1,12)=="     R = QQ["))
    # (R_QQ <-  mydata[row_R_QQ,])
    (R_QQ <-  as.character(mydata[row_R_QQ,]))
    (R_QQ_number_parameters <-   sum(strsplit(R_QQ, "")[[1]]==",") +1)
    
    # Information of as and zs
    text_as_zs <- substr(R_QQ,17,nchar(R_QQ)-1)
    vec_as_zs <- unlist(strsplit(text_as_zs, split=',', fixed=TRUE))
    (how_many_a <- sum(substr(vec_as_zs,1,1)=="a"))
    (vec_as <- paste(vec_as_zs[substr(vec_as_zs,1,1)=="a"],collapse = "," ))
    (how_many_z <- sum(substr(vec_as_zs,1,1)=="z"))
    (vec_zs <- paste(vec_as_zs[substr(vec_as_zs,1,1)=="z"],collapse = "," ))
    
    # Filling mat_info matrix 
    mat_info[i,1] <- as.numeric(K_of_file)
    mat_info[i,2] <- as.numeric(N)
    mat_info[i,3] <- 1*(substr(list_out_files[i],4,6)=="sub")
    mat_info[i,4] <- as.numeric(nu_eq)
    mat_info[i,5] <- as.numeric(R_QQ_number_parameters)
    
    if(print_file_name) {
      (TeX_file_name <- basename(file_m2_path))
      (TeX_file_name <- str_replace_all(TeX_file_name, "_", ""))
      name_file_name_to_print <- paste(c("    file (no underscores): ",TeX_file_name),collapse = "") 
    } else {
      name_file_name_to_print <- ""
    }
    
    
    (row_G_eliminate <- which(substr(unlist_mydata,1,19)=="     G = eliminate("))
    
    if(row_G_eliminate == length(unlist_mydata)) {
      text_to_print[i] <- paste(c("\n\n$i=",i,"$\n \\item $ N =",N,"$  ",name_file_name_to_print,"\n",
                                  "This file looks uncompleted!",text_version_control," \\\\[2ex]\n\n"),collapse = "")
      if(print_info) cat( text_to_print[i])
      mat_ideal[i,] <- c(N,"Uncomputed")
      contador_ideal <- contador_ideal+1  
      next
    }
    
    (row_ideal <- which(substr(unlist_mydata,1,10)=="o3 = ideal"))
    (ideal <-  mydata[row_ideal,])
    
    (new_ideal <- as.character(ideal))
    
    exponents_found <- F
    
    # In case of multiple spaces
    (ini_interval_ideal <- row_G_eliminate +1)
    phrase_to_look_at <- "o3 : Ideal of R"
    length_phrase <- nchar(phrase_to_look_at)
    (end_interval_ideal <- which(substr(unlist_mydata,1,length_phrase)==phrase_to_look_at)-1)
    (all_ideal_rows <- unlist_mydata[ini_interval_ideal:end_interval_ideal])
    
    vec_ii_for <- max(length(all_ideal_rows)-1,1):1
    # all_ideal_rows contians the lines with the text between "o3 = ideal" and "o3 : Ideal of R" of the .txt file
    all_ideal_rows
    # The next for loops over all the rows that make the invariants
    for(ii in vec_ii_for) {
      (current_row <- all_ideal_rows[ii])
      (current_row_no_spaces <- gsub("\\s+", "", str_trim(current_row)))
      if(print_info) cat("ii=",ii,"\n",current_row,"\n")
      if(substr(current_row,1,20) == "     ---------------"){
        all_ideal_rows <- all_ideal_rows[-ii]
        if(print_info) cat("was eliminated because the spaces\n")
        next
      }
      if(current_row_no_spaces == ""){
        all_ideal_rows <- all_ideal_rows[-ii]
        if(print_info) cat("was eliminated because the its empty\n")
        next
      }
      # In case that the row has no letters, is a power of the next row
      if(regexpr('a', current_row_no_spaces)[[1]]==-1) {
        exponents_found <- T
        bellow_current_row <- all_ideal_rows[ii+1]
        (posible_exponents <- current_row)
        (idx_exponents <- unlist(gregexpr("[[:digit:]]+", current_row)))
        vec_exponents <- regmatches(posible_exponents, gregexpr("[[:digit:]]+", posible_exponents)) # sin "+" se regresa un vector con cada dígito
        (vec_exponents <- as.numeric(unlist(vec_exponents)))
        
        for(jj in length(idx_exponents):1) {
          (one_exponent_index <- idx_exponents[jj])
          bellow_current_row <- paste0(substr(bellow_current_row,1,one_exponent_index-1),"^{",vec_exponents[jj],"}",substr(bellow_current_row,one_exponent_index,nchar(bellow_current_row)))
        }
        all_ideal_rows[ii+1] <- bellow_current_row
        all_ideal_rows <- all_ideal_rows[-ii]
        if(print_info) cat(" pasible power\n")
        next
      }
      if(print_info) cat("normal row\n")
    }
    
    all_ideal_rows
    
    # Adding info to mat_ideal
    
    (paste_all_ideal_rows <- paste(all_ideal_rows,collapse = ""))
    (text_paste_all_ideal_rows <- gsub("[\\(\\)]", "", regmatches(paste_all_ideal_rows, gregexpr("\\(.*?\\)", paste_all_ideal_rows))[[1]]))
    (text_paste_all_ideal_rows <- gsub("\\s+", "", str_trim(text_paste_all_ideal_rows)))# eliminating extra spaces
    
    mat_ideal[i,] <- c(N,text_paste_all_ideal_rows)
    
    # Correcting ideal to be in the TeX format (eg. addign \\item )
    new_ideal <- paste(all_ideal_rows,collapse = "")
    new_ideal <- transform_ideal_text(new_ideal)
    
    # Text of number of invariants
    if(all(new_ideal=="\\item $ NA $ \n") || new_ideal=="\\item o3 = ideal ()\n") {
      number_of_invariants <- 0
      # } else   number_of_invariants <- length(new_ideal)
    } else   number_of_invariants <- sum(strsplit(as.character(mydata[row_ideal,]), "")[[1]]==",") +1
    
    # Text of dimension of G
    row_dim_G <- which(mydata=="i4 : dim G ") +1
    (dim_G <- mydata[row_dim_G,])
    new_dim_G <- transform_dim_G_text(dim_G)
    
    
    
    
    text_to_print[i] <- paste(c(
      "\n$i=",i,"$",
      "\n","\\item $ N =",N,"$  ",name_file_name_to_print,"\\\\",
      "\n",R_QQ,"\\\\",
      "\nIdeal output:\n\\begin{enumerate}\n",new_ideal,"\\end{enumerate}",
      "\nNumber of equations:",nu_eq,"\\\\",
      "\nNumber of invariants:",number_of_invariants,"\\\\",
      "\ndimG = ",new_dim_G,"\\\\",
      "\nNumber of params of QQ[ ]: ",R_QQ_number_parameters,"\\\\",
      "\nNumber of as: ",how_many_a,
      "\nNumber of zs: ",how_many_z,
      "\nexponets found:",exponents_found,
      text_version_control,
      "\n\\\\[2ex]",
      "\n"),collapse = "")
    
    if(print_info) cat( text_to_print[i])
    
    mat_info[i,6] <- as.numeric(number_of_invariants)
    mat_info[i,7] <- as.numeric(new_dim_G)
  }
  
  collapsed_text_to_print <- paste(c(text_version_control,"\\begin{itemize}\n",text_to_print,"\n\\end{itemize}"),collapse = "")
  list_mat_Inv <- list(mat_info=mat_info,
                       mat_ideal=mat_ideal,
                       collapsed_text_to_print=collapsed_text_to_print,
                       vector_of_index_for_for=vector_of_index_for_for,
                       only_K=only_K)
  
  write.table(collapsed_text_to_print, file=file_Ivariance_info_for_TeX_K, append = F, sep = "", dec = ".",
              row.names = F, col.names = F, quote = FALSE)
  cat("\n\nThe file",file_Ivariance_info_for_TeX_K,"was generated with the strings for LaTeX\n")
  return(list_mat_Inv)
}



save_multiple_files_of_invariants <- function(list_mat_Inv) {
  mat_info <- list_mat_Inv$mat_info
  mat_ideal <- list_mat_Inv$mat_ideal
  collapsed_text_to_print <- list_mat_Inv$collapsed_text_to_print
  vector_of_index_for_for <- list_mat_Inv$vector_of_index_for_for
  only_K <- list_mat_Inv$only_K
  text_version_control <- paste0("\n% This file was made by the function save_multiple_files_of_invariants of 'CF_networks.R' and 'Fn phylo R.R' on the date ",
                                 format(Sys.time(), "%a %b %d %X %Y"),"\n\n")
  
  unique_invariats <- unique(unlist(strsplit(paste(mat_ideal[,2],collapse = ","), split=',', fixed=TRUE)))
  # Errasing the uncomputed and empty invariants
  unique_invariats <- unique_invariats[unique_invariats!="" & unique_invariats!="Uncomputed"]
  
  col_names_mat_invariants <- c("N","Number of invariants",paste("Invariant",1:length(unique_invariats)))
  mat_invariants <- matrix(0,length(vector_of_index_for_for),length(col_names_mat_invariants))
  colnames(mat_invariants) <- col_names_mat_invariants
  
  mat_invariants_identifier <- matrix(c(paste("Invariant",1:length(unique_invariats)),unique_invariats),ncol = 2)
  j <- 1
  i <- 1
  
  # j index different invariants
  vector_index_j <- 1:length(unique_invariats)
  
  # i index index of equations over N  
  vector_index_i <- 1:nrow(mat_ideal)
  
  text_help <- T
  text_help <- F
  
  # This for loops over the index of the different invariants
  for(j in vector_index_j) {
    # invariant is the equation that we will compare
    (invariant <- unique_invariats[j])
    if(text_help) cat("Current invariant:",invariant,"\n")
    # This for loops over the index of equations over N  
    for(i in vector_index_i) {
      # The first two colums are N and how many invariants has this N
      (mat_invariants[i,1] <- as.numeric(mat_ideal[i,1])) # N
      (invariants_this_N <- mat_ideal[i,2]) # variants of this N
      if(text_help) cat("i=",i,"  j=",j,"  For this N we have: ",invariants_this_N,"\t")
      # invariants_this_N
      invariants_this_N_noAsterisk <- gsub("\\*","",invariants_this_N)
      invariant_noAsterisk <- gsub("\\*","",invariant)
      # invariant_noAsterisk
      invariants_this_N_noAsterisk
      # A vector with all the invariants for this particular N
      (vec_invariants_this_N <- unlist(strsplit(invariants_this_N, split=',', fixed=TRUE)))
      # Later we correc this "number of invariants" since it could be counting "Uncomputed" Ns and other errors
      mat_invariants[i,2] <- length(vec_invariants_this_N)
      
      if(any(invariant==vec_invariants_this_N)) {
        mat_invariants[i,j+2] <- 1
        if(text_help) cat("True\n") 
      } else if(text_help) cat("False\n")
      
    }
  }
  
  # File txt
  (file_name_txt <- paste0("Files_txt/Invariant_counting_K",only_K,"_mat_ideal.txt"))
  write.table(mat_ideal, file=file_name_txt, row.names=FALSE, col.names=T,sep = ",")
  cat("\n\nThe file",file_name_txt,"was saved\n")
  
  # File xlsx multiple sheets 
  (file_name <- paste0("Files_xlsx/Invariant_counting_K",only_K,".xlsx"))
  (text_sheetName <- paste0("K",only_K,"mat_ideal"))
  write.xlsx(mat_ideal, file = file_name, 
             sheetName=text_sheetName, append=F)
  (text_sheetName <- paste0("K",only_K,"mat_invariants_identifier"))
  write.xlsx(mat_invariants_identifier, file = file_name, 
             sheetName=text_sheetName, append=T)
  (text_sheetName <- paste0("K",only_K,"mat_invariants"))
  write.xlsx(mat_invariants, file = file_name, 
             sheetName=text_sheetName, append=T)
  (text_sheetName <- "Version reference")
  write.xlsx(text_version_control, file = file_name, 
             sheetName=text_sheetName, append=T)
  cat("\n\nThe file",file_name,"was saved\n")
  
  # File plot
  text_title <- paste0("Invariants for K=",only_K)
  file_figure <- paste0("Files_Figures_R/Plot_mat_invariants_K",only_K,".pdf")
  image(as.matrix.csr(mat_invariants[,3:ncol(mat_invariants)]),main=text_title,ylab="N",xlab="Invariant #i") # plot it :)
  dev.print(pdf,  file_figure,width=8, height=5)
  cat("\n\nThe file",file_figure,"was saved\n")
  # File RData
  file_RData <- paste0("Files_RData/Mat_ideal_K",only_K,".RData")
  save(mat_ideal,file = file_RData)
  cat("\n\nThe file",file_RData,"was saved\n")
  
}



#' Given a equation in text this function changes the index with respect to 
#' mat_changes_Nx_to_Ny
#'
#' @param text_eq 
#' @param mat_changes_Nx_to_Ny 
#'
#' @return
#' @export
#'
#' @examples
#' 
#' mat_changes_N1_to_N2 <- matrix(c("0","2",
#'                                  "1","0",
#'                                  "2","3",
#'                                  "3","1",
#'                                  "0,1","0,2",
#'                                  "0,2","2,3",
#'                                  "1,3","0,1",
#'                                  "2,3","1,3"),ncol=2,byrow = T)
#' mat_changes_Nx_to_Ny <- mat_changes_N1_to_N2
#' text_eq <- "(1-\\gamma)\\dfrac{1}{3}z_{1,3}z_{3}+\\gamma\\dfrac{1}{3}z_{3}"
change_idx_for_rotation_TeX <- function(text_eq,mat_changes_Nx_to_Ny) {
  # We use uppercase z to dont mess with the previous changes
  for(i_mat_change in 1:nrow(mat_changes_Nx_to_Ny)) {
    old_idx <- mat_changes_Nx_to_Ny[i_mat_change,1]
    new_idx <- mat_changes_Nx_to_Ny[i_mat_change,2]
    old_z <- paste0("z_\\{",old_idx,"\\}")
    new_z <- paste0("Z_\\{",new_idx,"\\}") # Obs: here we use Z not z
    text_eq <- str_replace_all(text_eq, old_z, new_z)
  }
  text_eq <- str_replace_all(text_eq, "Z", "z")
  return(text_eq)
}


#' Given a equation in text this function changes the index with respect to 
#' mat_changes_Nx_to_Ny
#'
#' @param text_eq 
#' @param mat_changes_Nx_to_Ny 
#'
#' @return
#' @export
#'
#' @examples
#' 
#' mat_changes_N1_to_N2_Mat <- matrix(c("10","13", # This is the matrix of one clock-wize rotations
#'                                      "11","10",
#'                                      "12","11",
#'                                      "13","12",
#'                                      "0","3",
#'                                      "1","0",
#'                                      "2","1",
#'                                      "3","2"),ncol=2,byrow = T)
#' mat_changes_Nx_to_Ny <- mat_changes_N1_to_N2
#' text_eq <- "1-(2/3)*z10*z0*z11"
change_idx_for_rotation_Mat <- function(text_eq,mat_changes_Nx_to_Ny_Mat) {
  # We use uppercase z to dont mess with the previous changes
  for(i_mat_change in 1:nrow(mat_changes_Nx_to_Ny_Mat)) {
    old_idx <- mat_changes_Nx_to_Ny_Mat[i_mat_change,1]
    new_idx <- mat_changes_Nx_to_Ny_Mat[i_mat_change,2]
    old_z <- paste0("z",old_idx)
    new_z <- paste0("Z",new_idx) # Obs: here we use Z not z
    text_eq <- str_replace_all(text_eq, old_z, new_z)
  }
  text_eq <- str_replace_all(text_eq, "Z", "z")
  return(text_eq)
}


#' Generation of the matrix of text to compare rotations
#' 
#' Currently only works fors K=4 and Z0_t1=0.
#' 
#' It generates a normal text equations and then give the rotations of the z's index 
#' to get the equations to the rotated networks. 
#'
#' @param K 
#' @param Z0_t1 
#'
#' @return
#' @export
#'
#' @examples
#' Z0_t1 <- 0
#' K <- 4
#' mat_eq_rotated <- gen_mat_TeX_and_Mat_rotation_comparison(K,Z0_t1)
#' head(mat_eq_rotated)
#' 
gen_mat_TeX_and_Mat_rotation_comparison <- function(K,Z0_t1) {
  
  
  # l_var is a list with the not rotated equations (and other things)
  l_var <- Gen_eq_mat_text(K,Z0_t1) 
  
  # The next are matrices that contain the change of index for each rotation; as for TeX 
  # and for Mathematica notations
  
  mat_changes_N1_to_N2_TeX <- matrix(c("0","2", # This is the matrix of one clock-wize rotations
                                       "1","0",
                                       "2","3",
                                       "3","1",
                                       "0,1","0,2",
                                       "0,2","2,3",
                                       "1,3","0,1",
                                       "2,3","1,3"),ncol=2,byrow = T)
  
  mat_changes_N1_to_N3_TeX <- matrix(c("0","3", # This is the matrix of two clock-wize rotations
                                       "1","2",
                                       "2","1",
                                       "3","0",
                                       "0,1","2,3",
                                       "0,2","1,3",
                                       "1,3","0,2",
                                       "2,3","0,1"),ncol=2,byrow = T)
  
  mat_changes_N1_to_N4_TeX <- matrix(c("0","1", # This is the matrix of three clock-wize rotations
                                       "1","3",
                                       "2","0",
                                       "3","2",
                                       "0,1","1,3",
                                       "0,2","0,1",
                                       "1,3","2,3",
                                       "2,3","0,2"),ncol=2,byrow = T)
  
  
  
  mat_changes_N1_to_N2_Mat <- matrix(c("10","13", # This is the matrix of one clock-wize rotations
                                       "11","10",
                                       "12","11",
                                       "13","12",
                                       "0","3",
                                       "1","0",
                                       "2","1",
                                       "3","2"),ncol=2,byrow = T)
  
  mat_changes_N1_to_N3_Mat <- matrix(c("10","12", # This is the matrix of one clock-wize rotations
                                       "11","13",
                                       "12","10",
                                       "13","11",
                                       "0","2",
                                       "1","3",
                                       "2","0",
                                       "3","1"),ncol=2,byrow = T)
  
  mat_changes_N1_to_N4_Mat <- matrix(c("10","11", # This is the matrix of one clock-wize rotations
                                       "11","12",
                                       "12","13",
                                       "13","10",
                                       "0","1",
                                       "1","2",
                                       "2","3",
                                       "3","0"),ncol=2,byrow = T)
  
  # The next loop generates the desired matrix
  mat_eq_rotated <- matrix(0,nrow(l_var$mat_eq_text),11)
  colnames(mat_eq_rotated) <- c("i","n","N1_TeX","N2_TeX","N3_TeX","N4_TeX","N1_Mat","N2_Mat","N3_Mat","N4_Mat","z's")
  
  for(i in 1:nrow(l_var$mat_eq_text)) {
    text_eq <- l_var$mat_eq_text[i,4] # The four column has the TeX equations
    mat_eq_rotated[i,1] <- i
    mat_eq_rotated[i,2] <- l_var$mat_eq_text[i,2]
    mat_eq_rotated[i,3] <- text_eq
    mat_eq_rotated[i,4] <- change_idx_for_rotation_TeX(text_eq,mat_changes_N1_to_N2_TeX) 
    mat_eq_rotated[i,5] <- change_idx_for_rotation_TeX(text_eq,mat_changes_N1_to_N3_TeX) 
    mat_eq_rotated[i,6] <- change_idx_for_rotation_TeX(text_eq,mat_changes_N1_to_N4_TeX) 
    text_eq <- l_var$mat_eq_text[i,5] # The five column has the Mathematica equations
    mat_eq_rotated[i,7] <- text_eq
    mat_eq_rotated[i,8] <- change_idx_for_rotation_Mat(text_eq,mat_changes_N1_to_N2_Mat)
    mat_eq_rotated[i,9] <- change_idx_for_rotation_Mat(text_eq,mat_changes_N1_to_N3_Mat)
    mat_eq_rotated[i,10] <- change_idx_for_rotation_Mat(text_eq,mat_changes_N1_to_N4_Mat)
    mat_eq_rotated[i,11] <- l_var$mat_eq_text[i,10]
  }
  
  # Finally is needed to change some rows since the rotation not only change the labels of the
  # branche lenghts but also changes the possition of the hybrid with respect to the taxa
  n_vec <- mat_eq_rotated[,2] # vector of vectors of the type "(0,0,2,2)"
  n_vec
  
  # The next loop changes the rows of each of the rotations (N2, N3, and N4), the TeX and
  # Mathematica equations
  for(idx_Nj in 2:4) {
    vec_idx_change <- idx_change_rotation(idx_Nj,n_vec)
    mat_eq_rotated[,c(idx_Nj+2,idx_Nj+6)] <- mat_eq_rotated[vec_idx_change,c(idx_Nj+2,idx_Nj+6)]
  }
  
  return(mat_eq_rotated)
}



#' This function gerenates a TeX table with all the equatios of a particula
#' rotation
#'
#' @param mat_eq_rotated 
#' @param N_to_print 
#'
#' @return
#' @export
#'
#' @examples
#' Z0_t1 <- 0
#' K <- 4
#' mat_eq_rotated <- gen_mat_TeX_and_Mat_rotation_comparison(K,Z0_t1)
#' cat("\014") # borra consola 
#' N_to_print <- 2
#' print_TeX_table_Ni(mat_eq_rotated,N_to_print)
print_TeX_table_Ni <- function(mat_eq_rotated,N_to_print) {
  
  text_col_name_N <-  c("CF N1","CF N2","CF N2","CF N4")[N_to_print]
  n_test <- nrow(mat_eq_rotated)
  # n_test <- 3
  # cat("\\begin{landscape}")
  # cat("\\begin{longtable}{@{\\extracolsep{\\fill}}|l|l|l|@{}}\n	\\hline\n idx & $ n $ & CF N1 \\\\ \\hline\n")
  cat("\\begin{longtable}{@{\\extracolsep{\\fill}}|l|l|l|@{}}\n	\\hline\n idx & $ n $ & ",text_col_name_N," \\\\ \\hline\n")
  
  for(i in 1:n_test) {
    # for(i in 1:3) { # this line was for testing
    if(i%%3==1) n_print_or_not <- mat_eq_rotated[i,2] else n_print_or_not <- ""
    # cat(mat_eq_rotated[i,1],"& ",n_print_or_not,"& $",mat_eq_rotated[i,3],"$ \\\\ \n")
    cat(mat_eq_rotated[i,1],"& ",n_print_or_not,"& $",mat_eq_rotated[i,N_to_print+2],"$ \\\\ \n")
    # cat(mat_eq_rotated[i,2],"& $",mat_eq_rotated[i,5],"$ & = & $",mat_eq_rotated[i,8],"$ \\\\ \n\n")
    if(i%%3==0 && i<n_test) cat("\\hline\n")
  }
  cat("\\hline\n")
  cat("\\end{longtable}")
  # cat("\\end{landscape}")
}

#' Multiple call of function print_TeX_table_Ni to obtain the four tables
#'
#' @param mat_eq_rotated 
#' @param N_quartet_allowed 
#'
#' @return
#' @export
#'
#' @examples
print_all_TeX_table_Ni <- function(N_quartet_allowed,mat_eq_rotated) {
  # Text variables
  text_N_quartet_allowed <- paste(as.character(N_quartet_allowed),collapse = "")
  text_file_name <- file_name_for_print_TeX_Table_rotations(N_quartet_allowed)
  how_many_eq <- nrow(mat_eq_rotated)
  eq_numbers <- paste(mat_eq_rotated[,1],collapse = ",")
  # Initial text for Mathematica file
  ini_text <- paste0("%------------------------------------------------------------------\n",
                     "%--   Comparing equations of two rotations for 4-cycle networks  --\n",
                     "%------------------------------------------------------------------\n",
                     "%-- file name = TeX_Table_K4_N_allow",text_N_quartet_allowed,".tex",
                     "\n%-- N_allowed = ",text_N_quartet_allowed," (taxa allow in each of the four sub-trees)",
                     "\n%-- How many equations: ",how_many_eq,
                     "\n%-- Date of creation: ",format(Sys.time(), "%a %b %d %X %Y"),
                     "\n%-- Equation numbers = ",eq_numbers,
                     "\n%-- Generated by the function print_all_TeX_table_Ni of the file 'Fn phylo R.R'",
                     "\n%-- Obs: the 'n=' are with respect to the N1 (non rotated) network",
                     "\n\n")
  cat(ini_text)
  cat("\\subsection{Tables for N allowed = ",text_N_quartet_allowed,"}\n\n")
  for(N_to_print in 1:4) {
    cat("\\textbf{Concordance Factors network N",N_to_print,"}\n")
    print_TeX_table_Ni(mat_eq_rotated,N_to_print)
  }  
  cat("\n")
}

#' Get a subset of rows that is restricted by the number of allowed taxa from 
#' each subtree. THe vector N_quartet_allowed is with respect to the new enumeration 
#' meaning that first entry is the Down-subtree, second is the left, third is the right
#' and four is the top-subtree
#'
#' @param N_quartet_allowed vector of number of quartet alloweb by each sub tree,
#'                          obs: its entries could be 0,1 or 2, and its lenght is k (the number of subtrees).
#' @param mat_eq_rotated 
#'
#' @return
#' @export
#'
#' @examples
#' cat("\014") # borra consola 
#' rm(list=ls())  # Borra todo
#' source("Fn phylo R.R")
#' Z0_t1 <- 0
#' K <- 4
#' mat_eq_rotated <- gen_mat_TeX_and_Mat_rotation_comparison(K,Z0_t1)
#' N_quartet_allowed <- c(1,1,1,2)
#' gen_SUB_mat_eq_rotated(N_quartet_allowed,mat_eq_rotated)
#' 
gen_SUB_mat_eq_rotated <- function(N_quartet_allowed,mat_eq_rotated) {
  valid_i <- rep(F,nrow(mat_eq_rotated))
  for(i in 1:nrow(mat_eq_rotated)) {
    # substr(l_var$sub_mat_eq_text[i,2],2,nchar(l_var$sub_mat_eq_text[i,2])-1)
    (test_n <- mat_eq_rotated[i,2])
    (n_nureric <- as.numeric(unlist(strsplit(substr(test_n,2,nchar(test_n)-1), "[,]")) ))
    # l_var$N
    valid_i[i] <- all(n_nureric<=N_quartet_allowed)
  }
  valid_i
  SUB_mat_eq_rotated <- mat_eq_rotated[valid_i,]
  return(SUB_mat_eq_rotated)
}


#' Text to copy into Mathematica to run the Solve function with respect to two
#' different networks. This two networks are rotations of each other
#'
#' @param idx_Ni index of the rotated network could be 1,2,3, or 4
#' @param idx_Nj index of the rotated network could be 1,2,3, or 4
#' @param mat_eq_rotated matrix with the info to run this function
#' @param N_quartet_allowed vector with the possible number of taxa comming for each sub tree
#'
#' @return
#' @export
#'
#' @examples
#' cat("\014") # borra consola 
#' rm(list=ls())  # Borra todo
#' source("Fn phylo R.R")
#' Z0_t1 <- 0
#' K <- 4
#' mat_eq_rotated <- gen_mat_TeX_and_Mat_rotation_comparison(K,Z0_t1)
#' N_quartet_allowed <- c(1,1,1,2)
#' SUB_mat_eq_rotated <- gen_SUB_mat_eq_rotated(N_quartet_allowed,mat_eq_rotated)
#' 
#' idx_Ni <- 1
#' idx_Nj <- 2
#' print_Solve_Ni_vr_Nj_Mat(idx_Ni,idx_Nj,SUB_mat_eq_rotated) 
print_Solve_Ni_vr_Nj_Mat <- function(idx_Ni,idx_Nj,N_quartet_allowed,mat_eq_rotated) {
  # Correction of the index with respect to colums of mat_eq_rotated
  # idx_Ni <- idx_Ni+6
  # idx_Nj <- idx_Nj+6
  # Variables names
  text_gam <- "gam"
  z_var <- unique(unlist(strsplit(paste0(mat_eq_rotated[,11],",",collapse = ""), split=',', fixed=TRUE)))
  text_z_var <- paste0(z_var,",",collapse = "")
  
  n_test <- nrow(mat_eq_rotated)
  # n_test <- 9 # this line was for testing
  
  # Text variables
  text_N_quartet_allowed <- paste(as.character(N_quartet_allowed),collapse = "")
  text_file_name <- file_name_for_print_Solve_Ni_vr_Nj_Mat(idx_Ni,idx_Nj,N_quartet_allowed)
  how_many_eq <- nrow(mat_eq_rotated)
  eq_numbers <- paste(mat_eq_rotated[,1],collapse = ",")
  # Initial text for Mathematica file
  ini_text <- paste0("(*\n",
                     "------------------------------------------------------------------\n",
                     "--   Comparing equations of two rotations for 4-cycle networks  --\n",
                     "------------------------------------------------------------------\n",
                     "-- file name = ",text_file_name,
                     "\n-- N_allowed = ",text_N_quartet_allowed," (taxa allow in each of the four sub-trees)",
                     "\n-- First  rotation Ni = N",idx_Ni,
                     "\n-- Second rotation Nj = N",idx_Nj,
                     "\n-- How many equations: ",how_many_eq,
                     "\n-- Date of creation: ",format(Sys.time(), "%a %b %d %X %Y"),
                     "\n-- Equation numbers = ",eq_numbers,
                     "\n-- Generated by the function print_Solve_Ni_vr_Nj_Mat of the file 'Fn phylo R.R'",
                     "\n-- Obs: the 'n=' are with respect to the N1 (non rotated) network",
                     "\n*)\n\n")
  
  cat(ini_text)
  
  cat("Solve[{\n")
  for(i in 1:n_test) {
    # Obs: this only works for printing the equations with index i%%3==0, others this trick for the
    # comma should be different
    if(i<n_test) ending_comma <- "," else ending_comma <- "},"
    # if(i%%3==0) cat(mat_eq_rotated[i,idx_Ni]," == ",mat_eq_rotated[i,idx_Nj],ending_comma," \n")
    cat(mat_eq_rotated[i,idx_Ni+6]," == ",mat_eq_rotated[i,idx_Nj+6],ending_comma,"(* n=",mat_eq_rotated[i,2]," eq",mat_eq_rotated[i,1],"*)","\n")
    # cat(mat_eq_rotated[i,2],"& $",mat_eq_rotated[i,5],"$ & = & $",mat_eq_rotated[i,8],"$ \\\\ \n\n")
  }
  
  # cat("{",text_z_var,text_gam,"}]\n") # in case of only putting the variables that appear
  cat("{",all_variable_names_Mat(),"}]\n")
}


all_variable_names_Mat <- function() {
  return(paste0(c("z0","z1","z2","z3","z10","z11","z12","z13",
                  "zR0","zR1","zR2","zR3","zR10","zR11","zR12","zR13",
                  "zRR0","zRR1","zRR2","zRR3","zRR10","zRR11","zRR12","zRR13",
                  "zRRR0","zRRR1","zRRR2","zRRR3","zRRR10","zRRR11","zRRR12","zRRR13",
                  "gam","gamR","gamRR","gamRRR"),collapse = ","))
}

#' Name of the .nb files to save on the folder Mat_from_R
#'
#' @param idx_Ni 
#' @param idx_Nj 
#' @param N_quartet_allowed 
#'
#' @return
#' @export
#'
#' @examples
file_name_for_print_Solve_Ni_vr_Nj_Mat <- function(idx_Ni,idx_Nj,N_quartet_allowed) {
  text_N_quartet_allowed <- paste(as.character(N_quartet_allowed),collapse = "")
  text_file_name <- paste0("Mat_from_R/SolveK4_N_allow",text_N_quartet_allowed,"_for_N",idx_Ni,"vrN",idx_Nj,".nb")
  return(text_file_name)
}


file_name_for_print_TeX_Table_rotations <- function(N_quartet_allowed) {
  text_N_quartet_allowed <- paste(as.character(N_quartet_allowed),collapse = "")
  
  rutas_prueba <- c("/Users/arrigocoen/Dropbox","/Users/useradmin/Dropbox","","")
  eleccion_compu <- which(file.exists(rutas_prueba))
  
  # Direcciones de cada computadora
  source_raiz <- c("/Users/arrigocoen/Dropbox/Aplicaciones/Overleaf/snaq-identifiability-progress-report/Sections/TeX_Table_K4_N_allow",
                   "/Users/useradmin/Dropbox/Aplicaciones/Overleaf/snaq-identifiability-progress-report/Sections/TeX_Table_K4_N_allow",
                   "",
                   "")[eleccion_compu]
  
  text_file_name <- paste0(source_raiz,text_N_quartet_allowed,".tex")
  return(text_file_name)
}



#' Transformation of a vector of text n
#' 
#' For example "(1,1,1,2)"
#'
#' @param n_N1_original 
#' @param idx_Nj 
#'
#' @return
#' @export
#'
#' @examples
#' n_N1_original = "(1,1,1,2)"
#' idx_Nj <- 2
#' rotation_of_n(n_N1_original,idx_Nj) # we get "(1,1,2,1)"
rotation_of_n <- function(n_N1_original,idx_Nj) {
  n_N1_original_values <- strsplit(n_N1_original, "")[[1]][c(2,4,6,8)]
  
  mat_n_Nj_rotation_idx <- matrix(c(1,2,3,4,  # index of change for n of N1 to n of N1
                                    3,1,4,2,  # index of change for n of N1 to n of N2
                                    4,3,2,1,  # index of change for n of N1 to n of N3
                                    2,4,1,3), # index of change for n of N1 to n of N4
                                  4,byrow = T)
  
  n_Nj_rotation <- paste0(n_N1_original_values[mat_n_Nj_rotation_idx[idx_Nj,]],collapse = ",")
  n_Nj_rotation <- paste(c("(",n_Nj_rotation,")"),collapse = "")
  
  return(n_Nj_rotation)
}


#' Index of changes of all vectors
#'
#' @param idx_Nj 
#' @param n_vec 
#'
#' @return
#' @export
#'
#' @examples
idx_change_rotation <- function(idx_Nj,n_vec) {
  vec_idx_change <- rep(0,length(n_vec))
  for(i in seq(1,length(n_vec),3)) {
    n <- n_vec[i]
    n_rot <- rotation_of_n(n,idx_Nj)
    (idx_n <- which(n_vec==n))
    (idx_n_rot <- which(n_vec==n_rot))
    vec_idx_change[idx_n] <- idx_n_rot
  }
  return(vec_idx_change)
}



#' Generate all the TeX files with the equatios of the rotations 
#'
#' V02 with different notation for different files
#' @return
#' @export
#'
#' @examples
Gen_All_TeX_files_Table_rotations <- function() {
  Z0_t1 <- 0
  K <- 4
  # mat_eq_rotated <- gen_mat_TeX_and_Mat_rotation_comparison(K,Z0_t1)
  mat_eq_rotated <- gen_mat_rotation_Diff_variables(K,Z0_t1) # this line is for different variables
  
  
  mat_N_quartet_allowed <- matrix(c(1,1,1,2,
                                    1,1,2,2,
                                    1,2,2,2,
                                    2,2,2,2),ncol=4,byrow = T)
  
  for(i in 1:nrow(mat_N_quartet_allowed)) {
    N_quartet_allowed <- mat_N_quartet_allowed[i,]
    SUB_mat_eq_rotated <- gen_SUB_mat_eq_rotated(N_quartet_allowed,mat_eq_rotated)
    capture.output(print_all_TeX_table_Ni(N_quartet_allowed,SUB_mat_eq_rotated),
                   file = file_name_for_print_TeX_Table_rotations(N_quartet_allowed))
    cat("The file ",file_name_for_print_TeX_Table_rotations(N_quartet_allowed),"was generated\n")
  }
}


#' Given two rotations and the restriction of the allowed taxa from each sub-tree
#' this function generates the .nb file of Mathematica
#'
#' @param idx_Ni index of the first rotation
#' @param idx_Nj index of the second rotation
#' @param N_quartet_allowed how many taxa are allowed from each sub-tree
#' @param mat_eq_rotated Matrix with all the informatiof the equations
#'
#' @return
#' @export
#'
#' @examples
#' 
#' cat("\014") # borra consola 
#' rm(list=ls())  # Borra todo
#' source("Fn phylo R.R")
#' Z0_t1 <- 0
#' K <- 4
#' mat_eq_rotated <- gen_mat_TeX_and_Mat_rotation_comparison(K,Z0_t1)
#' idx_Ni <- 1
#' idx_Nj <- 2
#' N_quartet_allowed <- c(1,1,1,2)
#' gen_nb_file_Solve_rotation_Ni_vr_Nj(idx_Ni,idx_Nj,N_quartet_allowed,mat_eq_rotated)
#' 
gen_nb_file_Solve_rotation_Ni_vr_Nj <- function(idx_Ni,idx_Nj,N_quartet_allowed,mat_eq_rotated) {
  SUB_mat_eq_rotated <- gen_SUB_mat_eq_rotated(N_quartet_allowed,mat_eq_rotated)
  print_Solve_Ni_vr_Nj_Mat(idx_Ni,idx_Nj,N_quartet_allowed,SUB_mat_eq_rotated) 
  capture.output(print_Solve_Ni_vr_Nj_Mat(idx_Ni,idx_Nj,N_quartet_allowed,SUB_mat_eq_rotated),
                 file = file_name_for_print_Solve_Ni_vr_Nj_Mat(idx_Ni,idx_Nj,N_quartet_allowed))
  cat("The file ",file_name_for_print_Solve_Ni_vr_Nj_Mat(idx_Ni,idx_Nj,N_quartet_allowed),"was generated\n")
}



#' Generation of all possible Mathematica files,
#' the possible combination range between rotations N1 vr N2, or N3 or N4
#' and the restriction of the allowed taxa from each sub-tree
#' this function generates the .nb file of Mathematica
#'
#' Version 
#' V02 <- now we let all variables to be different
#'
#' @return
#' @export
#'
#' @examples
#' cat("\014") # borra consola 
#' rm(list=ls())  # Borra todo
#' source("Fn phylo R.R")
#' Gen_All_gen_nb_file_Solve_rotation_Ni_vr_Nj()
Gen_All_gen_nb_file_Solve_rotation_Ni_vr_Nj <- function(){
  
  Z0_t1 <- 0
  K <- 4
  # mat_eq_rotated <- gen_mat_TeX_and_Mat_rotation_comparison(K,Z0_t1)
  mat_eq_rotated <- gen_mat_rotation_Diff_variables(K,Z0_t1)
  
  mat_N_quartet_allowed <- matrix(c(1,1,1,2,
                                    1,1,2,2,
                                    1,2,2,2,
                                    2,2,2,2),ncol=4,byrow = T)
  idx_Ni <- 1
  
  idx_Nj <- 2
  i <- 1
  # The next double loop goes for each possible allowed arrangement of taxa comming
  # from the sub-trees and for each possible rotation
  for(idx_Nj in 2:4) for(i in 1:nrow(mat_N_quartet_allowed)) {
    N_quartet_allowed <- mat_N_quartet_allowed[i,]
    gen_nb_file_Solve_rotation_Ni_vr_Nj(idx_Ni,idx_Nj,N_quartet_allowed,mat_eq_rotated)
  }
}

#' THis function add "R"s to the text of an equation in Mathematica notation
#'
#' @param text_eq_Mat 
#' @param number_of_Rs 
#'
#' @return
#' @export
#'
#' @examples
#' 
#' text_eq_Mat <- "1-(2/3)*z10*z0*z11"
#' number_of_Rs <- 1
#' add_R_to_Mat_eq(text_eq_Mat,number_of_Rs)
add_R_to_Mat_eq <- function(text_eq_Mat,number_of_Rs) {
  text_eq_Mat <- str_replace_all(text_eq_Mat, "z", paste0(c("z",rep("R",number_of_Rs)),collapse = ""))
  text_eq_Mat <- str_replace_all(text_eq_Mat, "gam", paste0(c("gam",rep("R",number_of_Rs)),collapse = ""))
  return(text_eq_Mat)
}

#' THis function add "R"s to the text of an equation in LaTeX notation
#'
#' @param text_eq_Mat 
#' @param number_of_Rs 
#'
#' @return
#' @export
#'
#' @examples
#' text_eq_Mat <- "(1-\\gamma)\\left(1-\\dfrac{2}{3}z_{1}\\right)+\\gamma\\left(1-\\dfrac{2}{3}z_{1,3}z_{1}\\right)" 
#' number_of_Rs <- 2
#' add_R_to_TeX_eq(text_eq_Mat,number_of_Rs)
add_R_to_TeX_eq <- function(text_eq_TeX,number_of_Rs) {
  text_eq_TeX <- str_replace_all(text_eq_TeX, "z", paste0(c("z^{",rep("R",number_of_Rs),"}"),collapse = ""))
  text_eq_TeX <- str_replace_all(text_eq_TeX, "gamma", paste0(c("gamma_{",rep("R",number_of_Rs),"}"),collapse = ""))
  return(text_eq_TeX)
}


#' Generation of the matrix of text to compare rotations WITH DIFFERENT VARIABLES FOR EACH LENGHT
#' 
#' Currently only works fors K=4 and Z0_t1=0.
#' 
#' It generates a normal text equations and then give the rotations of the z's index 
#' to get the equations to the rotated networks. 
#'
#' @param K 
#' @param Z0_t1 
#'
#' @return
#' @export
#'
#' @examples
gen_mat_rotation_Diff_variables <- function(K,Z0_t1) {
  # l_var is a list with the not rotated equations (and other things)
  l_var <- Gen_eq_mat_text(K,Z0_t1) 
  
  # The next loop generates the desired matrix
  mat_eq_rotated <- matrix(0,nrow(l_var$mat_eq_text),11)
  colnames(mat_eq_rotated) <- c("i","n","N1_TeX","N2_TeX","N3_TeX","N4_TeX","N1_Mat","N2_Mat","N3_Mat","N4_Mat","z's")
  
  for(i in 1:nrow(l_var$mat_eq_text)) {
    text_eq_TeX <- l_var$mat_eq_text[i,4] # The four column has the TeX equations
    mat_eq_rotated[i,1] <- i
    mat_eq_rotated[i,2] <- l_var$mat_eq_text[i,2]
    mat_eq_rotated[i,3] <- text_eq_TeX
    mat_eq_rotated[i,4] <- add_R_to_TeX_eq(text_eq_TeX,1)
    mat_eq_rotated[i,5] <- add_R_to_TeX_eq(text_eq_TeX,2)
    mat_eq_rotated[i,6] <- add_R_to_TeX_eq(text_eq_TeX,3)
    text_eq_Mat <- l_var$mat_eq_text[i,5] # The five column has the Mathematica equations
    mat_eq_rotated[i,7] <- text_eq_Mat
    mat_eq_rotated[i,8] <- add_R_to_Mat_eq(text_eq_Mat,1)
    mat_eq_rotated[i,9] <- add_R_to_Mat_eq(text_eq_Mat,2)
    mat_eq_rotated[i,10] <- add_R_to_Mat_eq(text_eq_Mat,3)
    mat_eq_rotated[i,11] <- l_var$mat_eq_text[i,10]
  }
  
  # Finally is needed to change some rows since the rotation not only change the labels of the
  # branche lenghts but also changes the possition of the hybrid with respect to the taxa
  n_vec <- mat_eq_rotated[,2] # vector of vectors of the type "(0,0,2,2)"
  n_vec
  
  # The next loop changes the rows of each of the rotations (N2, N3, and N4), the TeX and
  # Mathematica equations
  for(idx_Nj in 2:4) {
    vec_idx_change <- idx_change_rotation(idx_Nj,n_vec)
    mat_eq_rotated[,c(idx_Nj+2,idx_Nj+6)] <- mat_eq_rotated[vec_idx_change,c(idx_Nj+2,idx_Nj+6)]
  }
  return(mat_eq_rotated)
}




#' Generation of all the Mathematica text needed to campare networks
#'
#' @return prints the text ready to run in Mathematica to compare the network equations
#' @export
#'
#' @examples
Gen_all_Mathematica_text <- function() {
  
  K <- 4
  K <- 8
  K <- 3
  
  Z0_t1 <- 1
  Z0_t1 <- 0
  
  rep_equations <- F
  rep_equations <- T
  
  TeX0_Mat1 <- 0
  TeX0_Mat1 <- 1
  
  
  a_index <- 1
  a_index <- "none"
  
  prin_as_table <- F
  prin_as_table <- T
  
  only_one_eq_Mat <- T
  only_one_eq_Mat <- F
  
  system_eq_for_R <- T
  system_eq_for_R <- F
  
  grobel_mathematica <- T
  grobel_mathematica <- F
  
  all_1_but3_2 <- T
  all_1_but3_2 <- F
  
  N <- c(2,2,2)
  Macaulay2 <- T
  Macaulay2 <- F
  
  l_var <- Initialize_l_var(K,Z0_t1) 
  # cat(l_var$Text_eq_Mat_Topo_this_N)
  
  i <- 1
  
  for(all_1_but3_2 in c(T,F))
    for(K in c(3,4,8)) {
      if(all_1_but3_2) how_many_eq <- "_sub" else how_many_eq <- "_all"
      name_txt <- paste0(c("Mathematica_Topology_text_K",K,how_many_eq,".txt"), collapse = "")
      
      if(K==3){N_mat <- l_var$possible_N_K3}
      if(K==4){N_mat <- l_var$possible_N_K4}
      if(K==8){N_mat <- l_var$possible_N_K8}
      for(i in 1:nrow(N_mat)) {
        N <- N_mat[i,]
        l_var <- print_eq_xlsx_N_vr_T(K,Z0_t1,TeX0_Mat1,rep_equations,a_index,
                                      prin_as_table,only_one_eq_Mat,system_eq_for_R,
                                      grobel_mathematica,all_1_but3_2,N,Macaulay2)
        if(i==1) should_append <- F else should_append <- T
        
        write.table(l_var$Text_eq_Mat_Topo_this_N, file=name_txt, append = should_append, sep = "", dec = ".",
                    row.names = F, col.names = F, quote = FALSE)
      }
    }  
}




#' Name of the txt files with the commands for Macaulay2
#'
#' @param idx_Ni 
#' @param idx_Nj 
#' @param N_quartet_allowed 
#'
#' @return
#' @export
#'
#' @examples
file_name_for_print_Solve_Ni_vr_Nj_M2_txt <- function(idx_Ni,idx_Nj,N_quartet_allowed) {
  text_N_quartet_allowed <- paste(as.character(N_quartet_allowed),collapse = "")
  text_file_name <- paste0("Macaulay2_Rotations/SolveK4_N_allow",text_N_quartet_allowed,"_for_N",idx_Ni,"vrN",idx_Nj,".m2")
  return(text_file_name)
}


#' Name of the txt files with the commands for Macaulay2
#'
#' @param idx_Ni 
#' @param idx_Nj 
#' @param N_quartet_allowed 
#'
#' @return
#' @export
#'
#' @examples
file_name_for_print_Solve_Ni_vr_Nj_M2_txt_NO_FOLDER <- function(idx_Ni,idx_Nj,N_quartet_allowed) {
  text_N_quartet_allowed <- paste(as.character(N_quartet_allowed),collapse = "")
  text_file_name <- paste0("SolveK4_N_allow",text_N_quartet_allowed,"_for_N",idx_Ni,"vrN",idx_Nj,".m2")
  return(text_file_name)
}



#' Returs the variables that where found in the text
#'
#' OBS: It is important thot we first pun in the vector the variables that could
#' be contained in other variables. For instance, we put firts "zR1" and after 
#' "zR11".
#' 
#'
#' @param vec_all_var 
#' @param text 
#'
#' @return
#' @export
#'
#' @examples
#' vec_all_var <- c("zR0","zR1","zR2","zR3","zR10","zR11","zR12","zR13","gamR")
#' text <- "(1-gamR)*(1-(2/3)*zR0*zR10)+gamR*(1-(2/3)*zR10)"
#' vec_var_found <- find_variables_in_text(vec_all_var,text)
#' vec_var_found
find_variables_in_text <- function(vec_all_var,text) {
  vec_var_found <- NULL
  for(ii in length(vec_all_var):1) {
    (var_to_find <- vec_all_var[ii])
    if(length(grep(pattern = var_to_find,text))>0) {
      text <- gsub(var_to_find, "", text)
      vec_var_found <- c(vec_var_found,var_to_find)
    } 
  }
  vec_var_found <- sort(vec_var_found)
  return(vec_var_found)
}




#' Extended version of the matrix SUB_mat_eq_rotated_EXTENDED
#' 
#' This version has 3 differences with the SUB_mat_eq_rotated:
#'    1) We add the columns "vars N2","vars N3","vars N4" at the end. In 
#'       this case are the columns 8,9 and 10. This columns contain the 
#'       variables that appear in the equations of the rotations.
#'    2) We rename the column "z's" to "vars N1".
#'    3) We add the variable "gam" to the column "vars N1" since this is 
#'       better than in the current case were only the zs variables are 
#'       defined. 
#'
#' @param SUB_mat_eq_rotated 
#'
#' @return
#' @export
#'
#' @examples
gen_SUB_mat_eq_rotated_EXTENDED <- function(SUB_mat_eq_rotated) {
  # Initialization of SUB_mat_eq_rotated_EXTENDED
  SUB_mat_eq_rotated_EXTENDED <- matrix("",nrow(SUB_mat_eq_rotated),ncol(SUB_mat_eq_rotated)+3)
  SUB_mat_eq_rotated_EXTENDED[,1:ncol(SUB_mat_eq_rotated)] <- SUB_mat_eq_rotated
  colnames(SUB_mat_eq_rotated_EXTENDED) <- c(colnames(SUB_mat_eq_rotated[,-ncol(SUB_mat_eq_rotated)]),"vars N1","vars N2","vars N3","vars N4")
  # This loop goes from each of the new colums and give them the respective values.
  for(idx_rotation in 1:4) {
    j <- c(7,8,9,10)[idx_rotation]
    if(idx_rotation == 1) vec_all_var <- c("z0","z1","z2","z3","z10","z11","z12","z13","gam")
    if(idx_rotation == 2) vec_all_var <- c("zR0","zR1","zR2","zR3","zR10","zR11","zR12","zR13","gamR")
    if(idx_rotation == 3) vec_all_var <- c("zRR0","zRR1","zRR2","zRR3","zRR10","zRR11","zRR12","zRR13","gamRR")
    if(idx_rotation == 4) vec_all_var <- c("zRRR0","zRRR1","zRRR2","zRRR3","zRRR10","zRRR11","zRRR12","zRRR13","gamRRR")
    # This loop in on the rows that need to be added.
    for(i in 1:nrow(SUB_mat_eq_rotated_EXTENDED)) {
      (text <- SUB_mat_eq_rotated[i,j])
      vec_var_found <- find_variables_in_text(vec_all_var,text) 
      SUB_mat_eq_rotated_EXTENDED[i,j+4] <- paste0(vec_var_found,collapse = ",")
    }
  }
  return(SUB_mat_eq_rotated_EXTENDED)
}


#' Returns a vector of the unique values of the lists
#'
#' @param vec_of_lists 
#'
#' @return
#' @export
#'
#' @examples
#' vec_of_lists <- c("z11","z11","z11","gam,z0,z11", "gam,z0,z11","gam,z0,z11", "gam,z0,z1")
#' paste_multiple_text_list(vec_of_lists)
#' "gam,z0,z1,z11"
paste_multiple_text_list <- function(vec_of_lists) {
  paste0(sort(unique(unlist(strsplit(paste0(vec_of_lists,collapse = ","), split=',', fixed=TRUE)))),collapse = ",")
}



#' Text of the Macaulay2 files for the rotation analysis
#'
#' @param idx_Ni 
#' @param idx_Nj 
#' @param N_quartet_allowed 
#' @param SUB_mat_eq_rotated_EXTENDED 
#'
#' @return
#' @export
#'
#' @examples
#' cat("\014") # borra consola 
#' rm(list=ls())  # Borra todo
#' source("Fn phylo R.R")
#' Z0_t1 <- 0
#' K <- 4
#' #  # mat_eq_rotated <- gen_mat_TeX_and_Mat_rotation_comparison(K,Z0_t1)
#' mat_eq_rotated <- gen_mat_rotation_Diff_variables(K,Z0_t1)
#' idx_Ni <- 1
#' idx_Nj <- 2
#' N_quartet_allowed <- c(1,1,1,2)
#' 
#' SUB_mat_eq_rotated <- gen_SUB_mat_eq_rotated(N_quartet_allowed,mat_eq_rotated)
#' SUB_mat_eq_rotated_EXTENDED <- gen_SUB_mat_eq_rotated_EXTENDED(SUB_mat_eq_rotated)
text_Solve_Ni_vr_Nj_M2 <- function(idx_Ni,idx_Nj,N_quartet_allowed,SUB_mat_eq_rotated_EXTENDED) {
  # z_var <- unique(unlist(strsplit(paste0(SUB_mat_eq_rotated_EXTENDED[,11],",",collapse = ""), split=',', fixed=TRUE)))
  # text_z_var <- paste0(z_var,",",collapse = "")
  
  n_test <- nrow(SUB_mat_eq_rotated_EXTENDED)
  # n_test <- 9 # this line was for testing
  
  # Text variables
  text_N_quartet_allowed <- paste(as.character(N_quartet_allowed),collapse = "")
  text_file_name <- file_name_for_print_Solve_Ni_vr_Nj_M2_txt(idx_Ni,idx_Nj,N_quartet_allowed)
  how_many_eq <- nrow(SUB_mat_eq_rotated_EXTENDED)
  eq_numbers <- paste(SUB_mat_eq_rotated_EXTENDED[,1],collapse = ",")
  # Vectors with the variables (ie the z and gam)
  vec_of_lists <- SUB_mat_eq_rotated_EXTENDED[,idx_Ni+10]
  variables_eq_Ni <- paste_multiple_text_list(vec_of_lists)
  
  vec_of_lists <- SUB_mat_eq_rotated_EXTENDED[,idx_Nj+10]
  variables_eq_Nj <- paste_multiple_text_list(vec_of_lists)
  
  variables_eq_Ni_and_Nj <- paste0(variables_eq_Ni,",",variables_eq_Nj,collapse = "")
  
  # Initial text for Mathematica file
  ini_text <- paste0("------------------------------------------------------------------\n",
                     "--   Comparing equations of two rotations for 4-cycle networks  --\n",
                     "------------------------------------------------------------------\n",
                     "-- file name = ",text_file_name,
                     "\n-- N_allowed = ",text_N_quartet_allowed," (taxa allow in each of the four sub-trees)",
                     "\n-- First  rotation Ni = N",idx_Ni,
                     "\n-- Second rotation Nj = N",idx_Nj,
                     "\n-- How many equations: ",how_many_eq,
                     "\n-- Date of creation: ",format(Sys.time(), "%a %b %d %X %Y"),
                     "\n-- Equation numbers = ",eq_numbers,
                     "\n-- Generated by the function 'Gen_one_M2_rotation_file' of the file 'Fn phylo R.R'",
                     "\n-- Obs: the 'n=' are with respect to the N1 (non rotated) network",
                     "\n\n")
  
  text_R_QQ <- paste("R = QQ[",variables_eq_Ni_and_Nj,"]\n\n")
  
  text_equations <- "I = ideal("
  for(i in 1:n_test) {
    if(i<n_test) ending_comma <- ",\n\t" else ending_comma <- ")\n\n"
    new_line <- paste(SUB_mat_eq_rotated_EXTENDED[i,idx_Ni+6]," -( ",SUB_mat_eq_rotated_EXTENDED[i,idx_Nj+6],")",ending_comma)
    text_equations <- c(text_equations,new_line)
  }
  text_equations <- paste(text_equations,collapse = "")
  text_query_of_function <- "primaryDecomposition I"
  
  all_text <- paste(ini_text,text_R_QQ,text_equations,text_query_of_function)
  return(all_text)
}



#' Generation of one Macaulay2 file for the rotation analysis
#'
#' @param idx_Ni 
#' @param idx_Nj 
#' @param mat_eq_rotated 
#' @param N_quartet_allowed 
#'
#' @return
#' @export
#'
#' @examples
#' Z0_t1 <- 0
#' K <- 4
#' #  # mat_eq_rotated <- gen_mat_TeX_and_Mat_rotation_comparison(K,Z0_t1)
#' mat_eq_rotated <- gen_mat_rotation_Diff_variables(K,Z0_t1)
#' idx_Ni <- 1
#' idx_Nj <- 2
#' N_quartet_allowed <- c(1,1,1,2)
#' Gen_one_M2_rotation_file(idx_Ni,idx_Nj,N_quartet_allowed,mat_eq_rotated)
Gen_one_M2_rotation_file <- function(idx_Ni,idx_Nj,N_quartet_allowed,mat_eq_rotated) {
  # Generation of the needed matrix withe the text
  SUB_mat_eq_rotated <- gen_SUB_mat_eq_rotated(N_quartet_allowed,mat_eq_rotated)
  SUB_mat_eq_rotated_EXTENDED <- gen_SUB_mat_eq_rotated_EXTENDED(SUB_mat_eq_rotated)
  # The next line generates the Macaulay2 file
  capture.output(cat(text_Solve_Ni_vr_Nj_M2(idx_Ni,idx_Nj,N_quartet_allowed,SUB_mat_eq_rotated_EXTENDED)),
                 file = file_name_for_print_Solve_Ni_vr_Nj_M2_txt(idx_Ni,idx_Nj,N_quartet_allowed))
  # And the next one only prints the messsage of confirmation
  cat("The file ",file_name_for_print_Solve_Ni_vr_Nj_M2_txt(idx_Ni,idx_Nj,N_quartet_allowed),"was generated\n")
}


#' This function generates all the Macaulay2 files  in the folder Macaulay2_Rotations
#'
#' @return
#' @export
#'
#' @examples
Gen_All_M2_rotation_file <- function(){
  
  Z0_t1 <- 0
  K <- 4
  # mat_eq_rotated <- gen_mat_TeX_and_Mat_rotation_comparison(K,Z0_t1)
  mat_eq_rotated <- gen_mat_rotation_Diff_variables(K,Z0_t1)
  
  mat_N_quartet_allowed <- matrix(c(1,1,1,2,
                                    1,1,2,2,
                                    1,2,2,2,
                                    2,2,2,2),ncol=4,byrow = T)
  idx_Ni <- 1
  
  idx_Nj <- 2
  i <- 1
  # The next double loop goes for each possible allowed arrangement of taxa comming
  # from the sub-trees and for each possible rotation
  for(idx_Nj in 2:4) for(i in 1:nrow(mat_N_quartet_allowed)) {
    N_quartet_allowed <- mat_N_quartet_allowed[i,]
    Gen_one_M2_rotation_file(idx_Ni,idx_Nj,N_quartet_allowed,mat_eq_rotated)
  }
}


#' This function generates the text to run in console
#'
#' @return
#' @export
#'
#' @examples
text_to_run_Rotations_on_cluster <- function() {
  
  Z0_t1 <- 0
  K <- 4
  # mat_eq_rotated <- gen_mat_TeX_and_Mat_rotation_comparison(K,Z0_t1)
  mat_eq_rotated <- gen_mat_rotation_Diff_variables(K,Z0_t1)
  
  mat_N_quartet_allowed <- matrix(c(1,1,1,2,
                                    1,1,2,2,
                                    1,2,2,2,
                                    2,2,2,2),ncol=4,byrow = T)
  
  idx_Ni <- 1
  idx_Nj <- 2
  i <- 1
  for(idx_Nj in 2:4) for(i in 1:nrow(mat_N_quartet_allowed)) {
    N_quartet_allowed <- mat_N_quartet_allowed[i,]
    # Text variables needed
    file_M2 <- file_name_for_print_Solve_Ni_vr_Nj_M2_txt_NO_FOLDER(idx_Ni,idx_Nj,N_quartet_allowed)
    file_output <- paste0(c(substr(file_M2,1,nchar(file_M2)-3),"_out.txt"),collapse = "")
    
    
    name_of_screen <- substr(file_M2,1,nchar(file_M2)-3)
    text_to_print <- c("### To run ",file_M2,"  \n",
                       "```shell\n",
                       "ssh acoencoria@solislemus-001.discovery.wisc.edu\n",
                       "FpD2!CTe\n",
                       "cd /mnt/dv/wid/projects1/SolisLemus-ArrigoCC/\n",
                       "screen -S ",name_of_screen,"\n",
                       "# Ctrl+a, d = to detach the screen\n",
                       "# Ctrl+a, k = to KILL the screen\n",
                       "module load M2-1.14\n",
                       "cat ",file_M2," | M2 &> ",file_output,"\n",
                       "```\n\n",
                       "Start Nov 04 19:00\n",
                       "```shell\n",
                       "screen -r ",name_of_screen,"\n",
                       "# Ctrl+a, d = to detach the screen\n",
                       "# Ctrl+a, k = to KILL the screen\n",
                       "```\n\n")
    # Print of the variables
    cat(text_to_print)
  }
}


