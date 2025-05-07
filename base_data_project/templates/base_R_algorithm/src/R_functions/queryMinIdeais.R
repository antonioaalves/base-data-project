#connection <- wfm_con
get_MI_Info <- function(pathConf, connection, postoID, dateSeq){
  ## Get HORARIOS
  queryInsMI <- paste(readLines(paste0(pathConf,"/data/querys/qry_estim_gran.sql")), collapse =" " )
  #i e f são parametros na query. 
  #exe: select * from esc_horario colaborador where data between to_date(:i,'yyyy-mm-dd') and to_date(:f,'yyyy-mm-dd')
  
  queryInsMI <- queryInsMI %>% 
    gsub(':p', paste0("'", postoID, "'"), .) %>% 
    gsub(':i', paste0("'", dateSeq[1], "'"), .) %>% 
    gsub(':f', paste0("'", dateSeq[length(dateSeq)], "'"), .)

  matriz_min_ideal <- tryCatch({
    dbGetQuery(connection, queryInsMI)
  }, error = function(e){
    print("erro query matriz mínimos ideais")
    print(e)
    data.frame()
  }
  )
  print(nrow(matriz_min_ideal))
  return(matriz_min_ideal)
}

