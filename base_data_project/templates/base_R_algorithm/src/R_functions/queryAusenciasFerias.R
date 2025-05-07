get_ausencias_ferias <- function(pathConf, erro_control = 0, colab_list){
  
  source("connection/dbconn.R")
  #source("connection/queryCalendario.R")
  sis <- Sys.info()[[1]]
  confFileName <-  "conf/CONFIGURATIONS.csv"
  wfm_con <-setConnectionWFM(pathConf, sis, confFileName)
  
  colab_list
  vetor_colabs = paste0("('",paste0(c(colab_list), collapse = "','"),"')")
  
  
  
  
  # AVALIA EXISTÊNCIA DE NOVOS HORARIOS PREGERADOS --------------------------
  erro_control <- tryCatch({
    query_get_ausencias<- paste(readLines("data/querys/Get/queryGetAusencias.sql",
                                          encoding = 'UTF-8'), collapse = " ")
    query_get_ausencias <- query_get_ausencias %>% 
      gsub("1=1",paste("MATRICULA IN ",vetor_colabs), .)
    
    
    
    df_ausencias <-  dbGetQuery(wfm_con, query_get_ausencias)
    
    
    0
  }, error = function(e){
    print(e$message)
    1
  })
  gc()
  dbDisconnect(wfm_con)
  
  
  
  return(df_ausencias)
  
}
