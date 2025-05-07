atribuirHorarioContinuos <- function(date_chosen, week, month, year, dfTest, colabHours, class, collaborator_tibbles, ColabData, tipo_cp='C'){
  print("Entering continuos")
  dfEMPloyee <- colabHours %>% 
    # dplyr::filter(Allocated != T) %>%
    # dplyr::filter(partido_continuado == tipo_cp)
    dplyr::filter(!day_type %in% c('MoT','P'))
  
  dfTest$Ideal_por_Cobrir <- as.integer(dfTest$Ideal_por_Cobrir)
  dfTest$Alocado <- as.integer(dfTest$Alocado)
  dfTest$Minimo_Por_cobrir <- as.integer(dfTest$Minimo_Por_cobrir)
  zeros <- 0
  minimos <- 0
  ideais <- 0
  
  while (any(!dfEMPloyee$Allocated)) {
    daily_dataframe$Dias_a_trabalhar[daily_dataframe$EMP %in% dfEMPloyee$EMP] <- TRUE
    #print(dfEMPloyee)
    
    
    interval_flag <- 0
    # Call the function and get the allocated timestamps
    # filtered_employees <- dfEMPloyee[dfEMPloyee$day_type == 'A', ]
    # 
    # # Loop through each employee and perform actions
    # for (i in seq_len(nrow(filtered_employees))) {
    #   employee <- filtered_employees[i, ]
    #   print(employee)
    #   tibble_index <- which(names(collaborator_tibbles) == as.character(employee$EMP))
    # 
    #   # carga <- collaborator_tibbles[[tibble_index]]$carga_media_atual[1]*4+1
    #   media_atual <- collaborator_tibbles[[tibble_index]]$carga_media_fixa[[1]]
    #   media_atual <- find_closest_mod_0.25(media_atual)
    #   carga <- abs(media_atual*4)
    #   collaborator_tibbles <- update_col_tibble(
    #     carga,
    #     employee,
    #     collaborator_tibbles,
    #     date_chosen,
    #     week,
    #     month,
    #     year,
    #     interval_flag
    #   )
    #   dfEMPloyee$Allocated[dfEMPloyee$EMP == employee$EMP] <- TRUE
    #   dfEMPloyee <- dfEMPloyee[dfEMPloyee$EMP != employee$EMP, ]
    #   
    #  next 
    # }
    
    intervalData <- getIntervalCobrirEntreMinimoIdealNew(dfTest)
    print(intervalData)
    # intervalData$start_time <- intervalData$start_time-0.25*3600
    
    # intervalData <- getIntervalZeros(dfTest)
    # 
    # #print(intervalData)
    # if(is.null(intervalData)){
    #   #print("Getting minimos")
    #   intervalData <- getIntervalMinimos(dfTest)
    #   interval_flag = 1
    # 
    #   if(is.null(intervalData)){
    #     #print("Getting ideals")
    #     intervalData <- getIntervalCobrirEntreMinimoIdeal(dfTest)
    #     interval_flag = 2
    #     ideais <- ideais +1
    # 
    #   }else{
    #     minimos <- minimos +1
    # 
    #   }
    # }else{
    #   zeros <- zeros +1
    # }
    
    colabsToUse <- NULL
    colabChosen <- NULL
    # print(intervalData)
    if (!is.null(intervalData)) {
      timestamps <- seq(intervalData$start_time, intervalData$end_time, by = "15 mins")
      
      colabsToUse <- selectColab(intervalData,dfEMPloyee,ColabData,dfTest)
      
      #print(colabsToUse)
      if(!is.null(colabsToUse)){
        # if (colabsToUse$EMP =='4097100') {
        #   break
        # }
        #print(colabsToUse)
        #if(interval_flag != 2){
        if (colabsToUse$tipo_hor =='FE' ) {
          indIni <- max(intervalData$start_time,colabsToUse$hora_in)
          indFim <- min(intervalData$end_time,colabsToUse$hora_out)
          if (indFim>indIni) {
            timestamps <- seq(as.POSIXct(indIni, format = '%Y-%m-%d %H:%M'), as.POSIXct(indFim, format = '%Y-%m-%d %H:%M'), by = "15 mins")
          } else{
            timestamps <- seq(as.POSIXct(colabsToUse$hora_in, format = '%Y-%m-%d %H:%M'), as.POSIXct(colabsToUse$hora_out, format = '%Y-%m-%d %H:%M'), by = "15 mins")
          }
          
          intervalData$start_time <- head(timestamps,1)
          intervalData$end_time <- tail(timestamps,1)
          intervalData$duration <- difftime(intervalData$end_time,intervalData$start_time, units = 'hours')
        }
        #print(collaborator_tibbles)
        print("Trying to give horario")
        colabChosen <- atribuirHorario(colabsToUse, intervalData,class,date_chosen,collaborator_tibbles)
        # print(colabChosen)
        # if(is.null(colabChosen)){
        #   print("Go for backup")
        #   next
        # }
        
        
        # }else{
        #   print("fuck this")
        #   colabChosen <- attribuirHorarioBK(dfEMPloyee,ColabData,daily_dataframe,collaborator_tibbles)
        # }
      }
    }
    if(is.null(intervalData)|is.null(colabsToUse)| is.null(colabChosen)){
      print("Giving back up shcedule to these cunts !")
      interval_flag = 3
      collabi <- dfEMPloyee %>%  filter(Allocated != TRUE) %>%
        dplyr::select(EMP,tipo_hor,hora_in,class_in,IJ_in,hora_out,class_out,IJ_out,day_type,
                      partido_continuado,fixo_semana,Allocated)
      
      colabChosen <- attribuirHorarioBK(collabi,ColabData,daily_dataframe,collaborator_tibbles)
      collabi <- colabChosen[[1]]
      timestamps <- seq(as.POSIXct(collabi$hora_in, format = '%Y-%m-%d %H:%M'), as.POSIXct(collabi$hora_out, format = '%Y-%m-%d %H:%M'), by = "15 mins")
    }
    
    # print(intervalData)
    if(!is.null(colabChosen)){
      
      
      #print("Giving schedule")
      if(interval_flag != 3){
        #print("Atribuir normal")
        testHora <- colabChosen
        collaborator_tibbles <- colabChosen[[2]]
        colabToUse <- colabChosen[[1]][[1]]
        slotsToGive <- colabChosen[[1]][[2]]
      }else{
        #print("Booooo")
        testHora2 <- colabChosen
        colabToUse <- colabChosen[[1]]
        slotsToGive <- colabChosen[[2]]
      }
      testWtf <- colabToUse
      # if (colabToUse$EMP %in% c(4097100)) {
      #   break
      # }
      
      # print(slotsToGive)
      dfEMPloyee$Allocated[dfEMPloyee$EMP == colabToUse$EMP] <- TRUE
      # print("nigga what")
      #matriz_implicacoes$`Dias com Hor?rio`[matriz_implicacoes$EMP == colabToUse$EMP] <- matriz_implicacoes$`Dias com Hor?rio`+1
      
      df_indices <- match(timestamps, dfTest$timestamps)
      df_indices[is.na(df_indices)] <- 0
      
      dfToCheck <- dfTest[df_indices,]
      # ##validacao extra cargas a atribuir
      # newHoras <- as.numeric(difftime(as.POSIXct(max(dfToCheck$timestamps), format = '%Y-%m-%d %H:%M'),as.POSIXct(min(dfToCheck$timestamps), format = '%Y-%m-%d %H:%M'), units = 'hours'))
      # if (newHoras < colabToUse$HORAS_TRAB_DIA_CARGA_MIN) {
      #   if(colabToUse$IJ_in == F & colabToUse$class_in =='R'){
      #     print("CARGA_MINIMA -> tentei dar horas para tras")
      #     diffFalta <- colabToUse$HORAS_TRAB_DIA_CARGA_MIN-newHoras
      #     
      #     timestamps <- seq(as.POSIXct(colabToUse$hora_in, format = '%Y-%m-%d %H:%M')-diffFalta*3600,
      #                       as.POSIXct(colabToUse$hora_out, format = '%Y-%m-%d %H:%M'), by = "15 mins")
      #     
      #     df_indices <- match(timestamps, dfTest$timestamps)
      #     df_indices[is.na(df_indices)] <- 0
      #     
      #     dfToCheck <- dfTest[df_indices,]
      #   }else if(colabToUse$IJ_out == F & colabToUse$class_out =='R'){
      #     print("CARGA_MINIMA -> tentei dar horas para frente")
      #     diffFalta <- colabToUse$HORAS_TRAB_DIA_CARGA_MIN-newHoras
      #     
      #     timestamps <- seq(as.POSIXct(colabToUse$hora_in, format = '%Y-%m-%d %H:%M'),
      #                       as.POSIXct(colabToUse$hora_out, format = '%Y-%m-%d %H:%M')+diffFalta*3600, by = "15 mins")
      #     
      #     df_indices <- match(timestamps, dfTest$timestamps)
      #     df_indices[is.na(df_indices)] <- 0
      #     
      #     dfToCheck <- dfTest[df_indices,]
      #     
      #   }
      # }
      best_group <- fitTimeSlots(colabToUse, dfToCheck,dfTest,slotsToGive,collaborator_tibbles,date_chosen,week,month,year,interval_flag)
      # #print the result
      
      df_indices <- match(best_group$timestamps, dfTest$timestamps)
      df_indices[is.na(df_indices)] <- 0
      #print(best_group$timestamps)
      collaborator_tibbles <- update_col_tibble((nrow(best_group)), colabToUse,collaborator_tibbles,date_chosen,week,month,year,interval_flag)
      
      # Update df$allocated directly for the relevant rows
      dfTest$Ideal_por_Cobrir <- as.integer(dfTest$Ideal_por_Cobrir)
      dfTest$Alocado <- as.integer(dfTest$Alocado)
      dfTest$Minimo_Por_cobrir <- as.integer(dfTest$Minimo_Por_cobrir)
      dfTest$Ideal <- as.integer(dfTest$Ideal)
      dfTest$Minimo <- as.integer(dfTest$Minimo)
      dfTest$Alocado[df_indices] <- dfTest$Alocado[df_indices]+1
      new_col_name <- paste0("EMPloyee_",colabToUse$EMP,sep="")
      dfTest[[new_col_name]] <- 0     
      dfTest[[new_col_name]][df_indices] <- dfTest[[new_col_name]][df_indices]+1
      daily_dataframe$Dia_atribuido[daily_dataframe$EMP == colabToUse$EMP] <- TRUE
    }
    
    # M?nimo! Por cobrir -> M?nimo! - Alocado
    dfTest$Ideal_por_Cobrir <- dfTest$Ideal - dfTest$Alocado
    dfTest$Minimo_Por_cobrir <- dfTest$Minimo - dfTest$Alocado
    # print(colnames(dfTest))
  }
  cat("--------- Horarios Atribuidos -----------\n")
  cat(sprintf("EMPloyees working: %d\n", nrow(dfEMPloyee)))
  cat(sprintf("Zeros:   %d\n", zeros))
  cat(sprintf("Minimos: %d\n", minimos))
  cat(sprintf("Ideais:  %d\n", ideais))  
  
  # if (nrow(dfEMPloyee)>0) {
  #   testResults <- dfTest #<- testResults
  #   for(i in 1:(nrow(dfEMPloyee))){ #:nrow(dfEMPloyee)
  #     pausasEMP<- dfEMPloyee
  #     if(dfEMPloyee[i,]$Allocated == FALSE){
  #       next
  #     } 
  #     # if(dfEMPloyee[i,]$tipo_hor == 'FG'){
  #     #   next
  #     # }
  #     col_name <- paste0("EMPloyee_",dfEMPloyee[i,'EMP'])
  #     ###print(col_name)
  #     saveTesttas <- dfTest
  #     col <- dfTest %>%  dplyr::select(timestamps, Alocado,Ideal_por_Cobrir, Minimo_Por_cobrir ,col_name)
  #     pause_index <- atribuirPausas(col,dfEMPloyee,dfTest)
  #     if(!is.null(pause_index)){
  #       for(index in pause_index){
  #         dfTest[index, col_name] <- 'P' 
  #         dfTest[index, 'Ideal_por_Cobrir'] <- dfTest[index, 'Ideal_por_Cobrir'] + 1
  #         dfTest[index, 'Minimo_Por_cobrir'] <- dfTest[index, 'Minimo_Por_cobrir'] + 1
  #         dfTest[index, 'Alocado'] <- dfTest[index, 'Alocado'] - 1
  #       }
  #     }
  #     
  #   }
  # }
  
  
  
  return(list(dfTest,daily_dataframe,collaborator_tibbles,dfEMPloyee))
}



