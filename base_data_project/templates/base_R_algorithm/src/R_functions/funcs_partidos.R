
atribuirHorarioPartidos <- function(date_chosen, week, month, year, dfTest, colabHours, class, collaborator_tibbles, ColabData){
  dfEMPloyee <- colabHours %>% 
    dplyr::filter(day_type=='P'#partido_continuado == 'P'
    )
  print("Entering partidos")
  
  dfTest$Ideal_por_Cobrir <- as.integer(dfTest$Ideal_por_Cobrir)
  dfTest$Alocado <- as.integer(dfTest$Alocado)
  dfTest$Minimo_Por_cobrir <- as.integer(dfTest$Minimo_Por_cobrir)
  zeros <- 0
  minimos <- 0
  ideais <- 0
  
  
  while (any(!dfEMPloyee$Allocated)) {
    daily_dataframe$Dias_a_trabalhar[daily_dataframe$EMP %in% dfEMPloyee$EMP] <- TRUE
    #print(dfEMPloyee)
    
    aux_go_bkup <- 0
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
    
    intervalData <- getIntervalZeros(dfTest)
    
    #print(intervalData)
    if(is.null(intervalData)){
      #print("Getting minimos")
      intervalData <- getIntervalMinimos(dfTest)
      interval_flag = 1
      
      if(is.null(intervalData)){
        #print("Getting ideals")
        intervalData <- getIntervalCobrirEntreMinimoIdeal(dfTest)
        interval_flag = 2
        ideais <- ideais +1
        
        if(is.null(intervalData)){
          #print("Getting ideals")
          intervalData$start_time <- dfTest[min(which(dfTest$Ideal>0)),]$timestamps
          intervalData$end_time <- dfTest[max(which(dfTest$Ideal>0)),]$timestamps
          intervalData$duration <- difftime(intervalData$end_time,intervalData$start_time, units = "hours")
          
          aux_go_bkup <- 1
        }
      }else{
        minimos <- minimos +1
        
      }
    }else{
      zeros <- zeros +1
    }
    colabsToUse <- NULL
    colabChosen <- NULL
    print(intervalData)
    if (!is.null(intervalData)) {
      
      interTimestamps <- seq(intervalData$start_time, intervalData$end_time, by = "15 mins")
      ii <<- intervalData
      epl <<- dfEMPloyee
      cdt <<- ColabData
      dtt <<- dfTest
      itflag <<-interval_flag
      
      ######------------------------------------------------
      #slide 65 - + dificil:
      #3  # servico al cliente - como destino/origem
      #1  # informacio - so destino
      #2  # ser globo - so destino
      #4  # cajas amiga - como destino/origem
      #5  # restion hueca - so destino
      #6  # contabilidade - so destino
      
      ######------------------------------------------------
      #quando faixa de intervalo fora da faixa do colaborador
      #criar array com min_traba+min_DEsc e deslizar pelo array todo de timestamps
      # e selecionar as posições que ocupam os ideais com maior valor
      
      
      #----------------- 
      # atribuir 1o C, cP, P
      #hipotese
      #atribuir continuados
      #atribuir partidos
      # depois avaliar ideal por cobrir
      # existe bossas?
      # sim CP -> passa a P
      # o 1o partido que escolhe é o que tem menos partidos por escolher
      # nao CP -> passa a C
      # da preferencia a ser a ser continuo, quanto mais partidos mais prefenrecia a ser continuo
      # tem que ver os dias vizinho
      # se nao houver, atribui a sorte e depois tenta manter o turno na semana
      # temos de olhar 1o para nr de bossas e nr de colabs que ainda faltam atribuir
      
      colabsToUse <- selectColabPartido(intervalData,dfEMPloyee,ColabData,dfTest)
      
      
      #print(colabsToUse)
      if(!is.null(colabsToUse)){
        
        if (nrow(colabsToUse)>0) {
          if (is.na(colabsToUse$HORAS_TRAB_PARTIDO_SLOT_MIN) | colabsToUse$HORAS_TRAB_PARTIDO_SLOT_MIN==0) {
            set_ProcessErrors(pathOS = pathFicheirosGlobal, user = wfm_user, 
                              fk_process = wfm_proc_id, 
                              type_error = 'E', process_type = 'atribuirHorarioPartidos', 
                              error_code = NA, 
                              description = 
                                #paste0('4.4 Subproceso ',childNumber,' -colab ',colabsToUse$EMP," sin valor en 'HORAS_TRAB_PARTIDO_SLOT_MIN'- Informar a soporte."),
                                paste0('4.4 Subproceso ',childNumber,' El empleado',colabsToUse$EMP," con horario partido no tiene todos los campos para asignar horarios partidos rellenados en la vista de variables."),
                                
                              employee_id = NA, schedule_day = date_chosen)
            return("C")
          }
          
          if (is.na(colabsToUse$DESC_PARTIDOS_DURACAO_MIN) | colabsToUse$DESC_PARTIDOS_DURACAO_MIN==0) {
            set_ProcessErrors(pathOS = pathFicheirosGlobal, user = wfm_user, 
                              fk_process = wfm_proc_id, 
                              type_error = 'E', process_type = 'atribuirHorarioPartidos', 
                              error_code = NA, 
                              description = 
                                # paste0('4.4 Subproceso ',childNumber,' -colab ',colabsToUse$EMP," sin valor en 'DESC_PARTIDOS_DURACAO_MIN'- Informar a soporte."),
                                paste0('4.4 Subproceso ',childNumber,' El empleado',colabsToUse$EMP," con horario partido no tiene todos los campos para asignar horarios partidos rellenados en la vista de variables."),
                              employee_id = NA, schedule_day = date_chosen)
            return("C")
          }
          
          if (as.numeric(intervalData$duration) < colabsToUse$HORAS_TRAB_PARTIDO_SLOT_MIN*2+colabsToUse$DESC_PARTIDOS_DURACAO_MIN) {
            intervalData$start_time <- dfTest[min(which(dfTest$Ideal>0)),]$timestamps
            intervalData$end_time <- dfTest[max(which(dfTest$Ideal>0)),]$timestamps
            intervalData$duration <- difftime(intervalData$end_time,intervalData$start_time, units = "hours")
            
            interTimestamps <- seq(intervalData$start_time, intervalData$end_time, by = "15 mins")
          }
        }
        
        
        print("Trying to give horario")
        cc <<- colabsToUse
        cll <<- class
        cttb <<- collaborator_tibbles 
        colabChosen <- atribuirHorario_Partidos(colabsToUse, intervalData,class,date_chosen,collaborator_tibbles)
        # print(colabChosen)
        if(is.null(colabChosen)){
          print("Go for backup")
          
          ##nao encontrou colabs apra o intervalo, seleciona um a sorte
          # if (nrow(colabsToUse)==0) {
          #   colabsToUse <- ColabData %>% 
          #     dplyr::filter(EMP %in% dfEMPloyee$EMP) %>% 
          #     slice(sample(1:nrow(dfEMPloyee),1)) %>% str()
          # }
          
          ##nao encontrou colabs para o intervalo, vai alargar o intervalo para a faixa toda
          intervalData$start_time <- dfTest[min(which(dfTest$Ideal>0)),]$timestamps
          intervalData$end_time <- dfTest[max(which(dfTest$Ideal>0)),]$timestamps
          intervalData$duration <- difftime(intervalData$end_time,intervalData$start_time,units = "hours")
          
          interTimestamps <- seq(intervalData$start_time, intervalData$end_time, by = "15 mins")
          
          colabsToUse <- selectColabPartido(intervalData,dfEMPloyee,ColabData,dfTest)
          colabChosen <- atribuirHorario_Partidos(colabsToUse, intervalData,class,date_chosen,collaborator_tibbles)
          if(is.null(colabChosen)){
            
            colabChosen <- atribuirHorario_Partidos(colabsToUse, intervalData,1,date_chosen,collaborator_tibbles)
          }
          aux_go_bkup <- 1
        }
        
        testHora <- colabChosen
        collaborator_tibbles <- colabChosen[[2]]
        colabToUse <- colabChosen[[1]][[1]]
        slotsToGive <- colabChosen[[1]][[2]]
        
        
        colabsToUse <- colabChosen[[1]][[1]]
        horasTrab <- colabChosen[[1]][[2]]/4
        abc3 <<- colabsToUse
        abc4 <<- horasTrab
        # if (horasTrab < 6.5) {
        #   # print(hmmmmmm)
        #   return("C")
        # }
        print("define period limits")
        
        newPeriod <- data.frame(
          hora_in = max(as.POSIXct(colabsToUse$hora_in, format = '%Y-%m-%d %H:%M:%S', tz='GMT'), min(interTimestamps)),
          hora_out = min(as.POSIXct(colabsToUse$hora_out, format = '%Y-%m-%d %H:%M:%S' , tz='GMT'), max(interTimestamps))
        )
        
        peridoDiff <- as.numeric(difftime(newPeriod$hora_out,newPeriod$hora_in, units = "hours"))
        
        
        print("calculate ptc")
        abc <<- newPeriod
        abc2 <<- peridoDiff
        
        if (peridoDiff - colabsToUse$DESC_PARTIDOS_DURACAO_MIN > colabsToUse$HORAS_TRAB_VAL_CARGA & 
            horasTrab + colabsToUse$DESC_PARTIDOS_DURACAO_MIN <= peridoDiff) {
          
          ptc <- horasTrab + colabsToUse$DESC_PARTIDOS_DURACAO_MIN
          
        } else{
          if (peridoDiff - colabsToUse$DESC_PARTIDOS_DURACAO_MIN <= colabsToUse$HORAS_TRAB_VAL_CARGA) {
            
            ptc <- colabsToUse$HORAS_TRAB_VAL_CARGA + colabsToUse$DESC_PARTIDOS_DURACAO_MIN
            
          } else if ( horasTrab + colabsToUse$DESC_PARTIDOS_DURACAO_MIN > peridoDiff ) {
            ptc <- peridoDiff
          }
        }
        
        print("definir Hd.in e Hd.out")
        newHorario <- data.frame()
        #Caso 1 - p não é suficientemente amplo para acomodar carga mínima, ie. ptc excede o período p (ptc > período p)
        
        if ( ptc > peridoDiff) {
          caso1 <- newPeriod$hora_out-ptc*3600
          
          if ( caso1 >= newPeriod$hora_in) {
            newHorario <- data.frame(
              hora_in = caso1,
              hora_out = newPeriod$hora_out  
            )
            
          } else{
            newHorario <- data.frame(
              hora_in = as.POSIXct(colabsToUse$hora_in, format = '%Y-%m-%d %H:%M:%S', tz='GMT'),
              hora_out = as.POSIXct(colabsToUse$hora_in, format = '%Y-%m-%d %H:%M:%S', tz='GMT')+ptc*3600 
            )
          }
        }
        
        #Caso 2 – ptc = período p
        if ( ptc == peridoDiff) {
          newHorario <- data.frame(
            hora_in = newPeriod$hora_in,
            hora_out = newPeriod$hora_out  
          )
          
        }
        
        #Caso 3 - ptc  < período p   - mover “janela” ptc sobre período p para escolher a que cubra o maior número de frações com ideal por cobrir > 0
        if ( ptc < peridoDiff) {
          newHorario <- data.frame(
            hora_in = newPeriod$hora_in, 
            hora_out = newPeriod$hora_out
          )
        }
        
        newPeriodTimes <- seq(newHorario$hora_in, newHorario$hora_out, by = "15 mins")
        
        newdfTest <- dfTest %>% dplyr::filter(timestamps %in% newPeriodTimes)
        
        
        newdfTest <- newdfTest %>% 
          dplyr::mutate(
            Ideal_por_Cobrir = case_when(
              Ideal_por_Cobrir >= 1 ~ 1,
              T ~ 0 
            )
          )
        
        # Calcular a soma cumulativa
        #ptc <- 9.5
        granHorario <- ptc*60/15
        
        
        # somaCum <- soma_cumulativa_intervalo(newdfTest$Ideal_por_Cobrir, granHorario)
        # 
        # # Encontrar as posições onde o valor é máximo
        # pos_inicial_h <- which(somaCum == max(somaCum))
        # 
        # if (length(pos_inicial_h)>1) {
        #   pos_inicial_h <- pos_inicial_h[1]
        # }
        
        granSlotTrab_min <- colabsToUse$HORAS_TRAB_PARTIDO_SLOT_MIN*60/15
        granSlotTrab_max <- colabsToUse$HORAS_TRAB_PARTIDO_SLOT_MAX*60/15#4.5*60/15#
        granSlotDesc_min <- colabsToUse$DESC_PARTIDOS_DURACAO_MIN*60/15
        granSlotDesc_max <- colabsToUse$DESC_PARTIDOS_DURACAO_MAX*60/15
        valorMinPartido <- colabsToUse$HORAS_TRAB_VAL_CARGA*60/15
        
        limitSlotManha <- which(newdfTest$timestamps== as.POSIXct(paste('2000-01-01',colabsToUse$LIMITE_SUPERIOR_MANHA), format = '%Y-%m-%d %H:%M', tz='GMT'))
        limitSlotTarde <- which(newdfTest$timestamps== as.POSIXct(paste('2000-01-01',colabsToUse$LIMITE_INFERIOR_TARDE), format = '%Y-%m-%d %H:%M', tz='GMT'))
        
        if(granSlotTrab_min + granSlotTrab_min + granSlotDesc_min > granHorario){
          granHorario <- granSlotTrab_min + granSlotTrab_min + granSlotDesc_min
        }
        if (nrow(newdfTest) < granHorario) {
          return("C")
        }
        #time1 <- Sys.time()
        if (aux_go_bkup == 0) {
          resultado <- select_horario_partido(newdfTest$Ideal_por_Cobrir, granHorario, granSlotTrab_min, granSlotTrab_max, granSlotDesc_min, granSlotDesc_max, limitSlotManha, limitSlotTarde,valorMinPartido)
        } else{
          resultado <- select_horario_partido_bkup(newdfTest$Ideal, granHorario, granSlotTrab_min, granSlotTrab_max, granSlotDesc_min, granSlotDesc_max, limitSlotManha, limitSlotTarde,valorMinPartido) 
        }
        #time2 <- Sys.time()
        
        if (is.null(resultado$h)) {
          varAdd <- 0.5
          print("intervalo dado nao foi suficiente para respeitar regras")
          while (is.null(resultado$h)) {
            newHorario <- data.frame(
              hora_in = as.POSIXct(colabsToUse$hora_in, format = '%Y-%m-%d %H:%M:%S', tz='GMT'),
              hora_out = as.POSIXct(colabsToUse$hora_in, format = '%Y-%m-%d %H:%M:%S', tz='GMT')+(varAdd+ptc)*3600 
            )
            
            newPeriodTimes <- seq(newHorario$hora_in, newHorario$hora_out, by = "15 mins")
            
            newdfTest <- dfTest %>% dplyr::filter(timestamps %in% newPeriodTimes)
            
            
            newdfTest <- newdfTest %>% 
              dplyr::mutate(
                Ideal_por_Cobrir = case_when(
                  Ideal_por_Cobrir >= 1 ~ 1,
                  T ~ 0 
                )
              )
            resultado <- select_horario_partido(newdfTest$Ideal_por_Cobrir, granHorario, granSlotTrab_min, granSlotTrab_max, granSlotDesc_min, granSlotDesc_max, limitSlotManha, limitSlotTarde,valorMinPartido)
            
            varAdd <- varAdd+0.5
            
            if (varAdd >2) {
              print("partidos loop infinito")
              break
            }
          }
        }
        
        if (is.null(resultado$h)) {
          if (dfEMPloyee$partido_continuado[dfEMPloyee$EMP == colabToUse$EMP]=='P') {
            new_col_name <- paste0("EMPloyee_",colabsToUse$EMP,sep="")
            dfTest[[new_col_name]] <- 0
            dfEMPloyee$Allocated[dfEMPloyee$EMP == colabToUse$EMP] <- TRUE
            next
          } else{
            return("C")
          }
          
        }
        
        #newdfTest$Ideal_por_Cobrir[min(resultado$posicoes_slots_h$slot1):max(resultado$posicoes_slots_h$slot3)]
        new_col_name <- paste0("EMPloyee_",colabsToUse$EMP,sep="")
        newdfTest[[new_col_name]] <- resultado$h
        
        
        # Criar vetor indicando posições cobertas por h
        dfTest <- merge(dfTest, newdfTest %>% dplyr::select(timestamps,!!new_col_name), all.x = T, by = "timestamps") %>% 
          dplyr::mutate(!!new_col_name := ifelse(is.na(!!sym(new_col_name)), 0, !!sym(new_col_name))) 
        
        horasTrab <- sum(resultado$h)*15/60
        
        #se nao conseguir dar
        if(is.null(intervalData)|is.null(colabsToUse)| is.null(colabChosen)){
          print("Giving back up shcedule to these cuntzie !")
          # interval_flag = 3
          # collabi <- dfEMPloyee %>%  filter(Allocated != TRUE)
          # colabChosen <- attribuirHorarioBK(collabi,ColabData,daily_dataframe,collaborator_tibbles)
          # collabi <- colabChosen[[1]]
          # timestamps <- seq(as.POSIXct(collabi$hora_in, format = '%H:%M'), as.POSIXct(collabi$hora_out, format = '%H:%M'), by = "15 mins")
        }
        
        if(!is.null(colabChosen)){
          print("Gave an horario of partido")
          print(colabsToUse$EMP)
          dfEMPloyee$Allocated[dfEMPloyee$EMP == colabToUse$EMP] <- TRUE
          
          dias_falta <- unique(cttb[[colabToUse$EMP]]$dias_para_atribuir)-1
          faltaHorasMediaAntes <- unique(cttb[[colabToUse$EMP]]$horas_goal)-horasTrab
          
          if (dias_falta==0) {
            if (unique(cttb[[colabToUse$EMP]]$horas_goal)<horasTrab) {
              dfEMPloyee$Allocated[dfEMPloyee$EMP == colabToUse$EMP] <- FALSE
              return("C")
            }
          } 
          
          
          collaborator_tibbles <- update_col_tibble_partidos(horasTrab, colabsToUse,collaborator_tibbles,date_chosen,week,month,year,interval_flag)
          if (dfEMPloyee$partido_continuado[dfEMPloyee$EMP == colabToUse$EMP]=='CP') {
            if (unique(collaborator_tibbles[[colabToUse$EMP]]$cargas_media_falta) < colabToUse$HORAS_TRAB_DIA_CARGA_MIN) {
              dfEMPloyee$Allocated[dfEMPloyee$EMP == colabToUse$EMP] <- FALSE
              return("C")
            }
            if (faltaHorasMediaAntes/dias_falta < colabToUse$HORAS_TRAB_DIA_CARGA_MIN) {
              dfEMPloyee$Allocated[dfEMPloyee$EMP == colabToUse$EMP] <- FALSE
              return("C")
            }
          }
          if (dfEMPloyee$partido_continuado[dfEMPloyee$EMP == colabToUse$EMP]=='P') {
            if (unique(collaborator_tibbles[[colabToUse$EMP]]$cargas_media_falta) < (colabToUse$HORAS_TRAB_PARTIDO_SLOT_MIN)*2) {
              dfEMPloyee$Allocated[dfEMPloyee$EMP == colabToUse$EMP] <- FALSE
              return("C")
            }
            if (faltaHorasMediaAntes/dias_falta < (colabToUse$HORAS_TRAB_PARTIDO_SLOT_MIN)*2) {
              dfEMPloyee$Allocated[dfEMPloyee$EMP == colabToUse$EMP] <- FALSE
              return("C")
            }
          }
          
          # Update df$allocated directly for the relevant rows
          dfTest$Ideal_por_Cobrir <- as.integer(dfTest$Ideal_por_Cobrir)
          dfTest$Alocado <- as.integer(dfTest$Alocado)
          dfTest$Minimo_Por_cobrir <- as.integer(dfTest$Minimo_Por_cobrir)
          dfTest$Ideal <- as.integer(dfTest$Ideal)
          dfTest$Minimo <- as.integer(dfTest$Minimo)
          
          daily_dataframe$Dia_atribuido[daily_dataframe$EMP == colabToUse$EMP] <- TRUE
          ddd <<- dfTest
          cawl <<- new_col_name
          # print(asdffffffffffffffffffffffffffffffff)
          
          # M?nimo! Por cobrir -> M?nimo! - Alocado
          dfTest <- dfTest %>% 
            dplyr::mutate(Alocado := case_when(
              !!sym(new_col_name)==1 ~ as.numeric(Alocado) + 1,
              T ~ as.numeric(Alocado)
            ),
            Ideal_por_Cobrir := case_when(
              !!sym(new_col_name)==1 ~ Ideal_por_Cobrir - 1,
              T ~ as.numeric(Ideal_por_Cobrir)
            ),
            Minimo_Por_cobrir := case_when(
              !!sym(new_col_name)==1 ~ Minimo_Por_cobrir - 1,
              T ~ as.numeric(Minimo_Por_cobrir)
            )
            )
          
          # dfTest$Ideal_por_Cobrir <- dfTest$Ideal - dfTest$Alocado
          # dfTest$Minimo_Por_cobrir <- dfTest$Minimo - dfTest$Alocado
        }
        cat("--------- Horarios Atribuidos -----------\n")
        cat(sprintf("EMPloyees working: %d\n", nrow(dfEMPloyee)))
        cat(sprintf("Zeros:   %d\n", zeros))
        cat(sprintf("Minimos: %d\n", minimos))
        cat(sprintf("Ideais:  %d\n", ideais))  
        
        
      }
    }
    
    
    # print(colnames(dfTest))
  }
  return(list(dfTest,daily_dataframe,collaborator_tibbles,dfEMPloyee))
  
}



