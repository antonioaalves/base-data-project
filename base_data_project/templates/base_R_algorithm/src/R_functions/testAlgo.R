# library(dplyr)
# setwd("C:/algoritmo/")
# ColabData <- matriz_colaborador
# colabHours <- dayResult$df1
# Matriz_Dia <- dayResult$df2
# Matriz_ideal_min <- dayResult$df3
# date_chosen <- select_day
# # collaborator_tibbles_bk <- collaborator_tibbles <- collaborator_tibbles_bk
# #collaborator_tibbles <- collaborator_tibbles_bk
# classIndex <- class
schedulerMain <- function(ColabData, colabHours, Matriz_Dia, Matriz_ideal_min,date_chosen,collaborator_tibbles, classIndex,matriz_colab_semana,matriz_colab_dia_turno){
  # source('algoFuncs.R')
  
  ##########################################################
  #         Set variables for implicacoes tibble           #
  ##########################################################
  week <- week(date_chosen)
  month <- month(date_chosen)
  year <- year(date_chosen)
  ##########################################################
  
  
  Matriz_ideal_min <- t.data.frame(Matriz_ideal_min) 
  Matriz_ideal_min <- as.data.frame(cbind(timestamps = rownames(Matriz_ideal_min), Matriz_ideal_min))
  Matriz_ideal_min$timestamps <- as.POSIXct(Matriz_ideal_min$timestamps, format = '%Y-%m-%d %H:%M')
  
  # Find opening timestamps
  opening_timestamps <<- getOpening(date_chosen)
  # if (length(opening_timestamps)==0) {
  #   opt <- colabHours %>% 
  #     dplyr::mutate(hora_in = as.POSIXct(hora_in,format='%Y-%m-%d %H:%M', tz = 'GMT'))
  #   opening_timestamps <<- min(opt$hora_in) 
  # }
  # Find closing timestamps
  closing_timestamps <<- getClosing(date_chosen)
  # if (length(closing_timestamps)==0) {
  #   opt <- colabHours %>% 
  #     dplyr::mutate(hora_out = as.POSIXct(hora_out,format='%Y-%m-%d %H:%M', tz = 'GMT'))
  #   closing_timestamps <<- max(opt$hora_out) 
  # }
  # closing_timestamps <<- as.POSIXct('2000-01-01 22:00:00')
  
  # Display the opening and closing timestamps
  cat("Opening Timestamps:\n")
  print(opening_timestamps)
  
  cat("\nClosing Timestamps:\n")
  print(closing_timestamps)
  colabHours$Allocated <- ifelse(colabHours$tipo_hor=='F' & colabHours$day_type!='MoT',TRUE,FALSE)
  
  saveDia <- Matriz_Dia
  dfTest <- Matriz_ideal_min
  
  for (emp_id in colabHours$EMP) {
    if(colabHours[colabHours$EMP == emp_id,]$Allocated == TRUE){
      allocated_col <- paste0("EMPloyee_", emp_id)
      allocation_row <- saveDia[saveDia$EMP == emp_id,]
      transposed_row <- t(allocation_row[,-1])
      dfTest[, allocated_col] <- transposed_row[1:nrow(dfTest)]
    }
  }
  
  
  # colabHours <- colabHours %>% 
  #   merge(ColabData %>% 
  #           dplyr::select(EMP,LIMITE_SUPERIOR_MANHA,LIMITE_INFERIOR_TARDE)) %>% 
  #   dplyr::mutate(LIT = as.POSIXct(paste('2000-01-01',LIMITE_INFERIOR_TARDE), tz='GMT'),
  #                 LSM = as.POSIXct(paste('2000-01-01',LIMITE_SUPERIOR_MANHA), tz='GMT')) %>% 
  #   dplyr::mutate(day_type = case_when(
  #     tipo_hor == 'FE' & day_type =='MoT' & difftime(LIT,hora_in, units = 'hours') >= difftime(hora_out,LSM, units = 'hours') ~ 'M',
  #     tipo_hor == 'FE' & day_type =='MoT' & difftime(LIT,hora_in, units = 'hours') < difftime(hora_out,LSM, units = 'hours') ~ 'T',
  #     T ~ day_type
  #   )) %>% dplyr::select(-c(LIMITE_SUPERIOR_MANHA,LIMITE_INFERIOR_TARDE,LIT,LSM))
  
  num_unallocated_EMPloyees <- sum(!colabHours$Allocated)
  time1_1 <- Sys.time()
  #cat("Number of unallocated EMPloyees:", num_unallocated_EMPloyees, "\n")
  dfRes <- atribuirHorarioContinuos(date_chosen, week, month, year, dfTest, colabHours, class, collaborator_tibbles, ColabData, tipo_cp='C')
  time1_2 <- Sys.time()
  dfTest <- dfRes[[1]]
  daily_dataframe <- dfRes[[2]]
  collaborator_tibbles <- dfRes[[3]]
  colabHours <-  colabHours %>% 
    dplyr::filter(!(EMP %in% dfRes[[4]]$EMP)) %>% 
    dplyr::bind_rows(dfRes[[4]])
  # ##print(daily_dataframe)
  
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
  
  #ATRIBUIR MoT FIXOS------------------------------------------------------
  dfRes <- atribuiMoTFixos(date_chosen,colabHours,saveDia,dfTest,ColabData,matriz_colab_semana)
  
  dfTest <- dfRes[[1]]
  colabHours <-  colabHours %>% 
    dplyr::filter(!(EMP %in% dfRes[[2]]$EMP)) %>% 
    dplyr::bind_rows(dfRes[[2]])
  
  if (nrow(dfRes[[2]])>0) {
    matriz_colab_dia_turno <- matriz_colab_dia_turno %>% 
      dplyr::bind_rows(
        data.frame(
          EMPLOYEE_ID = dfRes[[2]]$EMP, 
          SCHEDULE_DT = rep(date_chosen, length(dfRes[[2]]$EMP)),
          OPTION_TYPE = rep('P', length(dfRes[[2]]$EMP)),
          OPTION_C1 = rep('C', length(dfRes[[2]]$EMP)),
          OPTION_N1 = NA_integer_,
          stringsAsFactors = FALSE
        )
      ) 
  }
  
  #ATRIBUIR MoT ou P -> CP------------------------------------------------------
  #avalia as bossas + CP's-------------------------------------------------------
  dfEMPloyee <- colabHours %>%
    dplyr::filter(Allocated != T) %>%
    dplyr::filter( day_type =='MoT') 
  
  
  if (nrow(dfEMPloyee)>0) {
    while (any(!dfEMPloyee$Allocated)) {
      
      
      intervalData <- getIntervalCobrirEntreMinimoIdealNew(dfTest)
      
      #existem bossas
      if (!is.null(intervalData) && length(intervalData)>3) {
        
        bossasIdeais <- sum(intervalData$avgIdealL + intervalData$avgIdealR)
        
        dfEMPloyee2 <- dfEMPloyee %>% 
          dplyr::filter(Allocated != T, partido_continuado=='CP') #%>%
        # dplyr::mutate(day_type='P')
        
        #pelo menos 1colab tem de ser partido
        if (bossasIdeais > nrow(dfEMPloyee %>% dplyr::filter(Allocated != T)) & nrow(dfEMPloyee2)>0) {
          
          print("bossas partido")
          # print(bossasP)
          
          
          
          #existe algum colab sem M ou T nessa semana?
          semana <- as.numeric(format(as.Date(date_chosen), "%W"))
          colabsSemanaCP <- matriz_colab_semana %>% 
            dplyr::filter(SEMANA %in% c(semana-1,semana,semana+1) ) %>% 
            dplyr::filter(EMP %in% dfEMPloyee2$EMP)
          
          colabsSemanaCP_M <- colabsSemanaCP %>% 
            dplyr::filter(SEMANA == semana & (TOTAL_MANHA == 0 | TOTAL_TARDE == 0))
          
          if (nrow(colabsSemanaCP_M)==0) {
            #escolhe colab com menos PARTIDOS
            colabsSemanaCP_M <- colabsSemanaCP %>% 
              dplyr::filter(SEMANA == semana) %>% 
              dplyr::filter(TOTAL_PARTIDO == min(TOTAL_PARTIDO)) %>% 
              dplyr::arrange(desc(TOTAL_CONT)) %>% slice(1)
            
            if (nrow(colabsSemanaCP_M)==0) {
              colabsSemanaCP_M <- colabsSemanaCP %>% 
                dplyr::filter(SEMANA == semana)
            }
          }
          
          colabsSemanaCP_M <- colabsSemanaCP_M %>% 
            dplyr::filter(TOTAL_PARTIDO == min(TOTAL_PARTIDO)) %>% 
            dplyr::arrange(desc(TOTAL_CONT)) %>% slice(1)
          
          
          dfEMPloyee2 <- dfEMPloyee2 %>% 
            dplyr::filter(EMP == colabsSemanaCP_M$EMP) %>% 
            dplyr::mutate(day_type='P')
          
          resPartidos <- atribuirHorarioPartidos(date_chosen, week, month, year, dfTest, dfEMPloyee2, class, collaborator_tibbles, ColabData)
          aiiii <<- resPartidos #<- aiiii
          if (length(resPartidos) == 1 ) {
            if(resPartidos=='C'){
              print("bossas continuado")
              if (intervalData$avgIdealL < intervalData$avgIdealR  ) {
                intervalData$start_time <- intervalData$start_time2
                intervalData$end_time <- intervalData$end_time2
                intervalData$duration <- intervalData$duration2
              }
              
              dfRes <- atribuirHorarioContinuos_CP_Pai(dfEMPloyee,date_chosen, week, month, year, dfTest, colabHours, class, collaborator_tibbles, ColabData,intervalData,matriz_colab_semana,matriz_colab_dia_turno)
              
              dfTest <- dfRes[[1]]
              daily_dataframe <- dfRes[[2]]
              collaborator_tibbles <- dfRes[[3]]
              dfEMPloyee <-  dfRes[[4]]
              matriz_colab_dia_turno <- dfRes[[5]]
            }else print(killthisshit)
          } else{
            # print(atribuipartidoooooooooooooooooooooooooooooooooooooo)
            dfTest <- resPartidos[[1]]
            daily_dataframe <- resPartidos[[2]]
            collaborator_tibbles <- resPartidos[[3]]
            
            dfEMPloyee <-  dfEMPloyee %>% 
              dplyr::filter(!(EMP %in%  resPartidos[[4]]$EMP)) %>% 
              dplyr::bind_rows( resPartidos[[4]])
            
            matriz_colab_semana <- matriz_colab_semana %>% 
              dplyr::mutate(TOTAL_PARTIDO =
                              case_when(
                                EMP == resPartidos[[4]]$EMP & SEMANA == semana ~ TOTAL_PARTIDO+1,
                                T ~ TOTAL_PARTIDO
                              )
              ) 
            
            if (nrow(resPartidos[[4]])>0) {
              matriz_colab_dia_turno <- matriz_colab_dia_turno %>% 
                dplyr::bind_rows(
                  data.frame(
                    EMPLOYEE_ID = resPartidos[[4]]$EMP, 
                    SCHEDULE_DT = rep(date_chosen, length(resPartidos[[4]]$EMP)),
                    OPTION_TYPE = rep('P', length(resPartidos[[4]]$EMP)),
                    OPTION_C1 = rep('P', length(resPartidos[[4]]$EMP)),
                    OPTION_N1 = NA_integer_,
                    stringsAsFactors = FALSE
                  )
                )
            }
          }
          
          
        } else {
          
          print("bossas continuado")
          if (intervalData$avgIdealL < intervalData$avgIdealR  ) {
            intervalData$start_time <- intervalData$start_time2
            intervalData$end_time <- intervalData$end_time2
            intervalData$duration <- intervalData$duration2
          }
          
          dfRes <- atribuirHorarioContinuos_CP_Pai(dfEMPloyee,date_chosen, week, month, year, dfTest, colabHours, class, collaborator_tibbles, ColabData,intervalData,matriz_colab_semana,matriz_colab_dia_turno)
          
          dfTest <- dfRes[[1]]
          daily_dataframe <- dfRes[[2]]
          collaborator_tibbles <- dfRes[[3]]
          dfEMPloyee <-  dfRes[[4]]
          matriz_colab_dia_turno <- dfRes[[5]]
          
        }
        
      } else if (!is.null(intervalData)){
        dfRes <- atribuirHorarioContinuos_CP_Pai(dfEMPloyee,date_chosen, week, month, year, dfTest, colabHours, class, collaborator_tibbles, ColabData,intervalData,matriz_colab_semana,matriz_colab_dia_turno)
        
        dfTest <- dfRes[[1]]
        daily_dataframe <- dfRes[[2]]
        collaborator_tibbles <- dfRes[[3]]
        dfEMPloyee <-  dfRes[[4]]
        matriz_colab_dia_turno <- dfRes[[5]]
      } else{
        print("cobrir excessos")
        # print(excesso)
        excess <<- excess+1
        # print(excessssso)
        ##intervalo NULL -> ja nao ha nada por cobrir
        #avaliar exedenet
        ##exite algum colab em falta e com turno ja alocado
        ## avaliar onde ideias são predominantes M ou T
        
        dfEMPloyee2 <- dfEMPloyee %>% 
          dplyr::filter(Allocated != T)
        
        intervalData$start_time <- dfTest[min(which(dfTest$Ideal>0)),]$timestamps
        if (is.na(intervalData$start_time)) {
          intervalData$start_time <- opening_ideias_timestamps
        }
        intervalData$end_time <- dfTest[max(which(dfTest$Ideal>0)),]$timestamps
        if (is.na(intervalData$end_time)) {
          intervalData$end_time <- closing_ideias_timestamps
        }
        intervalData$duration <- difftime(intervalData$end_time,intervalData$start_time, units = "hours")
        
        limtes <- ColabData %>% 
          dplyr::select(EMP,LIMITE_SUPERIOR_MANHA,LIMITE_INFERIOR_TARDE) %>% 
          merge(dfEMPloyee2)
        
        LIT <- as.POSIXct(max(limtes$LIMITE_INFERIOR_TARDE), format="%H:%M", tz='GMT')
        LSM <- as.POSIXct(max(limtes$LIMITE_SUPERIOR_MANHA), format="%H:%M", tz='GMT')
        
        maiorIdeal <- dfTest[min(which(dfTest$Ideal==max(dfTest$Ideal))),]$timestamps
        
        semana <- as.numeric(format(as.Date(date_chosen), "%W"))
        
        colabsSemanaCP <- matriz_colab_semana %>% 
          dplyr::filter(SEMANA %in% c(semana-1,semana,semana+1) ) %>% 
          dplyr::filter(EMP %in% (dfEMPloyee2 %>% .$EMP))
        
        if (difftime(maiorIdeal,LIT, units = "hours") > difftime(LSM,maiorIdeal, units = "hours")  ) {
          ##tarde
          
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
            # horas <- adjust_end_time(format(as.POSIXct(ColabData[ColabData$EMP == colabsSemanaCP_T$EMP, "H_TT_IN"], format = "%H:%M"), "%H:%M:%S"),
            #                          format(as.POSIXct(ColabData[ColabData$EMP == colabsSemanaCP_T$EMP, "H_TT_OUT"], format = "%H:%M"), "%H:%M:%S"))
            # colabHours[colabHours$EMP == colabsSemanaCP_T$EMP,]$hora_in <- as.character(horas[[1]])
            # colabHours[colabHours$EMP == colabsSemanaCP_T$EMP,]$hora_out <- as.character(horas[[2]])
            
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
          
        } else{
          ##manha
          
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
        }
        
      }
      
      
    }
    
    matriz_colab_semana <- updateColabSemanaCont(date_chosen, matriz_colab_semana, dfTest, limitHourM='13:30', limitHourT='16:30')
  }
  
  
  # atribuir horarios_PARTIDOS ----------------------------------------------
  
  if (nrow(dfEMPloyee)>0) {
    colabHours <-  colabHours %>% 
      dplyr::filter(!(EMP %in% dfEMPloyee$EMP)) %>% 
      dplyr::bind_rows(dfEMPloyee)
  }
  
  dfEMPloyee <- colabHours %>% 
    dplyr::filter(Allocated != T) %>%
    dplyr::filter(day_type=='P')
  
  if (nrow(dfEMPloyee)>0) {
    print("---------------fazendo PARTIDOS---------------")
    time1_3 <- Sys.time()
    resPartidos <- atribuirHorarioPartidos(date_chosen, week, month, year, dfTest, colabHours, class, collaborator_tibbles, ColabData)
    time1_4 <- Sys.time()
    
    if (length(resPartidos) == 1 ) {
      if(resPartidos=='C'){
        print("-------------------NAO HA SUFICIENTES PARA P-----------------------")
        set_ProcessErrors(pathOS = pathFicheirosGlobal, user = wfm_user, 
                          fk_process = wfm_proc_id, 
                          type_error = 'E', process_type = 'atribuirHorarioPartidos', 
                          error_code = NA, 
                          description = 
                            #paste0('4.2 Subproceso ',childNumber,' - no hay horas para generar P para la fecha ',format(date_chosen)),
                            paste0('4.2 Subproceso ',childNumber,' - El empleado no tiene suficientes horas para generar los horarios partidos que tiene en el mapa.'),
                          employee_id = NA, schedule_day = date_chosen)
      }
    } else{
      colabHours <-  colabHours %>% 
        dplyr::filter(!(EMP %in%  resPartidos[[4]]$EMP)) %>% 
        dplyr::bind_rows( resPartidos[[4]])
      
      semana <- as.numeric(format(as.Date(date_chosen), "%W"))
      
      matriz_colab_semana <- matriz_colab_semana %>% 
        dplyr::mutate(TOTAL_PARTIDO =
                        case_when(
                          EMP %in% resPartidos[[4]]$EMP & SEMANA == semana ~ TOTAL_PARTIDO+1,
                          T ~ TOTAL_PARTIDO
                        )
        )
      
      if (nrow(resPartidos[[4]])>0) {
        matriz_colab_dia_turno <- matriz_colab_dia_turno %>% 
          dplyr::bind_rows(
            data.frame(
              EMPLOYEE_ID = resPartidos[[4]]$EMP, 
              SCHEDULE_DT = rep(date_chosen, length(resPartidos[[4]]$EMP)),
              OPTION_TYPE = rep('P', length(resPartidos[[4]]$EMP)),
              OPTION_C1 = rep('P', length(resPartidos[[4]]$EMP)),
              OPTION_N1 = NA_integer_,
              stringsAsFactors = FALSE
            )
          )
      }
      
      return(list(resPartidos[[1]],resPartidos[[2]],resPartidos[[3]], matriz_colab_semana,matriz_colab_dia_turno,colabHours))
    }
    
   
  }
  
  
  # dfTest,daily_dataframe,collaborator_tibbles
  # ##print(collaborator_tibbles)
  return(list(dfTest,daily_dataframe,collaborator_tibbles,matriz_colab_semana,matriz_colab_dia_turno,colabHours))
  # Display the updated EMPloyee data
  ###print(dfEMPloyee)
  
}




