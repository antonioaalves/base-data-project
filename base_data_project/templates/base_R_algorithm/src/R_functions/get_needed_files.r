# pathOS <- getwd()
# pathConf <- pathOS # paste0(pathOS,"conf/CONFIGURATIONS_EXT.csv")
# library(dplyr)
# # file_path <- paste0(pathOS,"/to_insert/outputGranularidade_Marco_V13.csv")
# # df_gran_alg <- read.table(file_path, header = TRUE, sep = ";",
# #                           check.names = FALSE,as.is = TRUE,)
# 
# data_ini <- '2024-01-01'
# data_fim <-  '2024-12-31'


# get_esc_faixa_horario !!!Fechado --------------------------------------------
get_esc_faixa_horario <-  function(pathOS, erro_control = 0){


  source(paste0(pathOS,"connection/dbconn.R"))
  
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  # paste(readLines(paste0(pathOS,"/data/querys/queryGetEscFaixaHorario.sql")), collapse = " ")



  # AVALIA EXISTÊNCIA DE NOVOS HORARIOS PREGERADOS --------------------------
  erro_control <- tryCatch({
  query_getEscFaixaHorario<- paste(readLines(paste0(pathOS,"/data/querys/queryGetEscFaixaHorario.sql")), collapse = " ")
  df_esc_faixa_horario <-  dbGetQuery(wfm_con, query_getEscFaixaHorario)


  0
  }, error = function(e){
    print(e$message)
    1
  })
  gc()
  dbDisconnect(wfm_con)



return(df_esc_faixa_horario)}


# get_esc_orcamento !!!Fechado --------------------------------------------
get_esc_orcamento <-  function(pathOS, data_ini, data_fim,fk_tipo_posto, erro_control = 0){
  
  
  source(paste0(pathOS,"connection/dbconn.R"))
  
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  
  
  erro_control <- tryCatch({
    query_getEscOrcamento<- paste(readLines(paste0(pathOS,"/data/querys/queryGetEscOrcamento.sql")), collapse = " ")
    
    query_getEscOrcamento <- query_getEscOrcamento %>% 
      gsub(':i', paste0("'", data_ini, "'"), .) %>% 
      gsub(':f', paste0("'", data_fim, "'"), .) %>% 
      gsub(':posto', fk_tipo_posto, .)
    
    df_esc_orcamento<-  dbGetQuery(wfm_con, query_getEscOrcamento)
    
    
    0
  }, error = function(e){
    print(e$message)
    1
  })
  gc()
  dbDisconnect(wfm_con)
  
  
  
  return(df_esc_orcamento)}


get_esc_estimado <-  function(pathConf, data_ini, data_fim, fk_tipo_posto, erro_control = 0){
  
  
  source(paste0(pathConf,"connection/dbconn.R"))
  
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathConf,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathConf, sis, confFileName)

  
  erro_control <- tryCatch({
    query_getEscEstimado<- paste(readLines(paste0(pathConf,"/data/querys/queryGetEscEstimado.sql")), collapse = " ")
    
    query_getEscEstimado <- query_getEscEstimado %>% 
      gsub(':i', paste0("'", data_ini, "'"), .) %>% 
      gsub(':f', paste0("'", data_fim, "'"), .) %>% 
      gsub(':posto', fk_tipo_posto, .)
    
    df_esc_estimado <-  dbGetQuery(wfm_con, query_getEscEstimado)
    
    
    0
  }, error = function(e){
    print(e$message)
    1
  })
  gc()
  dbDisconnect(wfm_con)
  
  
  
  return(df_esc_estimado)}


