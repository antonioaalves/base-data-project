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



UNI <- 'FÁTIMA'
SEC <- 'Cajas'
FK_POSTO <- 229



folgas <- read.csv2(paste0(pathOS,"/Data/Outputs/Fátima/matriz_2023-12-20_", UNI,"_", FK_POSTO, ".csv"), fileEncoding = 'UTF-8-BOM', check.names=FALSE)
csvs_joao <- read.csv2(paste0(pathOS,"/Data/CSV/",FK_POSTO,".csv"), fileEncoding = 'UTF-8-BOM', header = F,check.names=FALSE)


folgas <- reshape2::melt(folgas,id.vars='COLABORADOR')

names(folgas) <- c("COLABORADOR","DATA","TIPO_TURNO")

folgas <- folgas %>%
  dplyr::mutate(TIPO_TURNO = ifelse(TIPO_TURNO == 'FALSE', 'F', TIPO_TURNO))

folgas <- folgas %>% filter(DATA != '') %>% filter(COLABORADOR != 'TIPO_DIA')


names(folgas) <- c("COLABORADOR","DATA","TIPO_TURNO_2")

# names(folgas) <- c("EMPLOYEE_ID","SCHEDULE_DT","SCHED_SUBTYPE")

csvs_joao <- csvs_joao %>%
  dplyr::mutate(across(-1,
                       ~ ifelse(V1 == "DIA", as.character(as.Date(., format = "%d/%m/%Y")), .))
  )

names(csvs_joao) <- paste0(csvs_joao[csvs_joao$V1=='DIA',],"_",csvs_joao[csvs_joao$V1=='TURNO',])

csvs_joao <- reshape2::melt(csvs_joao,id.vars='DIA_TURNO')
names(csvs_joao) <- c("COLABORADOR","DATA","TIPO_TURNO")

csvs_joao <- csvs_joao %>% 
  dplyr::filter(!(COLABORADOR %in% c("DIA","maxTurno","mediaTurno","minTurno","sdTurno"))) %>% 
  dplyr::filter(COLABORADOR != 'TURNO')

csvs_joao$DATA <- sub("_.*$", "", csvs_joao$DATA)

csvs_joao <- csvs_joao%>% filter(COLABORADOR != 'TIPO_DIA')


matrizFolgasWFM <- merge(csvs_joao, folgas, by=c("COLABORADOR","DATA"), all=T)

names(matrizFolgasWFM) <- c("EMPLOYEE_ID","SCHEDULE_DT","SCHED_TYPE","SCHED_SUBTYPE")

matrizFolgasWFM <- matrizFolgasWFM %>%
  dplyr::mutate(SCHED_TYPE = case_when(
    SCHED_SUBTYPE == 'L'  ~ 'F',
    SCHED_SUBTYPE == 'LD'  ~ 'F',
    SCHED_SUBTYPE == 'C'  ~ 'F',
    SCHED_SUBTYPE == 'LQ'  ~ 'F',
    SCHED_SUBTYPE == '-'  ~ 'F',
    T ~ SCHED_TYPE
  ))



matrizFolgasWFM <- matrizFolgasWFM %>%
  dplyr::mutate(SCHED_SUBTYPE = case_when(
    SCHED_TYPE == 'V'  ~ 'Ferias',
    T ~ SCHED_SUBTYPE
  ))


matrizFolgasWFM <- matrizFolgasWFM %>%
  dplyr::mutate(SCHED_TYPE = case_when(
    SCHED_TYPE == 'M'  ~ 'T',
    SCHED_TYPE == 'T'  ~ 'T',
    SCHED_TYPE == 0  ~ 'T',
    T ~ SCHED_TYPE
  ))


matrizFolgasWFM <- matrizFolgasWFM %>%
  dplyr::mutate(SCHED_SUBTYPE = case_when(
    SCHED_TYPE == 'T'  ~ '',
    T ~ SCHED_SUBTYPE
  ))

matrizFolgasWFM <- distinct(matrizFolgasWFM)

# matrizFolgasWFM <- matrizFolgasWFM %>% dplyr::filter(TIPO_TURNO != 0)



write.csv2(matrizFolgasWFM, paste0("Data/intWFM/matriz_WFM_",Sys.Date(),"_",UNI,"_", FK_POSTO,".csv"))

