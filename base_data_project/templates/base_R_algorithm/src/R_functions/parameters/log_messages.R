getMessages <- function(pathOS, lang='ES'){
  
  # source(paste0(pathOS,"connection/dbconn.R"))
  # 
  # sis <- Sys.info()[[1]]
  # confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  # wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  # 
  # query <- paste(readLines(paste0(pathOS,"/data/querys/parameters/get_faixas_sec.sql")), collapse = " ")
  # 
  # 
  # query <- gsub(":d1",paste("'",as.character(dia1, format='%Y-%m-%d'),"'", sep=""), query)
  # query <- gsub(":d2",paste("'",as.character(dia2, format='%Y-%m-%d'),"'", sep=""), query)
  # query <- gsub(":s",paste0(sec), query)
  # query <- gsub(":l",paste0("'",uni,"'"), query)
  # 
  # dfData <- tryCatch({
  #   
  #   data.frame(dbGetQuery(wfm_con,query))
  #   
  # }, error = function(e) {
  #   #escrever para tabela de log erro de coneccao
  #   err <- as.character(gsub('[\"\']', '', e))
  #   print("erro")
  #   #dbDisconnect(connection)
  #   print(err)
  #   dbDisconnect(wfm_con)
  #   data.frame()
  # })
  # 
  # dbDisconnect(wfm_con)
  
  
  
  dfMsg <- tryCatch({

    dfMsg <- read.csv2(paste0(pathOS,'data/Traducoes_algoritmo_horarios_trads.csv'))
    names(dfMsg)[1] <- 'VAR'
    
    dfMsg <- reshape2::melt(dfMsg, id='VAR') %>%
      dplyr::rename(LANG = variable,
                    DESC = value) %>% 
      dplyr::filter(LANG==lang)
    
    dfMsg
  }, error = function(e) {
    #escrever para tabela de log erro de coneccao
    err <- as.character(gsub('[\"\']', '', e))
    print("erro")
    #dbDisconnect(connection)
    print(err)
    data.frame()
  })


  
  
  return(dfMsg)
}



# Função para substituir múltiplos placeholders
replace_placeholders <- function(template, values) {
  for (name in names(values)) {
    template <- gsub(paste0("{", name, "}"), values[[name]], template, fixed = TRUE)
  }
  template
}

# # # Exemplo
# # template <- "Olá, meu nome é {nome} e eu tenho {idade} anos."
# # values <- list(nome = "João", idade = 30)
# # mensagem <- replace_placeholders(template, values)
# dfMsg <- getMessages(pathFicheirosGlobal, lang='ES')

setMessages <- function(dfMsg, var, values){
  msg <- replace_placeholders(dfMsg[dfMsg$VAR == var,'DESC'], values)
  return(msg)
}

# setMessages(dfMsg,'iniProc',list('1'='x','2'='v'))
