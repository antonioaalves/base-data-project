# Import needed functions
# M_colab <- matriz_colaborador
# M_calendario <- matriz_calendario
# M_dia_final <- M_dia4_final
# dateList <- dateSeq
# unid <- info$UNI
# colabList <- matriz_calendario$MATRICULA

# Function that validates the several rules for scheduler
validatorSuperMega <- function(M_colab, M_calendario, M_dia_final, matriz_festivos, M_WFM, dateList, posto, unid, M_WFM_analysis, colabsCiclosPre) {
  ### Validates that scheduler rules are being met ###
  # Inputs: M_colab - Colab information, 
  #         M_dia_final - schedules saved as a list of dataframes (each one has the sequence of 1's, 0's and P's for the given timestamps), 
  #         dateList (list of days to be considered), 
  #         posto - FK_TIPO_POSTO (integer)
  #         colabList (list of colab ids to be considered)
  # Outputs: Excel containing 4 reports
  
  # Settings: ------------------------------------------------------------------
  colunasConsideradas <- c('EMP',
                           'TIPO_DE_TURNO',
                           'T_TOTAL', 
                           'HORAS_TRAB_DIA_CARGA_MAX', 
                           'HORAS_TRAB_DIA_CARGA_MIN',
                           'HORAS_TRAB_SEMANA_MAX',
                           "HORAS_TRAB_MENSAL_MIN",
                           'MIN_ANUAL',
                           'MAX_ANUAL',
                           'HORAS_MEDIAS_P_DIA',
                           'DESC_CONTINUOS_INC_EXC',
                           'DESC_CONTINUOS_TEMPO_LIMITE_NAO_DESCANSO',
                           'DESC_CONTINUOS_TMIN_ATE',
                           'DESC_CONTINUOS_TMIN_APOS',
                           'DESC_CONTINUOS_DURACAO',
                           'HORAS_TRAB_ANO',
                           'HORAS_TRAB_SEMANA_MAX')
  
  # Dataframe creation for cargas diárias
  df1 <- data.frame(
    DATE = character(),
    EMP = character(),
    HORAS_TRABALHADAS = numeric(),
    CARGA_MIN = numeric(),
    CARGA_MAX = numeric(),
    HORA_IN = character(),
    HORA_OUT = character(),
    PAUSA_TS = character(),
    PAUSA_TEMPO = numeric(),
    stringsAsFactors = FALSE
  )
  
  # Dataframe creation for zeros
  df2 <- data.frame(
    DATE = character(),
    TIPO_ERRO = character(),
    TIMESTAMP_ERRO = character(),
    stringsAsFactors = FALSE
  )
  
  # Apagar depois do Miguel dar merge ao código
  df3 <- data.frame(
    EMP = character(),
    DATE = character(),
    TIPO_ERRO = character(),
    stringsAsFactors = FALSE
  )
  
  # Create a list of data frames
  dfList <- list()
  dfListZeros <- list()
  
  # filter information for colabs needed and select columns used
  colabList <- matriz_calendario$MATRICULA
  M_colab <- M_colab %>% 
    filter(EMP %in% colabList) %>% 
    select(all_of(colunasConsideradas))
  
  
  # Loop through the sequence of days to acces each dataframe in M_dia_final
  for (dia in dateList) {
    print(paste('Dia:', dia))
    # date definition
    dateYMD <- format(as.POSIXct(dia, format = "%Y-%m-%d"), '%Y-%m-%d')
    dateDMY <- format(as.POSIXct(dia, format = "%Y-%m-%d"), '%d-%m-%Y')
    
    #saveDatttte <<- dia
    # skip iteration if no one works for date
    if (is.null(M_dia_final[[dateYMD]])) {next}
    
    # filter M_dia_final for this day, and remove unwanted columns
    M_dia <- M_dia_final[[dateYMD]] 
    
    # Get horarios for this day 
    horariosResult <- findSeq(M_dia)
    horariosList <- horariosResult[[1]]
    pausasDF <- horariosResult[[2]]
    
    # Get pausas for this day
    #pausasList <- findPausas(M_dia)
    
    # ensure horarios exist
    if (length(horariosList) == 0) {
      print(paste('Not possible to retrieve schedules for day: ', dia, sep = ''))
      next
    }
    
    # Create 1st dataframe with amount of hours worked for that day and add carga min and carga max
    dfList[[length(dfList) + 1]] <- horasTrabalhadas(df1, dia, M_calendario, M_colab, horariosList, pausasDF, colabList)
    
    # Create 2nd dataframe for zeros check up
    dfListZeros[[length(dfListZeros) + 1]] <- checkFaixaSec(df2, dia, M_dia)
  }
  
  # Join the dataframes lists into two single dataframes
  df1 <- do.call(rbind, dfList)
  df2 <- do.call(rbind, dfListZeros)
  
  # Check if cargas are nice
  dfHoras <- compareCargasDiarias(df1, matriz_colaborador)
  
  # Check if pausas are nice
  dfHorasPausas <- comparePausas(dfHoras)
  
  # Check if Zeros e alocados fora faixa are nice
  dfHorasPausasZeros <- compareZeros(dfHorasPausas, df2)
  
  # Calculate annual rules
  dfAnual <- annualRules(dfHoras, M_colab, M_calendario, colabList)
  
  # Calculate the weekly hours
  dfSemanal <- compareCargasSemana(dfHoras, M_colab)
  
  # Calculate the monthly hours
  dfMensal <- compareCargasMes(dfHoras, M_colab)
  
  # Check interjornadas rules
  df3 <- auditor_interjornadas_V2(M_WFM, matriz_festivos)
  
  # Create a dataframe with only the not valid occurrences
  dfValidacoes <- invalidOccurrences(df3, dfHorasPausasZeros, M_colab, colabList)
  
  # Save result in different indexes
  result <- list()
  result[[1]] <- dfValidacoes
  result[[2]] <- dfHorasPausas
  result[[3]] <- dfAnual
  result[[4]] <- dfSemanal
  result[[5]] <- dfMensal
  result[[6]] <- M_WFM_analysis
  return(result)
}