selectColabPartido <- function(timestamp,EMPloyee_data,colaData,dfTest){
  testTEMP <<- timestamp  #<- testTEMP
  testEMP <<- EMPloyee_data #<- testEMP
  colabasritas <<- colaData #<- colabasritas
  
  #print(class)
  EMPloyee_data <- left_join(EMPloyee_data, colaData, by = 'EMP')
  timestamp$start_time <- as.POSIXct(timestamp$start_time , format = '%Y-%m-%d %H:%M:%S')
  timestamp$end_time  <- as.POSIXct(timestamp$end_time , format = '%Y-%m-%d %H:%M:%S')
  EMPloyee_data$hora_in <- as.POSIXct(EMPloyee_data$hora_in , format = '%Y-%m-%d %H:%M')
  EMPloyee_data$hora_out  <- as.POSIXct(EMPloyee_data$hora_out , format = '%Y-%m-%d %H:%M')
  
  eligible_colabs <- EMPloyee_data[ 
    # Abertura condition
    (
      (EMPloyee_data$hora_in >= timestamp$start_time & EMPloyee_data$hora_in <= timestamp$end_time) |
        
        (EMPloyee_data$hora_out >= timestamp$start_time & EMPloyee_data$hora_in <= timestamp$end_time) |
        
        (timestamp$start_time >= EMPloyee_data$hora_in & timestamp$start_time <= EMPloyee_data$hora_out) |
        
        (timestamp$end_time >= EMPloyee_data$hora_in & timestamp$end_time <= EMPloyee_data$hora_out)
    )
    &
      (
        # Additional condition for both Abertura and Fecho
        (
          (as.numeric(difftime(min(EMPloyee_data$hora_out,timestamp$end_time), 
                               max(timestamp$start_time,EMPloyee_data$hora_in),
                               units = 'hours')) >= EMPloyee_data$HORAS_TRAB_VAL_CARGA) 
        )
      )
    & EMPloyee_data$Allocated != TRUE,
  ]
  
  
  if (nrow(eligible_colabs) == 0 || is.na(eligible_colabs$EMP)) {
    #print("No eligible collaborators found.")
    eligible_colabs <- EMPloyee_data[ 
      # Abertura condition
      (
        (EMPloyee_data$hora_in >= timestamp$start_time & EMPloyee_data$hora_in <= timestamp$end_time) |
          
          (EMPloyee_data$hora_out >= timestamp$start_time & EMPloyee_data$hora_in <= timestamp$end_time) |
          
          (timestamp$start_time >= EMPloyee_data$hora_in & timestamp$start_time <= EMPloyee_data$hora_out) |
          
          (timestamp$end_time >= EMPloyee_data$hora_in & timestamp$end_time <= EMPloyee_data$hora_out)
      )
      # &
      #   (
      #     # Additional condition for both Abertura and Fecho
      #     (
      #       (as.numeric(difftime(min(as.POSIXct(EMPloyee_data$hora_out, format = '%H:%M'),as.POSIXct(timestamp$end_time, format = '%H:%M')), 
      #                            max(as.POSIXct(timestamp$start_time, format = '%H:%M'),as.POSIXct(EMPloyee_data$hora_in, format = '%H:%M')),
      #                            units = 'hours')) >= EMPloyee_data$HORAS_TRAB_DIA_CARGA_MIN) 
      #     )
      #   )
      & EMPloyee_data$Allocated != TRUE,
    ]
    # return(NULL)
  }
  #print(opening_timestamps)
  #print(closing_timestamps)
  test <<- eligible_colabs# <- test
  # priority_colabs = eligible_colabs[
  #   (as.POSIXct(eligible_colabs$hora_in, format = '%H:%M') <= as.POSIXct(opening_timestamps)),
  # ] %>%  filter(!is.na(EMP))
  # start_index <- which(dfTest$timestamps == opening_timestamps)
  # end_index <- which(dfTest$timestamps == closing_timestamps)
  # 
  # #print(priority_colabs)
  # if (nrow(priority_colabs) > 0 & as.POSIXct(timestamp$start_time , format = '%H:%M') <= as.POSIXct(opening_timestamps) & dfTest[start_index,]$Alocado == 0){
  #   #print("Giving opening collaborators")
  #   collabs_in_priority <- collaborator_tibbles[sapply(collaborator_tibbles, function(tibble) any(tibble$EMP %in% priority_colabs$EMP))]
  #   
  #   max_ratio_collab <- collabs_in_priority[[which.max(sapply(collabs_in_priority, function(tibble) (tibble$horas_goal)[1] / sum(tibble$dias_para_atribuir)))]]
  #   
  #   max_ratio_EMP <- max_ratio_collab$EMP[1]
  #   max_ratio_info <- priority_colabs[priority_colabs$EMP == max_ratio_EMP, ]
  #   
  #   return(priority_colabs)
  # }
  # priority_colabs2 = eligible_colabs[
  #   as.POSIXct(eligible_colabs$hora_out, format = '%H:%M') >= as.POSIXct(closing_timestamps),
  #   ,
  # ] %>% filter(!is.na(EMP))
  # #print(priority_colabs2)
  # if (nrow(priority_colabs2) > 0 & as.POSIXct(timestamp$end_time , format = '%H:%M') == as.POSIXct(closing_timestamps) & dfTest[end_index,]$Alocado == 0){
  #   #print("Giving closing collaborators")
  #   collabs_in_priority <- collaborator_tibbles[sapply(collaborator_tibbles, function(tibble) any(tibble$EMP %in% priority_colabs2$EMP))]
  #   
  #   max_ratio_collab <- collabs_in_priority[[which.max(sapply(collabs_in_priority, function(tibble) (tibble$horas_goal)[1] / sum(tibble$dias_para_atribuir)))]]
  #   
  #   max_ratio_EMP <- max_ratio_collab$EMP[1]
  #   max_ratio_info <- priority_colabs2[priority_colabs2$EMP == max_ratio_EMP, ]
  #   return(priority_colabs2)
  # }
  # collabs_in_priority <- collaborator_tibbles[sapply(collaborator_tibbles, function(tibble) any(tibble$EMP %in% eligible_colabs$EMP))]
  # 
  # max_ratio_collab <- collabs_in_priority[[which.max(sapply(collabs_in_priority, function(tibble) (tibble$horas_goal)[1] / sum(tibble$dias_para_atribuir)))]]
  # 
  # max_ratio_EMP <- max_ratio_collab$EMP[1]
  # max_ratio_info <- eligible_colabs[eligible_colabs$EMP == max_ratio_EMP, ]
  # print(eligible_colabs)
  # print(max_ratio_EMP)
  
  max_ratio_EMP <- eligible_colabs$EMP[1]
  max_ratio_info <- eligible_colabs[eligible_colabs$EMP == max_ratio_EMP, ]
  
  return(max_ratio_info)
}


