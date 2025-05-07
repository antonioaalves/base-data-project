# library(dplyr)
# library(rstudioapi)
# library(readxl)
# library(data.table)
# library(dplyr)
# library(stringr)
# library(plotly)
# library(htmltools)
# library(ggplot2)
# library(forecast)
# library(readr)
# library(tidyr)
# library(scales)
# library(lubridate)
# library(chron)
# Sys.setlocale("LC_TIME", lang)

########################################################################################################################
########################################################################################################################
##################################### GERACAO DO FICHEIRO GRANULARIDADE.CSV ############################################
########################################################################################################################
########################################################################################################################


# minData <- startDate2
# maxData <- endDate2
# fk_unidade <- unitID
# fk_secao <- secaoID
# fk_tipo_posto <- posto
output_gran <- function(pathConf = pathFicheirosGlobal, minData = '2025-01-01', maxData = '2025-12-31',
                        fk_unidade, fk_secao, fk_tipo_posto){
  
  
  Sys.setlocale("LC_TIME", lang)
  
  # dfOrcamento <- get_esc_orcamento(pathConf, minData, maxData,fk_tipo_posto, erro_control = 0)
  dfOrcamento <- get_esc_estimado(pathConf, minData, maxData,fk_tipo_posto, erro_control = 0)
  
  dfOrcamento <- dfOrcamento %>% dplyr::filter(FK_TIPO_POSTO==fk_tipo_posto)
  
  dfOrcamento$DATA <- as.Date(dfOrcamento$DATA, format='%Y-%m-%d', tz='GMT')
  dfOrcamento$HORA_INI <- as.POSIXct(dfOrcamento$HORA_INI, format='%Y-%m-%d %H:%M:%S', tz='GMT')
  dfOrcamento$HORA_FIM <- dfOrcamento$HORA_INI + 15*60
  dfOrcamento$VALOR <- as.double(dfOrcamento$VALOR)
  dfOrcamento$ITENS <- as.double(dfOrcamento$ITENS)
  
  
  dfOrcamento <- dfOrcamento %>%
    dplyr::mutate(FC_gran=FC/4,
                  VALOR_POSTO=round(VALOR*PERCENTUAL_POSTO,2),
                  ITENS_POSTO=round(ITENS*PERCENTUAL_POSTO,0),
                  #PDVS=ceiling(ITENS_POSTO/FC_gran)
    )
  
  dfOrcamento$weekday_num <- lubridate::wday(dfOrcamento$DATA)
  portuguese_labels <- c("Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb")
  dfOrcamento$WD <- portuguese_labels[dfOrcamento$weekday_num]
  dfOrcamento$weekday_num <- NULL
  # dfOrcamento$WD <- lubridate::wday(dfOrcamento$DATA, label=T, abbr = T, locale = lang)
  
  dfOrcamento$WD <- as.character(dfOrcamento$WD)
  
  dfOrcamento <- dfOrcamento  %>% 
    dplyr::mutate(across(where(is.character), ~ iconv(., from = "UTF-8",  to = "UTF-8"))) %>% 
    dplyr::mutate(WD = ifelse(is.na(as.character(WD)),'sáb',as.character(WD)))
  
  Sys.setlocale("LC_TIME", lang)
  dfFeriados <- get_feriados(pathConf, erro_control = 0)
  
  names(dfFeriados) <- c('FK_UNIDADE', 'DATA')
  dfFeriados <- dfFeriados %>% 
    dplyr::filter(FK_UNIDADE==fk_unidade)
  
  dfFeriados$DATA <- as.Date(dfFeriados$DATA, format='%Y-%m-%d', tz='GMT')
  
  if (nrow(dfFeriados)>0) {
    dfFeriados$TIPO_DIA <- 'FERIADO'
    
    ano <- year(minData)
    
    dfFeriados <- dfFeriados %>% 
      dplyr::filter((DATA >= minData & DATA <= maxData) | DATA <'2000-12-31') %>%
      dplyr::mutate(DATA=update(DATA, year = ano))
    
    
    dfOrcamento2 <- merge(dfOrcamento, dfFeriados, by=c('FK_UNIDADE', 'DATA'), all.x=T)
    
    dfOrcamento2 <- dfOrcamento2 %>% 
      dplyr::mutate(TIPO_DIA=ifelse(is.na(TIPO_DIA), WD, 'fer')) %>% 
      dplyr::select(-WD) %>% 
      dplyr::rename(WD=TIPO_DIA)
  } else{
    dfOrcamento2 <- dfOrcamento
  }
  # kapa <<- dfOrcamento2
  ## vai buscar as faixas horarias - FILE
  # dfFaixaHorario <- read.delim('data/escFaixaHorario.txt', sep= '|', fileEncoding = "UTF-8-BOM")
  Sys.setlocale("LC_TIME", lang)
  dfFaixaHorario <- get_esc_faixa_horario(pathConf, erro_control = 0)
  
  dfFaixaHorario <- dfFaixaHorario %>% dplyr::filter(FK_SECAO==fk_secao)
  
  
  dfFaixaHorario <- dfFaixaHorario[1,]
  
  dfFaixaHorario <- pivot_longer(dfFaixaHorario, 
                                 cols=c("ABER_SEG", "FECH_SEG","ABER_TER","FECH_TER","ABER_QUA","FECH_QUA","ABER_QUI","FECH_QUI",
                                        "ABER_SEX","FECH_SEX","ABER_SAB","FECH_SAB","ABER_DOM","FECH_DOM","ABER_FER","FECH_FER"),
                                 names_to = 'WD_AB')
  
  dfFaixaHorario <- dfFaixaHorario %>%
    separate(WD_AB, into = c("A_F", "WD"), sep = "_")
  
  dfFaixaHorario <- pivot_wider(dfFaixaHorario, 
                                names_from = 'A_F')
  
  dfFaixaHorario$WD <- tolower(dfFaixaHorario$WD)
  
  # dfFaixaHorario <- dfFaixaHorario %>%
  #   mutate(WD=iconv(WD, from = "UTF-8", to = "UTF-8"))
  
  dfFaixaHorario$WD <- gsub("sab", "sáb", dfFaixaHorario$WD)
  
  dfFaixaHorario <- dfFaixaHorario %>% 
    dplyr::mutate(across(where(is.character), ~ iconv(., from = "UTF-8",  to = "UTF-8"))) %>% 
    dplyr::mutate(WD = ifelse(is.na(as.character(WD)),'sáb',as.character(WD)))
  
  dfFaixaHorario$ABER <- as.POSIXct(dfFaixaHorario$ABER, format='%Y-%m-%d %H:%M:%S', tz='GMT')
  dfFaixaHorario$FECH <- as.POSIXct(dfFaixaHorario$FECH, format='%Y-%m-%d %H:%M:%S', tz='GMT')
  
  
  # dfFaixaHorario <- dfFaixaHorario %>%
  #   mutate(WD=iconv(WD, from = "UTF-8", to = "UTF-8"))
  
  dfOrcamento2$WD <- tolower(dfOrcamento2$WD)
  dfOrcamento2$WD <- gsub("sab", "sáb", dfOrcamento2$WD)
  
  dfOrcamento3 <- merge(dfOrcamento2, dfFaixaHorario, by=c('FK_SECAO', 'WD'), all.x=T)
  
  dfOrcamento3 <- dfOrcamento3 %>% 
    dplyr::mutate(RESULT=ifelse(HORA_INI>=ABER & HORA_INI<FECH, 1, 0))
  
  dfOrcamento3 <- dfOrcamento3 %>% 
    dplyr::filter(RESULT==1)
  
  dfOrcamento3 <- dfOrcamento3 %>% 
    dplyr::select(-c(ABER, FECH, RESULT))
  
  dfOrcamento3 <- dfOrcamento3 %>%
    dplyr::mutate(PDVS=ifelse(PDVS==0 & ITENS_POSTO>0, 1, PDVS))
  
  if(all(is.na(dfFaixaHorario))) { return(0)}
  
  #print("valida sem tem NAs")
  #subset(dfOrcamento3, apply(dfOrcamento3, 1, function(row) any(is.na(row)))) %>% View()
  # kapa3 <<- dfOrcamento3
  
  ## calcula os minimos -> exc QTD + minimos posto - FILE
  # dfExcQTD <- read.delim('data/excecoesQuantidade.txt', sep='|')
  
  # writeLog(log_x = "GRANULARIDADE: LOAD EXC_QUANTIDADE", 
  #          logFile = logFile)
  
  dfExcQTD <- get_excecoes_quantidade(pathConf, erro_control = 0)
  
  # writeLog(log_x = paste0("DIAS SEMANAS 3.1.2:", unique(dfExcQTD$WD)), 
  #          logFile = logFile)
  
  dfExcQTD$HORA_INI <- as.POSIXct(dfExcQTD$HORA_INI, format='%Y-%m-%d %H:%M:%S', tz='GMT')
  dfExcQTD$HORA_FIM <- as.POSIXct(dfExcQTD$HORA_FIM, format='%Y-%m-%d %H:%M:%S', tz='GMT')
  
  dfExcQTD <- dfExcQTD %>% dplyr::filter(FK_TIPO_POSTO==fk_tipo_posto)
  
  if(nrow(dfExcQTD)>0){
    
    dfExcQTD<- dfExcQTD %>%
      rowwise() %>%
      transmute(FK_TIPO_POSTO,DIA_SEMANA, QTD,
                HORA_INI = list(seq(HORA_INI, HORA_FIM-60*15, by = "15 min"))) %>%
      unnest(HORA_INI) %>% distinct
    
    dfExcQTD <- dfExcQTD %>%
      dplyr::group_by(DIA_SEMANA, FK_TIPO_POSTO, HORA_INI) %>%
      dplyr::summarise(QTD=sum(QTD),
                       .groups='drop')
    
    dfExcQTD <- dfExcQTD  %>% 
      mutate(across(where(is.character), ~ iconv(., from = "UTF-8", to = "UTF-8"))) %>% 
      dplyr::mutate(WD=case_when(
        DIA_SEMANA==1 ~ 'seg',
        DIA_SEMANA==2 ~ 'ter',
        DIA_SEMANA==3 ~ 'qua',
        DIA_SEMANA==4 ~ 'qui',
        DIA_SEMANA==5 ~ 'sex',
        DIA_SEMANA==6 ~ 'sáb',
        DIA_SEMANA==7 ~ 'dom',
        DIA_SEMANA==8 ~ 'fer'
      ))
     
    # dfExcQTD <- dfExcQTD %>%
    #   mutate(across(where(is.character), ~ iconv(., from = "UTF-8", to = "UTF-8")))
    # 
    # dfExcQTD$WD <- gsub("sab", "sáb", dfExcQTD$WD)
    
    dfExcQTD <- dfExcQTD %>% 
      dplyr::select(-DIA_SEMANA)
    
    # dfExcQTD <- dfExcQTD %>%
    #   mutate(across(where(is.character), ~ iconv(., from = "UTF-8", to = "UTF-8")))
    
  }
  
  
  
  ## vai buscar os minimos - FILE
  # dfMinimos <- read.delim('data/escTipoPostoMinimos.txt', sep='|')
  
  # writeLog(log_x = "GRANULARIDADE: LOAD MINIMOS", 
  #          logFile = logFile)
  Sys.setlocale("LC_TIME", lang)
  
  dfMinimos <- get_esc_tipo_posto_minimos(pathConf, erro_control = 0)
  
  
  dfMinimos <- dfMinimos %>% dplyr::filter(FK_TIPO_POSTO==fk_tipo_posto)
  
  dfMinimos <- pivot_longer(dfMinimos, 
                            cols=c("INI_SEG", "FIM_SEG","INI_TER","FIM_TER","INI_QUA","FIM_QUA","INI_QUI","FIM_QUI",
                                   "INI_SEX","FIM_SEX","INI_SAB","FIM_SAB","INI_DOM","FIM_DOM","INI_FER","FIM_FER"),
                            names_to = 'WD_AB', values_to = 'HORA')
  
  dfMinimos <- dfMinimos %>%
    separate(WD_AB, into = c("A_F", "WD"), sep = "_")
  
  dfMinimos <- pivot_wider(dfMinimos, 
                           names_from = 'A_F', values_from = 'HORA')
  
  dfMinimos <- pivot_longer(dfMinimos, 
                            cols=c("OBRIG_SEG", "OBRIG_TER","OBRIG_QUA","OBRIG_QUI", "OBRIG_SEX","OBRIG_SAB","OBRIG_DOM","OBRIG_FER"),
                            names_to = 'WD_OBRIG', values_to = 'MINIMO')
  
  dfMinimos <- dfMinimos %>%
    separate(WD_OBRIG, into = c("OBRIG", "WD2"), sep = "_")
  
  dfMinimos <- dfMinimos %>% 
    dplyr::filter(WD2==WD) %>% 
    dplyr::select(c(FK_TIPO_POSTO, WD, INI, FIM, MINIMO)) 
  
  dfMinimos$WD <- tolower(dfMinimos$WD)
  
  dfMinimos$INI <- as.POSIXct(dfMinimos$INI, format='%Y-%m-%d %H:%M:%S', tz='GMT')
  dfMinimos$FIM <- as.POSIXct(dfMinimos$FIM, format='%Y-%m-%d %H:%M:%S', tz='GMT')
  
  dfMinimos <- dfMinimos %>%
    dplyr::mutate(across(where(is.character), ~ iconv(., from = "UTF-8", to = "UTF-8")))%>% 
    dplyr::mutate(WD = ifelse(is.na(as.character(WD)),'sáb',as.character(WD)))
  
  dfMinimos$WD <- gsub("sab", "sáb", dfMinimos$WD)
  
  
  # dfMinimos <- dfMinimos %>%
  #   mutate(across(where(is.character), ~ iconv(., from = "UTF-8", to = "UTF-8")))
  
  ## vai buscar toda a estrutura - FILE 
  # dfEstruturaWFM <- read.delim('data/estruturaWFM.txt', sep='|', fileEncoding = "UTF-8-BOM", 
  #                              colClasses = c("character", "character", "numeric", "character", "numeric", "character"))
  
  # writeLog(log_x = "GRANULARIDADE: LOAD ESTRUTURA WFM", 
  #          logFile = logFile)
  
  dfEstruturaWFM <- get_estrutura_WFM(pathConf, erro_control = 0)
  
  
  # junta a informação dos minimos com o mapeamento da estrutura
  
  dfMinimos <- merge(dfEstruturaWFM, dfMinimos, by='FK_TIPO_POSTO')
  
  
  Sys.setlocale("LC_TIME", lang)
  if(nrow(dfFaixaHorario)>0){
    
    dfFaixaHorario <- dfFaixaHorario %>% 
      dplyr::mutate(across(where(is.character), ~ iconv(., from = "UTF-8", to = "UTF-8")))%>% 
      dplyr::mutate(WD = ifelse(is.na(as.character(WD)),'sáb',as.character(WD)))
    dfMinimos <- dfMinimos %>% 
      dplyr::mutate(across(where(is.character), ~ iconv(., from = "UTF-8", to = "UTF-8")))%>% 
      dplyr::mutate(WD = ifelse(is.na(as.character(WD)),'sáb',as.character(WD)))
    
    dfMinimos <- merge(dfMinimos, dfFaixaHorario, by=c('FK_SECAO', 'WD')) 
    
  } else {
    
    dfMinimos$ABER <- NA
    dfMinimos$FECH <- NA
    
  }
  
  if(!any(is.na(dfMinimos$ABER) & is.na(dfMinimos$FECH))){
    
    dfMinimos <- dfMinimos %>% 
      dplyr::mutate(INI=case_when(is.na(INI) ~ ABER, 
                                  #INI < ABER ~ ABER, 
                                  TRUE ~ INI))
    
    dfMinimos <- dfMinimos %>% 
      dplyr::mutate(FIM=case_when(is.na(FIM) ~ FECH, 
                                  #FIM > FECH ~ FECH, 
                                  TRUE ~ FIM))
  }
  
  
  # dfMinimos <- dfMinimos %>%
  #   mutate(across(where(is.character), ~ iconv(., from = "UTF-8", to = "UTF-8")))
  
  # dfMinimos<- dfMinimos %>%
  #   dplyr::filter(!is.na(INI)|!is.na(FIM)) %>%
  #   dplyr::filter(!INI==FIM)
  
  dfMinimos <- dfMinimos %>%
    dplyr::mutate(FIM=case_when(INI==FIM ~ INI+60*15,
                                TRUE ~ FIM))
  
  dfMinimos <- dfMinimos %>%
    dplyr::mutate(INI=case_when(is.na(INI) ~ as.POSIXct('2000-01-01 09:00:00', format='%Y-%m-%d %H:%M:%S', tz='GMT'),
                                TRUE ~ INI))
  
  dfMinimos <- dfMinimos %>%
    dplyr::mutate(FIM=case_when(is.na(FIM) ~ as.POSIXct('2000-01-01 20:00:00', format='%Y-%m-%d %H:%M:%S', tz='GMT'),
                                TRUE ~ FIM))
  
  
  
  dfMinimos<- dfMinimos %>%
    rowwise() %>%
    transmute(FK_UNIDADE, UNIDADE, FK_SECAO, SECAO, FK_TIPO_POSTO, TIPO_POSTO, WD, MINIMO,
              INI = list(seq(INI, FIM-60*15, by = "15 min"))) %>%
    unnest(INI) %>% distinct
  
  dfMinimos <- dfMinimos %>%
    dplyr::group_by(WD, FK_UNIDADE, UNIDADE, FK_SECAO, SECAO, FK_TIPO_POSTO, TIPO_POSTO, INI) %>%
    dplyr::summarise(MINIMO=sum(MINIMO),
                     .groups='drop')
  
  dfMinimos$HORA_INI <- as.POSIXct(dfMinimos$INI, format='%Y-%m-%d %H:%M:%S', tz='GMT')
  
  dfMinimos <- dfMinimos %>% 
    dplyr::select(-INI)
  
  
  # dfMinimos <- dfMinimos %>%
  #   mutate(across(where(is.character), ~ iconv(., from = "UTF-8", to = "UTF-8")))
  
  dfExcQTD$FK_TIPO_POSTO <- as.character(dfExcQTD$FK_TIPO_POSTO)
  
  dfMinimos <- dfMinimos %>%
    mutate(across(where(is.character), ~ iconv(., from = "UTF-8", to = "UTF-8")))%>% 
    dplyr::mutate(WD = ifelse(is.na(as.character(WD)),'sáb',as.character(WD)))
  
  dfMinimos$WD <- gsub("sab", "sáb", dfMinimos$WD)
  
  
  if(nrow(dfExcQTD)>0){
    # ass <<- dfMinimos
    
    dfExcQTD <- dfExcQTD %>%
      dplyr::mutate(across(where(is.character), ~ iconv(., from = "UTF-8", to = "UTF-8")))%>% 
      dplyr::mutate(WD = ifelse(is.na(as.character(WD)),'sáb',as.character(WD)))
    
    dfExcQTD$WD <- gsub("sab", "sáb", dfExcQTD$WD)
    
    # qweqw <<- dfExcQTD
    
    
    dfMinAll <- merge(dfMinimos, dfExcQTD, by=c('FK_TIPO_POSTO', 'WD', 'HORA_INI'), all=T)
    
  } else {
    
    dfMinAll <- dfMinimos
    
    dfMinAll$QTD <- NA
    
  }
  
  
  dfMinAll <- dfMinAll %>% 
    dplyr::mutate(FINAL=ifelse(is.na(QTD), MINIMO, QTD)) %>% 
    dplyr::select(-c(QTD,MINIMO))
  
  # dfMinAll$WD <- gsub("sÃ¡b", "sáb", dfMinAll$WD)
  
  # dfMinAll <- dfMinAll %>% 
  #   dplyr::mutate(WD=ifelse(!WD %in% c('dom','seg','ter','qua','qui','sex','fer'), 'sáb', WD))
  
  # cria sequencia de datas e faz um crossing com as unidades
  
  dateSeq <- seq(as.Date(minData, format='%Y-%m-%d', tz='GMT'), as.Date(maxData, format='%Y-%m-%d', tz='GMT'), by = "day")
  
  dfData <- data.frame(dateSeq)
  Sys.setlocale("LC_TIME", lang)
  dfData <- dfData %>% 
    # dplyr::mutate(WD=lubridate::wday(dateSeq, abbr = T, label = T, locale = lang)) %>% 
    dplyr::rename(DATA=dateSeq)
  
  dfData$weekday_num <- lubridate::wday(dfData$DATA)
  portuguese_labels <- c("Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb")
  dfData$WD <- portuguese_labels[dfData$weekday_num]
  dfData$weekday_num <- NULL
  
  
  dfUnidade <- data.frame(fk_unidade)
  names(dfUnidade) <- 'FK_UNIDADE'
  
  dfData <- crossing(dfData, dfUnidade)
  
  # faz merge do dataframe de datas e unidades com os feriados abertos para identificar esses dias 
  if (nrow(dfFeriados) > 0) {
    dfData <- merge(dfData, dfFeriados, by=c('FK_UNIDADE', 'DATA'), all=T)
    
    dfData$WD <- as.character(dfData$WD)
    
    dfData <- dfData %>% 
      dplyr::mutate(TIPO_DIA=ifelse(is.na(TIPO_DIA), tolower(WD), 'fer')) %>% 
      dplyr::select(-WD) %>% 
      dplyr::rename(WD=TIPO_DIA)
  }
  
  dfData$WD <- tolower(dfData$WD)
  # faz um merge do dataframe de dadas e estrutura com os minimos por posto
  dfMinAll <- dfMinAll %>% 
    dplyr::mutate(WD = ifelse(is.na(as.character(WD)),'sáb',as.character(WD)))
  dfData <- dfData %>% 
    dplyr::mutate(WD = ifelse((wday(DATA)==7 & WD!='fer'),'sáb',as.character(WD))) %>% 
    dplyr::mutate(across(where(is.character), ~ iconv(., from = "UTF-8",  to = "UTF-8"))) %>% 
    dplyr::mutate(WD = ifelse(is.na(as.character(WD)),'sáb',as.character(WD)))
  
  dfMinAll <- merge(dfData, dfMinAll, by=c('FK_UNIDADE','WD'))
  
  
  #### Junta min + estimativas
  # miii <<- dfOrcamento3
  # miii2 <<- dfMinAll
  gc()
  dfOrcamento3 <- dfOrcamento3 %>% 
    dplyr::mutate(WD = ifelse((wday(DATA)==7 & WD!='fer'),'sáb',as.character(WD))) %>% 
    dplyr::mutate(across(where(is.character), ~ iconv(., from = "UTF-8",  to = "UTF-8"))) %>% 
    dplyr::mutate(WD = ifelse(is.na(as.character(WD)),'sáb',as.character(WD)))
  
  dfAll <- merge(dfMinAll, dfOrcamento3, 
                 by=c('FK_UNIDADE', 'UNIDADE', 'FK_SECAO', 'SECAO', 'FK_TIPO_POSTO', 'TIPO_POSTO', 'WD', 'DATA', 'HORA_INI'), 
                 all=T)
  
  # writeLog(log_x = "GRANULARIDADE: FIZ O DFALL", 
  #          logFile = logFile)
  
  # all_objects <- ls()
  # objects_to_remove <- setdiff(all_objects, dfAll)
  # 
  # # Remover os objetos indesejados
  # rm(list = objects_to_remove)
  
  
  dfAll <- dfAll %>% 
    dplyr::rename(PESSOAS_MIN=FINAL,
                  PESSOAS_gran=PDVS)
  
  dfAll <- dfAll %>% 
    dplyr::mutate(PESSOAS_gran=ifelse(is.na(PESSOAS_gran), 0, PESSOAS_gran),
                  PESSOAS_MIN=ifelse(is.na(PESSOAS_MIN), 0, PESSOAS_MIN)) %>% 
    rowwise() %>% 
    dplyr::mutate(PESSOAS_FINAL=max(PESSOAS_MIN, PESSOAS_gran)) %>% 
    dplyr::rename(PESSOAS_ESTIMADO=PESSOAS_gran)
  
  # print("valida sem tem NAs")
  # subset(dfAll, apply(dfAll, 1, function(row) any(is.na(row)))) %>% View()
  
  # fimGran <<- dfAll
  dfAll <- dfAll %>% distinct(FK_UNIDADE, UNIDADE, FK_SECAO, SECAO, FK_TIPO_POSTO, DATA, WD, HORA_INI, .keep_all = T)
  
  return(dfAll)
}

