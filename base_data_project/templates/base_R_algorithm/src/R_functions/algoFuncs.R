getOpening <- function(select_day){
  # mmi <- matriz_min_ideal %>% dplyr::filter(DATA == select_day, MINIMO > 0 | IDEAL > 0)
  # if (nrow(mmi)>0) {
  #   return(as.POSIXct(min(mmi$HORA_INI)))
  # } else{
  return(as.POSIXct(min(matriz_min_ideal %>% dplyr::filter(DATA == select_day) %>% .$HORA_INI),tz='GMT'))
  # }
}

getClosing <- function(select_day){
  # mmi <- matriz_min_ideal %>% dplyr::filter(DATA == select_day, MINIMO > 0 | IDEAL > 0)
  # if (nrow(mmi)>0) {
  #   return(as.POSIXct(max(mmi$HORA_INI)))
  # } else{
  return(as.POSIXct(max(matriz_min_ideal %>% dplyr::filter(DATA == select_day) %>% .$HORA_INI),tz='GMT'))
  # }
}

getClosingIdeais <- function(select_day){
  return(as.POSIXct(tail(matriz_min_ideal  %>% dplyr::filter(DATA == select_day & MINIMO > 0) %>%  arrange(HORA_INI), 1)$HORA_INI,tz='GMT'))
}
getOpeningIdeias <- function(select_day){
  return(as.POSIXct(head(matriz_min_ideal  %>% dplyr::filter(DATA == select_day & MINIMO > 0) %>%  arrange(HORA_INI), 1)$HORA_INI,tz='GMT'))
}


getIntervalCobrirEntreMinimoIdealNew <- function(df, max0desprezados = 2) {
  ##print("Getting values of ideais")
  df <- tryCatch({
    df[min(which(df$Ideal>0)):max(which(df$Ideal>0)),]
  }, error = function(e){
    return(NULL)
  })
  saveDF <<- df #<- saveDF
  
  zero_intervals <- which(df$Minimo_Por_cobrir > 0  & df$Alocado == 0)
  if (length(zero_intervals) == 0) {
    if (any(df$Minimo_Por_cobrir>0)==T) {
      df <- df[min(which(df$Minimo_Por_cobrir>0)):max(which(df$Minimo_Por_cobrir>0)),]  
    }
    minimo_indices <- which(df$Minimo_Por_cobrir  > 0)
    if (length(minimo_indices) == 0) {
      if (any(df$Ideal_por_Cobrir>0)==T) {
        df <- df[min(which(df$Ideal_por_Cobrir>0)):max(which(df$Ideal_por_Cobrir>0)),]  
      }
      ideal_indices <- which(df$Ideal_por_Cobrir > 0)
      if (length(ideal_indices) == 0) {
        return(NULL)
      }
    }else{
      ideal_indices <- minimo_indices
    }
  }else{
    ideal_indices <- zero_intervals
  }
  
  
  # Find indices of fractions with ideal greater than 0
  #ideal_indices <- which(df$Ideal_por_Cobrir > 0)
  
  
  # Find the first and last indices with ideal greater than 0
  h_in <- ideal_indices[1]
  h_fim <- ideal_indices[length(ideal_indices)]
  # Check if there are intervals with ideal equal to 0 between h_in and h_fim
  
  # Subset the data between h_in and h_fim
  subset_data <- df$timestamps > df$timestamps[h_in] & df$timestamps < df$timestamps[h_fim]
  subset_ideal <- df$Ideal_por_Cobrir[subset_data]
  zero_sequence <<- rle(subset_ideal <= 0)
  first_sequence_indices <<- which(zero_sequence$lengths > max0desprezados & zero_sequence$values == TRUE)[1]
  
  ##print(zzz)
  ##print(first_sequence_indices)
  if(!is.na(first_sequence_indices)){
    if (first_sequence_indices > 1) {
      actual_indices <- which(subset_data)[c(sum(zero_sequence$lengths[1:(first_sequence_indices - 1)]) + 1):(sum(zero_sequence$lengths[1:first_sequence_indices]))]
    } else {
      actual_indices <- which(subset_data)[1:zero_sequence$lengths[first_sequence_indices]]
    }
    testAI <<- actual_indices
    ##print("BOSSA DETETADA AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
    # Exclude indices with ideal equal to 0 and a duration greater than YYYY minutes
    # h_in <- max(h_in, min(which(oscillations_to_ignore)))
    # h_fim <- min(h_fim, max(which(oscillations_to_ignore)))
    left_size <- (actual_indices[1] - 1)
    left_side <- df[1:left_size, ]
    right_size <- nrow(df) - (nrow(left_side)+length(actual_indices))
    
    right_side <- df[left_size+length(actual_indices)+1:right_size, ]
    # Extract start time, end time, and duration of the interval
    # Find the first and last indices with ideal greater than 0
    # ideal_indices <- which(left_side$Ideal_por_Cobrir > 0)
    
    h_inL <- left_side$timestamps[1]
    h_fimL <- left_side$timestamps[nrow(left_side)]
    durationL <- difftime(h_fimL, h_inL, units = "hours")+0.25
    indicesL <- which(df$timestamps %in% left_side$timestamps)
    avgIdealL <- sum(df[indicesL,]$Ideal_por_Cobrir) / length(indicesL)
    # start_timeL <- df$timestamps[h_in]
    # end_timeL <- df$timestamps[h_fim]
    # durationL <- end_timeL - start_timeL
    
    # ideal_indices <- which(right_side$Ideal_por_Cobrir > 0)
    
    h_inR <- right_side$timestamps[1]
    h_fimR <- right_side$timestamps[nrow(right_side)]
    durationR <- difftime(h_fimR, h_inR, units = "hours")+0.25
    indicesR <- which(df$timestamps %in% right_side$timestamps)
    avgIdealR <- sum(df[indicesR,]$Ideal_por_Cobrir) / length(indicesR)
    # start_timeR <- df$timestamps[h_in]
    # end_timeR <- df$timestamps[h_fim]
    # durationR <- end_timeR - start_timeR
    interval_info <- list(
      start_time = h_inL,
      end_time = h_fimL,
      duration = durationL,
      avgIdealL = avgIdealL,
      start_time2 = h_inR,
      end_time2 = h_fimR,
      duration2 = durationR,
      avgIdealR = avgIdealR
    )
    #   
  }else{
    # Extract start time, end time, and duration of the interval
    start_time <- df$timestamps[h_in]
    end_time <- df$timestamps[h_fim]
    duration <- difftime(end_time, start_time, units = "hours")+0.25
    interval_info <- list(
      start_time = start_time,
      end_time = end_time,
      duration = duration
    )
  }
  ##print(interval_info)
  return(interval_info)
  # interval <- df$timestamps >= start_time & df$timestamps <= end_time
  # ##print(interval)
  # return(df$timestamps[interval])
}


