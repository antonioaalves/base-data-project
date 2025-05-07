#connection <- wfm_con
get_NECESS_Info <- function(pathConf, connection, postoID, dateSeq){
  ## Get HORARIOS
  queryInsNECESS <- paste(readLines(paste0(pathConf,"/data/querys/qry_estim_necessidades.sql")), collapse =" " )
  #i e f são parametros na query. 
  #exe: select * from esc_horario colaborador where data between to_date(:i,'yyyy-mm-dd') and to_date(:f,'yyyy-mm-dd')
  
  queryInsNECESS <- queryInsNECESS %>% 
    gsub(':p', paste0("'", postoID, "'"), .) %>% 
    gsub(':i', paste0("'", dateSeq[1], "'"), .) %>% 
    gsub(':f', paste0("'", dateSeq[length(dateSeq)], "'"), .)
  
  matriz_necessidades <- tryCatch({
    dbGetQuery(connection, queryInsNECESS)
  }, error = function(e){
    print("erro query matriz necessidades")
    print(e)
    data.frame()
  }
  )
  
  return(matriz_necessidades)
}
