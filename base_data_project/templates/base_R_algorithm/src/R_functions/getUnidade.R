getUnidade <- function(pathOS, secID){
  
  source(paste0(pathOS,"connection/dbconn.R"))
  
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  query <- paste(readLines(paste0(pathOS,"/data/querys/get_unidade.sql")), collapse = " ")
  
  
  query <- gsub(":s",as.character(secID), query)

  
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
  
  
  return(dfData)
}