# timestamp <- intervalData
# EMPloyee_data <- dfEMPloyee
# colaData <- ColabData
selectColab <- function(timestamp,EMPloyee_data,colaData,dfTest){
  testTEMP <<- timestamp  #<- testTEMP
  testEMP <<- EMPloyee_data #<- testEMP
  colabasritas <<- colaData #<- colabasritas
  
  #print(class)
  EMPloyee_data <- left_join(EMPloyee_data, colaData, by = 'EMP')
  timestamp$start_time <- as.POSIXct(timestamp$start_time , format = '%Y-%m-%d %H:%M:%S', tz='GMT')
  timestamp$end_time  <- as.POSIXct(timestamp$end_time , format = '%Y-%m-%d %H:%M:%S', tz='GMT')
  EMPloyee_data$hora_in <- as.POSIXct(EMPloyee_data$hora_in , format = '%Y-%m-%d %H:%M', tz='GMT')
  EMPloyee_data$hora_out  <- as.POSIXct(EMPloyee_data$hora_out , format = '%Y-%m-%d  %H:%M', tz='GMT')
  
  eligible_colabs <- EMPloyee_data[
    (
      # Abertura condition
      (
        EMPloyee_data$hora_in <= timestamp$start_time |
          (
            EMPloyee_data$class_in == 'R' &
              (EMPloyee_data$hora_in ) <= ((timestamp$start_time)+ as.difftime(1, units = "hours"))
          )
      ) |
        # Fecho condition
        (
          EMPloyee_data$hora_out >= timestamp$end_time |
            (
              EMPloyee_data$class_in == 'R' &
                (EMPloyee_data$hora_out ) >= ((timestamp$end_time)- as.difftime(1, units = "hours"))
            )
        )
    )
    &
      (
        # Additional condition for both Abertura and Fecho
        (
          (as.numeric(difftime(timestamp$end_time, EMPloyee_data$hora_in, units = 'hours')) >= EMPloyee_data$HORAS_TRAB_DIA_CARGA_MIN)
        )
      )
    & EMPloyee_data$Allocated != TRUE,
  ]
  # eligible_colabs <- EMPloyee_data[
  #   # Abertura condition
  #   (
  #     (
  #       (EMPloyee_data$hora_in >= timestamp$start_time & EMPloyee_data$hora_in <= timestamp$end_time) |
  # 
  #         (EMPloyee_data$hora_out >= timestamp$start_time & EMPloyee_data$hora_in <= timestamp$end_time) |
  # 
  #         (timestamp$start_time >= EMPloyee_data$hora_in & timestamp$start_time <= EMPloyee_data$hora_out) |
  # 
  #         (timestamp$end_time >= EMPloyee_data$hora_in & timestamp$end_time <= EMPloyee_data$hora_out)
  #     ) |
  #       (
  #         EMPloyee_data$class_in == 'R' &
  # 
  #           (EMPloyee_data$hora_in-1*3600 >= timestamp$start_time & EMPloyee_data$hora_in-1*3600 <= timestamp$end_time) |
  # 
  #           (EMPloyee_data$hora_out+1*3600 >= timestamp$start_time & EMPloyee_data$hora_in-1*3600 <= timestamp$end_time) |
  # 
  #           (timestamp$start_time >= EMPloyee_data$hora_in-1*3600 & timestamp$start_time <= EMPloyee_data$hora_out+1*3600) |
  # 
  #           (timestamp$end_time >= EMPloyee_data$hora_in-1*3600 & timestamp$end_time <= EMPloyee_data$hora_out+1*3600)
  # 
  #       )
  #   )
  #   & EMPloyee_data$Allocated != TRUE,
  # ]
  # 
  # eligible_colabs <- eligible_colabs %>%
  #   dplyr::group_by(EMP) %>%
  #   dplyr::mutate(
  #     DIFF = as.numeric(
  #       difftime(
  #         min(as.POSIXct(hora_out, format = '%H:%M'),as.POSIXct(timestamp$end_time, format = '%H:%M')),
  #         max(as.POSIXct(timestamp$start_time, format = '%H:%M'),as.POSIXct(hora_in, format = '%H:%M')),
  #         units = 'hours')
  #     ),
  #     DIFF2 = as.numeric(
  #       difftime(
  #         min(as.POSIXct(hora_out+1*3600, format = '%H:%M'),as.POSIXct(timestamp$end_time, format = '%H:%M')),
  #         max(as.POSIXct(timestamp$start_time, format = '%H:%M'),as.POSIXct(hora_in-1*3600, format = '%H:%M')),
  #         units = 'hours')
  #     )
  #   ) %>% ungroup() %>% data.frame() %>%
  #   dplyr::filter(DIFF>HORAS_TRAB_DIA_CARGA_MIN | DIFF2>HORAS_TRAB_DIA_CARGA_MIN) %>%
  #   dplyr::select(-c(DIFF,DIFF2))
  # 
  
  
  
  if (nrow(eligible_colabs) == 0) {
    #print("No eligible collaborators found.")
    return(NULL)
  } else{
    timestamp$start_time <- format(timestamp$start_time, '%Y-%m-%d %H:%M')
    timestamp$end_time  <- format(timestamp$end_time , '%Y-%m-%d %H:%M')
    EMPloyee_data$hora_in <- format(EMPloyee_data$hora_in , '%Y-%m-%d %H:%M')
    EMPloyee_data$hora_out  <- format(EMPloyee_data$hora_out , '%Y-%m-%d %H:%M')
  }
  #print(opening_timestamps)
  #print(closing_timestamps)
  test <<- eligible_colabs# <- test
  priority_colabs = eligible_colabs[
    (eligible_colabs$hora_in <= as.POSIXct(opening_timestamps)),# | (eligible_colabs$class_in == 'R' & as.POSIXct(eligible_colabs$hora_in, format = '%H:%M')-1*3600 <= as.POSIXct(opening_timestamps)),
  ] %>%  filter(!is.na(EMP))
  start_index <- which(dfTest$timestamps == opening_timestamps)
  end_index <- which(dfTest$timestamps == closing_timestamps)
  
  #print(priority_colabs)
  if (nrow(priority_colabs) > 0 & timestamp$start_time <= as.POSIXct(opening_timestamps) & dfTest[start_index,]$Alocado == 0){
    #print("Giving opening collaborators")
    collabs_in_priority <- collaborator_tibbles[sapply(collaborator_tibbles, function(tibble) any(tibble$EMP %in% priority_colabs$EMP))]
    
    max_ratio_collab <- collabs_in_priority[[which.max(sapply(collabs_in_priority, function(tibble) (tibble$horas_goal)[1] / sum(tibble$dias_para_atribuir)))]]
    
    max_ratio_EMP <- max_ratio_collab$EMP[1]
    max_ratio_info <- priority_colabs[priority_colabs$EMP == max_ratio_EMP, ]
    
    return(max_ratio_info)
  }
  priority_colabs2 = eligible_colabs[
    eligible_colabs$hora_out >= as.POSIXct(closing_timestamps),#| (eligible_colabs$class_out == 'R' & as.POSIXct(eligible_colabs$hora_out, format = '%H:%M')+1*3600 <= as.POSIXct(closing_timestamps)),
    ,
  ] %>% filter(!is.na(EMP))
  #print(priority_colabs2)
  if (nrow(priority_colabs2) > 0 & timestamp$end_time == as.POSIXct(closing_timestamps) & dfTest[end_index,]$Alocado == 0){
    #print("Giving closing collaborators")
    collabs_in_priority <- collaborator_tibbles[sapply(collaborator_tibbles, function(tibble) any(tibble$EMP %in% priority_colabs2$EMP))]
    
    max_ratio_collab <- collabs_in_priority[[which.max(sapply(collabs_in_priority, function(tibble) (tibble$horas_goal)[1] / sum(tibble$dias_para_atribuir)))]]
    
    max_ratio_EMP <- max_ratio_collab$EMP[1]
    max_ratio_info <- priority_colabs2[priority_colabs2$EMP == max_ratio_EMP, ]
    return(max_ratio_info)
  }
  collabs_in_priority <- collaborator_tibbles[sapply(collaborator_tibbles, function(tibble) any(tibble$EMP %in% eligible_colabs$EMP))]
  
  max_ratio_collab <- collabs_in_priority[[which.max(sapply(collabs_in_priority, function(tibble) (tibble$horas_goal)[1] / sum(tibble$dias_para_atribuir)))]]
  
  max_ratio_EMP <- max_ratio_collab$EMP[1]
  max_ratio_info <- eligible_colabs[eligible_colabs$EMP == max_ratio_EMP, ]
  # print(eligible_colabs)
  print(max_ratio_EMP)
  return(max_ratio_info)
}

# colabs <- colabsToUse
# timeperiod <- intervalData
# classu <- class
atribuirHorario <- function(colabs, timeperiod,classu,date_chosen,collaborator_tibbles){
  #print("Atribuindo horario")
  duration <- as.numeric(difftime(timeperiod$end_time, timeperiod$start_time, units = "hours"))
  testColabs <<- colabs
  class <- as.numeric(classu)  # Convert to numeric
  result <- NULL
  while (is.null(result) & class <= 5) {
    result <- getEligibleClass(colabs, duration, as.character(class), date_chosen, collaborator_tibbles)
    if (is.null(result) & class <= 5) {
      class <- class + 1
      # print(class)
    }
    
    if (class == 6) {
      #  print("me no gusta")
      if(is.null(result)) return(NULL)
    }
  }
  # print(result)
  #print("Got class")
  # print(class)
  result <- verifyPossible(result)
  #print("Result verified")
  week <- week(date_chosen)
  month <- month(date_chosen)
  year <- year(date_chosen)
  print(month)
  # print(colabs)
  collaborator_id <- result[[1]]$EMP
  result[[2]] <- abs(result[[2]])
  #print(collaborator_id)
  
  
  # print(collab)
  tibble_index <- which(names(collaborator_tibbles) %in% as.character(collaborator_id))
  week_index <- which(collaborator_tibbles[[tibble_index]]$week == week)
  month_index <- which(collaborator_tibbles[[tibble_index]]$month == month)
  year_index <- which(collaborator_tibbles[[tibble_index]]$year == year)
  
  week_column <- paste0("class", class, "_week")
  month_column <- paste0("class", class, "_month")
  year_column <- paste0("class", class, "_year")
  
  collaborator_tibbles[[tibble_index]][week_index, week_column] <-     collaborator_tibbles[[tibble_index]][week_index, week_column][1] -1
  #print('1')
  collaborator_tibbles[[tibble_index]][month_index, month_column] <-     collaborator_tibbles[[tibble_index]][month_index, month_column][1] -1
  # print('2')
  
  collaborator_tibbles[[tibble_index]][year_index, year_column] <-     collaborator_tibbles[[tibble_index]][year_index, year_column][1]-1
  result[[2]] <- result[[2]] *4
  # print("Returning class")
  return(list(result,collaborator_tibbles))
}