horasTrabalhadas <- function(dfHorasT, dia, M_calendario, M_colab, horariosList, pausasDF, colabList) {
  
  # Information about pausas
  pausaInfoContinuos <- M_colab %>% select(EMP, 
                                  DESC_CONTINUOS_INC_EXC, 
                                  DESC_CONTINUOS_TEMPO_LIMITE_NAO_DESCANSO, 
                                  DESC_CONTINUOS_DURACAO, 
                                  DESC_CONTINUOS_TMIN_ATE, 
                                  DESC_CONTINUOS_TMIN_APOS)
  
  # Information about cargas
  cargasInfo <- M_colab %>% select(EMP,
                                   HORAS_TRAB_DIA_CARGA_MIN, 
                                   HORAS_TRAB_DIA_CARGA_MAX)
  
  dfListH <- list()
  
  for (colab in colabList) {
    # print(paste('colab:', colab))
    dayType <- M_calendario[M_calendario$MATRICULA == colab, dia]
    colabHorario <- paste('EMPloyee_', colab, sep = '')
    
    # Retrieve CARGA_MIN and CARGA_MAX
    cargaMin <- (cargasInfo %>% filter(EMP == colab))[, 2]
    cargaMax <- (cargasInfo %>% filter(EMP == colab))[, 3]
    
    # Retrieve TEMPO_ANTES and DEPOIS, TEMPO_LIMITE_NAO_DESCANSO
    tempoLimite <- hour(as.POSIXct((pausaInfoContinuos %>% filter(EMP == colab))[1, 3], format = '%H:%M')) + minute(as.POSIXct((pausaInfoContinuos %>% filter(EMP == colab))[1, 3], format = '%H:%M'))/60
    tempoPausa <- hour(as.POSIXct((pausaInfoContinuos %>% filter(EMP == colab))[1, 4], format = '%H:%M')) + minute(as.POSIXct((pausaInfoContinuos %>% filter(EMP == colab))[1, 4], format = '%H:%M'))/60
    tempoAntes <- hour(as.POSIXct((pausaInfoContinuos %>% filter(EMP == colab))[1, 5], format = '%H:%M')) + minute(as.POSIXct((pausaInfoContinuos %>% filter(EMP == colab))[1, 5], format = '%H:%M'))/60
    tempoDepois <- hour(as.POSIXct((pausaInfoContinuos %>% filter(EMP == colab))[1, 6], format = '%H:%M')) + minute(as.POSIXct((pausaInfoContinuos %>% filter(EMP == colab))[1, 6], format = '%H:%M'))/60
    
    # saveHorar <<- horariosList
    # Check if it doesn't work on that day
    if (dayType != 'M' & dayType != 'T') {
      horitas <- 0
      pausitaTS <- ''
      pausitaTempo <- 0
      horitaIN <- ''
      horitaOUT <- '' 
    } else {
      horitaIN <- horariosList[[colabHorario]][[1]]

      # Must work do the meth - check if the pausa is included or excluded
      # if (pausaInfoContinuos[pausaInfoContinuos$EMP == colab, 2] == 'Y') {
        # Check if it has one sequence for schedule
      if (length(horariosList[[colabHorario]]) == 2) {
        horitas <- as.numeric(difftime(as.POSIXct(horariosList[[colabHorario]][[2]], format = '%H:%M'), as.POSIXct(horariosList[[colabHorario]][[1]], format = '%H:%M'), units = 'hours'))
        pausitaTS <- ''
        pausitaTempo <- 0
        horitaOUT <- horariosList[[colabHorario]][[2]]
        # Check if it has two sequences of schedule
      } else if (length(horariosList[[colabHorario]]) == 4) {
        horitas <- as.numeric(difftime(as.POSIXct(horariosList[[colabHorario]][[4]], format = '%H:%M'), as.POSIXct(horariosList[[colabHorario]][[3]], format = '%H:%M'), units = 'hours'))
        horitas <- horitas + as.numeric(difftime(as.POSIXct(horariosList[[colabHorario]][[2]], format = '%H:%M'), as.POSIXct(horariosList[[colabHorario]][[1]], format = '%H:%M'), units = 'hours'))
        pausitaTS <- pausasDF[pausasDF$EMP == colabHorario, 'PAUSA_TS']
        pausitaTempo <- pausasDF[pausasDF$EMP == colabHorario, 'TEMPO_DE_PAUSA']
        horitaOUT <- horariosList[[colabHorario]][[4]]
      }
    } 
      # else {
      #   if (length(horariosList[[colabHorario]]) == 2) {
      #     horitas <- as.numeric(difftime(as.POSIXct(horariosList[[colabHorario]][[2]], format = '%H:%M'), as.POSIXct(horariosList[[colabHorario]][[1]], format = '%H:%M'), units = 'hours'))
      #     pausitaTS <- ''
      #     pausitaTempo <- 0
      #     horitaOUT <- horariosList[[colabHorario]][[2]]
      #   } else if (length(horariosList[[colabHorario]]) == 4) {
      #     horitas <- as.numeric(difftime(as.POSIXct(horariosList[[colabHorario]][[4]], format = '%H:%M'), as.POSIXct(horariosList[[colabHorario]][[1]], format = '%H:%M'), units = 'hours'))
      #     pausitaTS <- pausasDF[pausasDF$EMP == colabHorario, 'PAUSA_TS']
      #     pausitaTempo <- pausasDF[pausasDF$EMP == colabHorario, 'TEMPO_DE_PAUSA']
      #     horitaOUT <- horariosList[[colabHorario]][[4]]
      #   }
      # }
  
    # print(horitas)
    new_row <- data.frame(
      DATE = as.character(dia),
      EMP = as.character(colab),
      TIPO_TURNO = as.character(M_colab[M_colab$EMP == colab, 'TIPO_DE_TURNO']),
      HORAS_TRABALHADAS = as.numeric(horitas),
      CARGA_MIN = as.numeric(cargaMin),
      CARGA_MAX = as.numeric(cargaMax),
      TEMPO_LIMITE_NAO_DESCANSO = as.numeric(tempoLimite),
      DAY_TYPE = as.character(dayType),
      HORA_IN = as.character(horitaIN),
      TEMPO_ANTES = as.numeric(tempoAntes),
      HORA_OUT = as.character(horitaOUT),
      TEMPO_DEPOIS = as.numeric(tempoDepois),
      PAUSA_TS = as.character(pausitaTS),
      PAUSA_TEMPO = as.numeric(pausitaTempo),
      PAUSA_CONTRATO = as.numeric(tempoPausa),
      stringsAsFactors = FALSE
    )
    # saveRow <<- new_row
    # dfHorasT <- rbind(dfHorasT, new_row)
    dfListH[[length(dfListH) + 1]] <- new_row
  }
  dfHorasT <- do.call(rbind, dfListH)
  return(dfHorasT)
}