# get_esc_orcamento_dia !!!Fechado --------------------------------------------
get_esc_orcamento_dia <-  function(pathOS,data_ini, data_fim, erro_control = 0, fk_tipo_posto){
  
  
  source(paste0(pathOS,"connection/dbconn.R"))
  
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  # paste(readLines(paste0(pathOS,"/data/querys/queryGetEscOrcamentoDia.sql")), collapse = " ")
  
  
  
  
  # AVALIA EXISTÊNCIA DE NOVOS HORARIOS PREGERADOS --------------------------
  erro_control <- tryCatch({
    query_getEscOrcamentoDia<- paste(readLines(paste0(pathOS,"/data/querys/queryGetEscOrcamentoDia.sql")), collapse = " ")
    
    query_getEscOrcamentoDia <- query_getEscOrcamentoDia %>% 
      gsub(':i', paste0("'", data_ini, "'"), .) %>% 
      gsub(':f', paste0("'", data_fim, "'"), .) %>% 
      gsub(':posto', fk_tipo_posto, .)
    
    
    df_esc_orcamento_dia <-  dbGetQuery(wfm_con, query_getEscOrcamentoDia)
    
    
    0
  }, error = function(e){
    print(e$message)
    1
  })
  gc()
  dbDisconnect(wfm_con)
  
  
  
  return(df_esc_orcamento_dia)}


# get_esc_tipo_posto_minimos !!!Fechado --------------------------------------------
get_esc_tipo_posto_minimos <-  function(pathOS, erro_control = 0){
  
  
  source(paste0(pathOS,"connection/dbconn.R"))
  
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  
  
  
  # AVALIA EXISTÊNCIA DE NOVOS HORARIOS PREGERADOS --------------------------
  erro_control <- tryCatch({
    query_getEscTipoPostoMinimos<- paste(readLines(paste0(pathOS,"/data/querys/queryGetEscTipoPostoMinimos.sql")), collapse = " ")
    df_esc_tipo_posto_minimos <-  dbGetQuery(wfm_con, query_getEscTipoPostoMinimos)
    
    
    0
  }, error = function(e){
    print(e$message)
    1
  })
  gc()
  dbDisconnect(wfm_con)
  
  
  
  return(df_esc_tipo_posto_minimos)}


# get_estrutura_WFM !!!Fechado --------------------------------------------
get_estrutura_WFM <-  function(pathOS, erro_control = 0){
  
  
  source(paste0(pathOS,"connection/dbconn.R"))
  
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  # paste(readLines(paste0(pathOS,"/data/querys/queryGetEstruturaWFM.sql")), collapse = " ")
  
  # AVALIA EXISTÊNCIA DE NOVOS HORARIOS PREGERADOS --------------------------
  erro_control <- tryCatch({
    query_getEstruturaWFM<- paste(readLines(paste0(pathOS,"/data/querys/queryGetEstruturaWFM.sql")), collapse = " ")
    df_estrutura_WFM <-  dbGetQuery(wfm_con, query_getEstruturaWFM)
    
    
    0
  }, error = function(e){
    print(e$message)
    1
  })
  gc()
  dbDisconnect(wfm_con)
  
  
  
  return(df_estrutura_WFM)}


# get_excecoes_quantidade !!!Fechado --------------------------------------------
get_excecoes_quantidade <-  function(pathOS, erro_control = 0){
  
  
  source(paste0(pathOS,"connection/dbconn.R"))
  
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  
  # AVALIA EXISTÊNCIA DE NOVOS HORARIOS PREGERADOS --------------------------
  erro_control <- tryCatch({
    query_getExcecoesQuantidade<- paste(readLines(paste0(pathOS,"/data/querys/queryGetExcecoesQuantidade.sql")), collapse = " ")
    df_excecoes_quantidade <-  dbGetQuery(wfm_con, query_getExcecoesQuantidade)
    
    
    0
  }, error = function(e){
    print(e$message)
    1
  })
  gc()
  dbDisconnect(wfm_con)
  
  
  
  return(df_excecoes_quantidade)}


