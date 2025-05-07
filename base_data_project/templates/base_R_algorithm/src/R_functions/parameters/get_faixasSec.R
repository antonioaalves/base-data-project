getFaixaSec <- function(pathOS, uni, sec, dia1, dia2){
  
  source(paste0(pathOS,"connection/dbconn.R"))
  
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  query <- paste(readLines(paste0(pathOS,"/data/querys/parameters/get_faixas_sec.sql")), collapse = " ")
  
  
  query <- gsub(":d1",paste("'",as.character(dia1, format='%Y-%m-%d'),"'", sep=""), query)
  query <- gsub(":d2",paste("'",as.character(dia2, format='%Y-%m-%d'),"'", sep=""), query)
  query <- gsub(":s",paste0(sec), query)
  query <- gsub(":l",paste0("'",uni,"'"), query)

  
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
