#-------------------------------------------------------------------------#
#                                                                         #
#                           Random tree simulator                         #
#                                                                         #
#-------------------------------------------------------------------------#

# USED PACKAGES -----------------------------------------------------------

library(ape)
# library(readtext)


# Functions ---------------------------------------------------------------

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
  }
  return(x)
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




#' Sonting the Newick format
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
  
  return(x)
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
  if(length(x)==1) x <- expand_Newick_format(x)
  taxa_place <- which(x==taxa_to_eliminate)
  taxa_place
  if(length(taxa_place)==0) {
    print("You try to eliminate a not existing taxa")
    return(x)
  }
  if(taxa_place==length(x)-1) {
    x <- ordering_Newick(x[2:(length(x)-3)])
    return(x)
  }
  if(taxa_place==length(x)-1) {
    x <- ordering_Newick(x[2:(length(x)-3)])
    return(x)
  }
  if(taxa_place==2) {
    x <- ordering_Newick(x[4:(length(x)-1)])
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
  # x <- ordering_Newick(x)
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
  for(taxa_to_eliminate in vec_taxa_to_eliminate) x <- errase_taxa(x,taxa_to_eliminate)
  return(x)
}