# get_turnos !!!Fechado --------------------------------------------
get_turnos <-  function(pathOS, erro_control = 0){
  
  
  source(paste0(pathOS,"connection/dbconn.R"))
  
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  
  
  # AVALIA EXISTÊNCIA DE NOVOS HORARIOS PREGERADOS --------------------------
  erro_control <- tryCatch({
    query_getTurnos <- paste(readLines(paste0(pathOS,"/data/querys/queryGetTurnos.sql")), collapse = " ")
    
    df_turnos <-  dbGetQuery(wfm_con, query_getTurnos)
    
    
    0
  }, error = function(e){
    print(e$message)
    1
  })
  gc()
  dbDisconnect(wfm_con)
  
  
  
  return(df_turnos)}


# get_feriado !!!Fechado --------------------------------------------
get_feriados <-  function(pathOS, erro_control = 0){
  
  
  source(paste0(pathOS,"connection/dbconn.R"))
  
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  
  # AVALIA EXISTÊNCIA DE NOVOS HORARIOS PREGERADOS --------------------------
  erro_control <- tryCatch({
    query_getFeriadosAbertos <- paste(readLines(paste0(pathOS,"/data/querys/queryGetFeriadosAbertos.sql")), collapse = " ")
    df_feriados <-  dbGetQuery(wfm_con, query_getFeriadosAbertos)
    
    0
  }, error = function(e){
    print(e$message)
    1
  })
  
  erro_control <- tryCatch({
    query_getUnidade <- paste(readLines(paste0(pathOS,"/data/querys/queryGetUnidade.sql")), collapse = " ")
    df_unidade <-  dbGetQuery(wfm_con, query_getUnidade)
    
    
    0
  }, error = function(e){
    print(e$message)
    1
  })
  
  
  gc()
  dbDisconnect(wfm_con)
  
  df_pais <- df_unidade %>% 
    dplyr::select(c(FK_PAIS, FK_UNIDADE)) %>% 
    dplyr::rename(FK_UNI_PAIS=FK_UNIDADE)
  
  df_cidade <- df_unidade %>% 
    dplyr::select(c(FK_CIDADE, FK_UNIDADE))%>% 
    dplyr::rename(FK_UNI_CIDADE=FK_UNIDADE)
  
  df_estado <- df_unidade %>% 
    dplyr::select(c(FK_ESTADO, FK_UNIDADE))%>% 
    dplyr::rename(FK_UNI_ESTADO=FK_UNIDADE)
  
  df_feriados <- merge(df_feriados, df_pais, by='FK_PAIS', all.x=T)
  df_feriados <- merge(df_feriados, df_cidade, by='FK_CIDADE', all.x=T)  
  df_feriados <- merge(df_feriados, df_estado, by='FK_ESTADO', all.x=T)
  
  df_feriados <- df_feriados %>% 
    dplyr::select(c(FK_UNIDADE, DATABASE, FK_UNI_PAIS, FK_UNI_CIDADE, FK_UNI_ESTADO)) %>% 
    dplyr::mutate(FK_UNIDADE_FINAL=ifelse(is.na(FK_UNIDADE), FK_UNI_PAIS, FK_UNIDADE),
                  FK_UNIDADE_FINAL=ifelse(is.na(FK_UNIDADE_FINAL), FK_UNI_CIDADE, FK_UNIDADE_FINAL),
                  FK_UNIDADE_FINAL=ifelse(is.na(FK_UNIDADE_FINAL), FK_UNI_ESTADO, FK_UNIDADE_FINAL)) %>% 
    dplyr::filter(!is.na(FK_UNIDADE_FINAL)) %>% 
    dplyr::select(c(FK_UNIDADE_FINAL, DATABASE)) 
  
  df_feriados <- df_feriados %>% 
    distinct(FK_UNIDADE_FINAL, DATABASE)
  
  return(df_feriados)}

######################TESTING################################
# df1 <- get_esc_faixa_horario(pathConf)
# df2 <- get_esc_orcamento(pathConf,data_ini, data_fim )
# df3 <- get_esc_orcamento_dia(pathConf, data_ini, data_fim)
# df4 <- get_esc_tipo_posto_minimos(pathConf)
# df5 <- get_estrutura_WFM(pathConf)
# df6 <- get_excecoes_quantidade(pathConf)