# Criar uma função para calcular o acumulado de cada posição até a posição + x
soma_cumulativa_intervalo <- function(vetor, tamanhoHorario) {
  n <- length(vetor)
  resultado <- numeric(n)
  
  for (i in 1:n) {
    fim_intervalo <- min(i + tamanhoHorario, n)
    resultado[i] <- sum(vetor[i:fim_intervalo])
  }
  
  return(resultado)
}




# set.seed(123)  # Para reprodutibilidade dos resultados
# p <- sample(0:1, 20, replace = TRUE)  # Lista p com valores aleatórios 0 ou 1
# p <- c(1,0,1,1,1,2,0,1,0,1,0,1,1,1,1,1,0,1,6,1)
# 
# # Função para criar lista h e retornar as posições ocupadas em p
# criar_lista_h <- function(p) {
#   n <- length(p)
#   max_tamanho_h <- 18
#   melhor_h <- NULL
#   melhor_contagem <- 0
#   menor_slots <- 99999
#   posicoes_ocupadas_p <- NULL
#   posicoes_slots_h <- NULL
#   
#   # Iterar sobre diferentes posições iniciais para h
#   for (pos_inicial_h in 1:(n - max_tamanho_h + 1)) {
#     # Iterar sobre diferentes tamanhos para slot 1
#     for (tam_slot1 in 3:6) {
#       # Iterar sobre diferentes tamanhos para slot 2
#       for (tam_slot3 in 3:6) {
#         # Calcular o tamanho do slot 3 com base nos outros tamanhos
#         # tam_slot3 <- max_tamanho_h - tam_slot1 - tam_slot2
#         for (tam_slot2 in 3:6){ 
#           
#           # Verificar se os tamanhos são válidos
#           if (tam_slot1 >= 3 && tam_slot1 <= 6 &&
#               tam_slot2 >= 3 && tam_slot2 <= 6 &&
#               tam_slot3 >= 3 && tam_slot3 <= 6 &&
#               (pos_inicial_h + tam_slot1 + tam_slot2 + tam_slot3 - 1) <= n) {
#             # Criar lista h com os tamanhos e valores específicos
#             h <- c(rep(1, tam_slot1), rep(0, tam_slot2), rep(1, tam_slot3))
#             # Deslocar h para a posição inicial
#             h <- c(rep(0, pos_inicial_h - 1), h, rep(0, n - (pos_inicial_h + length(h) - 1)))
#             
#             # Encontrar as posições ocupadas em p pelos valores de h
#             posicoes_ocupadas_p_temp <- which(p >= 1 & h == 1)
#             
#             # Calcular a contagem de valores positivos cobertos por h
#             contagem_positivos <- sum(p[posicoes_ocupadas_p_temp])
#             
#             # Calcular o tempo utilizado
#             atual_slots <- tam_slot1+tam_slot2+tam_slot3
#             
#             # Atualizar se encontrarmos uma solução melhor
#             if ((contagem_positivos > melhor_contagem) || 
#                 (contagem_positivos == melhor_contagem && atual_slots < menor_slots)
#             ) {
#               melhor_h <- h
#               melhor_contagem <- contagem_positivos
#               menor_slots <- tam_slot1+tam_slot2+tam_slot3
#               # Salvar as posições ocupadas em p
#               posicoes_ocupadas_p <- posicoes_ocupadas_p_temp
#               # Salvar as posições exatas dos slots de h em p
#               posicoes_slots_h <- list(tam_slot1 =tam_slot1,
#                                        slot1 = c(pos_inicial_h:(pos_inicial_h+tam_slot1-1)),
#                                        tam_slot2 = tam_slot2,
#                                        slot2 = c((pos_inicial_h+tam_slot1):(pos_inicial_h+tam_slot1 + tam_slot2-1)),
#                                        tam_slot3 = tam_slot3,
#                                        slot3 = c((pos_inicial_h+tam_slot1 + tam_slot2):(pos_inicial_h+tam_slot1 + tam_slot2+tam_slot3-1)))
#             }
#           }
#         }
#       }
#     }
#   }
#   
#   return(list(h = melhor_h, posicoes_ocupadas_p = posicoes_ocupadas_p, posicoes_slots_h = posicoes_slots_h))
# }
# 
# p <- c(0, 0, 0, 1, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0    , 0, 0    , 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1)
# # p <- c(0, 0, 0, 1, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0, 0    , 0, 0    , 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 1)
# # Criar a lista h e obter as posições ocupadas em p
# resultado <- criar_lista_h(p)