# dfFaixa <- df2
checkFaixaSec <- function(dfFaixa, dia, M_dia) {
  opening_index <- which(diff(M_dia$Minimo > 0) == 1)
  opening_index <- opening_index[1]
  closing_index <- which(diff(M_dia$Minimo > 0) == -1)
  closing_index <- closing_index[length(closing_index)]
  opening_index <- ifelse(is.na(opening_index), 1, opening_index)
  closing_index <- ifelse(is.na(closing_index), nrow(M_dia), closing_index)
  closing_index <- ifelse(length(closing_index) == 0, nrow(M_dia), closing_index[1])
  # opening_index <- getOpening(dia) 
  # closing_index <- getClosing(dia)
  # Separating the dataframe
  # M_faixa_pre <- M_dia %>% slice(1:opening_index)
  M_faixa <- M_dia %>% slice((opening_index):closing_index)
  # M_faixa_pos <- M_dia %>% slice((closing_index+1):nrow(M_dia))
  
  # New approach
  # M_faixa_dentro <- M_dia[which(M_dia$Minimo > 0),]
  # M_faixa_fora <- M_dia[which(M_dia$Minimo == 0),]
  
  dfList <- list()
  
  
  ### Testa alocados fora da faixa (descontinuado)
  # if (any(M_faixa_pre$Alocado < M_faixa_pre$Minimo)) {
  #   indexErrosPre <- which(M_faixa_pre$Alocado - M_faixa_pre$Minimo < 0)
  #   for (index in indexErrosPre) {
  #     dfList[[length(dfList) + 1]] <- data.frame(
  #       DATE = as.character(dia),
  #       TIPO_ERRO = 'Alocado antes da faixa',
  #       TIMESTAMP_ERRO = rownames(M_faixa_pre[index,]),
  #       stringsAsFactors = FALSE
  #     )
  #   }
  # }
  
  # Testa não haver alocados dentro da faixa
  if (any(M_faixa$Alocado == 0)) {
    indexErrosDentro <- which(M_faixa$Alocado == 0)
    for (index in indexErrosDentro) {
      # Check if there is a pausa for that index in any of the colabs, if so consider it a error and register the information
      if (length(apply(M_faixa[index,],1 ,function(x) which(x=='P'))) == 0) {
        dfList[[length(dfList) + 1]] <- data.frame(
          DATE = as.character(dia),
          TIPO_ERRO = 'Zeros dentro da faixa',
          TIMESTAMP_ERRO = rownames(M_faixa[index,]),
          stringsAsFactors = FALSE
        )
      }
    }
  }

  # Testa alocados fora da faixa (descontinuado)
  # if (any(M_faixa_pos$Alocado < M_faixa_pos$Minimo)) {
  #   indexErrosPos <- which(M_faixa_pos$Alocado - M_faixa_pos$Minimo < 0)
  #   for (index in indexErrosPos) {
  #     dfList[[length(dfList) + 1]] <- data.frame(
  #       DATE = as.character(dia),
  #       TIPO_ERRO = 'Alocado depois da faixa',
  #       TIMESTAMP_ERRO = rownames(M_faixa_pos[index,]),
  #       stringsAsFactors = FALSE
  #     )
  #   }
  # }
  
  if (length(dfList) == 0) {
    dfResult <- data.frame(
      DATE = as.character(),
      TIPO_ERRO = as.character(),
      TIMESTAMP_ERRO = as.character(),
      stringsAsFactors = FALSE
    )
  } else {
    dfResult <- do.call(rbind, dfList)
  }
  return(dfResult)
}

