getParamsLQ <- function(pathOS, connection){
  ## Get HORARIOS
  queryGetParams <- paste(readLines(paste0(pathOS,"/Data/querys/qry_params_LQ.sql")), collapse = " ")
  params <- tryCatch({
    dbGetQuery(connection, queryGetParams)
  }, error = function(e){
    print("erro query params para LQ")
    print(e)
    data.frame()
  }
  )
  
  return(params)
}