escolheMomento <- function(){
  
  # nao existe bossa
  # avalia em que momento o ideal é maior, M ou T?
  left_side <- dfTest %>% 
    dplyr::filter(timestamps >= intervalData$start_time & timestamps < as.POSIXct('15:00',format='%H:%M', tz='GMT'))
  
  if (nrow(left_side)>0) {
    indicesL <- which(dfTest$timestamps %in% left_side$timestamps)
    avgIdealL <- sum(as.numeric(dfTest[indicesL,]$Ideal_por_Cobrir)) / length(indicesL)
  } else{
    avgIdealL <- 0
  }
  
  
  right_side <- dfTest %>% 
    dplyr::filter(timestamps > as.POSIXct('16:30',format='%H:%M', tz='GMT') & timestamps <= intervalData$end_time)
  
  if (nrow(right_side)>0) {
    indicesR <- which(dfTest$timestamps %in% right_side$timestamps)
    avgIdealR <- sum(as.numeric(dfTest[indicesR,]$Ideal_por_Cobrir)) / length(indicesR)
  } else{
    avgIdealR <- 0
  }
  
  int_side <- dfTest %>% 
    dplyr::filter(timestamps >= intervalData$start_time & timestamps >= as.POSIXct('15:00',format='%H:%M', tz='GMT') & timestamps <= as.POSIXct('16:30',format='%H:%M', tz='GMT') & timestamps <= intervalData$end_time)
  
  if (nrow(int_side)>0) {
    indicesI <- which(dfTest$timestamps %in% int_side$timestamps)
    avgIdealI <- sum(as.numeric(dfTest[indicesI,]$Ideal_por_Cobrir)) / length(indicesI)
  } else{
    avgIdealI <- 0
  }
  
  index_max <- which.max(c(avgIdealL,avgIdealR, avgIdealI))
  if (index_max == 1){
    print("Left side biggest")
    #avalia se existe algum colaborador com horario_atribuido na s, s-1 ou s+1 para M
    mColabSemM <- matriz_colab_semana %>% 
      dplyr::filter(EMP %in% dfEMPloyee$EMP & SEMANA == week(date_chosen) & TOTAL_MANHA > 0) %>% 
      dplyr::arrange(TOTAL_CONT) %>% slice(1)
    
    if (nrow(mColabSemM)==0) {
      mColabSemM <- matriz_colab_semana %>% 
        dplyr::filter(EMP %in% dfEMPloyee$EMP & (SEMANA == (week(date_chosen)+1) | SEMANA == (week(date_chosen)-1)) & TOTAL_MANHA > 0) %>% 
        dplyr::arrange(TOTAL_CONT) %>% slice(1)
      
      if (nrow(mColabSemM)==0) {
        mColabSemM <- matriz_colab_semana %>% 
          dplyr::filter(EMP %in% dfEMPloyee$EMP & SEMANA == week(date_chosen)) %>% 
          dplyr::arrange(TOTAL_CONT) %>% slice(1)
        
      }
      
      
    }
    
    
    dfRes <- atribuirHorarioContinuos(date_chosen, week, month, year, dfTest, 
                                      colabHours %>% dplyr::filter(EMP %in% mColabSemM$EMP), 
                                      class, collaborator_tibbles, ColabData,  tipo_cp='CP')
    
    dfTest <- dfRes[[1]]
    daily_dataframe <- dfRes[[2]]
    collaborator_tibbles <- dfRes[[3]]
    
    
  }else if (index_max == 2){
    print("Right side biggest")
    #avalia se existe algum colaborador com horario_atribuido na s, s-1 ou s+1 para T
    mColabSemM <- matriz_colab_semana %>% 
      dplyr::filter(EMP %in% dfEMPloyee$EMP & SEMANA == week(date_chosen) & TOTAL_TARDE > 0) %>% 
      dplyr::arrange(TOTAL_CONT) %>% slice(1)
    
    if (nrow(mColabSemM)==0) {
      mColabSemM <- matriz_colab_semana %>% 
        dplyr::filter(EMP %in% dfEMPloyee$EMP & (SEMANA == (week(date_chosen)+1) | SEMANA == (week(date_chosen)-1)) & TOTAL_TARDE > 0) %>% 
        dplyr::arrange(TOTAL_CONT) %>% slice(1)
      
      if (nrow(mColabSemM)==0) {
        mColabSemM <- matriz_colab_semana %>% 
          dplyr::filter(EMP %in% dfEMPloyee$EMP & SEMANA == week(date_chosen)) %>% 
          dplyr::arrange(TOTAL_CONT) %>% slice(1)
        
      }
      
      
    }
    
    
    dfRes <- atribuirHorarioContinuos(date_chosen, week, month, year, dfTest, 
                                      colabHours %>% dplyr::filter(EMP %in% mColabSemM$EMP), 
                                      class, collaborator_tibbles, ColabData,  tipo_cp='CP')
    
    dfTest <- dfRes[[1]]
    daily_dataframe <- dfRes[[2]]
    collaborator_tibbles <- dfRes[[3]]
    
  }else{
    print("Intersection biggest")
    #avalia se existe algum colaborador com horario_atribuido na s, s-1 ou s+1 para o Intersection 
    
    
  }
  
}