comparePausas <- function(df1) {
  df1 <- df1 %>%
    mutate(VALID_ANTES_DEPOIS = if_else(
      ((DAY_TYPE %in% c('M', 'T')) & (PAUSA_TEMPO > 0) & !(difftime(as.POSIXct(PAUSA_TS, format = '%H:%M'), as.POSIXct(HORA_IN, format = '%H:%M'), units = 'hours') >= TEMPO_ANTES) & !(difftime(as.POSIXct(PAUSA_TS, format = '%H:%M'), as.POSIXct(HORA_OUT, format = '%H:%M'), units = 'hours') >= TEMPO_DEPOIS)),
      'NO',
      'YES')) %>%
    # if it is a working day, pausa_contrato different than pausa_tempo and has pausa is invalid
    mutate(VALID_DURACAO = if_else(
      ((DAY_TYPE %in% c('M', 'T')) & !(PAUSA_CONTRATO == PAUSA_TEMPO) & (PAUSA_TEMPO > 0)),
        'NO',
        'YES'
    )) %>% 
    mutate(VALID_LIMITE_DESCANSO = if_else(
      ((DAY_TYPE %in% c('M', 'T')) & !(TEMPO_LIMITE_NAO_DESCANSO <= HORAS_TRABALHADAS) & (PAUSA_TEMPO > 0)),
       'NO',
       'YES'
    )) %>% 
    mutate(VALID_PAUSAS = if_else(
      (VALID_ANTES_DEPOIS == 'YES' & VALID_DURACAO == 'YES' & VALID_LIMITE_DESCANSO == 'YES'),
      'YES',
      'NO'
    ))
  return(df1)
}

compareCargasDiarias <- function(dfCargas, matriz_colaborador) {
  dfCargas <- dfCargas %>% 
    mutate(VALID_CARGAS = if_else(
      !between(HORAS_TRABALHADAS, CARGA_MIN, CARGA_MAX) & (DAY_TYPE %in% c('M', 'T') & TIPO_TURNO != 'F'),
      "NO",
      "YES"
    ))
  return(dfCargas)
}

compareZeros <- function(dfHP, df1) {
  # Store the days that have colabs before the store opens
  invalidPreDays <- unique(df1 %>% filter(TIPO_ERRO == 'Alocado antes da faixa') %>% select(DATE))[,1]
  dfHP <- dfHP %>%
    mutate(VALID_ANTES_FAIXA = case_when(
      DATE %in% unlist(invalidPreDays) ~ "NO",
      TRUE ~ "YES"
    ))
  
  # Store the days that have no colabs during the store open hours
  invalidDuringDays <- unique(df1 %>% filter(TIPO_ERRO == 'Zeros dentro da faixa') %>% select(DATE))[,1]
  dfHP <- dfHP %>%
    mutate(VALID_DUR_FAIXA = case_when(
      DATE %in% unlist(invalidDuringDays) ~ "NO",
      TRUE ~ "YES"
    ))

  # Store the days that have colabs after the store closes
  invalidAfterDays <- unique(df1 %>% filter(TIPO_ERRO == 'Alocado depois da faixa') %>% select(DATE))[,1]
  dfHP <- dfHP %>%
    mutate(VALID_DEPOIS_FAIXA = case_when(
      DATE %in% unlist(invalidAfterDays) ~ "NO",
      TRUE ~ "YES"
    ))
  
  # Check if all the values are valid
  dfHP <- dfHP %>% 
    mutate(VALID_FAIXA = if_else(
      (VALID_ANTES_FAIXA == 'YES' & VALID_DUR_FAIXA == 'YES' & VALID_DEPOIS_FAIXA == 'YES'),
      'YES',
      'NO'
    ))
  return(dfHP)
}

