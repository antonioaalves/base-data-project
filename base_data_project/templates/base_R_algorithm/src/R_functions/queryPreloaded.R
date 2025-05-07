#connection <- wfm_con
getPreloadedBD <- function(pathConf, connection, colabsID, dateSeq){
  ## Get HORARIOS
  queryPreloaded <- paste(readLines(paste0(pathConf,"/data/querys/qry_preloaded.sql")), collapse =" " )
  #i e f são parametros na query. 
  #exe: select * from esc_horario colaborador where data between to_date(:i,'yyyy-mm-dd') and to_date(:f,'yyyy-mm-dd')
 
  queryPreloaded <- queryPreloaded %>% 
    gsub(':colabs', paste0(c(colabsID),collapse = ","), .) %>% 
    gsub(':i', paste0("'", dateSeq[1], "'"), .) %>% 
    gsub(':f', paste0("'", dateSeq[length(dateSeq)], "'"), .)
 
  matriz_preload <- tryCatch({
    dbGetQuery(connection, queryPreloaded)
  }, error = function(e){
    print("erro query matriz calendario")
    print(e)
    data.frame()
  }
  )
  
  return(matriz_preload)
}