# 
# projectPath <- getwd()
# pathConf <- projectPath



########################################################################################################################

## vai buscar os turnos 
# pathConf = pathFicheirosGlobal
# minData <- as.Date(startDate2, format='%d-%m-%Y')
# maxData <- as.Date(endDate2, format='%d-%m-%Y')
# fk_unidade <- unitID
# fk_secao <- secaoID
# fk_tipo_posto <- posto
# Ficheiro-tranformar em query assim que existir a info em BD -------------
output_turnos <- function(pathConf = pathFicheirosGlobal, minData = '2025-01-01', maxData = '2025-12-31',
                          fk_unidade, fk_secao, fk_tipo_posto, lang){
  
  source(paste0(pathConf,"Rfiles/get_needed_files.R"))
  
  Sys.setlocale("LC_TIME", lang)
  
  dfTurnos <- get_turnos(pathConf)
  
  dfTurnos <- dfTurnos %>% 
    dplyr::filter(FK_TIPO_POSTO == fk_tipo_posto)
  
  
  columnsIN <- c("H_TM_IN", "H_SEG_IN", "H_TER_IN", "H_QUA_IN", "H_QUI_IN", "H_SEX_IN", "H_SAB_IN", "H_DOM_IN", "H_FER_IN")
  
  dfTurnos$MinIN1 <- do.call(pmin, c(dfTurnos[columnsIN], na.rm = TRUE))
  
  columnsOUT <- c("H_TT_OUT", "H_SEG_OUT", "H_TER_OUT", "H_QUA_OUT", "H_QUI_OUT", "H_SEX_OUT", "H_SAB_OUT", "H_DOM_OUT", "H_FER_OUT")
  
  dfTurnos$MaxOUT2 <- do.call(pmax, c(dfTurnos[columnsOUT], na.rm = TRUE))
  
  dfTurnos <- dfTurnos %>% 
    dplyr::select(c(EMP, FK_TIPO_POSTO, MinIN1, H_TM_OUT, H_TT_IN, MaxOUT2))
  
  dfTurnos <- dfTurnos %>% 
    dplyr::group_by(FK_TIPO_POSTO) %>% 
    dplyr::summarise(MinIN1=min(MinIN1, na.rm = TRUE),
                     H_TM_OUT=max(H_TM_OUT, na.rm = TRUE),
                     H_TT_IN=min(H_TT_IN, na.rm = TRUE),
                     MaxOUT2=max(MaxOUT2, na.rm = TRUE),
                     .groups='drop') 
  
  dfTurnos <- dfTurnos %>%
    mutate(MED1 = case_when(
        H_TM_OUT < H_TT_IN ~ H_TM_OUT,
        TRUE ~ pmin(H_TM_OUT, H_TT_IN, na.rm = TRUE)),
        MED2 = case_when(
          H_TM_OUT < H_TT_IN ~ H_TT_IN,
          TRUE ~ pmin(H_TM_OUT, H_TT_IN, na.rm = TRUE)))
  
  
  dfTurnos <- dfTurnos %>% 
    dplyr::select(c(FK_TIPO_POSTO, MinIN1, MED1, MED2, MaxOUT2))
  
  dfTurnos <- dfTurnos %>%
    mutate(MED3 = MED1,
           MED3 = case_when(
        MED3 < MED2 ~ MED2,
        TRUE ~ MED3)) %>% 
    select(-MED2)
  
  dfTurnos <- dfTurnos %>% 
    dplyr::select(c(FK_TIPO_POSTO, MinIN1, MED1, MED3, MaxOUT2))
  
  dfTurnos <- dfTurnos %>%
    mutate(MED3=case_when(
      is.na(as.character(MED3)) ~ MED1,
      TRUE ~ MED3))
  
  dfTurnos <- dfTurnos %>%
    mutate(MaxOUT2=case_when(
      is.na(as.character(MaxOUT2)) ~ MED3,
      TRUE ~ MaxOUT2),
      MED1=case_when(
        is.na(as.character(MED1)) ~ MinIN1,
        TRUE ~ MED1),
      MED3=case_when(
        is.na(as.character(MED3)) ~ MaxOUT2,
        TRUE ~ MED3))
  
  # columnsIN <- c("H_TT_IN","H_TM_OUT")
  # 
  # dfTurnos <- dfTurnos %>% 
  #   dplyr::mutate(MED1=ifelse(H_TM_OUT>H_TT_IN, as.POSIXct(do.call(pmin, c(dfTurnos[columnsIN], na.rm = TRUE))), H_TM_OUT),
  #                 MED2=ifelse(H_TM_OUT>H_TT_IN, do.call(pmin, c(dfTurnos[columnsIN], na.rm = TRUE)),H_TT_IN))
  
  
  # ## vai buscar toda a estrutura - FILE
  # dfEstruturaWFM <- read.delim('data/estruturaWFM.txt', sep='|', fileEncoding = "UTF-8-BOM", 
  #                              colClasses = c("character", "character", "numeric", "character", "numeric", "character"))
  
  dfEstruturaWFM <- get_estrutura_WFM(pathConf)
  dfEstruturaWFM <- dfEstruturaWFM %>% 
    dplyr::filter(FK_TIPO_POSTO == fk_tipo_posto)
  # junta a informação dos minimos com o mapeamento da estrutura
  
  dfTurnos <- merge(dfEstruturaWFM, dfTurnos, by='FK_TIPO_POSTO', all=T)
  
  dfTurnos <- dfTurnos %>% 
    mutate(MinIN1=as.POSIXct(paste0('2000-01-01 ',MinIN1), format='%Y-%m-%d %H:%M'),
           MED1=as.POSIXct(paste0('2000-01-01 ',MED1), format='%Y-%m-%d %H:%M'),
           MED3=as.POSIXct(paste0('2000-01-01 ',MED3), format='%Y-%m-%d %H:%M'),
           MaxOUT2=as.POSIXct(paste0('2000-01-01 ',MaxOUT2), format='%Y-%m-%d %H:%M'))
  
  ## vai buscar a faixa horaria - FILE
  
  dateSeq <- seq(as.Date(minData, format='%Y-%m-%d', tz='GMT'), as.Date(maxData, format='%Y-%m-%d', tz='GMT'), by = "day")
  
  dfData <- data.frame(dateSeq)
  
  dfData <- dfData %>% 
    dplyr::mutate(WD=lubridate::wday(dateSeq, abbr = T, label = T)) %>% 
    dplyr::rename(DATA=dateSeq)
  
  dfUnidade <- data.frame(fk_unidade)
  names(dfUnidade) <- 'FK_UNIDADE'
  
  dfData <- crossing(dfData, dfUnidade)
  
  dfFeriados <- get_feriados(pathConf, erro_control = 0)
  
  names(dfFeriados) <- c('FK_UNIDADE', 'DATA')
  
  dfFeriados <- dfFeriados %>% 
    dplyr::filter(FK_UNIDADE==fk_unidade)
  
  if (nrow(dfFeriados)>0) {
    dfFeriados$DATA <- as.Date(dfFeriados$DATA, format='%Y-%m-%d', tz='GMT')
    
    dfFeriados$TIPO_DIA <- 'FERIADO'
    ano <- year(minData)
    dfFeriados <- dfFeriados %>% 
      dplyr::filter((DATA >= minData & DATA <= maxData) | DATA <'2000-12-31') %>% 
      dplyr::mutate(DATA=update(DATA, year = ano))
    
    # faz merge do dataframe de datas e unidades com os feriados abertos para identificar esses dias 
    
    dfData <- merge(dfData, dfFeriados, by=c('FK_UNIDADE', 'DATA'), all=T)
    
    dfData$WD <- as.character(dfData$WD)
    
    dfData <- dfData %>% 
      dplyr::mutate(TIPO_DIA=ifelse(is.na(TIPO_DIA), WD, 'fer')) %>% 
      dplyr::select(-WD) %>% 
      dplyr::rename(WD=TIPO_DIA)
  }

  

  
  # dfFaixaHorario <- read.delim('data/escFaixaHorario.txt', sep= '|', fileEncoding = "UTF-8-BOM")
  Sys.setlocale("LC_TIME", lang)
  dfFaixaHorario <- get_esc_faixa_horario(pathConf)
  
  dfFaixaHorario <- dfFaixaHorario %>% dplyr::filter(FK_SECAO==fk_secao)
  
  dfFaixaHorario <- dfFaixaHorario %>%
    rowwise() %>%
    dplyr::mutate(DATA = list(as.character(seq(as.Date(DATA_INI), as.Date(DATA_FIM), by = "day")))) %>%
    unnest(DATA)
  
  # dfFaixaHorario <- dfFaixaHorario[1,]
  
  dfFaixaHorario <- tidyr::pivot_longer(dfFaixaHorario, 
                                 cols=c("ABER_SEG", "FECH_SEG","ABER_TER","FECH_TER","ABER_QUA","FECH_QUA","ABER_QUI","FECH_QUI",
                                        "ABER_SEX","FECH_SEX","ABER_SAB","FECH_SAB","ABER_DOM","FECH_DOM","ABER_FER","FECH_FER"),
                                 names_to = 'WD_AB')
  

  dfFaixaHorario <- dfFaixaHorario %>%
    separate(WD_AB, into = c("A_F", "WD"), sep = "_")
  
  
  # dfFaixaHorario$value <- as.character(dfFaixaHorario$value)
  
  dfFaixaHorario <- dfFaixaHorario %>% distinct(FK_SECAO,DATA, A_F, WD, .keep_all = T)
  
  dfFaixaHorario <- tidyr::pivot_wider(dfFaixaHorario, 
                                names_from = 'A_F')
  
  dfFaixaHorario$WD <- tolower(dfFaixaHorario$WD)
  dfFaixaHorario$WD <- gsub("sab", "sáb", dfFaixaHorario$WD)
  
  
  dfFaixaHorario$WD_DATE <- lubridate::wday(dfFaixaHorario$DATA, label=T, abbr = T)
  
  dfFaixaHorario$WD_DATE <- as.character(dfFaixaHorario$WD_DATE)
  dfFaixaHorario$WD_DATE <- tolower(dfFaixaHorario$WD_DATE)
  dfFaixaHorario$WD_DATE <- gsub("sab", "sáb", dfFaixaHorario$WD_DATE)
  
  # lklk23 <<- dfFaixaHorario
  
  dfFaixaHorario <- dfFaixaHorario %>% 
    dplyr::mutate(across(where(is.character), ~ iconv(., from = "UTF-8",  to = "UTF-8"))) %>% 
    dplyr::mutate(WD = ifelse(is.na(as.character(WD)),'sáb',as.character(WD))) %>% 
    dplyr::filter(WD==WD_DATE)
  # dfFaixaHorario <- dfFaixaHorario %>%
  #   dplyr::mutate(across(where(is.character), ~ iconv(., from = "UTF-8",  to = "UTF-8")))
  
  # lklk2 <<- dfFaixaHorario
  
  
  dfFaixaHorario$ABER <- as.POSIXct(dfFaixaHorario$ABER, format='%Y-%m-%d %H:%M:%S', tz='GMT')
  dfFaixaHorario$FECH <- as.POSIXct(dfFaixaHorario$FECH, format='%Y-%m-%d %H:%M:%S', tz='GMT')
  
  
  # dfFaixaHorario <- dfFaixaHorario %>%
  #   dplyr::mutate(across(where(is.character), ~ iconv(., from = "UTF-8",  to = "UTF-8")))
  
  # dfFaixaHorario <- dfFaixaHorario %>% 
  #   dplyr::group_by(FK_SECAO) %>% 
  #   dplyr::summarise(ABER=min(ABER, na.rm = TRUE),
  #                    FECH=max(FECH, na.rm = TRUE),
  #                    .groups='drop') 
  dfFaixaHorario <- dfFaixaHorario %>% 
    dplyr::select(FK_SECAO, DATA, ABER, FECH)
  
  # dfTurnos <- dfTurnos %>% 
  #   dplyr::filter(FK_TIPO_POSTO==fk_tipo_posto)
  
  dfTurnos <- merge(dfTurnos, dfData, by=c('FK_UNIDADE'))
  
  dfTurnos <- merge(dfTurnos, dfFaixaHorario, by=c('FK_SECAO', 'DATA'), all.x=T)
  
  dfTurnos <- dfTurnos %>%
    mutate(MaxOUT2=case_when(
      is.na(as.character(MaxOUT2)) ~ FECH,
      TRUE ~ MaxOUT2),
      MinIN1=case_when(
        is.na(as.character(MinIN1)) ~ ABER,
        TRUE ~ MinIN1)) 

  
  
  # dfTurnos$start_chron <- times(format(dfTurnos$MinIN1, format='%H:%M:%S'))
  # dfTurnos$end_chron <- times(format(dfTurnos$MaxOUT2, format='%H:%M:%S'))
  # 
  # dfTurnos$MIDDLE_TIME <- (dfTurnos$start_chron + dfTurnos$end_chron) / 2
  # 
  # 
  # dfTurnos$MIDDLE_TIME <- as.POSIXct(paste0('2000-01-01 ',dfTurnos$MIDDLE_TIME), format='%Y-%m-%d %H:%M:%S', tz='GMT')
  # Calculando a média entre as duas colunas
  dfTurnos$MIDDLE_TIME <- as.POSIXct((as.numeric(dfTurnos$MinIN1) + as.numeric(dfTurnos$MaxOUT2)) / 2, origin = "1970-01-01")
  
  
  dfTurnos$HOUR <- hour(dfTurnos$MIDDLE_TIME)
  
  dfTurnos$MIDDLE_TIME <- as.POSIXct(paste0('2000-01-01 ',dfTurnos$HOUR, ':00:00'), format='%Y-%m-%d %H:%M:%S', tz='GMT')
  
  
  dfTurnos <- dfTurnos %>% 
    dplyr::select(c(FK_UNIDADE, UNIDADE, FK_SECAO, SECAO, FK_TIPO_POSTO, TIPO_POSTO, MinIN1, MED1, MED3, MaxOUT2, MIDDLE_TIME, ABER, FECH, DATA))  
  # dfTurnos <- dfTurnos %>%
  #   mutate(MED1=case_when(
  #     is.na(as.character(MED1)) ~ MIDDLE_TIME,
  #     TRUE ~ MED1),
  #     MED3=case_when(
  #       is.na(as.character(MED3)) ~ MIDDLE_TIME,
  #       TRUE ~ MED3)) %>%
  #   select(-MIDDLE_TIME)
  
  dfTurnos <- dfTurnos %>%
    dplyr::mutate(MED1= MIDDLE_TIME,
                  MED3= MIDDLE_TIME) %>%
    select(-MIDDLE_TIME)
  
  names(dfTurnos) <- c("FK_UNIDADE", "UNIDADE", "FK_SECAO", "SECAO", "FK_TIPO_POSTO", "TIPO_POSTO", "M_INI",  "M_OUT", "T_INI", "T_OUT", "ABER", "FECH", "DATA")  
  dfTurnos <- pivot_longer(dfTurnos, 
                           cols=c("M_INI", "T_INI"),
                           names_to = 'TURNO',
                           values_to = 'H_INI_1')
  
  dfTurnos <- pivot_longer(dfTurnos, 
                           cols=c("M_OUT", "T_OUT"),
                           names_to = 'TURNO2',
                           values_to = 'H_OUT_1')
  
  dfTurnos <- dfTurnos %>% 
    dplyr::mutate(TURNO=ifelse(TURNO=="M_INI","M","T"),
                  TURNO2=ifelse(TURNO2=="M_OUT","M","T")) 
  
  dfTurnos <- dfTurnos %>% 
    dplyr::filter(TURNO==TURNO2) %>% 
    dplyr::select(-TURNO2)
  
  
  dfTurnos <- dfTurnos %>% 
    dplyr::filter(H_INI_1!=H_OUT_1)
  
  # dfTurnos$RESULT <- as.POSIXct(NA, tz='GMT')
  
  dfTurnos <- dfTurnos %>% 
    dplyr::mutate(H_OUT_1=case_when(
      H_INI_1>H_OUT_1 ~ as.POSIXct(H_OUT_1+ 24*60*60, tz='GMT'),
      TRUE ~ H_OUT_1))
  # 
  # dfTurnos$RESULT <- as.POSIXct(dfTurnos$RESULT, tz='GMT')
  dfTurnos <- dfTurnos %>% 
    dplyr::mutate(FECH=case_when(
      TURNO=='M' ~ H_OUT_1,
      TRUE ~ FECH),
      ABER=case_when(
        TURNO=='T' ~ H_INI_1,
        TRUE ~ ABER))
  
  dfTurnos <- dfTurnos %>% 
    dplyr::mutate(H_INI_1=case_when(TURNO=='M'~min(H_INI_1, ABER),TRUE ~ H_INI_1),
                  H_OUT_1=case_when(TURNO=='T'~max(H_OUT_1, FECH),TRUE ~ H_OUT_1))
  # xxxx <<- dfTurnos
  ## vai buscar as estimativas 
  
  # dfGranularidade <- read.csv2('Estimativas_ALCAMPO/data/inputHorasPessoas.csv')
  
  # fk_unidade <- unitID
  # fk_secao <- secaoID
  # fk_tipo_posto <- posto
  dfGranularidade <- output_gran(pathConf, minData = minData, maxData = maxData,
                            fk_unidade, fk_secao, fk_tipo_posto)
  
  # lkj <<- dfGranularidade
  
  output_final <- data.frame()
  
  # dfTurnosOLD <- readxl::read_xlsx('data/atual/Horarios_Turnos.xlsx', sheet="Sheet1")
  
  #dfTurnos$TURNO <- 'D'
  #postos <- c(159,161)
  
  dfTurnos <- dfTurnos %>% 
    dplyr::select(c(FK_TIPO_POSTO, H_INI_1, H_OUT_1, TURNO, DATA)) 
  
  dfTurnos$FK_POSTO_TURNO <- paste0(dfTurnos$FK_TIPO_POSTO, '_', dfTurnos$TURNO)
  
  dfGranularidade$DATA <- as.Date(dfGranularidade$DATA, format='%Y-%m-%d', tz='GMT')
  
  dfTurnos$DATA <- as.Date(dfTurnos$DATA, format='%Y-%m-%d', tz='GMT')
  
  
  dfTurnos$H_INI_1 <- as.POSIXct(dfTurnos$H_INI_1, format='%Y-%m-%d %H:%M:%S', tz='GMT')
  
  dfTurnos$H_OUT_1 <- as.POSIXct(dfTurnos$H_OUT_1, format='%Y-%m-%d %H:%M:%S', tz='GMT')
  
  dfGranularidade$HORA_INI <- as.POSIXct(dfGranularidade$HORA_INI, format='%Y-%m-%d %H:%M:%S', tz='GMT')
  
  dateSeq <- seq(as.Date(minData, format='%Y-%m-%d', tz='GMT'), as.Date(maxData, format='%Y-%m-%d', tz='GMT'), by = "day")
  
  dfTurnos <- dfTurnos %>% 
    dplyr::filter(!is.na(FK_TIPO_POSTO))
  
  i=0
  
  
  
  dfTurnos <- dfTurnos %>% 
    dplyr::filter(FK_TIPO_POSTO==fk_tipo_posto)
  
  if(nrow(dfTurnos)==0){
    
    
    min <- times(format(min(dfGranularidade$HORA_INI), format='%H:%M:%S'))
    max <- times(format(max(dfGranularidade$HORA_INI), format='%H:%M:%S'))
    
    middle <- (min + max) / 2
    
    
    middle <- as.POSIXct(paste0('2000-01-01 ',middle), format='%Y-%m-%d %H:%M:%S', tz='GMT')
    
    hour <- hour(middle)
    
    middle <- as.POSIXct(paste0('2000-01-01 ',hour, ':00:00'), format='%Y-%m-%d %H:%M:%S', tz='GMT')
    
    dfTurnos[nrow(dfTurnos) + 1, ] <- list(as.character(fk_tipo_posto), min(dfGranularidade$HORA_INI), middle, 'M', paste0(fk_tipo_posto,'_M'))
    
    dfTurnos[nrow(dfTurnos) + 1, ] <- list(as.character(fk_tipo_posto), middle, max(dfGranularidade$HORA_INI), 'T', paste0(fk_tipo_posto,'_T'))
    
    
    
  }

  
  dfGranularidade <- dfGranularidade %>% 
    dplyr::filter(FK_TIPO_POSTO==fk_tipo_posto)
  
  # kkkkk <<- dfGranularidade
  
  for (variable in unique(dfTurnos$FK_POSTO_TURNO)) {
    #variable <- unique(dfTurnos$FK_POSTO_TURNO)[1]
    i=i+1
    
    print(i)
    
    print(paste0('variavel: ', variable))
    
    dfTurnos_F <- dfTurnos %>% 
      dplyr::filter(FK_POSTO_TURNO==variable)
    
    fk_posto <- unique(dfTurnos_F$FK_TIPO_POSTO)
    # hora_ini <- unique(dfTurnos_F$H_INI_1)
    # hora_fim <- unique(dfTurnos_F$H_OUT_1)
    turno <- unique(dfTurnos_F$TURNO)
    
    dfGranularidade_F <- dfGranularidade %>% 
      dplyr::filter(FK_TIPO_POSTO==fk_posto#,
                    #HORA_INI>=hora_ini,
                    #HORA_INI<hora_fim
                    )
    
    # uasdf <<- dfGranularidade_F
    # dasdas2 <<- dfTurnos_F
    
    dfGranularidade_F <- merge(dfGranularidade_F, dfTurnos_F, by=c('FK_TIPO_POSTO','DATA'))
    
    dfGranularidade_F <- dfGranularidade_F %>% 
      rowwise() %>% 
      dplyr::filter(HORA_INI>=H_INI_1,
                    HORA_INI<H_OUT_1) %>% 
      dplyr::mutate(PESSOAS_FINAL = as.numeric(PESSOAS_FINAL))
    
    # dfGranularidade_F$PESSOAS_FINAL <- as.numeric(dfGranularidade_F$PESSOAS_FINAL)
    output <- dfGranularidade_F %>%
      dplyr::group_by(DATA) %>%
      dplyr::summarise(mediaTurno = mean(PESSOAS_FINAL),
                       maxTurno = calcular_MAX(PESSOAS_FINAL),
                       minTurno = min(PESSOAS_FINAL),
                       sdTurno = sd(PESSOAS_FINAL),
                       .groups = 'drop')
    
    dateSeq <- seq(as.Date(minData, format='%Y-%m-%d', tz='GMT'), as.Date(maxData, format='%Y-%m-%d', tz='GMT'), by = "day")
    
    dfData <- data.frame(dateSeq)
    
    dfData <- dfData %>% 
      dplyr::rename(DATA=dateSeq)
    
    
    output <- merge(dfData, output, by=c('DATA'), all.x=T)
    
    output[is.na(output)] <- 0
    
    output$TURNO <- turno
    output$FK_TIPO_POSTO <- fk_posto
    
    output_final <- rbind(output_final, output)
    
    print('FEITO')
    
  }
  
  if(nrow(output_final)>0){
    
    output_final$DATA_TURNO <- paste0(output_final$DATA, '_', output_final$TURNO)
    
  }
  
  output_final[is.na(output_final)] <- 0
  
  output_final <- output_final %>% distinct()
  
  #output_final %>% distinct(FK_TIPO_POSTO, DATA, TURNO) %>% View()
  
  output_final$FK_TIPO_POSTO <- fk_tipo_posto
  
  # writeLog(log_x = "TURNOS: DATAFRAME CONCLUIDO", 
  #          logFile = logFile)
  
  
  output_final <- output_final %>% distinct(FK_TIPO_POSTO, DATA, DATA_TURNO, TURNO, .keep_all = T)
  
  if (lang == 'pt_PT.UTF-8') {
    output_final <- output_final %>% 
      dplyr::mutate(maxTurno = as.numeric(maxTurno)) %>% 
      dplyr::mutate(minTurno = as.numeric(minTurno))
    
  }
  #write.csv2(unique(output_final$FK_TIPO_POSTO), 'Estimativas_ALCAMPO/data/outputs/postosGeradosTurnos_V01.csv', row.names=F)
  
  #write.csv2(output_final, paste0('Estimativas_ALCAMPO/data/outputs/postos/turnos/output_',fk_tipo_posto,'.csv'), row.names=F)

  # Sys.setlocale("LC_TIME", "C")
  return(list(output_final,dfTurnos))
}