# Exibir resultados
# print("Lista p:")
# print(p)
# print(p[min(resultado$posicoes_ocupadas_p):max(resultado$posicoes_ocupadas_p)])
# print("Lista h:")
# print(resultado$h)
# print("Posições ocupadas em p por h:")
#print(resultado$posicoes_ocupadas_p)
# print("Posições exatas dos slots de h em p:")
# print(resultado$posicoes_slots_h)

# 
# # Criar vetor indicando posições cobertas por h
# posicoes_cobertas <- rep(0, length(p))
# posicoes_cobertas[resultado$posicoes_ocupadas_p] <- 1
# print(resultado$posicoes_slots_h)
# print(p)
# print(sum(p[min(resultado$posicoes_ocupadas_p):max(resultado$posicoes_ocupadas_p)]))



# Criar uma função para calcular o acumulado de cada posição até a posição + 12
soma_cumulativa_intervalo <- function(vetor) {
  n <- length(vetor)
  resultado <- numeric(n)
  
  for (i in 1:n) {
    fim_intervalo <- min(i + 11, n)
    resultado[i] <- sum(vetor[i:fim_intervalo])
  }
  
  return(resultado)
}

# Calcular a soma cumulativa para o vetor p
# soma_cumulativa_resultado <- soma_cumulativa_intervalo(p)
# p <- newdfTest$Ideal_por_Cobrir 

