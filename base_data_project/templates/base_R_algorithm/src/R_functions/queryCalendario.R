#connection <- wfm_con
getCalendarInfo <- function(pathConf, connection, colabsID, iniDate, fimDate){
  ## Get HORARIOS
  queryInsCalendar <- paste(readLines(paste0(pathConf,"/data/querys/qry_mcalendario.sql")), collapse =" " )
  #i e f são parametros na query. 
  #exe: select * from esc_horario colaborador where data between to_date(:i,'yyyy-mm-dd') and to_date(:f,'yyyy-mm-dd')
 
  queryInsCalendar <- queryInsCalendar %>% 
    gsub(':colabs', paste0(c(colabsID),collapse = ","), .) %>% 
    gsub(':i', paste0("'", iniDate, "'"), .) %>% 
    gsub(':f', paste0("'", fimDate, "'"), .)
 
  matriz_calendario <- tryCatch({
    dbGetQuery(connection, queryInsCalendar)
  }, error = function(e){
    print("erro query matriz calendario")
    print(e)
    data.frame()
  }
  )
  
  return(matriz_calendario)
}
