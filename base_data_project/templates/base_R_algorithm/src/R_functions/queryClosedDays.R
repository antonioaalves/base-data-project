get_closed_days <- function(pathOS, unidade){
  source(paste0(pathOS,"/connection/dbconn.R"))
  ### Connect to the databse
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  ## Get HORARIOS
  query_get_colsed_days<- paste(readLines("data/querys/Get/queryGetClosedDays.sql",
                                       encoding = 'UTF-8'), collapse = " ")
  query_get_colsed_days <- query_get_colsed_days %>% 
    gsub(':c', paste0("'", unidade, "'"), .)
  
  M_ClosedDays <- tryCatch({
    dbGetQuery(wfm_con, query_get_colsed_days)
  }, error = function(e){
    print("erro query matriz festivos")
    print(e)
    data.frame()
  })
  
  dbDisconnect(wfm_con)
  
  return(M_ClosedDays)
}
