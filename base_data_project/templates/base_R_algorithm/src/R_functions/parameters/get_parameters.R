getAllParams <- function(pathOS, unitID,secao,posto,p_name=NULL){
  
  source(paste0(pathOS,"connection/dbconn.R"))
  
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  query <- paste(readLines(paste0(pathOS,"/data/querys/parameters/get_all_parameters.sql")), collapse = " ")
  
  dfData <- tryCatch({
    data.frame(dbGetQuery(wfm_con,query))
  }, error = function(e) {
    #escrever para tabela de log erro de coneccao
    err <- as.character(gsub('[\"\']', '', e))
    print("erro")
    #dbDisconnect(connection)
    print(err)
    dbDisconnect(wfm_con)
    data.frame()
  })
  
  dbDisconnect(wfm_con)

  
  if (!is.null(p_name)) {
    dfData <- dfData %>%
      dplyr::filter(SYS_P_NAME == p_name)
  }
  

  globalParams <- dfData %>% 
    dplyr::filter(is.na(FK_UNIDADE), is.na(FK_SECAO), is.na(FK_TIPO_POSTO))
  
  if (all(!is.null(unitID))) {
    dfData_tmp <- dfData %>% dplyr::filter(FK_UNIDADE %in% unitID)
    if (nrow(dfData_tmp)==0) {
      dfData_tmp <- dfData %>% dplyr::filter(is.na(FK_UNIDADE))
    }
    dfData <- dfData_tmp
    rm(dfData_tmp)
  }

  
  if (all(!is.null(secao))) {
    dfData_tmp <- dfData %>% dplyr::filter(FK_SECAO %in% secao)
    if (nrow(dfData_tmp)==0) {
      dfData_tmp <- dfData %>% dplyr::filter(is.na(FK_SECAO))
    }
    dfData <- dfData_tmp
    rm(dfData_tmp)
  }
  
  
  if (all(!is.null(posto))) {
    dfData_tmp <- dfData %>% dplyr::filter(FK_TIPO_POSTO %in% posto)
    if (nrow(dfData_tmp)==0) {
      dfData_tmp <- dfData %>% dplyr::filter(is.na(FK_TIPO_POSTO))
    }
    dfData <- dfData_tmp
    rm(dfData_tmp)
  }
  
  
  dfData <- dfData %>% 
    dplyr::bind_rows(globalParams) %>% 
    unique()
  
  return(dfData)
}


##QUERY GRANULARIDADE
getGranEqui <- function(pathOS, secao){
  source(paste0(pathOS,"connection/dbconn.R"))
  
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  gran <- tryCatch({
    as.numeric(dbGetQuery(wfm_con,
                          paste("select s_pck_core_parameter.getnumberattr('GRANULARIDADE_ESCALA', 'S',",secao,") from dual")
    )
    )
    
  }, error = function(e) {
    #escrever para tabela de log erro de coneccao
    err <- as.character(gsub('[\"\']', '', e))
    # showErrorPop('Por favor reinicie a aplicação.')
    
    #dbDisconnect(datasourceDatabaseCon)
    print(err)
    
  })
  dbDisconnect(wfm_con)
  
  return(gran)
}
