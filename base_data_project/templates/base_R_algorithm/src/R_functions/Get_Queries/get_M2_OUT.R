get_M2_of_OUT <- function(pathOS,maOUT, start_date, end_date){
  source(paste0(pathOS,"/connection/dbconn.R"))
  
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  query <- paste(readLines(paste0(pathOS,"/data/querys/get_M2_OUT.sql")), collapse = " ")
  
  
  maOUT_str <- paste0('(',paste0("'", as.character(maOUT), "'", collapse = ", "),')')
  
  query <- gsub(":colabas", maOUT_str, query)
  query <- gsub(":d1",paste0("'",as.character(start_date),"'"), query)
  query <- gsub(":d2",paste0("'",as.character(end_date),"'"), query)
  
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
