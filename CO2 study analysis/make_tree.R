library(V.PhyloMaker2)
library(dplyr)

# PhyloMaker takes a dataframe with species, genus, and family columns (see Jin and Qian 2019 paper)
here::i_am("make_tree.R")

sp_list <- readxl::read_xlsx(here::here("species_list.xlsx"))

# PhyloMaker generates the phylogeny using three approaches (what they call "scenarios")
result <- phylo.maker(sp_list, scenarios = c("S1", "S2", "S3"))

# The approaches lead to very similar phylogenies and divergence times. 
# I suggest using 1 or 3, because they keep uncertain relationships as polytomies (i.e., more conservative).

#plot.phylo(result$scenario.1, cex = 1.5, main = "scenario.1")
# nodelabels(round(branching.times(result$scenario.1), 1), cex = 1)
plot.phylo(result$scenario.2, cex = 1.5, main = "scenario.2")
nodelabels(round(branching.times(result$scenario.2), 1), cex = 1)
plot.phylo(result$scenario.3, cex = 1.5, main = "scenario.3")
nodelabels(round(branching.times(result$scenario.3), 1), cex = 1)

tree <- result$scenario.3
tree$tip.label <- paste(tree$tip.label %>% stringr::word(1, sep = "_") %>% substr(1, 1), tree$tip.label %>% stringr::word(2, sep = "_"), sep = ". ")

# Save scenario 3 as a file
ape::write.tree(tree, here::here("data/co2_species_tree.tre"))

########
# C4s!

sp_list_c4 <- readxl::read_xlsx(here::here("species_list_c4.xlsx"))

# PhyloMaker generates the phylogeny using three approaches (what they call "scenarios")
result_c4 <- phylo.maker(sp_list_c4, scenarios = c("S1", "S2", "S3"))

# The approaches lead to very similar phylogenies and divergence times. 
# I suggest using 1 or 3, because they keep uncertain relationships as polytomies (i.e., more conservative).

#plot.phylo(result$scenario.1, cex = 1.5, main = "scenario.1")
# nodelabels(round(branching.times(result$scenario.1), 1), cex = 1)
plot.phylo(result_c4$scenario.2, cex = 1.5, main = "scenario.2")
nodelabels(round(branching.times(result_c4$scenario.2), 1), cex = 1)
plot.phylo(result_c4$scenario.3, cex = 1.5, main = "scenario.3")
nodelabels(round(branching.times(result_c4$scenario.3), 1), cex = 1)

tree_c4 <- result_c4$scenario.3
tree_c4$tip.label <- paste(tree_c4$tip.label %>% stringr::word(1, sep = "_") %>% substr(1, 1), tree_c4$tip.label %>% stringr::word(2, sep = "_"), sep = ". ")

# Save scenario 3 as a file
ape::write.tree(tree_c4, here::here("data/co2_species_tree_c4.tre"))
