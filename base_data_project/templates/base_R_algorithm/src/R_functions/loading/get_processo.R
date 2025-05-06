getProcessByStatus <- function(pathOS, user, process_type, event_type, status){
  
  source(paste0(pathOS,"connection/dbconn.R"))

  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  query <- paste(readLines(paste0(pathOS,"/data/querys/loading/get_process_by_status.sql")), collapse = " ")
  
  
  query <- gsub(":user",paste("'",as.character(user),"'", sep=""), query)
  query <- gsub(":process_type",paste("'",as.character(process_type),"'", sep=""), query)
  query <- gsub(":event_type",paste("'",as.character(event_type),"'", sep=""), query)
  query <- gsub(":status",paste("'",as.character(status),"'", sep=""), query)

  
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


getProcessById <- function(pathOS, process_id){
  
  source(paste0(pathOS,"connection/dbconn.R"))
  
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  query <- paste(readLines(paste0(pathOS,"/data/querys/loading/get_process_by_id.sql")), collapse = " ")
  
  query <- gsub(":i",process_id, query)
  
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


getTotalProcessByStatus <- function(pathOS){
  
  source(paste0(pathOS,"connection/dbconn.R"))
  
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  query <- paste(readLines(paste0(pathOS,"/data/querys/loading/get_total_process_by_status.sql")), collapse = " ")
  
  query <- gsub(":i_process_type","'MPD'", query)
  query <- gsub(":i_status","'P'", query)
  
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