annualRules <- function(df1, M_colab, M_calendario, colabList) {
  # Dataframe creation for annual rules
  df <- data.frame(
    EMP = character(),
    DIAS_TRABALHADOS_REAL = numeric(),
    DIAS_TRABALHADOS_CALENDARIO = numeric(),
    DIAS_TRABALHADOS_CONTRATO = numeric(),
    CARGA_ANUAL_REAL = numeric(),
    CARGA_ANUAL_CONTRATO = numeric(),
    CARGA_ANUAL_MIN = numeric(),
    CARGA_ANUAL_MAX = numeric(),
    CARGA_MEDIA_DIARIA_REAL = numeric(),
    CARGA_MEDIA_DIARIA_CONTRATO = numeric(),
    stringsAsFactors = FALSE
  )
  
  # Declare the dfList
  dfList <- list()
  
  for (colab in colabList) {
    T_real <- count(df1 %>% filter(EMP == colab, HORAS_TRABALHADAS > 0) %>% select(HORAS_TRABALHADAS))[1, 1] # dias de trabalho reais
    T_calendario <- rowSums(matriz_calendario %>% filter(MATRICULA == colab) == 'M' | matriz_calendario %>% filter(MATRICULA == colab) == 'T') # dias de trabalho no calendario
    T_contrato <- M_colab[M_colab$EMP == colab, "T_TOTAL"] # dias de trabalho previstos no contrato
    CA_real <- sum(df1 %>% filter(EMP == colab) %>% select(HORAS_TRABALHADAS)) # carga anual real
    CA_contrato <- M_colab[M_colab$EMP == colab, "HORAS_TRAB_ANO"] # carga anual prevista no contrato
    CA_max <- M_colab[M_colab$EMP == colab, "MAX_ANUAL"] # carga anual maxima prevista no contrato
    CA_min <- M_colab[M_colab$EMP == colab, "MIN_ANUAL"] # carga anual minima prevista no contrato
    CM_real <- CA_real/T_real # carga média diária durante o ano
    CM_contrato <- M_colab[M_colab$EMP == colab, "HORAS_MEDIAS_P_DIA"]
      
    new_row <- data.frame(
      EMP = as.character(colab),
      DIAS_TRABALHADOS_REAL = T_real,
      DIAS_TRABALHADOS_CALENDARIO = T_calendario,
      DIAS_TRABALHADOS_CONTRATO = T_contrato,
      CARGA_ANUAL_REAL = CA_real,
      CARGA_ANUAL_CONTRATO = CA_contrato,
      CARGA_ANUAL_MIN = CA_min,
      CARGA_ANUAL_MAX = CA_max,
      CARGA_MEDIA_DIARIA_REAL = CM_real,
      CARGA_MEDIA_DIARIA_CONTRATO = CM_contrato,
      stringsAsFactors = FALSE
    )
    new_row$EMP <- as.character(colab)
    dfList[[length(dfList) + 1]] <- new_row
  }
  # Merge all dataframes
  df1 <- do.call(rbind, dfList)
  return(df1)
}

compareCargasSemana <- function(dfHorasT, M_colab) {
  dfHorasT <- dfHorasT %>% 
    mutate(WEEK_NUMBER = isoweek(as.Date(DATE, format = "%d-%m-%Y"))) %>% 
    mutate(WEEK_NUMBER_FIXED = ifelse(WEEK_NUMBER < lag(WEEK_NUMBER, default = first(WEEK_NUMBER)),
                                      WEEK_NUMBER + max(WEEK_NUMBER, na.rm = TRUE),
                                      if_else(row_number() == n(), WEEK_NUMBER + max(WEEK_NUMBER, na.rm = TRUE), WEEK_NUMBER)))
  
  dfHorasT <- dfHorasT %>% select(-c(WEEK_NUMBER))
  df_sum <- dfHorasT %>%
    group_by(EMP, WEEK_NUMBER_FIXED) %>%
    summarize(TOTAL_HORAS_TRABALHADAS = sum(HORAS_TRABALHADAS, na.rm = TRUE))
  
  cargaSemanal <- M_colab %>% 
    select(EMP, HORAS_TRAB_SEMANA_MAX)
  
  df_sum <- df_sum %>%
    left_join(cargaSemanal, by = "EMP") %>% 
    mutate(VALID_CARGAS_SEMANA = ifelse(TOTAL_HORAS_TRABALHADAS < HORAS_TRAB_SEMANA_MAX, 'YES', 'NO'))
  
  return(df_sum)
}

compareCargasMes <- function(dfHorasT, M_colab) {
  dfHorasT <- dfHorasT %>% 
    mutate(MONTH_NUMBER = as.numeric(format(as.Date(DATE, format = "%d-%m-%Y"), '%m'))) %>% 
    mutate(MONTH_NUMBER_FIXED = ifelse(MONTH_NUMBER < lag(MONTH_NUMBER, default = first(MONTH_NUMBER)),
                                       MONTH_NUMBER + max(MONTH_NUMBER, na.rm = TRUE),
                                      if_else(row_number() == n(), MONTH_NUMBER + max(MONTH_NUMBER, na.rm = TRUE), MONTH_NUMBER))) %>% 
    select(-MONTH_NUMBER)
  
  df_sum <- dfHorasT %>%
    group_by(EMP, MONTH_NUMBER_FIXED) %>%
    summarize(TOTAL_HORAS_TRABALHADAS = sum(HORAS_TRABALHADAS, na.rm = TRUE))
  
  cargaMensal <- M_colab %>% 
    select(EMP, HORAS_TRAB_MENSAL_MIN)
  names(cargaMensal)[names(cargaMensal) == 'HORAS_TRAB_MENSAL_MIN'] <- 'CARGA_MENSAL_CONTRATO'
  
  df_sum <- df_sum %>%
    left_join(cargaMensal, by = "EMP") %>% 
    mutate(CARGA_MENSAL_MIN = CARGA_MENSAL_CONTRATO*0.99) %>% 
    mutate(CARGA_MENSAL_MAX = CARGA_MENSAL_CONTRATO*1.01) %>% 
    mutate(VALID_CARGAS_MES = ifelse(between(TOTAL_HORAS_TRABALHADAS, CARGA_MENSAL_MIN, CARGA_MENSAL_MAX), 'YES', 'NO'))
  
  return(df_sum)
  
}