select_horario_partido <- function(p,granHorario, #pos_inicial_h,
                                   granSlotTrab_min, granSlotTrab_max, granSlotDesc_min, granSlotDesc_max,
                                   limitSlotManha, limitSlotTarde,valorMinPartido) {
  
  n <- length(p)
  melhor_h <- NULL
  melhor_contagem <- 0
  menor_slots <- 99999
  posicoes_ocupadas_p <- NULL
  posicoes_slots_h <- NULL
  # Iterar sobre diferentes posições iniciais para h
  for (pos_inicial_h in 1:(n - granHorario + 1)) {
    # Iterar sobre diferentes tamanhos para slot 1
    for (tam_slot1 in granSlotTrab_min:granSlotTrab_max) {
      # Iterar sobre diferentes tamanhos para slot 2
      for (tam_slot3 in granSlotTrab_min:granSlotTrab_max) {
        # Calcular o tamanho do slot 3 com base nos outros tamanhos
        # tam_slot3 <- max_tamanho_h - tam_slot1 - tam_slot2
        for (tam_slot2 in granSlotDesc_min:granSlotDesc_max){ 
          
          # Verificar se os tamanhos são válidos
          if (tam_slot1 >= granSlotTrab_min && tam_slot1 <= granSlotTrab_max &&
              tam_slot2 >= granSlotDesc_min && tam_slot2 <= granSlotDesc_max &&
              tam_slot3 >= granSlotTrab_min && tam_slot3 <= granSlotTrab_max &&
              tam_slot1 + tam_slot2 + tam_slot3 <= granHorario &&
              tam_slot1 + tam_slot3 >= valorMinPartido &&
              (pos_inicial_h + tam_slot1 + tam_slot2 + tam_slot3 - 1) <= n) {
            
            # Se horario fim manha ultrapassar limite manha, passa a frente
            if (pos_inicial_h+tam_slot1 -1 > limitSlotManha) {
              print("ultrapassa manha")
              next
            }
            # Se horario ini tarde ultrapassar limite tarde, passa a frente
            if (pos_inicial_h + tam_slot1 + tam_slot2  < limitSlotTarde) {
              print("ultrapassa tarde")
              next
            }
            # Criar lista h com os tamanhos e valores específicos
            h <- c(rep(1, tam_slot1), rep(0, tam_slot2), rep(1, tam_slot3))
            # Deslocar h para a posição inicial
            h <- c(rep(0, pos_inicial_h - 1), h, rep(0, n - (pos_inicial_h + length(h) - 1)))
            
            # Encontrar as posições ocupadas em p pelos valores de h
            posicoes_ocupadas_p_temp <- which(p == 1 & h == 1)
            
            # Calcular a contagem de valores positivos cobertos por h
            contagem_positivos <- length(posicoes_ocupadas_p_temp)
            
            # Calcular o tempo utilizado
            atual_slots <- tam_slot1+tam_slot2+tam_slot3
            
            # Atualizar se encontrarmos uma solução melhor
            if ((contagem_positivos > melhor_contagem) || 
                (contagem_positivos == melhor_contagem && atual_slots < menor_slots)
            ) {
              melhor_h <- h
              melhor_contagem <- contagem_positivos
              menor_slots <- tam_slot1+tam_slot2+tam_slot3
              # Salvar as posições ocupadas em p
              posicoes_ocupadas_p <- posicoes_ocupadas_p_temp
              # Salvar as posições exatas dos slots de h em p
              posicoes_slots_h <- list(tam_slot1 =tam_slot1,
                                       slot1 = c(pos_inicial_h:(pos_inicial_h+tam_slot1-1)),
                                       tam_slot2 = tam_slot2,
                                       slot2 = c((pos_inicial_h+tam_slot1):(pos_inicial_h+tam_slot1 + tam_slot2-1)),
                                       tam_slot3 = tam_slot3,
                                       slot3 = c((pos_inicial_h+tam_slot1 + tam_slot2):(pos_inicial_h+tam_slot1 + tam_slot2+tam_slot3-1)))
              print("entrei")
            }
          }
        }
      }
    }
  }
  
  return(list(h = melhor_h, posicoes_ocupadas_p = posicoes_ocupadas_p, posicoes_slots_h = posicoes_slots_h))
}




