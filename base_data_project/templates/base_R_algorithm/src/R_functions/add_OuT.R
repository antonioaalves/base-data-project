add_OUT <- function(pathOS,M2, MA, start_date, end_date, final){
  # pathOS <- pathFicheirosGlobal
  # M2 <- matriz2_bk
  # MA <- matrizA_bk
  # start_date <- startDate2
  # end_date <- endDate2
  M2 <- M2 %>%
    mutate(DATA = as.Date(DATA))
  M2_UPDATED <- M2
  for ( i in 1:nrow(MA)){
    row_using <- MA[i,]
    colabSelecionado <- row_using$MATRICULA
    print(i)
    maOUT_og <- (unlist(strsplit(as.character(MA %>% dplyr::filter(MATRICULA == colabSelecionado) %>% .$OUT), "/")))
    maOUT_og <- gsub(" ", "", maOUT_og )
    
    maOUT <- maOUT_og[!(maOUT_og %in% MA$MATRICULA)]
    #MA_OUT <- unlist(strsplit(as.character(MA %>% dplyr::filter(MATRICULA %in% maOUT) %>% .$MATRICULA), "/"))
    if (any(maOUT_og %in% MA$MATRICULA)) {
      next
    }
    M2_FILTRO <- M2 %>% 
      dplyr::filter(COLABORADOR == colabSelecionado)
    
    M2_OUT <- data.frame()
    
    if (nrow(final)>0) {
      M2_OUT <- final %>% 
        dplyr::filter(COLABORADOR %in% maOUT)
      
    }
    
    if (nrow(M2_OUT)>0) {
      M2_OUT <-  convert_types_out(M2_OUT)
      M2_OUT <- M2_OUT %>% 
        dplyr::rename(EMPLOYEE_ID = COLABORADOR,
                      SCHEDULE_DAY = DATA,
                      TYPE = SCHED_TYPE,
                      SUBTYPE = SCHED_SUBTYPE)
    } else{
      M2_OUT <- get_M2_of_OUT(pathOS,maOUT, start_date, end_date)
    }
    
    
    
    if (nrow(M2_OUT)>0) {
      M2_OUT %>%  select(EMPLOYEE_ID, SCHEDULE_DAY,TYPE)
      
      M2_OUT_COUNT <- M2_OUT %>%
        dplyr::group_by(SCHEDULE_DAY) %>%
        dplyr::summarise(F_count = sum(TYPE == "F"))
      
      
      M2_FILTRO <- M2_FILTRO %>%
        dplyr::mutate(DATA = as.Date(DATA))
      
      M2_OUT_COUNT <- M2_OUT_COUNT %>%
        dplyr::mutate(SCHEDULE_DAY = as.Date(SCHEDULE_DAY))
      
      M2_FILTRO_UPDATED <- M2_FILTRO %>%
        left_join(M2_OUT_COUNT, by = c("DATA" = "SCHEDULE_DAY")) %>%
        dplyr::mutate(HORARIO = ifelse(HORARIO == "H" & F_count == length(maOUT_og), "OUT", HORARIO)) %>%
        dplyr::select(-F_count)
      
      matching_indices <- which(M2_UPDATED$COLABORADOR %in% M2_FILTRO_UPDATED$COLABORADOR & M2_UPDATED$DATA %in% M2_FILTRO_UPDATED$DATA & !(M2_FILTRO_UPDATED$TIPO_TURNO %in% c('0','F','V')))
      
      for (i in matching_indices) {
        print(i)
        update_row <- M2_FILTRO_UPDATED[M2_FILTRO_UPDATED$COLABORADOR == M2_UPDATED$COLABORADOR[i] & M2_FILTRO_UPDATED$DATA == M2_UPDATED$DATA[i] & (M2_FILTRO_UPDATED$TIPO_TURNO == M2_UPDATED$TIPO_TURNO[i] & !(M2_UPDATED$TIPO_TURNO[i] %in% c('0','F','V'))), ]
        M2_UPDATED$HORARIO[i] <- update_row$HORARIO
        
      }
    }
    
  }

  return(M2_UPDATED)
}
