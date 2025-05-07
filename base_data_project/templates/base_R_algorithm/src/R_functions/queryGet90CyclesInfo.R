# PROCESS_ID <- 17127
# pathConf <- pathOS
get_90_cycles_info <- function(pathConf, erro_control = 0, PROCESS_ID, startDate_2, endDate_2, colabsID){
  
  source("connection/dbconn.R")
  #source("connection/queryCalendario.R")
  sis <- Sys.info()[[1]]
  confFileName <-  "conf/CONFIGURATIONS.csv"
  wfm_con <-setConnectionWFM(pathConf, sis, confFileName)
  
 
  
  
  
  
  # AVALIA EXISTÊNCIA DE NOVOS HORARIOS PREGERADOS --------------------------
  erro_control <- tryCatch({
    query_get_90_cycles<- paste(readLines("Data/querys/Get/queryGet90CyclesInfo.sql",
                                          encoding = 'UTF-8'), collapse = " ")
    query_get_90_cycles <- query_get_90_cycles %>% 
      gsub(":c",paste0(PROCESS_ID), .) %>% 
      gsub(':m', paste0(c(colabsID),collapse = ","), .) %>% 
      gsub(":i",paste0("'", startDate_2, "'"), .) %>% 
      gsub(":f",paste0("'", endDate_2, "'"), .)
    
    
    
    
    df_90_cycles_info <-  dbGetQuery(wfm_con, query_get_90_cycles)
    
    
    0
  }, error = function(e){
    print(e$message)
    1
  })
  gc()
  dbDisconnect(wfm_con)
  
  
  
  return(df_90_cycles_info)
  
}