select_horario_partido_bkup <- function(p,granHorario, #pos_inicial_h,
                                        granSlotTrab_min, granSlotTrab_max, granSlotDesc_min, granSlotDesc_max,
                                        limitSlotManha, limitSlotTarde,valorMinPartido) {
  n <- length(p)
  melhor_h <- NULL
  melhor_contagem <- 0
  menor_slots <- 99999
  posicoes_ocupadas_p <- NULL
  posicoes_slots_h <- NULL
  # Iterar sobre diferentes posições iniciais para h
  for (pos_inicial_h in 1:(n - granHorario + 1)) {
    # Iterar sobre diferentes tamanhos para slot 1
    for (tam_slot1 in granSlotTrab_min:granSlotTrab_max) {
      # Iterar sobre diferentes tamanhos para slot 2
      for (tam_slot3 in granSlotTrab_min:granSlotTrab_max) {
        # Calcular o tamanho do slot 3 com base nos outros tamanhos
        # tam_slot3 <- max_tamanho_h - tam_slot1 - tam_slot2
        for (tam_slot2 in granSlotDesc_min:granSlotDesc_max){ 
          
          # Verificar se os tamanhos são válidos
          if (tam_slot1 >= granSlotTrab_min && tam_slot1 <= granSlotTrab_max &&
              tam_slot2 >= granSlotDesc_min && tam_slot2 <= granSlotDesc_max &&
              tam_slot3 >= granSlotTrab_min && tam_slot3 <= granSlotTrab_max &&
              tam_slot1 + tam_slot2 + tam_slot3 <= granHorario &&
              tam_slot1 + tam_slot3 >= valorMinPartido &&
              (pos_inicial_h + tam_slot1 + tam_slot2 + tam_slot3 - 1) <= n) {
            
            # Se horario fim manha ultrapassar limite manha, passa a frente
            if (pos_inicial_h+tam_slot1 -1 > limitSlotManha) {
              next
            }
            # Se horario ini tarde ultrapassar limite tarde, passa a frente
            if (pos_inicial_h + tam_slot1 + tam_slot2  < limitSlotTarde) {
              next
            }
            
            # Criar lista h com os tamanhos e valores específicos
            h <- c(rep(1, tam_slot1), rep(0, tam_slot2), rep(1, tam_slot3))
            # Deslocar h para a posição inicial
            h <- c(rep(0, pos_inicial_h - 1), h, rep(0, n - (pos_inicial_h + length(h) - 1)))
            
            # Encontrar as posições ocupadas em p pelos valores de h
            posicoes_ocupadas_p_temp <- which(p >= 1 & h == 1)
            
            # Calcular a valor total de p cobertos por h
            contagem_positivos <- sum(p[posicoes_ocupadas_p_temp])
            
            # Calcular o tempo utilizado
            atual_slots <- tam_slot1+tam_slot2+tam_slot3
            
            # Atualizar se encontrarmos uma solução melhor
            if ((contagem_positivos > melhor_contagem) || 
                (contagem_positivos == melhor_contagem && atual_slots < menor_slots)
            ) {
              melhor_h <- h
              melhor_contagem <- contagem_positivos
              menor_slots <- tam_slot1+tam_slot2+tam_slot3
              # Salvar as posições ocupadas em p
              posicoes_ocupadas_p <- posicoes_ocupadas_p_temp
              # Salvar as posições exatas dos slots de h em p
              posicoes_slots_h <- list(tam_slot1 =tam_slot1,
                                       slot1 = c(pos_inicial_h:(pos_inicial_h+tam_slot1-1)),
                                       tam_slot2 = tam_slot2,
                                       slot2 = c((pos_inicial_h+tam_slot1):(pos_inicial_h+tam_slot1 + tam_slot2-1)),
                                       tam_slot3 = tam_slot3,
                                       slot3 = c((pos_inicial_h+tam_slot1 + tam_slot2):(pos_inicial_h+tam_slot1 + tam_slot2+tam_slot3-1)))
            }
          }
        }
      }
    }
  }
  
  return(list(h = melhor_h, posicoes_ocupadas_p = posicoes_ocupadas_p, posicoes_slots_h = posicoes_slots_h))
}



