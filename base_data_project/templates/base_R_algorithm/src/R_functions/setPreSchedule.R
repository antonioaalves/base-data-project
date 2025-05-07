funcInsertDF <- function(matriz, pathOS){
  
  source(paste0(pathOS,"connection/dbconn.R"))
  
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  matriz$SCHED_TYPE <- as.character(matriz$SCHED_TYPE)
  matriz$SCHED_SUBTYPE <- as.character(matriz$SCHED_SUBTYPE)
  
  dfTratado <- convert_types_out(matriz)
  
  
  ## INSERT HORARIOS
  errInd <- tryCatch({
    
    queryInsHorarios <- paste(readLines(paste0(pathOS,"/data/querys/set_pre_schedule.sql")))
    
    dbSendUpdate(wfm_con,
                 queryInsHorarios,
                 dfTratado$wfm_proc_id,
                 dfTratado$COLABORADOR,
                 dfTratado$DATA,
                 dfTratado$SCHED_TYPE,
                 dfTratado$SCHED_SUBTYPE
    )
    print("sucesso inserir horarios")
    0
  }, error = function(e){
    print("erro inserir horarios")
    print(e)
    1
  }
  )
  print(errInd)
  
  
  dbDisconnect(wfm_con)
}
