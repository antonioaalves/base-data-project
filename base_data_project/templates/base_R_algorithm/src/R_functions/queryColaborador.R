getColaboratorInfo <- function(pathOS, connection, colabsID){
  ## Get HORARIOS
  queryColaboratorInfo <- paste(readLines(paste0(pathOS,"/Data/querys/qry_ma.sql")), collapse = " ")
  #i e f são parametros na query. 
  #exe: select * from esc_horario colaborador where data between to_date(:i,'yyyy-mm-dd') and to_date(:f,'yyyy-mm-dd')
  queryColaboratorInfo <- gsub(':colabs',  paste0(c(colabsID),collapse = ","), queryColaboratorInfo)
  M_colab <- tryCatch({
    dbGetQuery(connection, queryColaboratorInfo)
  }, error = function(e){
    print("erro query matriz colab")
    print(e)
    data.frame()
  }
  )
  
  return(M_colab)
}
