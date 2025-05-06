get_90_cycles <- function(pathConf, erro_control = 0, colab_list){
  
  source("connection/dbconn.R")
  #source("connection/queryCalendario.R")
  sis <- Sys.info()[[1]]
  confFileName <-  "conf/CONFIGURATIONS.csv"
  wfm_con <-setConnectionWFM(pathConf, sis, confFileName)
  
  colab_list
  vetor_colabs = paste0("('",paste0(c(colab_list), collapse = "','"),"')")
  
  
  
  
  # AVALIA EXISTÊNCIA DE NOVOS HORARIOS PREGERADOS --------------------------
  erro_control <- tryCatch({
    query_get_90_cycles<- paste(readLines("Data/querys/Get/queryGet_FK_Ciclo.sql",
                                            encoding = 'UTF-8'), collapse = " ")
    query_get_90_cycles <- query_get_90_cycles %>% 
      gsub("1=1",paste("MATRICULA IN ",vetor_colabs), .)
      gs
    
    
    
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