getEligibleClass <- function(colabs,duration,class,date_chosen,collaborator_tibbles){
  week <- week(date_chosen)
  month <- as.numeric(month(date_chosen))
  monthchanged <- ifelse(month < 10, sprintf("%02d", month), as.character(month))
  month <- as.character(month)
  year <- year(date_chosen)
  
  # print(colabs)
  collaborator_id <- colabs$EMP
  #print(collaborator_id)
  colabChosen <- NULL
  carga_faltamax = 0
  day_check <- 0
  falta_check <- 0
  media_check <- 0
  # Locate the corresponding tibble
  for (collab in collaborator_id){
    #print(collab)
    tibble_index <- which(names(collaborator_tibbles) %in% as.character(collab))
    week_index <- which(collaborator_tibbles[[tibble_index]]$week == week)
    month_index <- which(collaborator_tibbles[[tibble_index]]$month == monthchanged)
    if(length(month_index) < 1){
      month_index <- which(collaborator_tibbles[[tibble_index]]$month == month)
    }
    year_index <- which(collaborator_tibbles[[tibble_index]]$year == year)
    week_column <- paste0("class", class, "_week")
    month_column <- paste0("class", class, "_month")
    year_column <- paste0("class", class, "_year")
    
    daysFalta <-collaborator_tibbles[[tibble_index]][year_index, "dias_para_atribuir"][1]
    weekleft <- collaborator_tibbles[[tibble_index]][week_index, week_column][1]
    monthleft <- collaborator_tibbles[[tibble_index]][month_index, month_column][1]
    yearleft <- collaborator_tibbles[[tibble_index]][year_index, year_column][1]
    media_atual <- collaborator_tibbles[[tibble_index]][year_index, 'cargas_media_falta'][1]
    carga_falta <-collaborator_tibbles[[tibble_index]][year_index, "cargas_media_falta"][1]
    horas_goal <- collaborator_tibbles[[tibble_index]][year_index, "horas_goal"][1]
    
    #print(carga_falta)
    
    chosenTibble <<- collaborator_tibbles[[tibble_index]]
    if(weekleft > 0 & yearleft >0 & monthleft >0){
      if(is.null(colabChosen)){
        #print("Default")
        colabChosen <- colabs[colabs$EMP == collab,]
        carga_faltamax <- carga_falta
        day_check <- daysFalta -1
        media_check <- carga_faltamax
      }else if(carga_falta > carga_faltamax){
        #print("Switching")
        carga_faltamax <- carga_falta
        day_check <- daysFalta -1
        media_check <- carga_faltamax
        colabChosen <- colabs[colabs$EMP == collab,]
        
      }
    }
    #print(colabChosen)
  }
  
  if(is.null(colabChosen)) return(NULL)
  carga_max <- colabChosen$HORAS_TRAB_DIA_CARGA_MAX
  carga_max_schedule <- as.numeric(difftime(as.POSIXct(colabChosen$hora_out,format='%Y-%m-%d %H:%M') , as.POSIXct(colabChosen$hora_in ,format='%Y-%m-%d %H:%M'), units = "hours"))+0.25
  collabbi <<- colabChosen
  if(carga_max_schedule < colabChosen$HORAS_TRAB_DIA_CARGA_MAX){
    carga_max <- carga_max_schedule
  }
  if(class == '1'){
    carga <- carga_max
  }else if(class == '2'){
    carga <- ((carga_max+((carga_max+colabChosen$HORAS_TRAB_DIA_CARGA_MIN)/2))/2) 
  }else if(class == '3'){
    carga <- carga_faltamax
  }else if(class == '4'){
    carga <- ((((carga_max+colabChosen$HORAS_TRAB_DIA_CARGA_MIN)/2)+colabChosen$HORAS_TRAB_DIA_CARGA_MIN)/2) 
  }else{
    carga <- colabChosen$HORAS_TRAB_DIA_CARGA_MIN
  }
  carga_check <- horas_goal - carga ### horas_Goal 1770 carga 9  ---> carga_check 1761
  return(list(colabChosen,carga,carga_check,day_check,carga_faltamax))
}

verifyPossible <- function(result){
  testVerify <<- result #<- testVerify
  if(!is.null(result)){
    media_nova <- result[[3]]/result[[4]]
    if(media_nova < result[[1]]$HORAS_TRAB_DIA_CARGA_MIN || is.nan(media_nova)){
      if(result[[5]] < result[[1]]$HORAS_TRAB_DIA_CARGA_MIN){
        result[[2]] <- result[[1]]$HORAS_TRAB_DIA_CARGA_MIN
      }else result[[2]] <- min(result[[5]],result[[1]]$HORAS_TRAB_DIA_CARGA_MAX)
    } else{
      result[[2]] <- min(result[[5]],result[[1]]$HORAS_TRAB_DIA_CARGA_MAX)
    }
  }else{
    media_nova <- result[[3]]/result[[4]]
    if(media_nova > result[[1]]$HORAS_TRAB_DIA_CARGA_MAX || is.nan(media_nova)){
      if(result[[5]] > result[[1]]$HORAS_TRAB_DIA_CARGA_MAX){
        result[[2]] <- result[[1]]$HORAS_TRAB_DIA_CARGA_MAX
      }else result[[2]] <- result[[5]]
    }
  }
  return(result)
}
find_closest_mod_0.25 <- function(value) {
  remainder <- value %% 0.25
  if (remainder == 0) {
    return(value)  # No adjustment needed, already a multiple of 0.25
  } else {
    # Adjust to the closest number where mod by 0.25 equals 0
    closest_below <- value - remainder
    closest_above <- value + (0.25 - remainder)
    
    # Choose the closest one
    if (abs(value - closest_below) < abs(value - closest_above)) {
      return(closest_below)
    } else {
      return(closest_above)
    }
  }
}

# EMPloyee_data <- collabi
# colabData <- ColabData
attribuirHorarioBK <- function(EMPloyee_data,colabData,daily_dataframe,collaborator_tibbles){
  EMPloyee_data2 <- left_join(EMPloyee_data , colabData, by = 'EMP')
  colabs <- as.data.frame(EMPloyee_data2)
  
  colabs <- colabs %>%  filter(Allocated != TRUE)
  testcolabas <<- colabs
  
  colab <- colabs [1,]
  # Extract collaborator ID from colabData
  collaborator_id <- colab$EMP
  ctt <<- collaborator_tibbles
  # Locate the corresponding tibble
  tibble_index <- which(names(collaborator_tibbles) == as.character(collaborator_id))
  startLimiter <- as.POSIXct(colab$hora_in, format = '%Y-%m-%d %H:%M')#- as.difftime(1, units = "hours")
  endLimiter <- as.POSIXct(colab$hora_out, format = '%Y-%m-%d %H:%M')#+ as.difftime(1, units = "hours")
  time_diff <- as.numeric(difftime(endLimiter, startLimiter, units = "hours"))
  
  # carga <- collaborator_tibbles[[tibble_index]]$carga_media_atual[1]*4+1
  media_atual <- collaborator_tibbles[[tibble_index]]$cargas_media_falta[[1]]
  media_atual <- find_closest_mod_0.25(media_atual)
  if (media_atual < colab$HORAS_TRAB_DIA_CARGA_MIN) {
    carga <- colab$HORAS_TRAB_DIA_CARGA_MIN
  }
  if (media_atual > colab$HORAS_TRAB_DIA_CARGA_MAX) {
    carga <- colab$HORAS_TRAB_DIA_CARGA_MAX
  }
  
  
  carga <- abs(media_atual*4)
  #daily_dataframe$Carga_minima[daily_dataframe$EMP == colab$EMP] <- TRUE
  
  return(list(colab,carga,daily_dataframe))
}
detectCases <- function(EMPloyee_data,duration) {
  cases <- list()
  EMPloas <<- EMPloyee_data 
  min_max_colc_dia <- min(EMPloyee_data$HT_dia_carga_max)
  max_min_colc_dia <- max(EMPloyee_data$HT_dia_carga_min)
  max_max_colc_dia <- max(EMPloyee_data$HT_dia_carga_max)
  min_min_colc_dia <- min(EMPloyee_data$HT_dia_carga_min)
  if(duration <= min_max_colc_dia){
    cases <- append(cases,1)
  }
  
  if(duration > max_max_colc_dia){
    cases <- append(cases,2)
  } 
  if(duration < max_min_colc_dia){
    cases <- append(cases,3)
  }
  if(duration >= max_min_colc_dia){
    cases <- append(cases,4)
  }
  
  return(cases)
}