# Função para calcular a Ocorrência A
ocorrencia_A <- function(sequencia) {
  # Passo 1: Procurar por 3 ocorrências consecutivas do maior valor
  valores_unicos <- sort(unique(sequencia), decreasing = TRUE)
  n <- length(sequencia)
  
  resultado_pass1 <- -Inf
  
  for (valor in valores_unicos) {
    for (i in 1:(n - 2)) {
      if (sequencia[i] == valor && sequencia[i + 1] == valor && sequencia[i + 2] == valor) {
        resultado_pass1 <- valor  
        break  
      }
    }
    if (resultado_pass1 != -Inf) break  
  }
  
  # Passo 2: Caso não encontre, seguimos para a segunda regra
  if (length(valores_unicos) < 3) {
    X <- valores_unicos  
  } else {
    X <- valores_unicos[1:3]
  }
  
  melhor_sequencia <- NULL
  melhor_soma <- -Inf
  resultado_pass2 <- -Inf  
  
  for (i in 1:(n - 2)) {
    sub_seq <- sequencia[i:(i + 2)] 
    if (all(sub_seq %in% X)) {  
      soma_seq <- sum(sub_seq)  
      if (soma_seq > melhor_soma) {
        melhor_soma <- soma_seq
        melhor_sequencia <- sub_seq 
      }
    }
  }
  
  if (!is.null(melhor_sequencia)) {
    resultado_pass2 <- min(melhor_sequencia)
  }
  
  return(max(resultado_pass1, resultado_pass2))
}