auditor_interjornadas_V2 <- function(M_WFM, matriz_festivos) {
  wdList <- list(
    Monday = 'SEG',
    Tuesday = 'TER',
    Wednesday = 'QUA',
    Thursday = 'QUI',
    Friday = 'SEX',
    Saturday = 'SAB',
    Sunday = 'DOM',
    Festivo = 'FER',
    0
  )
  
  interjornadas <- list(
    Monday = 12,
    Tuesday = 12,
    Wednesday = 12,
    Thursday = 12,
    Friday = 12,
    Saturday = 12,
    Sunday = 9,
    Festivo = 9,
    0
  )
  
  bigData <- M_WFM %>% 
    mutate(ST_1 = as.POSIXct(paste0(SCHEDULE_DT, ' ', Start_Time_1), format = '%Y-%m-%d %H:%M')) %>% 
    mutate(ET_1 = as.POSIXct(paste0(SCHEDULE_DT, ' ', End_Time_1), format = '%Y-%m-%d %H:%M')) %>% 
    mutate(ST_2 = as.POSIXct(paste0(SCHEDULE_DT, ' ', Start_Time_2), format = '%Y-%m-%d %H:%M')) %>% 
    mutate(ET_2 = as.POSIXct(paste0(SCHEDULE_DT, ' ', End_Time_2), format = '%Y-%m-%d %H:%M')) %>% 
    mutate(ST = ST_1) %>% 
    mutate(ET = if_else(is.na(ET_2), ET_1, ET_2)) %>% 
    select(-c(Start_Time_1, Start_Time_2, End_Time_1, End_Time_2, ST_1, ST_2, ET_1, ET_2)) %>% 
    arrange(EMPLOYEE_ID, SCHEDULE_DT) %>% 
    mutate(TIME_DIFF_ANTES = if_else(
      (SCHED_TYPE != 'T' & lag(SCHED_TYPE) != 'T'), 
      NA_real_, 
      as.numeric(difftime(ST, lag(ET, n=1L), units = 'hours')))) %>% 
    # mutate(TIME_DIFF_DEPOIS = if_else((SCHED_TYPE != 'T' & lead(SCHED_TYPE) != 'T'), NA, as.numeric(difftime(lead(ST, n=1L), ET, units = 'hours')))) %>% 
    mutate(FESTIVO = if_else(SCHEDULE_DT %in% matriz_festivos, 'yes', 'no')) %>% 
    mutate(WD = if_else(
      FESTIVO == 'yes', 
      'Festivo', 
      weekdays(as.POSIXct(SCHEDULE_DT, format = '%Y-%m-%d',tz='GMT')- days(1)))) %>% 
    mutate(IJ_MIN_ANTES = interjornadas[WD]) %>% 
    # mutate(IJ_MIN_DEPOIS = interjornadas[lead(WD)]) %>% 
    mutate(VALID_IJ = if_else(
      is.na(TIME_DIFF_ANTES) | (!is.na(TIME_DIFF_ANTES) & (TIME_DIFF_ANTES >= IJ_MIN_ANTES)),
      'yes',
      'no')) %>% 
    filter(VALID_IJ == 'no') %>% 
    select(EMPLOYEE_ID, SCHEDULE_DT) %>% 
    mutate(TIPO_ERRO = 'Interjornada')
  
  colnames(bigData) <- c('EMP', 'DATE', 'TIPO_ERRO')
  return(bigData)
}