fitTimeSlots <- function(colabToUse, dfToCheck,dfTest,slotsToGive,collaborator_tibbles,date_chosen,week,month,year,interval_flag){
  
  mudoEndLimit <- F
  mudoStartLimit <- F
  
  max_cumsum <- -Inf
  best_start_index <- 1
  #print(colabToUse)
  tstdfToCheck <<- dfToCheck #<- tstdfToCheck
  testasColabas <<- colabToUse #<- testasColabas
  saveSlots <<- slotsToGive #<- saveSlots
  ddia <<- date_chosen #<- ddia
  
 
  #----------
  
  startLimiter <- as.POSIXct(colabToUse$hora_in, format = '%Y-%m-%d %H:%M')#- as.difftime(1, units = "hours")
  if (colabToUse$tipo_hor  != 'FE' & colabToUse$IJ_in == F) {
    
    ##---
    #validar interjornada
    selectCCday <- colabToUse
    selectCCday$hora_in <- startLimiter - as.difftime(1, units = 'hours')
    selectCCday$hora_out <- as.POSIXct(colabToUse$hora_out, format = '%Y-%m-%d %H:%M')
    selectCCday <- checkInterjornada(selectCCday, date_chosen, interjornadas)
    
    if (selectCCday$IJ_in ==F) {
      canOpen <- ifelse(startLimiter - as.difftime(1, units = 'hours') <= opening_ideias_timestamps, TRUE, FALSE)
    } else{
      colabToUse$IJ_in <- selectCCday$IJ_in
      canOpen <- ifelse(startLimiter <= opening_ideias_timestamps, TRUE, FALSE)
    }
    
  } else{
    canOpen <- ifelse(startLimiter <= opening_ideias_timestamps, TRUE, FALSE)
  }
  
  endLimiter <- as.POSIXct(colabToUse$hora_out, format = '%Y-%m-%d %H:%M')#- as.difftime(15, units = "mins")
  if (closing_timestamps < endLimiter  ) {
    closing_timestamps <- endLimiter
  }
  if (colabToUse$tipo_hor  != 'FE' & colabToUse$IJ_out == F) {
    
    ##---
    #validar interjornada
    selectCCday <- colabToUse
    selectCCday$hora_in <- as.POSIXct(colabToUse$hora_in, format = '%Y-%m-%d %H:%M')
    selectCCday$hora_out <- endLimiter + as.difftime(1, units = 'hours')
    selectCCday <- checkInterjornada(selectCCday, date_chosen, interjornadas)
    
    if (selectCCday$IJ_out ==F) {
      canClose <- ifelse(endLimiter + as.difftime(1, units = 'hours') >= closing_ideias_timestamps, TRUE, FALSE)
    } else{
      colabToUse$IJ_out <- selectCCday$IJ_out
      canClose <- ifelse(endLimiter >= closing_ideias_timestamps, TRUE, FALSE) 
    }
    
  } else{
    canClose <- ifelse(endLimiter >= closing_ideias_timestamps, TRUE, FALSE) 
  }
  
  # time_diff <- (as.numeric(difftime(endLimiter, startLimiter, units = "hours"))+0.25)
  morningLimiter <-  as.POSIXct(paste('2000-01-01',colabToUse$LIMITE_SUPERIOR_MANHA) , format = '%Y-%m-%d %H:%M') - as.difftime(15, units = "mins")
  tardeLimiter <-  as.POSIXct(paste('2000-01-01',colabToUse$LIMITE_INFERIOR_TARDE) , format = '%Y-%m-%d %H:%M') 
  # print(dfToCheck)
  #Adicionar turno a matriz dia
  # print(startLimiter)
  # print(endLimiter)
  # print(head(dfToCheck$timestamps,1))
  # print(startLimiter - as.difftime(1, units = "hours"))
  # print(dfToCheck)
  # print(canOpen)
  
  #---------------------------------------------------------------------------------------------------#
  #                                            See if referencia is needed                            #
  #---------------------------------------------------------------------------------------------------#
  
  #Put this in a seperate function
  if((head(dfToCheck$timestamps,1) >= startLimiter - as.difftime(1, units = "hours")) & head(dfToCheck$timestamps,1) < startLimiter & colabToUse$IJ_in == FALSE & colabToUse$tipo_hor  != 'FE'){
    
    
    diff <- abs(as.numeric(difftime(head(dfToCheck$timestamps,1),startLimiter, units = "hours")))
    if(diff > 1) diff <- 1
    print("Lowering time")
    # if (colabToUse$tipo_hor =='R') {
    #   diff_ini <- abs(as.numeric(difftime(tail(dfToCheck$timestamps,1),endLimiter, units = "hours")))
    #   if(diff_ini > 1) diff_ini <- 1
    # 
    #   idealPorCobrir <-  dfToCheck %>%
    #     dplyr::filter(timestamps >= as.POSIXct(endLimiter, format = '%Y-%m-%d %H:%M'),
    #                   timestamps<= as.POSIXct(endLimiter, format = '%Y-%m-%d %H:%M')+diff_ini*3600) %>%
    #     dplyr::summarise(ipc=sum(Ideal_por_Cobrir)) %>% .$ipc
    # 
    #   if (idealPorCobrir > 0) {
    # 
    #     #calcular nova carga
    #     cargaNew <- abs(as.numeric(difftime(startLimiter - as.difftime(diff, units = "hours"),
    #                                         endLimiter + as.difftime(diff_ini, units = "hours"), units = "hours")))
    # 
    #     #retira tempo de pausa
    #     cargaNew <- cargaNew-0.25
    # 
    #     #validar se pode dar nova carga
    #     #.....
    #     slotsToGive <- cargaNew*4
    # 
    #     startLimiter <-  startLimiter - as.difftime(diff, units = "hours")
    #     endLimiter <- endLimiter + as.difftime(diff_ini, units = "hours")
    #     mudoEndLimit <- T
    #     mudoStartLimit <- T
    # 
    #   } else{
    #     startLimiter <-  startLimiter - as.difftime(diff, units = "hours")
    #     endLimiter <- endLimiter - as.difftime(diff, units = "hours")
    #     mudoEndLimit <- T
    #     mudoStartLimit <- T
    #   }
    # 
    # }
    startLimiter <-  startLimiter - as.difftime(diff, units = "hours")
    endLimiter <- endLimiter - as.difftime(diff, units = "hours")
    mudoEndLimit <- T
    mudoStartLimit <- T
    
    
    
    
    #IF HEAD < PREVIOUS DAY ENTAO PREVIOUS DAY SENAO HEAD
    prev_entrada <- get_interjornada_entrada(date_chosen, interjornadas = interjornadas, colabToUse)
    
    if(!is.null(prev_entrada)){
      startLimiter_new <- as.POSIXct(paste(as.character(if_else(startLimiter >= '2000-01-02',as.Date(date_chosen)+1,as.Date(date_chosen))),
                                           ' ',format(startLimiter, '%H:%M:%S'), sep = ''), tz = 'GMT')
      
      if(startLimiter_new < prev_entrada) {
        startLimiter <- prev_entrada
        startLimiter <- if_else(startLimiter<as.POSIXct(paste(format(startLimiter,'%Y-%m-%d'),format(getOpening(date_chosen),"%H:%M:%S")),tz='GMT'),
                                as.POSIXct(paste('2000-01-02',format(startLimiter,'%H:%M:%S')),tz='GMT'),
                                as.POSIXct(paste('2000-01-01',format(startLimiter,'%H:%M:%S')),tz='GMT'))
        M_dia1_final[[date_chosen]][ M_dia1_final[[date_chosen]]$EMP ==colabToUse$EMP ,]$IJ_in <- TRUE
        M_dia1_final[[date_chosen]][ M_dia1_final[[date_chosen]]$EMP ==colabToUse$EMP ,]$hora_in <- format(startLimiter,'%Y-%m-%d %H:%M')
        
      }
    }
    
    
    #Tendo turno se com referencia for abaixo do limite inferior tarde nao deixar
  }else if(((head(dfToCheck$timestamps,1) <= endLimiter + as.difftime(1, units = "hours")) & tail(dfToCheck$timestamps,1) > endLimiter || startLimiter + as.difftime(1, units = "hours") < opening_timestamps) & colabToUse$IJ_out == FALSE & colabToUse$tipo_hor  != 'FE'){
    
    diff <- abs(as.numeric(difftime(endLimiter,tail(dfToCheck$timestamps,1), units = "hours"))) 
    #abs(tail(dfToCheck$timestamps,1) - endLimiter)
    print("Adding time ")
    if(diff > 1) diff <- 1
    
    if (colabToUse$tipo_hor =='R' & colabToUse$IJ_in == F) {
      
      diff_ini <- abs(as.numeric(difftime(startLimiter,head(dfToCheck$timestamps,1), units = "hours")))
      if(diff_ini > 1) diff_ini <- 1
      
      idealPorCobrir <-  dfToCheck %>% dplyr::filter(timestamps <= as.POSIXct(startLimiter, format = '%Y-%m-%d %H:%M'),
                                                     timestamps>= as.POSIXct(startLimiter, format = '%Y-%m-%d %H:%M')-diff_ini*3600) %>% dplyr::summarise(ipc=sum(Minimo_Por_cobrir)) %>% .$ipc
      
      if (idealPorCobrir > 0) {
        
        #calcular nova carga
        cargaNew <- abs(as.numeric(difftime(startLimiter - as.difftime(diff_ini, units = "hours"),
                                            endLimiter + as.difftime(diff, units = "hours"), units = "hours")))
        
        
        if (cargaNew < colabToUse$HORAS_TRAB_DIA_CARGA_MIN) {
          cargaNew <- colabToUse$HORAS_TRAB_DIA_CARGA_MIN
        }
        
        #retira tempo de pausa
        if (cargaNew > as.numeric(sapply(colabToUse$DESC_CONTINUOS_TEMPO_LIMITE_NAO_DESCANSO, convert_to_hours))) {
          cargaNew <- cargaNew-0.25
        }
        
        
        #validar se pode dar nova carga
        #.....
        
        
        collaborator_tibbles <- update_col_tibble(cargaNew*4, colabToUse,collaborator_tibbles,date_chosen,week,month,year,interval_flag)
        if (unique(collaborator_tibbles[[colabToUse$EMP]]$cargas_media_falta) < colabToUse$HORAS_TRAB_DIA_CARGA_MIN) {
          startLimiter <-  startLimiter + as.difftime(diff, units = "hours")
          endLimiter <- endLimiter + as.difftime(diff, units = "hours")
          mudoEndLimit <- T
          mudoStartLimit <- T
        } else{
          slotsToGive <- cargaNew*4
          startLimiter <-  startLimiter - as.difftime(diff_ini, units = "hours")
          endLimiter <- endLimiter + as.difftime(diff, units = "hours")
          mudoEndLimit <- T
          mudoStartLimit <- T
        }
        
        
        
      } else{
        startLimiter <-  startLimiter + as.difftime(diff, units = "hours")
        endLimiter <- endLimiter + as.difftime(diff, units = "hours")
        mudoEndLimit <- T
        mudoStartLimit <- T
      }
      
    }
    # startLimiter <-  startLimiter + as.difftime(diff, units = "hours")
    # endLimiter <- endLimiter + as.difftime(diff, units = "hours")
    # mudoEndLimit <- T
    # mudoStartLimit <- T
    
    #Tendo turno se com referencia for acima do limite superior manha nao deixar
    # IF END > NEXT DAY ENTAO NEXT DAY SENAO END
    next_leave <- get_interjornada_saida(date_chosen, interjornadas = interjornadas, colabToUse)
    # hora_in_time <- as.POSIXct(colabToUse$hora_out, format = '%Y-%m-%d %H:%M',tz='GMT')
    # temp_time <- as.POSIXct(paste(select_day, format(hora_in_time, "%H:%M:%S")),tz='GMT')
    
    if(!is.null(next_leave)){
      endLimiter_new <- as.POSIXct(paste(as.character(if_else(endLimiter>='2000-01-02',as.Date(date_chosen)+1,as.Date(date_chosen)))
                                         , ' ',format(endLimiter,'%H:%M:%S'), sep = ''), tz = 'GMT')
      
      
      if(endLimiter_new > next_leave ){
        
        endLimiter <- next_leave
        endLimiter <- if_else(endLimiter<as.POSIXct(paste(format(endLimiter,'%Y-%m-%d'),format(getOpening(date_chosen),"%H:%M:%S")),tz='GMT'),
                              as.POSIXct(paste('2000-01-02',format(endLimiter,'%H:%M:%S')),tz='GMT'),
                              as.POSIXct(paste('2000-01-01',format(endLimiter,'%H:%M:%S')),tz='GMT'))
        # print(endLimiter)
        # print(str(endLimiter))
        M_dia1_final[[date_chosen]][ M_dia1_final[[date_chosen]]$EMP ==colabToUse$EMP ,]$IJ_out <- TRUE
        M_dia1_final[[date_chosen]][ M_dia1_final[[date_chosen]]$EMP ==colabToUse$EMP ,]$hora_out <- format(endLimiter,'%Y-%m-%d %H:%M')
        
      } 
      
    }
  }
  # print("passei1")
  # print(str(colabToUse))
  #---------------------------------------------------------------------------------------------------#
  #---------------------------------------------------------------------------------------------------#
  
  if(colabToUse$day_type == 'M'){
    if(endLimiter > morningLimiter){
      endLimiter <- morningLimiter
      mudoEndLimit <- T
    }
  }else if(colabToUse$day_type == 'T'){
    if(startLimiter < tardeLimiter){
      startLimiter <- tardeLimiter
      mudoStartLimit <- T
    }
  }
  if(endLimiter > closing_timestamps){
    endLimiter <- closing_timestamps
    mudoEndLimit <- T
  }
  
  if(startLimiter < opening_timestamps){
    startLimiter <- opening_timestamps
    mudoStartLimit <- T
  }
  
  if (colabToUse$tipo_hor  == 'FE') {
    startLimiter <- as.POSIXct(colabToUse$hora_in, format = '%Y-%m-%d %H:%M')#- as.difftime(1, units = "hours")
    endLimiter <- as.POSIXct(colabToUse$hora_out, format = '%Y-%m-%d %H:%M')
    mudoStartLimit <- T
    mudoEndLimit <- T
    
    if(colabToUse$day_type == 'M'){
      if(endLimiter > morningLimiter){
        endLimiter <- morningLimiter
        # mudoEndLimit <- T
      }
    }else if(colabToUse$day_type == 'T'){
      if(startLimiter < tardeLimiter){
        startLimiter <- tardeLimiter
        # mudoStartLimit <- T
      }
    }
  }
  
  if (mudoEndLimit==T) {
    time_diff <- (as.numeric(difftime(endLimiter, startLimiter, units = "hours")))
    if (colabToUse$tipo_hor  != 'FE' & colabToUse$IJ_in == F) {
      canOpen <- ifelse(startLimiter - as.difftime(1, units = 'hours') <= opening_ideias_timestamps, TRUE, FALSE)
    } else{
      canOpen <- ifelse(startLimiter <= opening_ideias_timestamps, TRUE, FALSE)
    }
    if (colabToUse$tipo_hor  != 'FE' & colabToUse$IJ_out == F) {
      canClose <- ifelse(endLimiter + as.difftime(1, units = 'hours') >= closing_ideias_timestamps, TRUE, FALSE)
    } else{
      canClose <- ifelse(endLimiter >= closing_ideias_timestamps, TRUE, FALSE) 
    }
    # canOpen <- ifelse(startLimiter - as.difftime(1, units = 'hours') <= opening_timestamps, TRUE, FALSE)
    # canClose <- ifelse(endLimiter + as.difftime(1, units = 'hours') >= closing_timestamps, TRUE, FALSE)
  } else{
    time_diff <- (as.numeric(difftime(endLimiter, startLimiter, units = "hours"))+0.25)
  }
  if (mudoStartLimit==T) {
    time_diff <- (as.numeric(difftime(endLimiter, startLimiter, units = "hours"))+0.25)
    # canOpen <- ifelse(startLimiter - as.difftime(1, units = 'hours') <= opening_timestamps, TRUE, FALSE)
    # canClose <- ifelse(endLimiter + as.difftime(1, units = 'hours') >= closing_timestamps, TRUE, FALSE)
    if (colabToUse$tipo_hor  != 'FE' & colabToUse$IJ_in == F) {
      canOpen <- ifelse(startLimiter - as.difftime(1, units = 'hours') <= opening_ideias_timestamps, TRUE, FALSE)
    } else{
      canOpen <- ifelse(startLimiter <= opening_ideias_timestamps, TRUE, FALSE)
    }
    if (colabToUse$tipo_hor  != 'FE' & colabToUse$IJ_out == F) {
      canClose <- ifelse(endLimiter + as.difftime(1, units = 'hours') >= closing_ideias_timestamps, TRUE, FALSE)
    } else{
      canClose <- ifelse(endLimiter >= closing_ideias_timestamps, TRUE, FALSE) 
    }
  } 
  # print(endLimiter)
  # print(startLimiter)
  # print(startLimiter_ini)
  # print(endLimiter_ini)
  cargaMin <- colabToUse$HORAS_TRAB_DIA_CARGA_MIN  
  dfToCheck$Ideal_por_Cobrir <- as.integer(dfToCheck$Ideal_por_Cobrir)
  
  time_difffecho <- as.numeric(difftime(closing_timestamps, startLimiter, units = "hours"))
  
  time_diff <- time_diff*4
  time_difffecho <- time_difffecho*4
  # print(time_diff)
  # print(slotsToGive)
  saveslots1 <<- slotsToGive
  print(time_diff)

  
  saveslots2 <<- slotsToGive
  
  pausasDuration <- as.POSIXct(colabToUse$DESC_CONTINUOS_DURACAO , format = '%H:%M')
  pausasDuration <- arredondaHora(pausasDuration)
  pausasSlots <- hour(pausasDuration) *4 + minute(pausasDuration) / 15
  workTime <- as.POSIXct(colabToUse$DESC_CONTINUOS_TEMPO_LIMITE_NAO_DESCANSO , format = '%H:%M')
  workSlots <- (hour(workTime) *4 + minute(workTime) / 15)
  pausaIncluida <- colabToUse$DESC_CONTINUOS_INC_EXC
  
  if(slotsToGive > workSlots){
    print("Giving pausa")
    print(slotsToGive)
    slotsToGive <- slotsToGive+pausasSlots
  }
  if (time_diff <= slotsToGive) {
    slotsToGive <- max(time_diff)
    print("timediff limited")
  }
  if (time_difffecho <= slotsToGive) {
    print("time diff fecho limited")
    slotsToGive <- max(time_difffecho)
  }
  
  startLimiter <- as.POSIXct(startLimiter, format = '%Y-%m-%d %H:%M')
  endLimiter <- as.POSIXct(endLimiter, format = '%Y-%m-%d %H:%M')
  #Validate morning and afternoon limiters before, this cannot change
  print(startLimiter)
  print(endLimiter)
  
  #print(morningLimiter)
  
  
  savetest <- dfTest #<- savetest
  saveCheck <- dfToCheck #<- saveCheck
  saveStart <- startLimiter #<- saveStart
  saveEnd <- endLimiter #<- saveEnd
  # print("Giving horarios")
  # print(saveEnd)
  # print(canOpen)
  # Sys.sleep(10)
  # print(nrow(dfToCheck))
  given <- FALSE
  
  
  # print(slotsToGive)
  if(canOpen){
    
    start_index <- which(dfTest$timestamps == opening_ideias_timestamps)
    if(dfTest[start_index,]$Alocado == 0){
      print("Giving store opening")
      best_group <- dfTest[start_index:(start_index + slotsToGive -1), ]
      given <- TRUE
      saveOpen <- best_group
    }
    
  }else if(canClose){
    index <- which(dfTest$timestamps == closing_ideias_timestamps)
    if(dfTest[index,]$Alocado == 0){
      print("Giving store closing")
      slotsToGive <- slotsToGive-1
      start_index <- which(dfTest$timestamps == closing_ideias_timestamps) - floor(slotsToGive)
      if (start_index < 0) {
        print("start_index negativo")
        # emp_day <- colabToUse$FK_COLABORADOR
        # set_ProcessErrors(pathOS = pathFicheirosGlobal, user = wfm_user, 
        #                   fk_process = wfm_proc_id, 
        #                   type_error = 'E', process_type = 'schedulerMain', 
        #                   error_code = NA, 
        #                   description = paste0("4.2 no existen ideales para el horario del colaborador ",colabToUse$EMP,
        #                                        ": ",substring(colabToUse$hora_in,12,16),"-",substring(colabToUse$hora_out,12,16),
        #                                        " con tipo de dia = '",colabToUse$day_type,"'"),
        #                   employee_id = emp_day, schedule_day = date_chosen)
        
        index <- which(dfTest$timestamps == closing_timestamps)
        start_index <- which(dfTest$timestamps == closing_timestamps) - floor(slotsToGive)
      }
      saveStart <- start_index
      given <- TRUE
      best_group <- dfTest[start_index:(start_index + slotsToGive), ]
      saveClose <- best_group
    }
  }
  if(given == FALSE){
    if(slotsToGive > nrow(dfToCheck)){
      
      #print"Fitting timeslot if possible ")
      saveCheck <- dfToCheck 
      if(endLimiter - head(dfToCheck$timestamps,1) <= tail(dfToCheck$timestamps,1) - startLimiter) {
        print("Best option is to give from end to left")
        start_index <- (which(dfTest$timestamps ==endLimiter) -slotsToGive)+1
        
        #saveStart <- row_number(dfTest$timestamps == start_index) 
        
        if (start_index >= 1 & dfTest$timestamps[start_index] >= startLimiter & tail(dfToCheck$timestamps,1) - dfTest$timestamps[start_index]  >= cargaMin) {
          #print"We can give this interval")
          #printslotsToGive)
          best_group <- dfTest[start_index:(start_index + slotsToGive -1), ]
        }else if(nrow(dfToCheck)>cargaMin*4 ) {
          print("change slot size")
          slotsToGive <- nrow(dfToCheck)
          if (time_diff <= slotsToGive) {
            slotsToGive <- max(time_diff)
          }
          if (time_difffecho <= slotsToGive) {
            slotsToGive <- max(time_difffecho)
          }
          
          if(slotsToGive < cargaMin*4) slotsToGive <- cargaMin*4
          
          #printslotsToGive)
          start_index <- which(dfTest$timestamps == tail(dfToCheck$timestamps,1)) - slotsToGive+1
          if (start_index >= 1 & dfTest$timestamps[start_index] >= startLimiter & tail(dfToCheck$timestamps,1) - dfTest$timestamps[start_index]  >= cargaMin) {
            #print"We can give this interval")
            best_group <- dfTest[start_index:(start_index + slotsToGive -1), ]
          }else{
            print("Wtf from end to left")
          }
        }else{
          start_index <- which(dfTest$timestamps == startLimiter)
          best_group <- dfTest[start_index:(start_index + slotsToGive-1 ), ]
          
        }
      }else if(endLimiter - head(dfToCheck$timestamps,1) >= tail(dfToCheck$timestamps,1) - startLimiter & as.numeric(difftime(tail(dfToCheck$timestamps,1),startLimiter))>= cargaMin){
        print("Best option is to give from start to right")
        start_index <- which(dfTest$timestamps == startLimiter)
        if (start_index >= 1 & dfTest$timestamps[start_index] >= startLimiter & dfTest$timestamps[start_index+slotsToGive] - dfTest$timestamps[start_index] >= cargaMin) {
          #print"We can give this interval")
          best_group <- dfTest[start_index:(start_index + slotsToGive -1), ]
          #Could be giving less 15 minutes when time is exactly carga minima
        }else if(as.numeric(difftime(tail(dfToCheck$timestamps,1),startLimiter))>= cargaMin) {
          print("change slot size")
          slotsToGive <- as.numeric(difftime(tail(dfToCheck$timestamps,1),startLimiter))*4
          if (time_diff <= slotsToGive) {
            slotsToGive <- max(time_diff)
          }
          if (time_difffecho <= slotsToGive) {
            slotsToGive <- max(time_difffecho)
          }
          
          if(slotsToGive < cargaMin*4) slotsToGive <- cargaMin*4
          #printslotsToGive)
          start_index <- which(dfTest$timestamps == startLimiter) 
          #printstart_index)
          if (start_index >= 1 
              & dfTest$timestamps[start_index] >= startLimiter 
              & dfTest$timestamps[start_index+slotsToGive] - dfTest$timestamps[start_index] >= cargaMin) {
            #print"We can give this interval")
            best_group <- dfTest[start_index:(start_index + slotsToGive -1), ]
          }else{
            print("Wtf from start to right")
          }
        }else{
          start_index <- which(dfTest$timestamps == head(dfToCheck$timestamps,1))
          best_group <- dfTest[start_index:(start_index + slotsToGive -1), ]
          
        }
      }else{
        start_index <- which(dfTest$timestamps == startLimiter)
        best_group <- dfTest[start_index:(start_index + slotsToGive -1), ]
        
      }
    }else{
      print("Entering random")
      i <- 1
      best_start_index <- NULL
      
      if (colabToUse$IJ_in == F & colabToUse$IJ_out == F) {
        if(slotsToGive < cargaMin*4) slotsToGive <- cargaMin*4
      }
      
      #   print(startLimiter)
      #   print(endLimiter)
      # print(slotsToGive)
      while(i<=nrow(dfToCheck) & !is.na(as.POSIXct(dfToCheck$timestamps[max(ceiling(i + slotsToGive-1),1)], format = '%Y-%m-%d %H:%M')) & as.POSIXct(dfToCheck$timestamps[max(ceiling(i + slotsToGive-1),1)], format = '%Y-%m-%d %H:%M') <= endLimiter & as.POSIXct(dfToCheck$timestamps[max(ceiling(i + slotsToGive-1),1)], format = '%Y-%m-%d %H:%M') <= closing_timestamps){
        
        
        if(as.POSIXct(dfToCheck[i,'timestamps'], format = '%Y-%m-%d %H:%M') >= as.POSIXct(startLimiter, format = '%H:%M')){
          testDefCheck <<- dfToCheck[i:(i + slotsToGive-1),]
          # cumsum_value <- sum(dfToCheck$Ideal_por_Cobrir[i:(i + slotsToGive-1)])
          if (any(dfToCheck$Minimo_Por_cobrir > 0)) {
            cumsum_value <- sum(dfToCheck$Minimo_Por_cobrir[i:(i + slotsToGive-1)])
          }else{
            cumsum_value <- sum(dfToCheck$Ideal_por_Cobrir[i:(i + slotsToGive-1)])
          }
          if (cumsum_value > max_cumsum) {
            print("changing to new timestamp")
            # print(dfToCheck[i:(i + slotsToGive),'timestamps'])
            max_cumsum <- cumsum_value
            best_start_index <- i
          }
        }
        i <- i+1
      }
      print(slotsToGive)
      if(!is.null(best_start_index)){
        print("got this interval")
        best_group <- dfToCheck[best_start_index:(best_start_index + slotsToGive-1), ]
      }
      if(is.null(best_start_index)){
        print("forcing a bad one")
        if(slotsToGive > time_difffecho){
          slotsToGive <- time_difffecho
        }
        
        if (colabToUse$IJ_in == F & colabToUse$IJ_out == F) {
          if(slotsToGive < cargaMin*4) slotsToGive <- cargaMin*4
        }
        
        print(slotsToGive)
        best_start_index <- which(dfTest$timestamps == startLimiter)
        best_group <- dfTest[best_start_index:(best_start_index + slotsToGive-1), ]
        
      }
      
      print("Fitting")
      # i <- 1
      # while(!is.na(as.POSIXct(dfToCheck$timestamps[(i + slotsToGive-1)], format = '%H:%M')) & as.POSIXct(dfToCheck$timestamps[(i + slotsToGive-1)], format = '%H:%M') <= as.POSIXct(colabToUse$hora_out, format = '%H:%M') ){
      #   testDefCheck <<- dfToCheck[i:(i + slotsToGive-1),]
      #   cumsum_value <- sum(dfToCheck$Minimo_Por_cobrir[i:(i + slotsToGive-1)])
      #   if (cumsum_value > max_cumsum) {
      #     max_cumsum <- cumsum_value
      #     best_start_index <- i
      #   }
      #   i <- i+1
      # }
      # 
      # best_group <- dfToCheck[best_start_index:(best_start_index + slotsToGive-1), ]
      # 
    }
  }
  
  
  testResults <- best_group
  return(best_group)
}
failures <- vector("list")

