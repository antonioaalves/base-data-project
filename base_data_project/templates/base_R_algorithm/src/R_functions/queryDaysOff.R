get_days_off <- function(pathConf, erro_control = 0, colab_list){
  
  source("connection/dbconn.R")
  #source("connection/queryCalendario.R")
  sis <- Sys.info()[[1]]
  confFileName <-  "conf/CONFIGURATIONS.csv"
  wfm_con <-setConnectionWFM(pathConf, sis, confFileName)
  
  colab_list
  colab_list <- c(4401683, colab_list) # colab 4401683 for testing purposes
  
  vetor_colabs = paste0("('",paste0(c(colab_list), collapse = "','"),"')")
  
  
  
  
  # AVALIA EXISTÊNCIA DE NOVOS HORARIOS PREGERADOS --------------------------
  erro_control <- tryCatch({
    query_get_get_days_off<- paste(readLines("Data/querys/Get/queryGetDaysOff.sql",
                                          encoding = 'UTF-8'), collapse = " ")
    query_get_get_days_off <- query_get_get_days_off %>% 
      gsub("1=1",paste("EMPLOYEE_ID IN ",vetor_colabs), .)
    
    
    
    df_days_off <-  dbGetQuery(wfm_con, query_get_get_days_off)
    
    
    0
  }, error = function(e){
    print(e$message)
    1
  })
  gc()
  dbDisconnect(wfm_con)
  
  
  
  return(df_days_off)
  
}
