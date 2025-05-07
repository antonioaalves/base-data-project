get_current_cycle_info <- function(pathConf, erro_control = 0, fk_ciclo){
  
  source("connection/dbconn.R")
  #source("connection/queryCalendario.R")
  sis <- Sys.info()[[1]]
  confFileName <-  "conf/CONFIGURATIONS.csv"
  wfm_con <-setConnectionWFM(pathConf, sis, confFileName)
  
  
  
  
  
  
  # AVALIA EXISTÊNCIA DE NOVOS HORARIOS PREGERADOS --------------------------
  erro_control <- tryCatch({
    query_get_current_cycle_info<- paste(readLines("Data/querys/Get/queryGetCurrentCycleInfo.sql",
                                          encoding = 'UTF-8'), collapse = " ")
    query_get_current_cycle_info <- query_get_current_cycle_info %>% 
      gsub("1=1",paste("FK_CICLO = ",fk_ciclo), .)
    
    
    
    df_current_cycle_info <-  dbGetQuery(wfm_con, query_get_current_cycle_info)
    
    
    0
  }, error = function(e){
    print(e$message)
    1
  })
  gc()
  dbDisconnect(wfm_con)
  
  
  
  return(df_current_cycle_info)
  
}
