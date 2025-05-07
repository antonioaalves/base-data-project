get_pre_gerados <- function(pathConf, erro_control = 0, colab_list,startDate_2,endDate_2){  
  source("connection/dbconn.R")
  #source("connection/queryCalendario.R")
  sis <- Sys.info()[[1]]
  confFileName <-  "conf/CONFIGURATIONS.csv"
  wfm_con <-setConnectionWFM(pathConf, sis, confFileName)
  
  colab_list
  vetor_colabs = paste0("('",paste0(c(colab_list), collapse = "','"),"')")
  
  
  
  
  # AVALIA EXISTÊNCIA DE NOVOS HORARIOS PREGERADOS --------------------------
  erro_control <- tryCatch({
    query_get_pre_gerados<- paste(readLines("Data/querys/Get/queryGetPregerados.sql",
                                            encoding = 'UTF-8'), collapse = " ")
    
    query_get_pre_gerados <- query_get_pre_gerados %>% 
      gsub("1=1", paste0("FK_EMP IN ", paste(vetor_colabs, collapse = ", ")), .) %>% 
      gsub(":i", paste0("'", startDate_2, "'"), .) %>% 
      gsub(":f", paste0("'", endDate_2, "'"), .)
    
    
    
    
    
    
    df_pregerados <-  dbGetQuery(wfm_con, query_get_pre_gerados)
    
    
    0
  }, error = function(e){
    print(e$message)
    1
  })
  gc()
  dbDisconnect(wfm_con)
  
  
  
  return(df_pregerados)
  
}
  