# MANHA
# colabHours <- colabHours %>% dplyr::filter(EMP == colabsSemanaCP_M$EMP) %>% dplyr::mutate(day_type='M')
# ColabData <- ColabData %>% dplyr::filter(EMP == colabsSemanaCP_M$EMP) 
# TARDE
# colabHours <- colabHours %>% dplyr::filter(EMP == colabsSemanaCP_T$EMP) %>% dplyr::mutate(day_type='T')
# ColabData <- ColabData %>% dplyr::filter(EMP == colabsSemanaCP_T$EMP) 
# tipo_cp='CP'

atribuirHorarioContinuos_CP <- function(date_chosen, week, month, year, dfTest, colabHours, class, collaborator_tibbles, ColabData, tipo_cp='CP',intervalData){
  print("Entering continuos")
  dfEMPloyee <- colabHours #%>% 
  # dplyr::filter(Allocated != T) %>%
  # dplyr::filter(partido_continuado == tipo_cp)
  # dplyr::filter(day_type %in% c('MoT'))
  
  dfTest$Ideal_por_Cobrir <- as.integer(dfTest$Ideal_por_Cobrir)
  dfTest$Alocado <- as.integer(dfTest$Alocado)
  dfTest$Minimo_Por_cobrir <- as.integer(dfTest$Minimo_Por_cobrir)
  zeros <- 0
  minimos <- 0
  ideais <- 0
  
  while (any(!dfEMPloyee$Allocated)) {
    daily_dataframe$Dias_a_trabalhar[daily_dataframe$EMP %in% dfEMPloyee$EMP] <- TRUE
    #print(dfEMPloyee)
    
    
    interval_flag <- 0
    # Call the function and get the allocated timestamps
    # filtered_employees <- dfEMPloyee[dfEMPloyee$day_type == 'A', ]
    # 
    # # Loop through each employee and perform actions
    # for (i in seq_len(nrow(filtered_employees))) {
    #   employee <- filtered_employees[i, ]
    #   print(employee)
    #   tibble_index <- which(names(collaborator_tibbles) == as.character(employee$EMP))
    # 
    #   # carga <- collaborator_tibbles[[tibble_index]]$carga_media_atual[1]*4+1
    #   media_atual <- collaborator_tibbles[[tibble_index]]$carga_media_fixa[[1]]
    #   media_atual <- find_closest_mod_0.25(media_atual)
    #   carga <- abs(media_atual*4)
    #   collaborator_tibbles <- update_col_tibble(
    #     carga,
    #     employee,
    #     collaborator_tibbles,
    #     date_chosen,
    #     week,
    #     month,
    #     year,
    #     interval_flag
    #   )
    #   dfEMPloyee$Allocated[dfEMPloyee$EMP == employee$EMP] <- TRUE
    #   dfEMPloyee <- dfEMPloyee[dfEMPloyee$EMP != employee$EMP, ]
    #   
    #  next 
    # }
    
    # intervalData <- getIntervalCobrirEntreMinimoIdealNew(dfTest)
    
    # intervalData <- getIntervalZeros(dfTest)
    # 
    # #print(intervalData)
    # if(is.null(intervalData)){
    #   #print("Getting minimos")
    #   intervalData <- getIntervalMinimos(dfTest)
    #   interval_flag = 1
    # 
    #   if(is.null(intervalData)){
    #     #print("Getting ideals")
    #     intervalData <- getIntervalCobrirEntreMinimoIdeal(dfTest)
    #     interval_flag = 2
    #     ideais <- ideais +1
    # 
    #   }else{
    #     minimos <- minimos +1
    # 
    #   }
    # }else{
    #   zeros <- zeros +1
    # }
    
    colabsToUse <- NULL
    colabChosen <- NULL
    # print(intervalData)
    if (!is.null(intervalData)) {
      timestamps <- seq(intervalData$start_time, intervalData$end_time, by = "15 mins")
      
      colabsToUse <- selectColab(intervalData,dfEMPloyee,ColabData,dfTest)
      #print(colabsToUse)
      if(!is.null(colabsToUse)){
        #print(colabsToUse)
        #if(interval_flag != 2){
        #print(collaborator_tibbles)
        if (colabsToUse$tipo_hor =='FE' ) {
          indIni <- max(intervalData$start_time,colabsToUse$hora_in)
          indFim <- min(intervalData$end_time,colabsToUse$hora_out)
          if (indFim>indIni) {
            timestamps <- seq(as.POSIXct(indIni, format = '%Y-%m-%d %H:%M'), as.POSIXct(indFim, format = '%Y-%m-%d %H:%M'), by = "15 mins")
          } else{
            timestamps <- seq(as.POSIXct(colabsToUse$hora_in, format = '%Y-%m-%d %H:%M'), as.POSIXct(colabsToUse$hora_out, format = '%Y-%m-%d %H:%M'), by = "15 mins")
          }
          
          intervalData$start_time <- head(timestamps,1)
          intervalData$end_time <- tail(timestamps,1)
          intervalData$duration <- difftime(intervalData$end_time,intervalData$start_time, units = 'hours')
        }
        print("Trying to give horario")
        colabChosen <- atribuirHorario(colabsToUse, intervalData,class,date_chosen,collaborator_tibbles)
        # print(colabChosen)
        if(is.null(colabChosen)){
          #print("Go for backup")
        }
        
        
        # }else{
        #   print("fuck this")
        #   colabChosen <- attribuirHorarioBK(dfEMPloyee,ColabData,daily_dataframe,collaborator_tibbles)
        # }
      }
    }
    if(is.null(intervalData)|is.null(colabsToUse)| is.null(colabChosen)){
      print("Giving back up shcedule to these cunts !")
      interval_flag = 3
      collabi <- dfEMPloyee %>%  filter(Allocated != TRUE) %>% 
        dplyr::select(EMP,tipo_hor,hora_in,class_in,IJ_in,hora_out,class_out,IJ_out,day_type,
                      partido_continuado,fixo_semana,Allocated)
      
      colabChosen <- attribuirHorarioBK(collabi,ColabData,daily_dataframe,collaborator_tibbles)
      collabi <- colabChosen[[1]]
      timestamps <- seq(as.POSIXct(collabi$hora_in), as.POSIXct(collabi$hora_out), by = "15 mins")
    }
    # print(intervalData)
    if(!is.null(colabChosen)){
      #print("Giving schedule")
      if(interval_flag != 3){
        #print("Atribuir normal")
        testHora <- colabChosen
        collaborator_tibbles <- colabChosen[[2]]
        colabToUse <- colabChosen[[1]][[1]]
        slotsToGive <- colabChosen[[1]][[2]]
      }else{
        #print("Booooo")
        testHora2 <- colabChosen
        colabToUse <- colabChosen[[1]]
        slotsToGive <- colabChosen[[2]]
      }
      testWtf <- colabToUse
      
      # print(slotsToGive)
      dfEMPloyee$Allocated[dfEMPloyee$EMP == colabToUse$EMP] <- TRUE
      # print("nigga what")
      #matriz_implicacoes$`Dias com Hor?rio`[matriz_implicacoes$EMP == colabToUse$EMP] <- matriz_implicacoes$`Dias com Hor?rio`+1 
      
      df_indices <- match(timestamps, dfTest$timestamps)
      df_indices[is.na(df_indices)] <- 0
      
      dfToCheck <- dfTest[df_indices,]
      best_group <- fitTimeSlots(colabToUse, dfToCheck,dfTest,slotsToGive,collaborator_tibbles,date_chosen,week,month,year,interval_flag)
      # #print the result
      
      df_indices <- match(best_group$timestamps, dfTest$timestamps)
      df_indices[is.na(df_indices)] <- 0
      #print(best_group$timestamps)
      collaborator_tibbles <- update_col_tibble((nrow(best_group)), colabToUse,collaborator_tibbles,date_chosen,week,month,year,interval_flag)
      
      # Update df$allocated directly for the relevant rows
      dfTest$Ideal_por_Cobrir <- as.integer(dfTest$Ideal_por_Cobrir)
      dfTest$Alocado <- as.integer(dfTest$Alocado)
      dfTest$Minimo_Por_cobrir <- as.integer(dfTest$Minimo_Por_cobrir)
      dfTest$Ideal <- as.integer(dfTest$Ideal)
      dfTest$Minimo <- as.integer(dfTest$Minimo)
      dfTest$Alocado[df_indices] <- dfTest$Alocado[df_indices]+1
      new_col_name <- paste0("EMPloyee_",colabToUse$EMP,sep="")
      dfTest[[new_col_name]] <- 0     
      dfTest[[new_col_name]][df_indices] <- dfTest[[new_col_name]][df_indices]+1
      daily_dataframe$Dia_atribuido[daily_dataframe$EMP == colabToUse$EMP] <- TRUE
    }
    
    # M?nimo! Por cobrir -> M?nimo! - Alocado
    dfTest$Ideal_por_Cobrir <- dfTest$Ideal - dfTest$Alocado
    dfTest$Minimo_Por_cobrir <- dfTest$Minimo - dfTest$Alocado
    # print(colnames(dfTest))
  }
  cat("--------- Horarios Atribuidos -----------\n")
  cat(sprintf("EMPloyees working: %d\n", nrow(dfEMPloyee)))
  cat(sprintf("Zeros:   %d\n", zeros))
  cat(sprintf("Minimos: %d\n", minimos))
  cat(sprintf("Ideais:  %d\n", ideais))  
  
  
  # testResults <- dfTest #<- testResults
  # for(i in 1:(nrow(dfEMPloyee))){ #:nrow(dfEMPloyee)
  #   pausasEMP<- dfEMPloyee
  #   if(dfEMPloyee[i,]$Allocated == FALSE){
  #     next
  #   } 
  #   # if(dfEMPloyee[i,]$tipo_hor == 'FG'){
  #   #   next
  #   # }
  #   col_name <- paste0("EMPloyee_",dfEMPloyee[i,'EMP'])
  #   ###print(col_name)
  #   saveTesttas <- dfTest
  #   col <- dfTest %>%  select(timestamps, Alocado,Ideal_por_Cobrir, Minimo_Por_cobrir ,col_name)
  #   pause_index <- atribuirPausas(col,dfEMPloyee,dfTest)
  #   if(!is.null(pause_index)){
  #     for(index in pause_index){
  #       dfTest[index, col_name] <- 'P' 
  #       dfTest[index, 'Ideal_por_Cobrir'] <- dfTest[index, 'Ideal_por_Cobrir'] + 1
  #       dfTest[index, 'Minimo_Por_cobrir'] <- dfTest[index, 'Minimo_Por_cobrir'] + 1
  #       dfTest[index, 'Alocado'] <- dfTest[index, 'Alocado'] - 1
  #     }
  #   }
  #   
  # }
  
  return(list(dfTest,daily_dataframe,collaborator_tibbles,dfEMPloyee))
}