# df <- day_df_partido
# dfEMPloyee <- matriz_colaborador
# dfTest <- day_df
#Fix giving the break to make sure they work above what they need
atribuirPausas <- function(df, dfEMPloyee,dfTest){
  col_name <- names(df[5])
  EMPloyee_id <- as.character(gsub("EMPloyee_", "", col_name))
  print(paste0("Atribuindo pausas para EMPloyee com id: ", EMPloyee_id))
  indices <- which(df[col_name] == 1)
  givePausa <- FALSE
  
  colab <- matriz_colaborador[matriz_colaborador$EMP == EMPloyee_id,]
  bottomLine <- as.POSIXct(colab$DESC_CONTINUOS_TMIN_ATE, format = '%H:%M')
  if (is.na(bottomLine) | length(bottomLine)==0) {
    set_ProcessErrors(pathOS = pathFicheirosGlobal, user = wfm_user, 
                      fk_process = wfm_proc_id, 
                      type_error = 'E', process_type = 'resolve_pausas', 
                      error_code = NA, description = paste0('4.4 Subproceso ',childNumber,' -colab ',EMPloyee_id," con valores faltantes en 'DESC_CONTINUOS_TMIN_ATE'"),
                      employee_id = colab$FK_COLABORADOR, schedule_day = NA)
  }
  superiorLine <- as.POSIXct(colab$DESC_CONTINUOS_TMIN_APOS , format = '%H:%M')
  if (is.na(superiorLine) | length(superiorLine)==0) {
    set_ProcessErrors(pathOS = pathFicheirosGlobal, user = wfm_user, 
                      fk_process = wfm_proc_id, 
                      type_error = 'E', process_type = 'resolve_pausas', 
                      error_code = NA, description = paste0('4.4 Subproceso ',childNumber,' -colab ',EMPloyee_id," con valores faltantes en 'DESC_CONTINUOS_TMIN_APOS'"),
                      employee_id = colab$FK_COLABORADOR, schedule_day = NA)
  }
  slotsAntes <- hour(bottomLine) *4 + minute(bottomLine) / 15
  slotsDepois <- hour(superiorLine) *4 + minute(superiorLine) / 15
  
  pausasDuration <- as.POSIXct(colab$DESC_CONTINUOS_DURACAO , format = '%H:%M')
  pausasDuration <- arredondaHora(pausasDuration)
  pausasSlots <- hour(pausasDuration) *4 + minute(pausasDuration) / 15
  workTime <- as.POSIXct(colab$DESC_CONTINUOS_TEMPO_LIMITE_NAO_DESCANSO , format = '%H:%M')
  workSlots <- (hour(workTime) *4 + minute(workTime) / 15)
  if (workSlots==0) {
    set_ProcessErrors(pathOS = pathFicheirosGlobal, user = wfm_user, 
                      fk_process = wfm_proc_id, 
                      type_error = 'E', process_type = 'resolve_pausas', 
                      error_code = NA, description = paste0('4.4 Subproceso ',childNumber,' -colab ',EMPloyee_id," con valor 0 en 'DESC_CONTINUOS_TEMPO_LIMITE_NAO_DESCANSO'"),
                      employee_id = colab$FK_COLABORADOR, schedule_day = NA)
  }
  
  # granularidades podem alterar 4 15
  save_indices <<- indices #<- save_indices
  if (length(indices) > workSlots) {
    
    # Remove the first "10" rows in the range (tempo para trabalhar antes pausa)
    indices <- indices[-(1:slotsAntes)]  
    #Remove the last "4" (tempo para trabalhar depois pausa)
    indices <- indices[1:(length(indices)-slotsDepois)]
    if(length(indices) >= pausasSlots) givePausa <- TRUE
  } else {
    print("Pausa não atribuivel - Não trabalha horas minimas ou não tem espaço no horario.")
  }
  saveDf <<- df
  df <- saveDf
  # Check if there are any indices
  if (givePausa == TRUE) {
    
    # Get the indices where alocado > 1 and minimo_por_cobrir < 0
    valid_indices <- c()
    valid_moments <- c()
    for(i in 1:(length(indices))){
      if(df$Alocado [indices[i]] > 1 & df$Minimo_Por_cobrir[indices[i]] < 0){
        valid_indices <- c(valid_indices, indices[i])
        if(length(valid_indices) == pausasSlots){
          valid_moments <- c(valid_moments,list(valid_indices))
          valid_indices <- c()
          i <- i-pausasSlots-1
        }
      }else{
        valid_indices <- c()
      }
    }
    
    if(is.null(valid_moments)){
      valid_indices <- c()
      for(i in 1:(length(indices))){
        if(df$Alocado [indices[i]] > 1){
          valid_indices <- c(valid_indices, indices[i])
          if(length(valid_indices) >= pausasSlots){
            valid_moments <- c(valid_moments,list(valid_indices))
            valid_indices <- c()
            i <- i-pausasSlots-1
          }
        }else{
          valid_indices <- c()
        }
      }
      if(!is.null(valid_moments)) print("Pausa atribuida - Sacrificando minimos por cobrir.")
    }
    
    if(is.null(valid_moments)){
      valid_indices <- c()
      for(i in 1:(length(indices))){
        if(!(df$Alocado [indices[i]] > 1)){
          valid_indices <- c(valid_indices, indices[i])
          if(length(valid_indices) >= pausasSlots){
            valid_moments <- c(valid_moments,list(valid_indices))
            valid_indices <- c()
            i <- i-pausasSlots-1
          }
        }else{
          valid_indices <- c()
        }
      }
      if(!is.null(valid_moments)) print("Pausa atribuida!!!!! - Sacrificando cobertura maior que 0 no Tipo Posto.")
    }
    
    min_ideal_window <- NULL
    min_ideal_value <- Inf
    
    for (i in seq_along(valid_moments)) {
      current_window <- valid_moments[[i]]
      current_ideal_value <- sum(df$Ideal_por_Cobrir[current_window])
      
      if (current_ideal_value < min_ideal_value) {
        min_ideal_value <- current_ideal_value
        min_ideal_window <- current_window
      }
    }
    
    return(min_ideal_window)
  }  else {
    return(NULL)
  }
  return(NULL)
}

