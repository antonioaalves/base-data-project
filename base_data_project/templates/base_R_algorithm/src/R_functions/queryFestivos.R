get_feriados_all <- function(pathOS, unidade){
  source(paste0(pathOS,"/connection/dbconn.R"))
  ### Connect to the databse
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  ## Get HORARIOS
  query_get_feriados<- paste(readLines("data/querys/Get/queryGetFeriados.sql",
                                       encoding = 'UTF-8'), collapse = " ")
  query_get_feriados <- query_get_feriados %>% 
    gsub(':c', paste0("'", unidade, "'"), .)
  
  M_festivos <- tryCatch({
    dbGetQuery(wfm_con, query_get_feriados)
  }, error = function(e){
    print("erro query matriz festivos")
    print(e)
    data.frame()
  })
  
  dbDisconnect(wfm_con)
  
  return(M_festivos)
}
