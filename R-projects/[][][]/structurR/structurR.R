#CH 0: Libraries ----
library(dplyr)
library(ggplot2)
library(readr)
library(stringr)
library(lubridate)
library(tidyr)
library(forcats)
library(praise)
library(purrr)
library(vcfR)
library(poppr)
library(ape)
library(RColorBrewer)
#CH 1: Building a table of populations for samples ----

pop_table <- read_csv("data/Pop_Spread_Table_Final.csv") %>%
  select(SAMPLE) %>%
  unique()
pop_table <- pop_table %>%
  rename("individualreorder"="SAMPLE")
pop_table <- pop_table %>%
  mutate(index=row_number()) %>%
  mutate(individual=individualreorder) %>%
  mutate(site=str_sub(individual, start = 1, end = 3)) %>%
  mutate(river=case_when(
    site%in%c("HUX","TMR","HHT","HRM","LLB") ~ "Huron",
    site%in%c("KOB","KOA","KOC","KOK","KDN","KGL") ~ "Kokosing",
    site=="BOK" ~ "bok",
    site=="STW" ~ "stw",
    site=="CRM" ~ "crm",
    site=="SCL" ~ "scl",
    site=="VSG" ~ "vsg")) %>%
  mutate(species=case_when(
    river%in%c("Huron","Kokosing") ~ "Hybrid",
    river%in%c("bok","stw") ~ "Rusticus",
    river%in%c("crm","scl","vsg") ~ "Samborni")) %>%
  select(!individualreorder)
write_csv(pop_table,"data/population_table.csv")

#CH 1.5: reading the already made pop_table and sorting it ----
pop_table <- read_csv("data/population_table.csv")
pop_table_sort <- pop_table %>%
  arrange(individual)

#CH 2: vcf-> genlight ----
the_vcf <- read.vcfR("data/first_filter.vcf.gz")
genlight <- vcfR2genlight(the_vcf)
ploidy(genlight) <- 2

#CH 3: Pop table pain ----
#attempting to reconcile the differences in the pop table that has everything and the pop table which is accurate to the vcf. annoyingly
pops_t <- pull(pop_table_sort,individual)
pops_v <- genlight@ind.names
pops_true <- pops_t%in%pops_v
pop_table_valid <- pop_table_sort %>%
  mutate(keep=pops_true) %>%
  filter(keep==TRUE) %>%
  select(!keep)

#my previous attempts to remove KOC14_LN2 from the vcf have failed, somehow... this warrents more investigation but for now i am gonna make a new version of the pop table that has kocln2
koc_pain <- tibble(index=999,individual="KOC14_LN2",site="KOC",river="Kokosing",species="Hybrid")
pop_table_pain <- add_row(pop_table_valid,koc_pain) %>%
  arrange(individual)

#CH 4: adding the pop table ----
pop(genlight) <- pop_table_pain$species

#CH 5: DAPC ----
genlight.dapc <- dapc(genlight, n.pca = 3, n.da = 2)

compoplot(genlight.dapc,col = cols, posi = 'top')
#this is not working AHH: some 'col_types' are not S3 collector objects: 1
compoplot(genlight.dapc, posi = 'top')
#CH 6: trying it with the normal data ----
rubi.VCF <- read.vcfR("data/prubi_gbs.vcf.gz")
pop.data <- read.table("data/population_data.gbs.txt", sep = "\t", header = TRUE)
all(colnames(rubi.VCF@gt)[-1] == pop.data$AccessID)
gl.rubi <- vcfR2genlight(rubi.VCF)
ploidy(gl.rubi) <- 2
pop(gl.rubi) <- pop.data$State
pnw.dapc <- dapc(gl.rubi, n.pca = 3, n.da = 2)
scatter(pnw.dapc, col = cols, cex = 2, legend = TRUE, clabel = F, posi.leg = "bottomleft", scree.pca = TRUE,posi.pca = "topleft", cleg = 0.75)
compoplot(pnw.dapc,col = cols, posi = 'top')
compoplot(pnw.dapc, posi = 'top')
?dapc


#CH 7 angiemeetin----
#by site
genlightSite <- vcfR2genlight(the_vcf)
ploidy(genlightSite) <- 2
pop(genlightSite) <- pop_table_pain$site
site.dapc <- dapc(genlightSite, n.pca = 3, n.da = 2)
compoplot(site.dapc, posi = 'top')

#tree
tree <- aboot(genlightSite, tree = "upgma", distance = bitwise.dist, sample = 100, showtree = F, cutoff = 50, quiet = T)
cols <- brewer.pal(n = nPop(genlightSite), name = "Dark2")
plot.phylo(tree, cex = 0.8, font = 2, adj = 0, tip.color =  cols[pop(genlightSite)])
nodelabels(tree$node.label, adj = c(1.3, -0.5), frame = "n", cex = 0.8,font = 3, xpd = TRUE)
#legend(35,10,c("CA","OR","WA"),cols, border = FALSE, bty = "n")
legend('topleft', legend = c("CA","OR","WA"), fill = cols, border = FALSE, bty = "n", cex = 2)
axis(side = 1)
title(xlab = "Genetic distance (proportion of loci that are different)")