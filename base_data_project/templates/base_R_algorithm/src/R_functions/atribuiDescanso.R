# ATRIBUI DESCANSO + Implicacoes ----------------------


# ATRIBUI DESCANSO + Implicacoes ----------------------

atribuiDesc <- function(COLAB, DIA, M2, MA, MB, tpL , paramNLDF ,paramNL10) {
  
  # DIA <- diaTurnoSelecionado
  # COLAB <- colabSelecionado
  # M2 <- matriz2_bk
  # MA <- matrizA_bk
  # MB <- matrizB
  # paramNLDF  <- paramNLDF 
  # paramNL10 <- paramNL10
  # tpL <- tipoLibranca
  
  # tudo o que for domingo ou feriado tem um tipo de dia associado a si
  
  # M2$WD <- lubridate::wday(as.character(M2$DATA), label=T, abbr = T)
  # M2$WD <- as.character(M2$WD)
  M2$DATA <- as.Date(M2$DATA)
  MB$DATA <- as.Date(MB$DATA)
  DIA$DATA <- as.Date(DIA$DATA)
  
  # M2 <- M2 %>% 
  #   dplyr::group_by(DATA) %>% 
  #   dplyr::mutate(DIA_TIPO = ifelse(((any(TIPO_TURNO == "F") | WD == "Sun") & HORARIO != 'F'), 'domYf',WD)) %>% 
  #   ungroup()
  
  #IMPLICAÇÕES - Colabs ouT
  
  maOUT <- (unlist(strsplit(as.character(MA %>% dplyr::filter(MATRICULA == colabSelecionado) %>% .$OUT), "/")))
  maOUT <- gsub(" ", "", maOUT )
  
  MA_OUT <- unlist(strsplit(as.character(MA %>% dplyr::filter(MATRICULA %in% maOUT) %>% .$MATRICULA), "/"))
  
  M2_FILTRO <- M2 %>% 
    dplyr::filter(COLABORADOR == colabSelecionado, DATA == DIA$DATA)
  
  M2_OUT <- M2 %>% 
    #dplyr::filter(COLABORADOR %in% MA_OUT, DATA == DIA$DATA, grepl('N|H|-|0|V',HORARIO , ignore.case = TRUE))
    dplyr::filter(COLABORADOR %in% MA_OUT, DATA == DIA$DATA, grepl('N|H|-|0',HORARIO , ignore.case = TRUE))
  
  
  if(#(M2_FILTRO %>% dplyr::filter(HORARIO %in% c('H', 'F')) %>% nrow() > 0)&
    (MA %>% dplyr::filter(MATRICULA == COLAB) %>% .$L_TOTAL > 0))  {
    
    ## Atribui libranca ----
    
    if (length(MA_OUT) == 0) {
      M2 <- M2 %>% 
        dplyr::mutate(HORARIO = case_when(
          COLABORADOR == colabSelecionado & DATA == DIA$DATA ~ tpL,
          T ~ HORARIO))
      
    } 
    
    if (length(MA_OUT) > 1) {
      M2 <- M2 %>%
        dplyr::mutate(HORARIO = case_when(
          COLABORADOR == colabSelecionado & DATA == DIA$DATA & nrow(M2_OUT) > 0 ~ tpL,
          COLABORADOR == colabSelecionado & DATA == DIA$DATA & nrow(M2_OUT) == 0 & TIPO_TURNO != 'V' ~ "OUT",
          T ~ HORARIO))
    }

    
    if (length(MA_OUT) == 1) {
      M2 <- M2 %>%
        dplyr::mutate(HORARIO = case_when(
          COLABORADOR == colabSelecionado & DATA == DIA$DATA  ~ tpL,
          COLABORADOR %in% unique(M2_OUT$COLABORADOR) & DATA == DIA$DATA ~ "OUT",
          T ~ HORARIO))
    }
    
    
    
    # DOMINGOS E FERIADOS ---------------
    if (nrow(M2 %>% dplyr::filter(COLABORADOR == colabSelecionado & DATA == DIA$DATA & HORARIO != "OUT")) > 0) {
      
      if(nrow(M2_FILTRO %>% dplyr::filter(DIA_TIPO == 'domYf'))> 0)  {
        
        ## Implicações ----
        ## 1. Atribui NDDF aos domingos e feriados anteriores e posteriores ---------------------
        
        Dyf_Datas <- ((M2 %>% 
                         dplyr::filter(DIA_TIPO == 'domYf', 
                                       COLABORADOR == colabSelecionado))[!duplicated((M2 %>% 
                                                                                        dplyr::filter(DIA_TIPO == 'domYf', COLABORADOR == colabSelecionado))$DATA), ]) %>% 
          select(DATA)
        
        
        ## Contagem de quandos dyf anteriores
        prev_index <- if_else(((which(unique(Dyf_Datas$DATA) == (DIA$DATA))) - paramNLDF) <= 0, 1, ((which(unique(Dyf_Datas$DATA) == (DIA$DATA))) - paramNLDF ))
        
        DATA_PREV <- as.Date((Dyf_Datas[prev_index, , drop = FALSE])$DATA)
        
        
        ## Contagem de quandos dyf posteriores
        DATA_NEXT <- if_else(is.na(as.Date((Dyf_Datas[(which(unique(Dyf_Datas$DATA) == (DIA$DATA))) + paramNLDF , , drop = FALSE])$DATA)), 
                             as.Date((Dyf_Datas[nrow(Dyf_Datas), ])$DATA),
                             as.Date((Dyf_Datas[(which(unique(Dyf_Datas$DATA) == (DIA$DATA))) + paramNLDF , , drop = FALSE])$DATA))
        
        
        M2 <- M2 %>% 
          dplyr::mutate(HORARIO = case_when(
            DATA >= DATA_PREV & DATA < DIA$DATA & DIA_TIPO == 'domYf' & COLABORADOR == colabSelecionado & HORARIO %in% c('H', 'F')  ~ "NLDF",
            DATA <= DATA_NEXT & DATA > DIA$DATA & DIA_TIPO == 'domYf' & COLABORADOR == colabSelecionado & HORARIO %in% c('H', 'F')  ~ "NLDF",
            T ~ HORARIO
          ))
        
        
        
        ## 2. MA - Decrementos do tipos de descasos: L_TOTAL, L_DOM, L_F ----
        ### Descanso ao Domingo -----
        # if(as.character(unique(M2_FILTRO$WD)) == "Sun") {
        
        MA <- MA %>%
          dplyr::filter(MATRICULA == colabSelecionado) %>%
          dplyr::mutate(L_TOTAL = L_TOTAL - 1,
                        L_DOM = L_DOM - 1, 
                        DESCANSOS_ATRB = DESCANSOS_ATRB + 1) %>%
          dplyr::bind_rows( MA %>%
                              dplyr::filter(MATRICULA != colabSelecionado))
        
        ### Descanso ao Feriado -----
        # } else {
        #   
        #   MA <- MA %>%
        #     dplyr::filter(MATRICULA == colabSelecionado) %>%
        #     dplyr::mutate(L_TOTAL = L_TOTAL - 1,
        #                   L_F = L_F - 1, 
        #                   DESCANSOS_ATRB = DESCANSOS_ATRB + 1) %>%
        #     dplyr::bind_rows( MA %>%
        #                         dplyr::filter(MATRICULA != colabSelecionado))
        #   
        # }
        # 
        
        ## 3. MB - Remover 1 dia ----
        
        MB <- MB %>% 
          dplyr::filter(DATA == DIA$DATA, TURNO == DIA$TURNO) %>% 
          dplyr::mutate(diff = diff - 1,
                        `+H` = `+H`- 1) %>% 
          dplyr::bind_rows(MB %>% 
                             dplyr::filter(!(DATA == DIA$DATA & TURNO == DIA$TURNO))) 
        
        
      } else {
        
        # RESTANTES DIAS ---------------
        
        ## Implicações ----
        ## 1. Atribui L aos dias anteriores e posteriores ---------------------
        
        Dyf_Datas <- ((M2 %>% 
                         dplyr::filter(COLABORADOR == colabSelecionado))[!duplicated((M2 %>% 
                                                                                        dplyr::filter(COLABORADOR == colabSelecionado))$DATA), ]) %>% 
          select(DATA)
        
        
        ## Contagem de quandos dias anteriores
        prev_index <- if_else(((which(unique(Dyf_Datas$DATA) == (DIA$DATA))) - paramNL10) <= 0, 1, ((which(unique(Dyf_Datas$DATA) == (DIA$DATA))) - paramNL10))
        
        DATA_PREV <- as.Date((Dyf_Datas[prev_index, , drop = FALSE])$DATA)
        
        
        ## Contagem de quandos dias posteriores
        DATA_NEXT <- if_else(is.na(as.Date((Dyf_Datas[(which(unique(Dyf_Datas$DATA) == (DIA$DATA))) + paramNL10, , drop = FALSE])$DATA)), 
                             as.Date((Dyf_Datas[nrow(Dyf_Datas), ])$DATA),
                             as.Date((Dyf_Datas[(which(unique(Dyf_Datas$DATA) == (DIA$DATA))) + paramNL10, , drop = FALSE])$DATA))
        
        
        
        M2 <- M2 %>% 
          dplyr::mutate(HORARIO = case_when(
            DIA_TIPO != 'domYf' & tpL %in% c('L_RES','L_Q') & DATA >= DATA_PREV & DATA < DIA$DATA & COLABORADOR == colabSelecionado & HORARIO %in% c('H') ~ "NL",
            DIA_TIPO == 'domYf' & DATA >= DATA_PREV & DATA < DIA$DATA & COLABORADOR == colabSelecionado & HORARIO %in% c('H') & TIPO_TURNO == DIA$TURNO ~ "NLDF",
            DIA_TIPO != 'domYf' & tpL %in% c('L_RES','L_Q') & DATA <= DATA_NEXT & DATA > DIA$DATA & COLABORADOR == colabSelecionado & HORARIO %in% c('H')  ~ "NL",
            DIA_TIPO == 'domYf' & DATA <= DATA_NEXT & DATA > DIA$DATA & COLABORADOR == colabSelecionado & HORARIO %in% c('H') & TIPO_TURNO == DIA$TURNO ~ "NLDF",
            T ~ HORARIO
          ))
        
        
        
        ## 2. MA - Decrementos do tipos de descasos -------------
        MA <- MA %>%
          dplyr::filter(MATRICULA == colabSelecionado) %>%
          dplyr::mutate(L_TOTAL = L_TOTAL - 1,
                        !!tpL := !!sym(tpL) - 1,
                        DESCANSOS_ATRB = DESCANSOS_ATRB + 1) %>%
          dplyr::bind_rows( MA %>%
                              dplyr::filter(MATRICULA != colabSelecionado))
        
        
        
        ## 3. MB - Remover 1 dia -------------------------------
        MB <- MB %>% 
          dplyr::filter(DATA == DIA$DATA, TURNO == DIA$TURNO) %>% 
          dplyr::mutate(diff = diff - 1,
                        `+H` = `+H`- 1) %>% 
          dplyr::bind_rows(MB %>% 
                             dplyr::filter(!(DATA == DIA$DATA & TURNO == DIA$TURNO)))
        
      }
      
      
      return(list(MB=MB, MA=MA, M2=M2))
    }
    
  } else{
    print("descanso por dar com total a 0...-------------------------------------------------------")
  }
  
  
  return(list(MB=MB, MA=MA, M2=M2))
  
  
  
}
