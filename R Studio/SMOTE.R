rm(list=ls())

library(caret)
library(DMwR)
library(dummies)

df <- read.csv("C:/Users/theloloboss/Desktop/scoring/subsample_df.csv")

attach(df)
names(df)
head(df)


df = df[,-c(2,3,4)]
sapply(df,class)
sapply(df,factor)


#statistique descriptive


#changer la variable de defaut pour le smote (prend que les facteurs 1 et 2)

df$WE18[df$WE18==1]=2
df$WE18[df$WE18==0]=1

df$WE18 = as.factor(df$WE18)
sapply(df,fact)

typeof(df)

df_smote=SMOTE(WE18~., df, perc.over = 800, k = 5, perc.under = 400)
table(df_smote$WE18)
prop.table(table(df_smote$WE18))

df_smote$WE18 = as.integer(df_smote$WE18)

df_smote$WE18[df_smote$WE18==1]=0
df_smote$WE18[df_smote$WE18==2]=1

df_smote[sample(nrow(df_smote)),]

df_smote$fichage = round(df_smote$fichage,0)
df_smote$bdf_cote = round(df_smote$bdf_cote,0)
df_smote$duree_cl = round(df_smote$duree_cl,0)
df_smote$pc_appo2 = round(df_smote$pc_appo2,0)
df_smote$age2 = round(df_smote$age2,0)
df_smote$mt_rev2 = round(df_smote$mt_rev2,0)
df_smote$part_loyer2 = round(df_smote$part_loyer2,0)
df_smote$anc_emp2 = round(df_smote$anc_emp2,0)


write.csv(df_smote,"C:/Users/theloloboss/Desktop/scoring/df_smote.csv")