atribuirHorario_Partidos <- function(colabs, timeperiod,classu,date_chosen,collaborator_tibbles){
  #print("Atribuindo horario")
  duration <- as.numeric(difftime(timeperiod$end_time, timeperiod$start_time, units = "hours"))
  testColabs <<- colabs
  class <- as.numeric(classu)  # Convert to numeric
  result <- NULL
  while (is.null(result) & class <= 5) {
    result <- getEligibleClass_Partidos(colabs, duration, as.character(class), date_chosen, collaborator_tibbles)
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
  result <- verifyPossible_Partidos(result)
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

getEligibleClass_Partidos <- function(colabs,duration,class,date_chosen,collaborator_tibbles){
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
  carga_max_schedule <- as.numeric(difftime(as.POSIXct(colabChosen$hora_out,format='%H:%M') , as.POSIXct(colabChosen$hora_in ,format='%H:%M'), units = "hours"))+0.25
  collabbi <<- colabChosen
  if(carga_max_schedule < colabChosen$HORAS_TRAB_DIA_CARGA_MAX){
    carga_max <- carga_max_schedule
  }
  if(class == '1'){
    carga <- carga_max
  }else if(class == '2'){
    carga <- ((carga_max+((carga_max+colabChosen$HORAS_TRAB_VAL_CARGA)/2))/2) 
  }else if(class == '3'){
    carga <- carga_faltamax
  }else if(class == '4'){
    carga <- ((((carga_max+colabChosen$HORAS_TRAB_VAL_CARGA)/2)+colabChosen$HORAS_TRAB_VAL_CARGA)/2) 
  }else{
    carga <- colabChosen$HORAS_TRAB_VAL_CARGA
  }
  
  carga_check <- horas_goal - carga ### horas_Goal 1770 carga 9  ---> carga_check 1761
  return(list(colabChosen,carga,carga_check,day_check,carga_faltamax))
}

verifyPossible_Partidos <- function(result){
  testVerify <<- result #<- testVerify
  if(!is.null(result)){
    media_nova <- result[[3]]/result[[4]]
    if(media_nova < result[[1]]$HORAS_TRAB_VAL_CARGA || is.nan(media_nova)){
      if(result[[5]] < result[[1]]$HORAS_TRAB_VAL_CARGA){
        result[[2]] <- result[[1]]$HORAS_TRAB_VAL_CARGA
      }else result[[2]] <- result[[5]]
    }
  }
  return(result)
}