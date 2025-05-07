## Import das bibliotecas

library(readxl)
library(data.table)
library(stringr)
library(lubridate)
library(tidyr)
library(dplyr)
library(zoo)

Sys.setlocale("LC_TIME", "C")
set.seed(123)

sis <- Sys.info()[[1]]

pathOS <- getwd()#paste0(dirname(getSourceEditorContext()$path),"/")



UNI <- 'Madrid Rio'
UNI_2 <- 'MADRID RÍO'
# SEC <- 'Cajas'
# FK_POSTO <- 307


files = list.files(path = paste0(pathOS,'/Data/Outputs/', UNI), full.names = T)

filesnames <- sapply(strsplit(files,"_"), tail, 1) %>% unique()

folgas <- data.table()


# f = filesnames[1] ### usar quando short term
for (f in filesnames) {
  
  df_folgas <- read.csv2(file = paste0(pathOS,'/Data/Outputs/', UNI, '/matriz_2023-12-21_', UNI_2, '_', f), fileEncoding = 'UTF-8-BOM',
                         check.names=FALSE)
  
  
  df_folgas <- reshape2::melt(df_folgas,id.vars='COLABORADOR')
  
  names(df_folgas) <- c("COLABORADOR","DATA","TIPO_TURNO")
  
  
  df_folgas <- df_folgas %>%
    dplyr::mutate(TIPO_TURNO = ifelse(TIPO_TURNO == 'FALSE', 'F', TIPO_TURNO),
                  TIPO_TURNO = ifelse(TIPO_TURNO == 'TRUE', 'T', TIPO_TURNO))
  
  df_folgas <- df_folgas %>% filter(DATA != '', DATA != 'FK_TIPO_POSTO') %>% filter(COLABORADOR != 'TIPO_DIA')
  
  
  names(df_folgas) <- c("COLABORADOR","DATA","TIPO")
  

  df_folgas$DATA <- as.character(as.Date(df_folgas$DATA, format = "%d/%m/%Y"))
  
  
  folgas <- rbind(folgas,
                  data.table(df_folgas))
  
}


# matrizFolgasWFM <- matrizFolgasWFM %>% dplyr::filter(TIPO_TURNO != 0)



write.csv2(folgas, paste0("Data/intBD/matriz_BD_",Sys.Date(),"_",UNI,".csv"))

