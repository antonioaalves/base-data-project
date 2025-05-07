get_limit_MT <- function(pathConf, erro_control = 0, colab){
  source("connection/dbconn.R")
  #source("connection/queryCalendario.R")
  sis <- Sys.info()[[1]]
  confFileName <-  "conf/CONFIGURATIONS.csv"
  wfm_con <-setConnectionWFM(pathConf, sis, confFileName)
  # colab_list
  # vetor_colabs = paste0("('",paste0(c(colab_list), collapse = "','"),"')")
  
  
  # AVALIA EXISTÊNCIA DE NOVOS HORARIOS PREGERADOS --------------------------
  erro_control <- tryCatch({
    query_get_limit_MT<- paste(readLines("data/querys/Get/queryGetLimiteMT.sql",
                                         encoding = 'UTF-8'), collapse = " ")
    query_get_limit_MT <- query_get_limit_MT %>% 
      gsub("1=1",paste0("EMP = '",colab,"'"), .)
    
    df_limit_MT <-  dbGetQuery(wfm_con, query_get_limit_MT)
    
    0
  }, error = function(e){
    print(e$message)
    1
  })
  gc()
  dbDisconnect(wfm_con)
  
  return(df_limit_MT)
}