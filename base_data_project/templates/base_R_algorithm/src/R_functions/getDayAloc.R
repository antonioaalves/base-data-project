getDayAloc <- function(pathOS, unitID, date1, date2, matricula){
  
  source(paste0(pathOS,"/connection/dbconn.R"))
  
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  query <- paste(readLines(paste0(pathOS,"/data/querys/linha_horas_praticadas.sql")), collapse = " ")
  
  
  query <- gsub(":i",paste("'",as.character(date1),"'", sep=""), query)
  query <- gsub(":f",paste("'",as.character(date2),"'", sep=""), query)
  query <- gsub(":u",paste("'",as.character(unitID),"'", sep=""), query)
  
  if (!is.null(matricula)) {
    query <- gsub("3=3",paste("ehc.FK_COLABORADOR not in (",matricula,")", sep=""), query)
    
  }
  qwy <<- query
  
  
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