# auditor_interjornadas <- function(M_WFM, matriz_festivos, cidade = info$UNI, regra = "Interjornada"){
#   wdList <- list(
#     Monday = 'SEG',
#     Tuesday = 'TER',
#     Wednesday = 'QUA',
#     Thursday = 'QUI',
#     Friday = 'SEX',
#     Saturday = 'SAB',
#     Sunday = 'DOM',
#     Festivo = 'FER',
#     0
#   )
#   
#   interjornadas <- list(
#     Monday = 12,
#     Tuesday = 12,
#     Wednesday = 12,
#     Thursday = 12,
#     Friday = 12,
#     Saturday = 12,
#     Sunday = 9,
#     Festivo = 9, #????????????????????????????????
#     0
#   )
#   
#   current_emps <- unique(M_WFM$EMPLOYEE_ID)
#   # 
#   # 
#   # 
#   # matriz_festivos_temp <- matriz_festivos
#   # 
#   # matriz_festivos_temp <- data.frame(lapply(matriz_festivos_temp, function(x) parse_date_time(x, orders = c("d/m/y", "d-m-y"))))
#   # 
#   # # tornar esta selecao dinamica --------------------------------------------
#   # 
#   # 
#   # festivos <- as.POSIXct(matriz_festivos, format = "%d/%m/%Y")
#   # festivos <- format(festivos, "%Y-%m-%d")
#   
#   festivos <- matriz_festivos
#   
#   df_erros <- data.frame(EMP = character(), DATE = character(), TIPO_ERRO = character() )
#   
#   for (emp in current_emps) {
#     M_WFM_temp <- M_WFM %>%
#       dplyr::filter(M_WFM$EMPLOYEE_ID %in% emp)
#     
#     
#     
#     
#     # falta blindar para escolher a 1ª hora de entrada e a ultima hora --------
#     # de saida, neste momento está Hardcoded
#     
#     M_WFM_temp$dateTime_ST1 <- as.POSIXct(paste(M_WFM_temp$SCHEDULE_DT, M_WFM_temp$Start_Time_1), format = "%Y-%m-%d %H:%M")
#     M_WFM_temp$dateTime_ET1 <- as.POSIXct(paste(M_WFM_temp$SCHEDULE_DT, M_WFM_temp$End_Time_1), format = "%Y-%m-%d %H:%M")
#     M_WFM_temp$dateTime_ST2 <- as.POSIXct(paste(M_WFM_temp$SCHEDULE_DT, M_WFM_temp$Start_Time_2), format = "%Y-%m-%d %H:%M")
#     M_WFM_temp$dateTime_ET2 <- as.POSIXct(paste(M_WFM_temp$SCHEDULE_DT, M_WFM_temp$End_Time_2), format = "%Y-%m-%d %H:%M")
#     
#     
#     
#     M_WFM_temp <- M_WFM_temp %>%
#       
#       mutate(descanso_interjonada = pmin(dateTime_ST1, dateTime_ET1, dateTime_ST2, dateTime_ET2, na.rm = TRUE) - lag(pmax(dateTime_ST1, dateTime_ET1, dateTime_ST2, dateTime_ET2, na.rm = TRUE))) %>% 
#       mutate(SCHEDULE_DT = as.POSIXct(SCHEDULE_DT, format = "%Y-%m-%d")) %>% 
#       mutate(interjornada_legal = interjornadas [weekdays(SCHEDULE_DT)]) %>% 
#       mutate(interjornada_legal = ifelse(as.character(M_WFM_temp$SCHEDULE_DT) %in% as.character(festivos), 9, interjornada_legal)) %>% 
#       mutate(interjornada_legal = lag(interjornada_legal)) %>% 
#       mutate(descanso_interjonada = as.double(descanso_interjonada)) %>% 
#       mutate(interjornada_legal = ifelse(row_number() == 1, 9, interjornada_legal)) %>% 
#       mutate(interjornada_legal = unlist(interjornada_legal)) %>% 
#       mutate(interjornada_legal = as.double(interjornada_legal))
#     
#     
#     teste <- all(M_WFM_temp$descanso_interjonada >= M_WFM_temp$interjornada_legal, na.rm=TRUE)
#     if (teste) {
#       print(paste("Os horarios do colab", emp, "cumprem a lei das interJornadas"))
#       
#     }else{
#       false_rows <- M_WFM_temp %>%
#         filter((descanso_interjonada < interjornada_legal) &  (!is.na(descanso_interjonada) & !is.na(interjornada_legal)))
#       
#       print(paste("Os horarios do colab ", emp, "não cumprem interJornadas nestas datas:"))
#       print(false_rows$SCHEDULE_DT)
#       
#       df_erros <- rbind(df_erros, data.frame(EMP = emp, DATE = false_rows$SCHEDULE_DT, TIPO_ERRO = regra ))
#       
#     }
#     
#     
#     
#     
#     
#     
#     
#   }
#   
#   
#   if (nrow(df_erros) == 0) {
#     cumpre = TRUE
#   } else {
#     cumpre = FALSE
#   }
#   print(cumpre)
#   
#   
#   return(df_erros)
# }
# dfHPZ <- dfHorasPausasZeros
invalidOccurrences <- function(df3, dfHPZ, M_colab, colabList) {
  # if (nrow(df3) > 0) {
  #   df3$DATE <- format(df3$DATE, '%d-%m-%Y')
  # }
  
  invalidCargas <- dfHPZ %>% filter(VALID_CARGAS == 'NO')
  if (nrow(invalidCargas) > 0) {
    cargasDF <- invalidCargas %>% select(EMP, DATE)
    cargasDF$TIPO_ERRO <- 'Carga invalida'
    df3 <- rbind(df3, cargasDF)
  }
  
  invalidAntesDepois <- dfHPZ %>% filter(VALID_ANTES_DEPOIS == 'NO')
  if (nrow(invalidAntesDepois) > 0) {
    antesdepoisDF <- invalidAntesDepois %>% select(EMP, DATE)
    antesdepoisDF$TIPO_ERRO <- 'Pausa nao respeita regras de antes e depois'
    df3 <- rbind(df3, antesdepoisDF)
  }
  
  invalidDuracao <- dfHPZ %>% filter(VALID_DURACAO == 'NO')
  if (nrow(invalidDuracao) > 0) {
    duracaoDF <- invalidDuracao %>% select(EMP, DATE)
    duracaoDF$TIPO_ERRO <- 'Pausa nao respeita regras de duracao'
    df3 <- rbind(df3, duracaoDF)
  }
  
  invalidLimite <- dfHPZ %>% filter(VALID_LIMITE_DESCANSO == 'NO')
  if (nrow(invalidLimite) > 0) {
    limiteDF <- invalidLimite %>% select(EMP, DATE)
    limiteDF$TIPO_ERRO <- 'Pausa nao respeita regra de limite de tempo para ter descanso'
    df3 <- rbind(df3, limiteDF)
  }
  
  invalidAntesFaixa <- dfHPZ %>% filter(VALID_ANTES_FAIXA == 'NO')
  if (nrow(invalidAntesFaixa) > 0) {
    antesFDF <<- invalidAntesFaixa %>% select(EMP, DATE)
    antesFDF$TIPO_ERRO <- 'Existe colaboradores alocados antes da faixa da sec'
    df3 <- rbind(df3, antesFDF)
  }
  
  invalidDurFaixa <- dfHPZ %>% filter(VALID_DUR_FAIXA == 'NO')
  if (nrow(invalidDurFaixa) > 0) {
    durFDF <<- invalidDurFaixa %>% 
      select(DATE) %>%
      unique() %>% 
      mutate(EMP = '-') %>% 
      mutate(TIPO_ERRO = 'Existem zeros dentro da faixa da sec')
    # durFDF$TIPO_ERRO <- 'Existem zeros dentro da faixa da sec'
    df3 <- rbind(df3, durFDF)
  }
  
  invalidDepoisFaixa <- dfHPZ %>% filter(VALID_DEPOIS_FAIXA == 'NO')
  if (nrow(invalidDepoisFaixa) > 0) {
    depoisFDF <- invalidDepoisFaixa %>% select(EMP, DATE)
    depoisFDF$TIPO_ERRO <- 'Existe colaboradores alocados depois da faixa da sec'
    df3 <- rbind(df3, depoisFDF)
  }
  
  ## Add colab information to a new column - easier to analyse if the error is in the data or the algorithms
  colabTotalList <- unique(c(colabList, colabsCiclosPre))
  colabType <- data.frame(
    EMP = unlist(colabTotalList),
    TIPO_DE_TURNO = character(length(colabTotalList))
  )
  colabType <- colabType %>%
    merge(M_colab %>% select(EMP, TIPO_DE_TURNO), by.x = "EMP", by.y = "EMP", all.x = TRUE) %>% 
    dplyr::select(-TIPO_DE_TURNO.x) %>% 
    dplyr::rename(TIPO_DE_TURNO = TIPO_DE_TURNO.y) %>% 
    dplyr::mutate(TIPO_DE_TURNO = if_else(EMP %in% colabsCiclosPre, 'Pregerados/Ciclos', TIPO_DE_TURNO))
  
  # savedf3 <<- df3 <- savedf3
  
  df3 <- df3 %>% 
    merge(colabType, by.x = "EMP", by.y = "EMP", all.x = TRUE)
  
  return(df3)
}


