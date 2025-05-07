
source(paste0(pathOS,"/Rfiles/funcs.R"))

inicializaCalendarioTurnos_old <- function(pathOS, FK_POSTO) {
  ### Declare variables
  valid1 <- T
  valid2 <- T
  valid3 <- T
  errorMessage <- ''
  wrongDate <- T
  
  ### Read the csv file and store it in a variable
  fileName <- paste0(pathOS,"/Data/CSV/",FK_POSTO,".csv")
  matriz <- read.csv2(fileName, fileEncoding = 'UTF-8-BOM', header = F,check.names=FALSE)
  
  ### Remove the last column if FK_TIPO_POSTO is present
  if (matriz[1,ncol(matriz)] == 'FK_TIPO_POSTO' | is.na(matriz[1,ncol(matriz)])) {
    matriz <- matriz[-length(matriz)]
  }
  
  ### File CALENDARIO validations ---------------------------------------------- 
  # 1st line must be DIA
  if (matriz[1,1] != 'DIA') {
    errorMessage <- paste0(errorMessage, 'Calendario inválido: "DIA" tem que corresponder à primeira linha - analisar ficheiro ', fileName, '.\n')
    valid1 <- FALSE
  }
  # 2nd line must be TIPO_DIA
  if (matriz[2,1] != 'TIPO_DIA') {
    errorMessage <- paste0(errorMessage, 'Calendario inválido: "TIPO_DIA" tem que corresponder à segunda linha - analisar ficheiro ', fileName, '.\n')
    valid2 <- FALSE
  }
  # 3rd line must be TURNO
  if (matriz[3,1] != 'TURNO') {
    errorMessage <- paste0(errorMessage, 'Calendario inválido: "TURNO" tem que corresponder à terceira linha - analisar ficheiro ', fileName, '.\n')
    valid3 <- FALSE
  }
  # Check if there is double the number of dates
  if (((ncol(matriz)-1)/2) %% 2 != 0) {
    errorMessage <- paste0(errorMessage, 'Calendário inválido: Tem que existir um número par de datas - analisar ficheiro ', fileName, '.\n')
  }
  # if ANY validation is not true, the algorithm should not go on
  if (!valid1 | !valid2 | !valid3) {
    cat(errorMessage)
    return(NULL)
  }
  
  
  ### Transformations ----------------------------------------------------------
  matriz[,1] <- as.character(matriz[,1])
  matriz[,1] <- sapply(matriz[,1], pad_zeros)
  
  # Do not let it change TURNO
  matriz[3,1] <- 'TURNO'
  
  # Transform date format if needed
  # if (all(IsDate(matriz[1, -1]))) {
  #   matriz <- matriz %>%
  #     dplyr::mutate(across(-1,
  #                          ~ ifelse(V1 == "DIA", as.character(as.Date(., format = "%Y-%m-%d")), .)))
  #   
  #   
  # }
  if (wrongDate) {matriz[1,-1] <- format(as.Date(as.character(matriz[1,-1]), format='%d/%m/%Y'), '%Y-%m-%d')}
  
  
  return(matriz)
}

inicializaEstimativas <- function(pathOS, pathFile = "/Data/outputTurnos_Marco_V29_getafe.csv", daysNumber) {
  ### Declare variables
  errorMessage <- ''
  valid <- list()
  
  ### Read the file and store it in a variable
  matriz <- read.csv(paste0(pathOS,pathFile), fileEncoding = 'UTF-8-BOM', header = T, sep=";",dec = ",",check.names=FALSE)
  
  ### Transformations
  matriz <- matriz %>%
    dplyr::select(mediaTurno, maxTurno, minTurno, sdTurno, FK_TIPO_POSTO, DATA_TURNO) %>% 
    separate(DATA_TURNO, into = c("DATA", "TURNO"), sep = "_") %>% 
    dplyr::filter(DATA >= '2024-01-01') %>%
    dplyr::filter(FK_TIPO_POSTO == FK_POSTO)
  
  ### Validations --------------------------------------------------------------
  for (tipoTurno in c('M', 'T')) {
    valid <- c(valid, T)
    matrizTurnos <- matriz %>%
      dplyr::filter(TURNO == tipoTurno)
    if (nrow(matrizTurnos) != daysNumber) {
      errorMessage <- paste0(errorMessage, 
                             'Estimativas inválidas: O ficheiro ', 
                             pathFile, 
                             ' tem apenas ', 
                             nrow(matrizTurnos),
                             ' rows e deviam ser ',
                             daysNumber,
                             '.\n')
    } 
    
  }
  
  if (!any(as.logical(unlist(valid)))) {
    cat(errorMessage)
    return(NULL)
  }
  
  return(matriz)
}
