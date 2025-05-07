setConnectionWFM <- function(pathOS, sis,confFile= paste0(pathOS,'/conf/CONFIGURATIONS.csv')){
  
  ##----------CONEXAO BD WFM-------
  
  # setwd(paste0(pathOS,'/connection'))
  
  # connect to oracle bd
  l=c('<CONF>')
  
  ll=1
  source(paste0(pathOS,'/connection/conn.R'))
  conn(CON=l[ll],sis,confFile)
  
  if (ll==2) {
    
    dbSendUpdate(datasourceDatabaseCon)
  }
  
  
  # skSql_DRAW <-paste(readLines(paste0(pathOS,"Data/scheme_dra_wfm.sql")), collapse = " ")
  # tryCatch(
  #   dbSendUpdate(datasourceDatabaseCon, skSql_DRAW)
  # )
  
  
  
}

setConnectionShiny <- function(pathOS, sis, confFile){
  ##----------CONEXAO BD WFM-------
  # setwd(paste0(pathOS,'/connection'))
  # connect to oracle bd
  l=c('<CONF>')
  ll=1
  # source("connShiny.R")
  source(paste0(pathOS,'/connection/connShiny.R'))
  #confFilePLN <- '/conf/CONFIGURATIONS__PLN.dat'
  #conWFMPLN <- conn(CON=l[ll],confFilePLN)
  connShiny <- connShiny(CON=l[ll],sis,confFile)
  
  skSql <-paste(readLines(paste0(pathOS,"/Data/scheme.sql")), collapse = " ")
  tryCatch(
    dbSendUpdate(connShiny, skSql)
  )
  
  return(connShiny)
}
