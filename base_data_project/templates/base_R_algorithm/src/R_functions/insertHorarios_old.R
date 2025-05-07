funcInsertDF <- function(M_WFM2, pathOS, wfm_con){
  
  M_WFM2$SCHED_TYPE <- as.character(M_WFM2$SCHED_TYPE)
  M_WFM2$SCHED_SUBTYPE <- as.character(M_WFM2$SCHED_SUBTYPE)
  
  
  M_WFM2 <- M_WFM2 %>%
    dplyr::mutate(SCHED_TYPE = ifelse(SCHED_TYPE == 'FALSE', 'F', SCHED_TYPE)) %>% 
    dplyr::mutate(SCHED_TYPE = ifelse(SCHED_TYPE == 'TRUE', 'T', SCHED_TYPE))
  
  dfTratado <- M_WFM2 %>% 
    dplyr::mutate(
      SCHED_TYPE = case_when(
        SCHED_TYPE == 'F' & SCHED_SUBTYPE %in% c('L','LD','C','LQ') ~ 'F',
        SCHED_TYPE == 'F' & SCHED_SUBTYPE %in% c('F') ~ 'R',
        SCHED_TYPE == 'F' & SCHED_SUBTYPE %in% c('A') ~ 'A',
        SCHED_TYPE == 'V'  ~ 'A',
        SCHED_SUBTYPE == '-'  ~ 'N',
        T ~ SCHED_TYPE
      ),
      SCHED_SUBTYPE = case_when(
        # SCHED_TYPE == 'F' & SCHED_SUBTYPE %in% c('L','LD','C','LQ') ~ 'O',
        SCHED_TYPE == 'R' & SCHED_SUBTYPE %in% c('F') ~ '',
        SCHED_TYPE == 'A' & SCHED_SUBTYPE %in% c('A') ~ '',
        SCHED_SUBTYPE == 'Ferias'  ~ '',
        SCHED_SUBTYPE == '-'  ~ '',
        T ~ SCHED_SUBTYPE
      )
    ) 
  
  dfTratado <- dfTratado %>% 
    merge(matriz_colab_dia_turno, all.x = T) 
  
  dfTratado$EMPLOYEE_ID <- gsub("[^0-9]", "", dfTratado$EMPLOYEE_ID)
  

  
  ## INSERT HORARIOS
  errInd <- tryCatch({
    
    queryInsHorarios <- paste(readLines(paste0(pathOS,"/data/querys/ins_schedules.sql")))
    
    dbSendUpdate(wfm_con,
                 queryInsHorarios,
                 dfTratado$EMPLOYEE_ID,
                 dfTratado$SCHEDULE_DT,
                 dfTratado$SCHED_TYPE,
                 dfTratado$SCHED_SUBTYPE,
                 dfTratado$Start_Time_1,
                 dfTratado$End_Time_1,
                 dfTratado$Start_Time_2,
                 dfTratado$End_Time_2,
                 dfTratado$OPTION_TYPE,
                 dfTratado$OPTION_C1
                 )
    print("sucesso inserir horarios")
    0
  }, error = function(e){
    print("erro inserir horarios")
    print(e)
    1
  }
  )
  print(errInd)
  # 
  # ## INSERT AUSENCIAS
  # errAbs <- tryCatch({
  #   
  #   queryInsAbs <- paste(readLines(paste0(pathOS,"/data/querys/ins_absences.sql")))
  #   
  #   dbSendUpdate(wfm_con,
  #                queryInsHorarios,
  #                dfAusencias$EMPLOYEE_ID,
  #                dfAusencias$SCHEDULE_DT,
  #                dfAusencias$SCHEDULE_DT
  #   )
  #   print("sucesso inserir ausencias")
  #   return(0)
  # }, error = function(e){
  #   print("erro inserir ausencias")
  #   return(1)
  # }
  # )
  # print(errAbs)
  
}