update_col_tibble <- function(slotsGiven, colabData, collaborator_tibbles, select_day,week,month,year,flag) {
  
  #print("UPDATING")
  # Extract collaborator ID from colabData
  collaborator_id <- colabData$EMP
  colab <- matriz_colaborador[matriz_colaborador$EMP == collaborator_id,]
  pausasDuration <- as.POSIXct(colab$DESC_CONTINUOS_DURACAO , format = '%H:%M')
  pausasDuration <- format(as.POSIXct(pausasDuration), format = '%H:%M')
  #pausasSlots <- hour(pausasDuration) *4 + minute(pausasDuration) / 15
  workTime <- as.POSIXct(colab$DESC_CONTINUOS_TEMPO_LIMITE_NAO_DESCANSO , format = '%H:%M')
  workSlots <- (hour(workTime) *4 + minute(workTime) / 15)
  pausaIncluida <- colab$DESC_CONTINUOS_INC_EXC 
  
  print(pausasDuration)
  print(slotsGiven)
  pausasSlotsRound <- convert_to_hours(pausasDuration)
  
  if (slotsGiven > workSlots) {
    hours <- (slotsGiven / 4) - pausasSlotsRound
  }else{
    hours <- slotsGiven / 4
  }
  print(hours)
  
  # Locate the corresponding tibble
  tibble_index <- which(names(collaborator_tibbles) == as.character(collaborator_id))
  print(tibble_index)
  # Check if collaborator is present in collaborator_tibbles
  if (length(tibble_index) > 0) {
    # Update the tibble with the new hours for the select_day
    date_index <- which(collaborator_tibbles[[tibble_index]]$date == select_day)
    week_index <- which(collaborator_tibbles[[tibble_index]]$week == week)
    month_index <- which(collaborator_tibbles[[tibble_index]]$month == month)
    year_index <- which(collaborator_tibbles[[tibble_index]]$year == year)
    carga_media_Falta <- collaborator_tibbles[[tibble_index]][year_index,"cargas_media_falta"]
    # Check if the select_day is present in the tibble
    if (length(date_index) > 0) {
      collaborator_tibbles[[tibble_index]][date_index, "hours_given"] <- collaborator_tibbles[[tibble_index]][date_index, "hours_given"] + hours
      collaborator_tibbles[[tibble_index]][date_index, "max_carga_diaria"] <- collaborator_tibbles[[tibble_index]][date_index, "max_carga_diaria"] - hours
      collaborator_tibbles[[tibble_index]][week_index, "max_carga_semanal"] <- collaborator_tibbles[[tibble_index]][week_index, "max_carga_semanal"] - hours
      collaborator_tibbles[[tibble_index]][month_index, "max_carga_mensal"] <- collaborator_tibbles[[tibble_index]][month_index, "max_carga_mensal"] - hours
      collaborator_tibbles[[tibble_index]][year_index, "dias_para_atribuir"] <- collaborator_tibbles[[tibble_index]][year_index, "dias_para_atribuir"] - 1
      collaborator_tibbles[[tibble_index]][year_index, "days_given"] <- collaborator_tibbles[[tibble_index]][year_index, "days_given"] + 1
      collaborator_tibbles[[tibble_index]][year_index, "horas_goal"] <- collaborator_tibbles[[tibble_index]][year_index, "horas_goal"] - hours
      collaborator_tibbles[[tibble_index]][year_index,"carga_media_atual"] <- ifelse(collaborator_tibbles[[tibble_index]][year_index,"days_given"] == 0,0,collaborator_tibbles[[tibble_index]][year_index,"hours_given"]/ collaborator_tibbles[[tibble_index]][year_index,"days_given"])
      collaborator_tibbles[[tibble_index]][year_index,"cargas_media_falta"] <- ifelse(collaborator_tibbles[[tibble_index]][year_index, "dias_para_atribuir"] == 0,carga_media_Falta,collaborator_tibbles[[tibble_index]][year_index,"horas_goal"]/ collaborator_tibbles[[tibble_index]][year_index,"dias_para_atribuir"])
      #cargas_media_faltas <<--- cargamediafalta
      if(flag == 0){
        collaborator_tibbles[[tibble_index]][year_index, "hours_for_zeros"] <- collaborator_tibbles[[tibble_index]][year_index, "hours_for_zeros"] + hours
        collaborator_tibbles[[tibble_index]][year_index, "zeros_filled"] <- collaborator_tibbles[[tibble_index]][year_index, "zeros_filled"] + 1
        
      }else if(flag == 1){
        collaborator_tibbles[[tibble_index]][year_index, "hours_for_min"] <- collaborator_tibbles[[tibble_index]][year_index, "hours_for_min"] + hours
        collaborator_tibbles[[tibble_index]][year_index, "minimums_filled"] <- collaborator_tibbles[[tibble_index]][year_index, "minimums_filled"] + 1
        
      }else if(flag == 2){
        collaborator_tibbles[[tibble_index]][year_index, "hours_for_ideal"] <- collaborator_tibbles[[tibble_index]][year_index, "hours_for_ideal"] + hours
        collaborator_tibbles[[tibble_index]][year_index, "ideals_filled"] <- collaborator_tibbles[[tibble_index]][year_index, "ideals_filled"] + 1
        
      }
    } else {
      warning(paste("Selected day", select_day, "not found in collaborator_tibbles for Collaborator ID", collaborator_id))
    }
  } else {
    warning(paste("Collaborator ID", collaborator_id, "not found in collaborator_tibbles"))
  }
  # finalColabTibble <<- collaborator_tibbles
  # Return the updated collaborator_tibbles
  return(collaborator_tibbles)
}



