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

#CH 1: Reading data ----
#reading is simple
VCF <- read.vcfR("data/all.vcf")

#now we convert to a tibble and hope that it doesnt break
VCF_tidy_all <- vcfR2tidy(VCF)
#this tibble seems to have a lot of data that we dont need, i think i can jsut extract the stuff in this way

#this gives us a nicer tibble that has already been made longer for me
VCF_tidy <- VCF_tidy_all[["gt"]]

#now then lets not forget to remove KOC14_L2, and hope nothing breaks 	
VCF_tidy <- VCF_tidy %>%
  filter(Indiv!="KOC14_LN2")


#CH2: encoding presence ----
#ok lets add a presence column
VCF_work <- VCF_tidy %>%
  mutate(present=case_when(
    gt_CATG=="0,0,0,0" ~ FALSE,
    .default = TRUE
  ))

#CH 3: Wide time ----

#now we wider by sample so that we can do some population based counting. we need these population numbers for filtration. also adding an index column
VCF_work_w <- VCF_work %>%
  select(c(ChromKey,POS,Indiv,present)) %>%
  pivot_wider(names_from=Indiv,values_from=present) %>%
  mutate(index=row_number())

#CH 4: Encoding populations ----
#now we do the higher level population encoding
VCF_work_w <- VCF_work_w %>%
  mutate(HUX_PRESENT = select(.,HUX01:HUX14)%>%rowSums(),#this is a genius way of doing this. We select all of the columns representing individuals in a single population we want since they are next to each other, this essentially creates an ephemeral dataframe, which can be rowsummed to make a single column. We set this to the mutate
         TMR_PRESENT = select(.,TMR01:TMR14)%>%rowSums(), #I dont know why we need the . but we do
         HHT_PRESENT = select(.,HHT01:HHT14)%>%rowSums(),
         HRM_PRESENT = select(.,HRM01:HRM14)%>%rowSums(),         
         LLB_PRESENT = select(.,LLB01:LLB14)%>%rowSums(),         
         KOB_PRESENT = select(.,KOB01:KOB15)%>%rowSums(), 
         KOA_PRESENT = select(.,KOA01:KOA14)%>%rowSums(),
         KOC_PRESENT = select(.,KOC01:KOC14)%>%rowSums(),
         KOK_PRESENT = select(.,KOK01:KOK14)%>%rowSums(),
         KDN_PRESENT = select(.,KDN01:KDN14)%>%rowSums(),
         KGL_PRESENT = select(.,KGL01:KGL14)%>%rowSums(),
         BOK_PRESENT = select(.,BOK01:BOK14)%>%rowSums(),
         STW_PRESENT = select(.,STW01:STW14)%>%rowSums(),
         CRM_PRESENT = select(.,CRM01:CRM14)%>%rowSums(),
         SCL_PRESENT = select(.,SCL01:SCL14)%>%rowSums(),
         VSG_PRESENT = select(.,VSG01:VSG14)%>%rowSums())

VCF_work_w <- VCF_work_w %>%
  mutate(HURON = select(.,HUX_PRESENT,TMR_PRESENT,HHT_PRESENT,HRM_PRESENT,LLB_PRESENT)%>%rowSums(),
         KOKOSING = select(.,KOB_PRESENT,KOA_PRESENT,KOC_PRESENT,KOK_PRESENT,KDN_PRESENT,KGL_PRESENT)%>%rowSums(),
         RUSTICUS = select(.,BOK_PRESENT,STW_PRESENT)%>%rowSums(),
         SAMBORNI = select(.,CRM_PRESENT,SCL_PRESENT,VSG_PRESENT)%>%rowSums())

VCF_work_w <- VCF_work_w %>%
  mutate(TOTAL=select(.,HURON:SAMBORNI)%>%rowSums())

#making a table without the individuals
VCF_work_summary <- VCF_work_w %>%
  select(ChromKey,POS,index:TOTAL)

#CH 5: filtration ----

#for now im just gonna do a pretty simple filtration
VCF_filtered <- VCF_work_summary %>%
  filter(HURON>=5 & KOKOSING>=5 & RUSTICUS>=5 & SAMBORNI>=5)
#create a list which we can use to modify the original vcf
gold <- pull(VCF_filtered,index)

#CH 6: VCF modification ----
VCF_modified <- VCF
VCF_mod_gt <- VCF@gt[gold,]
VCF_mod_fix <- VCF@fix[gold,]
VCF_modified@gt <- VCF_mod_gt
VCF_modified@fix <- VCF_mod_fix
#i think that does it, now lets write this badboy
write.vcf(VCF_modified,"data/first_filter.vcf.gz")