atribuirHorarioContinuos_CP_Pai <- function(dfEMPloyee,date_chosen, week, month, year, dfTest, colabHours, class, collaborator_tibbles, ColabData,intervalData,matriz_colab_semana,matriz_colab_dia_turno){
  #tenta atribuir continuo
  
  limtes <- ColabData %>% 
    dplyr::select(EMP,LIMITE_SUPERIOR_MANHA,LIMITE_INFERIOR_TARDE) %>% 
    merge(dfEMPloyee %>% dplyr::filter(Allocated!=T))
  
  LIT <- as.POSIXct(paste('2000-01-01',max(limtes$LIMITE_INFERIOR_TARDE)), tz='GMT')
  LSM <- as.POSIXct(paste('2000-01-01',max(limtes$LIMITE_SUPERIOR_MANHA)), tz='GMT')
  
  semana <- as.numeric(format(as.Date(date_chosen), "%W"))
  
  colabsSemanaCP <- matriz_colab_semana %>% 
    dplyr::filter(SEMANA %in% c(semana-1,semana,semana+1) ) %>% 
    dplyr::filter(EMP %in% (dfEMPloyee %>% dplyr::filter(Allocated!=T) %>% .$EMP))
  
  
  if (difftime(LIT,intervalData$start_time, units = 'hours') >= difftime(intervalData$end_time,LSM, units = 'hours')) {
    ## período da manha
    print("CP - periodo da manha")
    
    #existe algum colab com M nessa semana?
    colabsSemanaCP_M <- colabsSemanaCP %>% 
      dplyr::filter(SEMANA == semana & TOTAL_MANHA > 0) 
    
    if (nrow(colabsSemanaCP_M)==0) {
      #existe algum colab com M na semana-1 ou +1?
      colabsSemanaCP_M <- colabsSemanaCP %>% 
        dplyr::filter(SEMANA %in% c(semana-1,semana+1) & TOTAL_MANHA == 0 & TOTAL_TARDE > 0)
      
      if (nrow(colabsSemanaCP_M)==0) {
        colabsSemanaCP_M <- colabsSemanaCP %>% 
          dplyr::filter(SEMANA == semana)
      }
    }
    
    colabsSemanaCP_M <- colabsSemanaCP_M %>% #dplyr::filter(EMP=='5017444')
      slice(sample(1:nrow(colabsSemanaCP_M),1))
    
    #atualiza intervalo para ser so manha
    intervalData$end_time <- LSM
    intervalData$duration <- difftime(LSM,intervalData$start_time, units = 'hours')
    
    
    dfRes <- atribuirHorarioContinuos_CP(date_chosen, week, month, year, dfTest, 
                                         colabHours %>% dplyr::filter(EMP == colabsSemanaCP_M$EMP) %>% dplyr::mutate(day_type='M'), 
                                         class, collaborator_tibbles, 
                                         ColabData %>% dplyr::filter(EMP == colabsSemanaCP_M$EMP),  
                                         tipo_cp='CP',
                                         intervalData)
    dfTest <- dfRes[[1]]
    daily_dataframe <- dfRes[[2]]
    collaborator_tibbles <- dfRes[[3]]
    dfEMPloyee <-  dfEMPloyee %>% 
      dplyr::filter(!(EMP %in% dfRes[[4]]$EMP)) %>% 
      dplyr::bind_rows(dfRes[[4]])
    
    if (nrow(dfRes[[4]])>0) {
      matriz_colab_dia_turno <- matriz_colab_dia_turno %>% 
        dplyr::bind_rows(
          data.frame(
            EMPLOYEE_ID = dfRes[[4]]$EMP, 
            SCHEDULE_DT = rep(date_chosen, length(dfRes[[4]]$EMP)),
            OPTION_TYPE = rep('P', length(dfRes[[4]]$EMP)),
            OPTION_C1 = rep('C', length(dfRes[[4]]$EMP)),
            OPTION_N1 = NA_integer_,
            stringsAsFactors = FALSE
          )
        )
    }
    
  } else if (difftime(LIT,intervalData$start_time, units = 'hours') < difftime(intervalData$end_time,LSM, units = 'hours')){
    ##periodo da tarde
    print("CP - periodo da tarde")
    
    #existe algum colab com M nessa semana?
    colabsSemanaCP_T <- colabsSemanaCP %>% 
      dplyr::filter(SEMANA == semana & TOTAL_TARDE > 0)
    
    if (nrow(colabsSemanaCP_T)==0) {
      #existe algum colab com M na semana-1 ou +1?
      colabsSemanaCP_T <- colabsSemanaCP %>% 
        dplyr::filter(SEMANA %in% c(semana-1,semana+1) & TOTAL_TARDE == 0 & TOTAL_MANHA > 0)
      
      if (nrow(colabsSemanaCP_T)==0) {
        colabsSemanaCP_T <- colabsSemanaCP %>% 
          dplyr::filter(SEMANA == semana)
      }
    }
    
    colabsSemanaCP_T <- colabsSemanaCP_T %>% 
      slice(sample(1:nrow(colabsSemanaCP_T),1))
    
    #atualiza intervalo para ser so tarde
    intervalData$start_time <- LIT
    intervalData$duration <- difftime(intervalData$end_time, LIT, units = 'hours')
    
    # colabHours[colabHours$EMP == colabsSemanaCP_T$EMP,]$hora_in <- format(as.POSIXct(ColabData[ColabData$EMP == colabsSemanaCP_T$EMP, "H_TT_IN"], format = "%H:%M"), "%H:%M")
    # colabHours[colabHours$EMP == colabsSemanaCP_T$EMP,]$hora_out <- format(as.POSIXct(ColabData[ColabData$EMP == colabsSemanaCP_T$EMP, "H_TT_OUT"], format = "%H:%M"), "%H:%M")
    if(colabHours[colabHours$EMP == colabsSemanaCP_T$EMP,]$fixo_semana ==F){
      horas <- adjust_end_time(format(as.POSIXct(ColabData[ColabData$EMP == colabsSemanaCP_T$EMP, "H_TT_IN"], format = "%H:%M"), "%H:%M:%S"),
                               format(as.POSIXct(ColabData[ColabData$EMP == colabsSemanaCP_T$EMP, "H_TT_OUT"], format = "%H:%M"), "%H:%M:%S"))
      
      hh_out <- format(min(closing_timestamps,horas[[2]]-as.difftime(15, units = "mins")),'%Y-%m-%d %H:%M')
      
      ## sem horario para turno da tarde
      if (hh_out < '2000-01-01 00:00') {
        erroLogs <<- c(erroLogs,paste("sem horario para turno da tarde",date_chosen,colabsSemanaCP_T$EMP ))
        #dfEMPloyee[dfEMPloyee$EMP==colabsSemanaCP_T$EMP,]$Allocated <- T
        #return(list(dfTest,daily_dataframe,collaborator_tibbles,dfEMPloyee,matriz_colab_dia_turno))
        colabHours[colabHours$EMP == colabsSemanaCP_T$EMP,]$day_type <- 'M'
      } else{
        # colabHours[colabHours$EMP == colabsSemanaCP_T$EMP,]$hora_in <- format(horas[[1]],'%Y-%m-%d %H:%M')
        # colabHours[colabHours$EMP == colabsSemanaCP_T$EMP,]$hora_out <- format(min(closing_timestamps,horas[[2]]-as.difftime(15, units = "mins")),'%Y-%m-%d %H:%M')
        # colabHours[colabHours$EMP == colabsSemanaCP_T$EMP,]$day_type <- 'T'
        print("nova versao tarde")
        colabHours[colabHours$EMP == colabsSemanaCP_T$EMP,]$hora_in <- format(horas[[1]])
        colabHours[colabHours$EMP == colabsSemanaCP_T$EMP,]$hora_out <- format(min(closing_timestamps,horas[[2]]-as.difftime(15, units = "mins")))

        cc_selected <- colabHours[colabHours$EMP == colabsSemanaCP_T$EMP,]
        cc_selected$hora_in <- as.POSIXct(cc_selected$hora_in, tz='GMT')
        cc_selected$hora_out <- as.POSIXct(cc_selected$hora_out, tz='GMT')
        
        cc_selected <- checkInterjornada(cc_selected, date_chosen,interjornadas)

        colabHours[colabHours$EMP == colabsSemanaCP_T$EMP,]$hora_in <- format(cc_selected$hora_in,'%Y-%m-%d %H:%M')
        colabHours[colabHours$EMP == colabsSemanaCP_T$EMP,]$hora_out <- format(cc_selected$hora_out-as.difftime(15, units = "mins"),'%Y-%m-%d %H:%M')
        colabHours[colabHours$EMP == colabsSemanaCP_T$EMP,]$day_type <- 'T'
      }
      
    }
    print(paste("colab:",colabsSemanaCP_T$EMP))
    
    dfRes <- atribuirHorarioContinuos_CP(date_chosen, week, month, year, dfTest, 
                                         colabHours %>% dplyr::filter(EMP == colabsSemanaCP_T$EMP),# %>% dplyr::mutate(day_type='T'), 
                                         class, collaborator_tibbles, 
                                         ColabData %>% dplyr::filter(EMP == colabsSemanaCP_T$EMP),  
                                         tipo_cp='CP',
                                         intervalData)
    dfTest <- dfRes[[1]]
    daily_dataframe <- dfRes[[2]]
    collaborator_tibbles <- dfRes[[3]]
    dfEMPloyee <-  dfEMPloyee %>% 
      dplyr::filter(!(EMP %in% dfRes[[4]]$EMP)) %>% 
      dplyr::bind_rows(dfRes[[4]])
    
    if (nrow(dfRes[[4]])>0){
      matriz_colab_dia_turno <- matriz_colab_dia_turno %>% 
        dplyr::bind_rows(
          data.frame(
            EMPLOYEE_ID = dfRes[[4]]$EMP, 
            SCHEDULE_DT = rep(date_chosen, length(dfRes[[4]]$EMP)),
            OPTION_TYPE = rep('P', length(dfRes[[4]]$EMP)),
            OPTION_C1 = rep('C', length(dfRes[[4]]$EMP)),
            OPTION_N1 = NA_integer_,
            stringsAsFactors = FALSE
          )
        )
    }
    
  } else{
    print(avaliarErro)
  }
  
  
  
  return(list(dfTest,daily_dataframe,collaborator_tibbles,dfEMPloyee,matriz_colab_dia_turno))
  
}