update_col_tibble_partidos <- function(horasTrab, colabData, collaborator_tibbles, select_day,week,month,year,flag) {
  
  
  #print("UPDATING")
  # Extract collaborator ID from colabData
  collaborator_id <- colabData$EMP
  
  # Locate the corresponding tibble
  tibble_index <- which(names(collaborator_tibbles) == as.character(collaborator_id))
  print(tibble_index)
  
  # Check if collaborator is present in collaborator_tibbles
  if (length(tibble_index) > 0) {
    # Update the tibble with the new hours for the select_day
    date_index <- which(collaborator_tibbles[[tibble_index]]$date == select_day)
    week_index <- which(collaborator_tibbles[[tibble_index]]$week == week)
    month_index <- which(collaborator_tibbles[[tibble_index]]$month == month)
    year_index <- which(collaborator_tibbles[[tibble_index]]$year == year)
    carga_media_Falta <- collaborator_tibbles[[tibble_index]][year_index,"cargas_media_falta"]
    # Check if the select_day is present in the tibble
    if (length(date_index) > 0) {
      collaborator_tibbles[[tibble_index]][date_index, "hours_given"] <- collaborator_tibbles[[tibble_index]][date_index, "hours_given"] + horasTrab
      collaborator_tibbles[[tibble_index]][date_index, "max_carga_diaria"] <- collaborator_tibbles[[tibble_index]][date_index, "max_carga_diaria"] - horasTrab
      collaborator_tibbles[[tibble_index]][week_index, "max_carga_semanal"] <- collaborator_tibbles[[tibble_index]][week_index, "max_carga_semanal"] - horasTrab
      collaborator_tibbles[[tibble_index]][month_index, "max_carga_mensal"] <- collaborator_tibbles[[tibble_index]][month_index, "max_carga_mensal"] - horasTrab
      collaborator_tibbles[[tibble_index]][year_index, "dias_para_atribuir"] <- collaborator_tibbles[[tibble_index]][year_index, "dias_para_atribuir"] - 1
      collaborator_tibbles[[tibble_index]][year_index, "days_given"] <- collaborator_tibbles[[tibble_index]][year_index, "days_given"] + 1
      collaborator_tibbles[[tibble_index]][year_index, "horas_goal"] <- collaborator_tibbles[[tibble_index]][year_index, "horas_goal"] - horasTrab
      collaborator_tibbles[[tibble_index]][year_index,"carga_media_atual"] <- ifelse(collaborator_tibbles[[tibble_index]][year_index,"days_given"] == 0,0,collaborator_tibbles[[tibble_index]][year_index,"hours_given"]/ collaborator_tibbles[[tibble_index]][year_index,"days_given"])
      collaborator_tibbles[[tibble_index]][year_index,"cargas_media_falta"] <- ifelse(collaborator_tibbles[[tibble_index]][year_index, "dias_para_atribuir"] == 0,carga_media_Falta,collaborator_tibbles[[tibble_index]][year_index,"horas_goal"]/ collaborator_tibbles[[tibble_index]][year_index,"dias_para_atribuir"])
      #cargas_media_faltas <<--- cargamediafalta
      if(flag == 0){
        collaborator_tibbles[[tibble_index]][year_index, "hours_for_zeros"] <- collaborator_tibbles[[tibble_index]][year_index, "hours_for_zeros"] + horasTrab
        collaborator_tibbles[[tibble_index]][year_index, "zeros_filled"] <- collaborator_tibbles[[tibble_index]][year_index, "zeros_filled"] + 1
        
      }else if(flag == 1){
        collaborator_tibbles[[tibble_index]][year_index, "hours_for_min"] <- collaborator_tibbles[[tibble_index]][year_index, "hours_for_min"] + horasTrab
        collaborator_tibbles[[tibble_index]][year_index, "minimums_filled"] <- collaborator_tibbles[[tibble_index]][year_index, "minimums_filled"] + 1
        
      }else if(flag == 2){
        collaborator_tibbles[[tibble_index]][year_index, "hours_for_ideal"] <- collaborator_tibbles[[tibble_index]][year_index, "hours_for_ideal"] + horasTrab
        collaborator_tibbles[[tibble_index]][year_index, "ideals_filled"] <- collaborator_tibbles[[tibble_index]][year_index, "ideals_filled"] + 1
        
      }
    } else {
      warning(paste("Selected day", select_day, "not found in collaborator_tibbles for Collaborator ID", collaborator_id))
    }
  } else {
    warning(paste("Collaborator ID", collaborator_id, "not found in collaborator_tibbles"))
  }
  # finalColabTibble <<- collaborator_tibbles
  # Return the updated collaborator_tibbles
  return(collaborator_tibbles)
}