### QA -------------------------------------------------------------------------
# # source("C:/Users/antonio.alves/Documents/developments/[ALCAMPO]/algoritmos/validador.R")
# dataframingz <- validatorSuperMega(matriz_colaborador, matriz_calendario, M_dia4_final, matriz_festivos, M_WFM, dateSeq, posto, info$UNI, matriz_calendario$MATRICULA)
# 
# M_colab <- matriz_colaborador
# M_calendario <- matriz_calendario
# dateList <- dateSeq
# colabList <- matriz_calendario$MATRICULA
# M_dia_final <- M_dia4_final
# 
# 
# saveOutputValidador <- function(data, postoID, UniNAME) {
#   # Create file name
#   timeIndex <- format(as.POSIXct(Sys.time(), "%d-%m-%Y %H:%M:%OS", tz = 'UTC'), "%d-%m-%Y_%Hh%Mm%OSs")
#   fileName <- paste0(pathFicheirosGlobal, 'output/validador_output_', UniNAME,'_', postoID, '_', timeIndex, '.xlsx')
#   
#   # Create workbook
#   wb <- createWorkbook()
#   
#   # Create the veral sheets
#   addWorksheet(wb, 'Regras nao cumpridas')
#   addWorksheet(wb, 'Diario')
#   addWorksheet(wb, 'Semanal')
#   addWorksheet(wb, 'Anual')
#   
#   # Write data in the several sheets
#   writeData(wb, 'Regras nao cumpridas', data[[1]], startCol = 1, startRow = 1)
#   writeData(wb, 'Diario', data[[2]], startCol = 1, startRow = 1)
#   writeData(wb, 'Semanal', data[[4]], startCol = 1, startRow = 1)
#   writeData(wb, 'Anual', data[[3]], startCol = 1, startRow = 1)
#   
#   # Save excel file
#   saveWorkbook(wb, fileName)
# }
# generateVALIDADOR <- TRUE
# if (generateVALIDADOR == T) {
#   saveOutputValidador(dataframingz, info$FK_TIPO_POSTO, info$SEC)
# }