atribuiMoTFixos <- function(date_chosen,colabHours,saveDia,dfTest,ColabData,matriz_colab_semana){
  colabHoursFixos <- colabHours %>% 
    dplyr::filter(tipo_hor=='F', Allocated == F)
  
  if (nrow(colabHoursFixos)>0) {
    
    
    colabHoursFixos$Allocated <- ifelse(colabHoursFixos$fixo_semana,TRUE,FALSE)
    
    for (emp_id in colabHoursFixos$EMP) {
      if(colabHoursFixos[colabHoursFixos$EMP == emp_id,]$Allocated == TRUE){
        allocated_col <- paste0("EMPloyee_", emp_id)
        allocation_row <- saveDia[saveDia$EMP == emp_id,]
        transposed_row <- t(allocation_row[,-1])
        dfTest[, allocated_col] <- transposed_row[1:nrow(dfTest)]
      }
    }
    
    dfEMPloyee <- colabHoursFixos %>%
      dplyr::filter(Allocated != T)
    
    while (any(!dfEMPloyee$Allocated)) {
      
      intervalData <- getIntervalCobrirEntreMinimoIdealNew(dfTest)
      
      limtes <- ColabData %>% 
        dplyr::select(EMP,LIMITE_SUPERIOR_MANHA,LIMITE_INFERIOR_TARDE) %>% 
        merge(dfEMPloyee)
      
      LIT <- as.POSIXct(paste('2000-01-01',max(limtes$LIMITE_INFERIOR_TARDE)), tz='GMT')
      LSM <- as.POSIXct(paste('2000-01-01',max(limtes$LIMITE_SUPERIOR_MANHA)), tz='GMT')
      
      semana <- as.numeric(format(as.Date(date_chosen), "%W"))
      
      colabsSemanaCP <- matriz_colab_semana %>% 
        dplyr::filter(SEMANA %in% c(semana-1,semana,semana+1) ) %>% 
        dplyr::filter(EMP %in% (dfEMPloyee %>% dplyr::filter(Allocated!=T) %>% .$EMP))
      
      
      if (is.null(intervalData)) {
        
        colabsSemanaCP_M <- colabsSemanaCP %>% 
          slice(sample(1:nrow(colabsSemanaCP),1))
        
        colabHours_select <- colabHours %>%
          dplyr::filter(EMP == colabsSemanaCP_M$EMP) %>% dplyr::mutate(day_type='M')
        
        intervalo <- seq(from = as.POSIXct(colabHours_select$hora_in),# format = "%H:%M"),
                         to = as.POSIXct(colabHours_select$hora_out),# format = "%H:%M"),
                         by = "15 mins")
        intervalo <- format(intervalo, '%Y-%m-%d %H:%M')
        
        allocated_col <- paste0("EMPloyee_", colabsSemanaCP_M$EMP)
        
        #limpa o que vinha atribuir fixos
        saveDia[saveDia$EMP == colabsSemanaCP_M$EMP, -1] <- 0
        saveDia[saveDia$EMP == colabsSemanaCP_M$EMP, intervalo] <- 1
        
        allocation_row <- saveDia[saveDia$EMP == colabsSemanaCP_M$EMP,]
        transposed_row <- t(allocation_row[,-1])
        dfTest[, allocated_col] <- transposed_row[1:nrow(dfTest)]
        
        dfEMPloyee[dfEMPloyee$EMP == colabsSemanaCP_M$EMP,]$Allocated <- T
        
      } else{
        if (difftime(LIT,intervalData$start_time, units = 'hours') >= difftime(intervalData$end_time,LSM, units = 'hours')) {
          ## período da manha
          print("CP - período da manha")
          
          #existe algum colab com M nessa semana?
          colabsSemanaCP_M <- colabsSemanaCP %>% 
            dplyr::filter(SEMANA == semana & TOTAL_MANHA > 0) 
          
          if (nrow(colabsSemanaCP_M)==0) {
            #existe algum colab com M na semana-1 ou +1?
            colabsSemanaCP_M <- colabsSemanaCP %>% 
              dplyr::filter(SEMANA %in% c(semana-1,semana+1) & TOTAL_MANHA == 0 & TOTAL_TARDE > 0)
            
            if (nrow(colabsSemanaCP_M)==0) {
              colabsSemanaCP_M <- colabsSemanaCP %>% 
                dplyr::filter(SEMANA == semana)
            }
          }
          
          colabsSemanaCP_M <- colabsSemanaCP_M %>% 
            slice(sample(1:nrow(colabsSemanaCP_M),1))
          
          
          colabHours_select <- colabHours %>%
            dplyr::filter(EMP == colabsSemanaCP_M$EMP) %>% dplyr::mutate(day_type='M')
          
          intervalo <- seq(from = as.POSIXct(colabHours_select$hora_in),# format = "%H:%M"),
                           to = as.POSIXct(colabHours_select$hora_out),# format = "%H:%M"),
                           by = "15 mins")
          intervalo <- format(intervalo, '%Y-%m-%d %H:%M')
          
          allocated_col <- paste0("EMPloyee_", colabsSemanaCP_M$EMP)
          
          #limpa o que vinha atribuir fixos
          saveDia[saveDia$EMP == colabsSemanaCP_M$EMP, -1] <- 0
          saveDia[saveDia$EMP == colabsSemanaCP_M$EMP, intervalo] <- 1
          
          allocation_row <- saveDia[saveDia$EMP == colabsSemanaCP_M$EMP,]
          transposed_row <- t(allocation_row[,-1])
          dfTest[, allocated_col] <- transposed_row[1:nrow(dfTest)]
          
          dfEMPloyee[dfEMPloyee$EMP == colabsSemanaCP_M$EMP,]$Allocated <- T
          dfEMPloyee[dfEMPloyee$EMP == colabsSemanaCP_M$EMP,]$day_type <- 'M'
          
        } else if (difftime(LIT,intervalData$start_time, units = 'hours') < difftime(intervalData$end_time,LSM, units = 'hours')){
          ##periodo da tarde
          print("CP - período da tarde")
          
          #existe algum colab com M nessa semana?
          colabsSemanaCP_T <- colabsSemanaCP %>% 
            dplyr::filter(SEMANA == semana & TOTAL_TARDE > 0)
          
          if (nrow(colabsSemanaCP_T)==0) {
            #existe algum colab com M na semana-1 ou +1?
            colabsSemanaCP_T <- colabsSemanaCP %>% 
              dplyr::filter(SEMANA %in% c(semana-1,semana+1) & TOTAL_TARDE == 0 & TOTAL_MANHA > 0)
            
            if (nrow(colabsSemanaCP_T)==0) {
              colabsSemanaCP_T <- colabsSemanaCP %>% 
                dplyr::filter(SEMANA == semana)
            }
          }
          
          colabsSemanaCP_T <- colabsSemanaCP_T %>% 
            slice(sample(1:nrow(colabsSemanaCP_T),1))
          
          colabHours_select <- colabHours %>%
            dplyr::filter(EMP == colabsSemanaCP_T$EMP) %>% dplyr::mutate(day_type='T')
          print("nova versao tarde motFix")
          # colabHours_select$hora_in <- format(as.POSIXct(ColabData[ColabData$EMP == colabsSemanaCP_T$EMP, "H_TT_IN"], format = "%H:%M"), "%Y-%m-%d %H:%M")
          # colabHours_select$hora_out <- format(as.POSIXct(ColabData[ColabData$EMP == colabsSemanaCP_T$EMP, "H_TT_OUT"], format = "%H:%M"), "%Y-%m-%d %H:%M")
          if(colabHours_select$fixo_semana ==F){
            horas <- adjust_end_time(format(as.POSIXct(ColabData[ColabData$EMP == colabsSemanaCP_T$EMP, "H_TT_IN"], format = "%H:%M"), "%H:%M:%S"),
                                     format(as.POSIXct(ColabData[ColabData$EMP == colabsSemanaCP_T$EMP, "H_TT_OUT"], format = "%H:%M"), "%H:%M:%S"))
            # hh_in <- format(horas[[1]],'%Y-%m-%d %H:%M')
            hh_out <- format(min(closing_timestamps,horas[[2]]-as.difftime(15, units = "mins")),'%Y-%m-%d %H:%M')
            
            
            
            ## sem horario para turno da tarde
            if (hh_out < '2000-01-01 00:00') {
              erroLogs <<- c(erroLogs,paste("sem horario para turno da tarde",date_chosen, colabsSemanaCP_T$EMP))
              # dfEMPloyee[dfEMPloyee$EMP == colabsSemanaCP_T$EMP,]$Allocated <- T
              # next
              dfEMPloyee[dfEMPloyee$EMP == colabsSemanaCP_T$EMP,]$day_type <- 'M'
            } else{
              
              colabHours_select$hora_in <- horas[[1]]
              colabHours_select$hora_out <- min(closing_timestamps,horas[[2]]-as.difftime(15, units = "mins"))
              
              
              colabHours_select <- checkInterjornada(colabHours_select, date_chosen,interjornadas)
              
              colabHours_select$hora_in <- format(colabHours_select$hora_in,'%Y-%m-%d %H:%M')
              colabHours_select$hora_out <- format(colabHours_select$hora_out-as.difftime(15, units = "mins"),'%Y-%m-%d %H:%M')
              dfEMPloyee[dfEMPloyee$EMP == colabsSemanaCP_T$EMP,]$day_type <- 'T'
            }
          }
          
          intervalo <- seq(from = as.POSIXct(colabHours_select$hora_in),# format = "%H:%M"),
                           to = as.POSIXct(colabHours_select$hora_out),# format = "%H:%M"),
                           by = "15 mins")
          intervalo <- format(intervalo, '%Y-%m-%d %H:%M')
          
          allocated_col <- paste0("EMPloyee_", colabsSemanaCP_T$EMP)
          
          #limpa o que vinha atribuir fixos
          saveDia[saveDia$EMP == colabsSemanaCP_T$EMP, -1] <- 0
          saveDia[saveDia$EMP == colabsSemanaCP_T$EMP, intervalo] <- 1
          
          allocation_row <- saveDia[saveDia$EMP == colabsSemanaCP_T$EMP,]
          transposed_row <- t(allocation_row[,-1])
          dfTest[, allocated_col] <- transposed_row[1:nrow(dfTest)]
          
          dfEMPloyee[dfEMPloyee$EMP == colabsSemanaCP_T$EMP,]$Allocated <- T
          
        }
      }
      
      
      
      
      
    }
    
    colabHoursFixos <- colabHoursFixos %>% 
      dplyr::filter(!(EMP %in% dfEMPloyee$EMP)) %>% 
      dplyr::bind_rows(dfEMPloyee)
    
    
    
    # testResults <- dfTest #<- testResults
    # for(i in 1:(nrow(colabHoursFixos))){ #:nrow(dfEMPloyee)
    #   pausasEMP<- dfEMPloyee
    #   fsddss <<- colabHoursFixos
    #   if(colabHoursFixos[i,]$Allocated == FALSE){
    #     next
    #   } 
    #   # if(dfEMPloyee[i,]$tipo_hor == 'FG'){
    #   #   next
    #   # }
    #   col_name <- paste0("EMPloyee_",colabHoursFixos[i,'EMP'])
    #   ###print(col_name)
    #   saveTesttas <- dfTest
    #   col <- dfTest %>%  select(timestamps, Alocado,Ideal_por_Cobrir, Minimo_Por_cobrir ,col_name)
    #   pause_index <- atribuirPausas(col,colabHoursFixos,dfTest)
    #   if(!is.null(pause_index)){
    #     for(index in pause_index){
    #       dfTest[index, col_name] <- 'P' 
    #       dfTest[index, 'Ideal_por_Cobrir'] <- dfTest[index, 'Ideal_por_Cobrir'] + 1
    #       dfTest[index, 'Minimo_Por_cobrir'] <- dfTest[index, 'Minimo_Por_cobrir'] + 1
    #       dfTest[index, 'Alocado'] <- dfTest[index, 'Alocado'] - 1
    #     }
    #   }
    #   
    #   }
  }
  return(list(dfTest,colabHoursFixos))
}

