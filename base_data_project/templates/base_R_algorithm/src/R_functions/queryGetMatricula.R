# PROCESS_ID <- 16710 
# pathConf <- pathOS
get_matricula<- function(pathConf, erro_control = 0, colabs_90_cycle){
  
  source("connection/dbconn.R")
  #source("connection/queryCalendario.R")
  sis <- Sys.info()[[1]]
  confFileName <-  "conf/CONFIGURATIONS.csv"
  wfm_con <-setConnectionWFM(pathConf, sis, confFileName)
  
  
  
  colabs_90_cycle
  vetor_colabs = paste0("('",paste0(c(colabs_90_cycle), collapse = "','"),"')")
  
  # AVALIA EXISTÊNCIA DE NOVOS HORARIOS PREGERADOS --------------------------
  erro_control <- tryCatch({
    query_get_matricula<- paste(readLines("Data/querys/Get/queryGetMatriculaByFK.sql",
                                          encoding = 'UTF-8'), collapse = " ")
    query_get_matricula <- query_get_matricula %>% 
      gsub("1=1",paste0("CODIGO in ", vetor_colabs), .)
    
    
    
    
    matriculas <-  dbGetQuery(wfm_con, query_get_matricula)
    
    
    0
  }, error = function(e){
    print(e$message)
    1
  })
  gc()
  dbDisconnect(wfm_con)
  
  
  
  return(matriculas)
  
}
