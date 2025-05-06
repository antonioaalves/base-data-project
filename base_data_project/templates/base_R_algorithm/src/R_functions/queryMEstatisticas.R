#connection <- wfm_con
get_Me_Info <- function(pathConf, connection, postoID, dateSeq){
  ## Get HORARIOS
  queryInsME <- paste(readLines(paste0(pathConf,"/data/querys/qry_estim_turnos.sql")), collapse =" " )
  #i e f são parametros na query. 
  #exe: select * from esc_horario colaborador where data between to_date(:i,'yyyy-mm-dd') and to_date(:f,'yyyy-mm-dd')
  
  queryInsME <- queryInsME %>% 
    gsub(':p', paste0("'", postoID, "'"), .) %>% 
    gsub(':i', paste0("'", dateSeq[1], "'"), .) %>% 
    gsub(':f', paste0("'", dateSeq[length(dateSeq)], "'"), .)
  
  matriz_base_dados_estatisticas <- tryCatch({
    dbGetQuery(connection, queryInsME)
  }, error = function(e){
    print("erro query matriz estatisticas(Turnos)")
    print(e)
    data.frame()
  }
  )
  
  return(matriz_base_dados_estatisticas)
}
