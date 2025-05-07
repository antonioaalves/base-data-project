getCoreSchedule <- function(pathOS, iniDate, fimDate, colabs){
  
  source(paste0(pathOS,"connection/dbconn.R"))
  
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  query <- paste(readLines(paste0(pathOS,"/data/querys/get_core_schedule.sql")), collapse = " ")
  
  
  query <- query %>% 
    gsub(':colabs', paste0(c(colabsID),collapse = ","), .) %>% 
    gsub(':i', paste0("'",iniDate,"'"), .) %>% 
    gsub(':f', paste0("'",fimDate,"'"), .)

  fdfgfd <<- query
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