arredondaHora <- function(hora, gran=15){
  # Hora dada
  hora <- as.POSIXct(hora, format='%H:%M')
  
  # Gerar uma sequência de horas em incrementos de 15 minutos
  horas_15_min <- seq(as.POSIXct(format(as.POSIXct('00:00', format='%H:%M'), "%Y-%m-%d %H:00:00")), 
                      by = paste0(gran," min"), length.out = 20)
  
  # Calcular a diferença entre a hora dada e todas as horas em incrementos de 15 minutos
  diferencas <- abs(difftime(hora, horas_15_min))
  
  # Encontrar o índice da menor diferença
  indice_menor_diferenca <- which.min(diferencas)
  
  # A hora mais próxima em incrementos de 15 minutos
  hora_mais_proxima <- horas_15_min[indice_menor_diferenca]
  
  return(hora_mais_proxima)
}

verifyDaysAndHoras <- function(){
  matriz_preloaded_useful <- matriz_horarios_preloaded %>% filter(POSTO_ID == posto)
  matriz_colab_useful <- matriz_colaborador %>% filter(FK_TIPO_POSTO == posto)
  preloaded_ids <- unique(matriz_preloaded_useful$EMP)
  fixo_ids <- matriz_colaborador$EMP[startsWith(matriz_colaborador$TIPO_DE_TURNO, 'F')]
  unique_combinations <- list()
  # Iterate through each dataset
  for (id in names(collaborator_tibbles)) {
    # Extract EMP ID
    emp_id <- id
    # Extract unique combinations of days_given and horas_goal
    unique_days_given <- unique(collaborator_tibbles[[id]]$days_given)
    unique_horas_goal <- unique(collaborator_tibbles[[id]]$horas_goal)
    # Create combinations for each unique days_given and horas_goal
    combinations <- expand.grid(days_given = unique_days_given,
                                horas_goal = unique_horas_goal)
    # Store the combinations for the current ID
    unique_combinations[[id]] <- combinations
  }
  for (id in names(collaborator_tibbles)) {
    cat("ID:", id, "\n")
    # Extract combinations for the current ID
    combinations <- unique_combinations[[id]]
    # Iterate through each combination
    for (i in 1:nrow(combinations)) {
      days_given <- combinations$days_given[i]
      horas_goal <- combinations$horas_goal[i]
      if(id %in%  preloaded_ids){
        cat("Colab preloaded \n")
      }
      if(id %in% fixo_ids){
        cat("Colab fixo \n")
      }
      cat("Days Given:", days_given, "- Horas Goal:", horas_goal, "\n")
    }
    cat("\n")
  }
}


getIntervalZeros <- function( df) {
  #print("Getting values of 0")
  # Find intervals within the opening and closing periods where df$allocated is 0
  zero_intervals <<- which(df$Minimo_Por_cobrir > 0  & df$Alocado == 0)
  if (length(zero_intervals) == 0) {
    ##print("No fractions with zeros.")
    return(NULL)
  }
  
  # Find the first and last indices with minimum! greater than 0
  h_in <- zero_intervals[1]
  h_fim <- zero_intervals[length(zero_intervals)]
  
  # Extract start time, end time, and duration of the interval
  start_time <- df$timestamps[h_in]
  end_time <- df$timestamps[h_fim]
  duration <- end_time - start_time
  
  interval_info <- list(
    start_time = start_time,
    end_time = end_time,
    duration = duration
  )
  
  return(interval_info)
}


getIntervalMinimos <- function(df) {
  ##print("Getting values of minimos")
  
  # Find indices of fractions with minimum! greater than 0
  minimo_indices <- which(df$Minimo_Por_cobrir  > 0)
  # Check if there are any such fractions
  if (length(minimo_indices) == 0) {
    ##print("No fractions with minimum! greater than 0.")
    return(NULL)
  }
  
  # Find the first and last indices with minimum! greater than 0
  h_in <- minimo_indices[1]
  h_fim <- minimo_indices[length(minimo_indices)]
  
  # Extract start time, end time, and duration of the interval
  start_time <- df$timestamps[h_in]
  end_time <- df$timestamps[h_fim]
  duration <- end_time - start_time
  
  interval_info <- list(
    start_time = start_time,
    end_time = end_time,
    duration = duration
  )
  
  return(interval_info)
  # interval <- df$timestamps >= start_time & df$timestamps <= end_time
  # return(df$timestamps[interval])
}

getIntervalCobrirEntreMinimoIdeal <- function(df,xxx = 2,zzz = 3) {
  ##print("Getting values of ideais")
  
  saveDF <<- df #<- saveDF
  # Find indices of fractions with ideal greater than 0
  ideal_indices <- which(df$Ideal_por_Cobrir > 0)
  ##print(ideal_indices)
  # Check if there are any such fractions
  if (length(ideal_indices) == 0) {
    ##print("No fractions with ideal greater than 0.")
    return(NULL)
  }
  
  # Find the first and last indices with ideal greater than 0
  h_in <- ideal_indices[1]
  h_fim <- ideal_indices[length(ideal_indices)]
  
  # Extract start time, end time, and duration of the interval
  start_time <- df$timestamps[h_in]
  end_time <- df$timestamps[h_fim]
  duration <- end_time - start_time
  interval_info <- list(
    start_time = start_time,
    end_time = end_time,
    duration = duration
  )
  #}
  ##print(interval_info)
  return(interval_info)
  # interval <- df$timestamps >= start_time & df$timestamps <= end_time
  # ##print(interval)
  # return(df$timestamps[interval])
}