ocorrencia_B <- function(sequencia) {
  valores_unicos <- sort(unique(sequencia), decreasing = TRUE)
  n <- length(sequencia)
  
  # Passo 1: Calcular os 3 valores máximos da sequência
  if (length(valores_unicos) < 3) {
    maximos <- valores_unicos  
  } else {
    maximos <- valores_unicos[1:3]
  }
  
  # Passo 2: Verificar o maior desses valores máximos e se existem pelo menos 2 situações de 2 consecutivos
  maior_valor <- max(maximos)
  contagem_consecutiva <- 0
  i <- 1
  
  while (i <= (n - 1)) {
    if (sequencia[i] == maior_valor && sequencia[i + 1] == maior_valor) {
      contagem_consecutiva <- contagem_consecutiva + 1
      i <- i + 2  
    } else {
      i <- i + 1
    }
  }
  
  if (contagem_consecutiva >= 2) {
    return(maior_valor)
  }
  
  # Passo 3: Caso não existam 2 pares do maior valor, verificar pares entre os 3 maiores valores
  pares_validos <- list()
  i <- 1
  while (i <= (n - 1)) {
    if (sequencia[i] %in% maximos && sequencia[i + 1] %in% maximos) {
      pares_validos <- append(pares_validos, list(sequencia[i:(i+1)]))
      i <- i + 2 
    } else {
      i <- i + 1
    }
  }
  
  
  if (length(pares_validos) >= 2) {
    soma_maxima <- -Inf
    melhor_pares <- NULL
    
    
    for (j in 1:(length(pares_validos) - 1)) {
      for (k in (j + 1):length(pares_validos)) {
        soma_atual <- sum(unlist(pares_validos[j])) + sum(unlist(pares_validos[k]))
        if (soma_atual > soma_maxima) {
          soma_maxima <- soma_atual
          melhor_pares <- c(pares_validos[[j]], pares_validos[[k]]) 
        }
      }
    }
    
    return(min(melhor_pares))
  }
  
  return(-1)  # Caso não haja pares suficientes, retorna -1
}


# Função para calcular o valor MAX para cada sequência
calcular_MAX <- function(sequencia) {
  valor_A <- ocorrencia_A(sequencia)
  valor_B <- ocorrencia_B(sequencia)
  
  return(max(valor_A, valor_B))
}


