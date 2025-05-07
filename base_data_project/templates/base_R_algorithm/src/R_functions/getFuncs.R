getInfoGeral <- function(conn, pathOS, process_id){
  
  
  df <- tryCatch({
    #fkStore <-  unique(dfStg$FK_STORE)
    ##- - - - - - - - - - - - - - - VARIABLE - - - - - - - - - - - - - - - -
    
    query <- paste(readLines(paste0(pathOS, "/Data/BD/infoGeral.sql"), encoding = 'UTF-8'),collapse =" ")
    query <- gsub(":p",process_id, query)
    
    ##- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    
    df <- dbGetQuery(conn,query)
    
    
    df
    
  }, error = function(e) {
    
    e$message <- e$message %>% substr(1, 450)
    
    return(data.frame())
    
  })
  
  return(df)
}


getPonderacoes <- function(conn, pathOS, process_id){
  
  
  df <- tryCatch({
    #fkStore <-  unique(dfStg$FK_STORE)
    ##- - - - - - - - - - - - - - - VARIABLE - - - - - - - - - - - - - - - -
    
    query <- paste(readLines(paste0(pathOS, "/Data/BD/ponderacoes.sql"), encoding = 'UTF-8'),collapse =" ")
    query <- gsub(":p",process_id, query)
    
    ##- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    
    df <- dbGetQuery(conn,query)
    
    
    df
    
  }, error = function(e) {
    
    e$message <- e$message %>% substr(1, 450)
    
    return(data.frame())
    
  })
  
  return(df)
}



getMatrizInicial <- function(conn, pathOS, process_id){
  
  
  df <- tryCatch({
    #fkStore <-  unique(dfStg$FK_STORE)
    ##- - - - - - - - - - - - - - - VARIABLE - - - - - - - - - - - - - - - -
    
    query <- paste(readLines(paste0(pathOS, "/Data/BD/matrizInicial.sql"), encoding = 'UTF-8'),collapse =" ")
    query <- gsub(":p",process_id, query)
    
    ##- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    
    df <- dbGetQuery(conn,query)
    
    
    df
    
  }, error = function(e) {
    
    e$message <- e$message %>% substr(1, 450)
    
    return(data.frame())
    
  })
  
  return(df)
}