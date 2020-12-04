# Generating input files for PhyloKnit

**PhyloKnit** will be a web application that allows biologists to visualize complex phylogenetics networks. The inputs that it can accept are in different formats like Hyde, Parenthetical, Triplets, etc.

In this folder are presented some programs to generate the inputs in HyDe, Parenthetical and Triplet.

## Simulation of Parenthetical Format

To simulate the parenthetical format we could run the next R commands:

```
cat("\014") # 
rm(list=ls())  # 
# set.seed(42)

source("Fn_random_trees.R")
n <- 15 # n is the number of taxa to use
file_name <- "Parenthetical_file" # name of the output files
Sim_Parenthetical(n,file_name)
```

Where `n` is the number of taxa and `file_name` is the name of the output files.


## Simulation of Triplet Format

To simulate the triplet format we could run the next R commands:

```

cat("\014") 
rm(list=ls())  
# set.seed(42)

# Obs: the triplet format is ===> 1 2 3 => ((1,2),3)
source("Fn_random_trees.R")

n <- 5
file_name <- "Triplets_file"

Sim_Triplets(n,file_name)
```

Where `n` is the number of taxa and `file_name` is the name of the output files.
