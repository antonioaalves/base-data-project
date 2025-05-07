

selectWeek <- function(semanasTrabalho, semanasTotal, colabTotal, matrizB,trabM2){
  
  
  #select max delta semana
  maxSemana <- semanasTotal %>% 
    dplyr::filter(delta>0 ) 
  
  if (nrow(maxSemana)==0) {
    # zeroooo <<- 'T'
    maxSemana <- semanasTotal %>% 
      dplyr::filter(delta>= 0) #%>%  
    #dplyr::filter(delta == max(delta))
    if (nrow(maxSemana)==0) {
      maxSemana <- semanasTotal %>% 
        dplyr::filter(delta == max(delta))
    }
  } else{
    maxSemana <- maxSemana %>% 
      dplyr::filter(delta == max(delta))
  }
  #se >1 extrai a sorte
  if (nrow(maxSemana)>1) {
    matrizB2 <- matrizB %>% 
      dplyr::filter(DATA %in% trabM2$DATA) %>%
      dplyr::mutate(WW = isoweek(as.POSIXct(DATA, format = '%Y-%m-%d'))) %>%
      dplyr::filter(WW %in% maxSemana$WW) %>%
      dplyr::group_by(WW) %>%
      dplyr::summarise(diff = max(diff), .groups='drop') %>% 
      dplyr::filter(diff == max(diff))
    
    matrizB2 <- matrizB2 %>% 
      dplyr::slice(sample(1:nrow(matrizB2),1)) 
    
    
    maxSemana <- maxSemana %>% 
      dplyr::filter(WW == matrizB2$WW) 
  }
  
  
  #select max delta semana/colaborador
  maxColab <- semanasTrabalho %>% 
    dplyr::filter(WW == maxSemana$WW) %>% 
    dplyr::filter(delta == max(delta))
  
  #se >1 extrai a sorte
  if (nrow(maxColab)>1) {
    maxColab <- maxColab %>% 
      dplyr::slice(sample(1:nrow(maxColab),1)) 
  }

  return(list(maxSemana,maxColab))
}


selectDiasOverlap <- function(matriz2,colabSelecionadoLD,semanaSelecionadaLD){
  ###ver diaMax NaoTrabalho na anterior
  diaMaxPrev <- matriz2 %>% 
    dplyr::filter(HORARIO!=0) %>%
    dplyr::filter(COLABORADOR == colabSelecionadoLD, WW == semanaSelecionadaLD-1) %>%
    dplyr::filter(!grepl('H|NL|OUT|DFS',HORARIO , ignore.case = TRUE)) 
  
  seq_min <- NULL
  if (nrow(diaMaxPrev)>0) {
    diaMaxPrev <- diaMaxPrev %>% .$DATA %>% unique() %>% max()
    seq_min <- seq(diaMaxPrev, by = "days", length.out = 11)
  }
  
  ###ver diaMax NaoTrabalho na seguinte
  diaMaxNext <- matriz2 %>%
    dplyr::filter(HORARIO!=0) %>%
    dplyr::filter(COLABORADOR == colabSelecionadoLD, WW == semanaSelecionadaLD+1) %>% 
    dplyr::filter(!grepl('H|NL|OUT|DFS',HORARIO , ignore.case = TRUE))
  
  seq_max <- NULL
  if (nrow(diaMaxNext)>0) {
    diaMaxNext <- diaMaxNext %>% .$DATA %>% unique() %>% min()
    seq_max <- seq(diaMaxNext, by = "-1 days", length.out = 11)
  }

  # Extrai os dias sobrepostos  
  
  if (!is.null(seq_min) & !is.null(seq_max)) {
    dias_sobrepostos <- lubridate::intersect(as.character(seq_min), as.character(seq_max))
    
    dias_sobrepostos <- matriz2 %>% 
      dplyr::filter(HORARIO!=0) %>%
      dplyr::filter(DATA %in% as.Date(dias_sobrepostos), DIA_TIPO !='domYf') %>% .$DATA %>% unique()
    
    if (length(dias_sobrepostos)==0) {
      seq_min <- matriz2 %>% 
        dplyr::filter(HORARIO!=0) %>%
        dplyr::filter(COLABORADOR == colabSelecionadoLD, WW == semanaSelecionadaLD) %>% 
        dplyr::filter(HORARIO=='H', DIA_TIPO !='domYf') %>% .$DATA %>% unique()
      
      dias_sobrepostos <- lubridate::intersect(as.character(seq_min), as.character(seq_max))
      
    }
    
    
    return(dias_sobrepostos)
  }
  
  if (!is.null(seq_min)) {
    dias_sobrepostos <- seq_min
  }
  
  if (!is.null(seq_max)) {
    dias_sobrepostos <- seq_max
  }
  
  
  return(dias_sobrepostos)
  
}


selectBestLD <- function(matriz2,trabM2,semanasTrabalho,semanasTotal,colabTotal,matrizB){
  ##escolhe melhor semana/colaborador para apicar LD----------------------------------
  semanasTrabalhoLD <- trabM2 %>% dplyr::select(COLABORADOR,WW) %>% unique() %>% 
    merge(semanasTrabalho, by=c('COLABORADOR','WW'))
  
  semanasTotal <- semanasTrabalhoLD %>% 
    dplyr::group_by(WW) %>%
    dplyr::summarise(delta = sum(delta), .groups='drop') %>% ungroup()
  
  semanColabListLD <- selectWeek(semanasTrabalhoLD,
                                 semanasTotal,
                                 colabTotal%>% dplyr::filter(COLABORADOR %in% semanasTrabalhoLD$COLABORADOR),
                                 matrizB,
                                 trabM2
                                 )
  
  semanaSelecionadaLD <- semanColabListLD[[1]]$WW
  colabSelecionadoLD <- semanColabListLD[[2]]$COLABORADOR
  
  if (length(colabSelecionadoLD)==0 ) {
    return(data.table())
  }
  
  ##valida se semana anterior ou seguinte tem NaoTrabalho
  semanColabListLD_next_prev <- semanasTrabalho %>%
    dplyr::arrange(WW) %>%
    dplyr::filter(COLABORADOR == colabSelecionadoLD) %>%
    dplyr::filter(WW %in% c(semanaSelecionadaLD-1,semanaSelecionadaLD+1), nTrab>0)

  ##valida se semana propria tem NaoTrabalho
  semanColabListLD_select <- semanasTrabalho %>%
    dplyr::arrange(WW) %>%
    dplyr::filter(COLABORADOR == colabSelecionadoLD) %>%
    dplyr::filter(WW == semanaSelecionadaLD, nTrab>0)
  
  
  ##se anterior/seguinte nao tem NaoTrabalho ou propria NaoTrabalho
  if (nrow(semanColabListLD_select)>0 | (nrow(semanColabListLD_select)==0 & nrow(semanColabListLD_next_prev)==0)) {
    trabM2_1 <- trabM2 %>% 
      dplyr::filter(COLABORADOR == colabSelecionadoLD, WW == semanaSelecionadaLD)
  } else{
    #se existe NaoTrabalho anterior ou seguinte

    dias_sobrepostos <- selectDiasOverlap(matriz2,colabSelecionadoLD,semanaSelecionadaLD)

    trabM2_1 <- trabM2 %>%
      dplyr::filter(COLABORADOR == colabSelecionadoLD,WW == semanaSelecionadaLD) %>%
      dplyr::filter(DATA %in% as.Date(dias_sobrepostos))
    
    if (nrow(trabM2_1)==0) {
      trabM2_1 <- trabM2 %>%
        dplyr::filter(COLABORADOR == colabSelecionadoLD,WW == semanaSelecionadaLD)
    }

  }
  
  return(trabM2_1)
}


selectBestLDloop <- function(matriz2,trabM2,semanasTrabalho,semanasTotal,colabTotal){
  ##escolhe melhor semana/colaborador para apicar LD----------------------------------
  semanasTrabalhoLD <- trabM2 %>% dplyr::select(COLABORADOR,WW) %>% unique() %>% 
    merge(semanasTrabalho, by=c('COLABORADOR','WW')) %>% 
    dplyr::arrange(WW)
  
  semanasTrabalhoLD$ColabSema <- paste0(semanasTrabalhoLD$COLABORADOR,"|",semanasTrabalhoLD$WW)
  
  trab_res <- data.table()
  for (colsemana in unique(semanasTrabalhoLD$ColabSema)) {
    
    semanaSelecionadaLD <- semanasTrabalhoLD %>% dplyr::filter(ColabSema==colsemana) %>% .$WW %>% unique()
    colabSelecionadoLD <- semanasTrabalhoLD %>% dplyr::filter(ColabSema==colsemana) %>% .$COLABORADOR %>% unique()
    
    ##valida se semana anterior ou seguinte tem NaoTrabalho
    semanColabListLD_next_prev <- semanasTrabalho %>%
      dplyr::arrange(WW) %>% 
      dplyr::filter(COLABORADOR == colabSelecionadoLD) %>% 
      dplyr::filter(WW %in% c(semanaSelecionadaLD-1,semanaSelecionadaLD+1), nTrab>0)
    
    ##valida se semana propria tem NaoTrabalho
    semanColabListLD_select <- semanasTrabalho %>%
      dplyr::arrange(WW) %>% 
      dplyr::filter(COLABORADOR == colabSelecionadoLD) %>% 
      dplyr::filter(WW == semanaSelecionadaLD, nTrab>0)
    
    
    ##se anterior/seguinte nao tem NaoTrabalho ou propria NaoTrabalho
    if (nrow(semanColabListLD_select)>0 | (nrow(semanColabListLD_select)==0 & nrow(semanColabListLD_next_prev)==0)) {
      trab <- trabM2 %>% 
        dplyr::filter(COLABORADOR == colabSelecionadoLD, WW == semanaSelecionadaLD)
    } else{
      #se existe NaoTrabalho anterior ou seguinte
      
      dias_sobrepostos <- selectDiasOverlap(matriz2,colabSelecionadoLD,semanaSelecionadaLD)
      
      trab <- trabM2 %>% 
        dplyr::filter(COLABORADOR == colabSelecionadoLD,WW == semanaSelecionadaLD) %>% 
        dplyr::filter(DATA %in% as.Date(dias_sobrepostos))
      
    }
      trab_res <- trab_res %>%
        dplyr::bind_rows(trab)
  }
  
  
  
  
  
  
  return(trab_res)
}

selectLDOM <- function(matriz2, param = 4){

  matriz2DF <- matriz2 %>%
    dplyr::filter(DIA_TIPO == 'domYf', HORARIO!=0, HORARIO!='V') %>%
    arrange(DATA) #%>% dplyr::filter(COLABORADOR=='ESP0155540')

  domEfesList <- unique(matriz2DF$DATA)


  matriz2DF <- matriz2DF %>%
    dplyr::filter(HORARIO=='L_DOM')

  ###ver diaMin com L_DOM
  diaMin <- matriz2DF %>%
    dplyr::filter(DATA == min(DATA)) %>% .$DATA %>% unique()

  diaMin <- as.Date(domEfesList[ max(which(domEfesList==diaMin)- param,
                                     which(domEfesList=='2024-01-07'), na.rm = T) : max(which(domEfesList==diaMin)- 1,
                                                                                        which(domEfesList=='2024-01-07'), na.rm = T)])

  ###ver diaMax com L_DOM
  diaMax <- matriz2DF %>%
    dplyr::filter(DATA == max(DATA)) %>% .$DATA %>% unique()

  # diaMax <- min(as.Date('2024-12-22'),diaMax, na.rm = T)
  diaMax <- as.Date(domEfesList[ min(which(domEfesList==diaMax)+ param,
                                     which(domEfesList=='2024-12-15'), na.rm = T): min(which(domEfesList==diaMax)+ 1,
                                                                                       which(domEfesList=='2024-12-15'), na.rm = T)])


  mRes <- matriz2 %>%
    dplyr::filter(DATA %in% c(diaMin,diaMax)) %>%
    dplyr::filter(DIA_TIPO == 'domYf', HORARIO %in% c('H','NLDF')) %>%
    dplyr::select(COLABORADOR,DATA)


  return(mRes)

}

selectC2D <- function(matriz2, convenio){
  
  if (convenio=='SABECO') {
    sabSeg <-  matriz2 %>% 
      # dplyr::filter(DATA %in% domEfes$DATA ) %>% 
      dplyr::group_by(DATA) %>% 
      dplyr::filter(HORARIO!=0) %>% 
      dplyr::select(COLABORADOR,DATA,WDAY,HORARIO,DIA_TIPO,TIPO_TURNO) %>% unique() %>% 
      dplyr::arrange(COLABORADOR,DATA) %>%
      dplyr::group_by(COLABORADOR) %>%
      dplyr::mutate(PREV_HORARIO = lag(HORARIO),
                    PREV_PREV_HORARIO = lag(HORARIO,2),
                    NEXT_HORARIO = lead(HORARIO), 
                    NEXT_NEXT_HORARIO = lead(HORARIO,2)
      ) %>% ungroup() %>%
      dplyr::filter(
        !((WDAY == 2 & grepl('L_',NEXT_HORARIO , ignore.case = TRUE)) |
            (WDAY == 7 & grepl('L_',PREV_HORARIO , ignore.case = TRUE))
        )
      )  %>% 
      dplyr::filter(
        (WDAY == 2 & grepl('H',HORARIO , ignore.case = TRUE) & grepl('L_',PREV_HORARIO , ignore.case = TRUE) & !grepl('L_',PREV_PREV_HORARIO , ignore.case = TRUE)) |
          (WDAY == 7 & grepl('H',HORARIO , ignore.case = TRUE) & grepl('L_',NEXT_HORARIO , ignore.case = TRUE) & !grepl('L_',NEXT_NEXT_HORARIO , ignore.case = TRUE))
      ) %>% 
      dplyr::select(COLABORADOR,DATA,TIPO_TURNO,HORARIO,DIA_TIPO)
  }
  
  if (convenio=='ALCAMPO') {
    sabSeg <-  matriz2 %>%
      # dplyr::filter(DATA %in% domEfes$DATA ) %>%
      dplyr::group_by(DATA) %>%
      dplyr::filter(HORARIO!=0) %>%
      dplyr::select(COLABORADOR,DATA,WDAY,HORARIO,DIA_TIPO,TIPO_TURNO) %>% unique() %>%
      dplyr::arrange(COLABORADOR,DATA) %>%
      dplyr::group_by(COLABORADOR) %>%
      dplyr::mutate(PREV_HORARIO = lag(HORARIO),
                    PREV_PREV_HORARIO = lag(HORARIO,2),
                    NEXT_HORARIO = lead(HORARIO),
                    NEXT_NEXT_HORARIO = lead(HORARIO,2)
      ) %>% ungroup() %>%
      dplyr::filter(
        !(
          (WDAY == 7 & grepl('L_',PREV_HORARIO , ignore.case = TRUE))
        )
      )  %>%
      dplyr::filter(
        (WDAY == 7 & grepl('H',HORARIO , ignore.case = TRUE) & grepl('L_',NEXT_HORARIO , ignore.case = TRUE) & !grepl('L_',NEXT_NEXT_HORARIO , ignore.case = TRUE))
      ) %>%
      dplyr::select(COLABORADOR,DATA,TIPO_TURNO,HORARIO,DIA_TIPO)
  }
  
  return(sabSeg)
}


selectC3D <- function(matriz2){
  
  
  sabSeg <- matriz2 %>% 
    # dplyr::filter(DATA %in% domEfes$DATA ) %>% 
    dplyr::group_by(DATA) %>% 
    dplyr::filter(HORARIO!=0) %>% 
    dplyr::select(COLABORADOR,DATA,WDAY,HORARIO,DIA_TIPO,TIPO_TURNO) %>% unique() %>% 
    dplyr::arrange(COLABORADOR,DATA) %>%
    dplyr::group_by(COLABORADOR) %>%
    dplyr::mutate(PREV_HORARIO = lag(HORARIO),
                  PREV_PREV_HORARIO = lag(HORARIO,2),
                  NEXT_HORARIO = lead(HORARIO),
                  NEXT_NEXT_HORARIO = lead(HORARIO,2)) %>% ungroup() %>%
    dplyr::filter(
      !((WDAY == 2 & grepl('L_',NEXT_HORARIO , ignore.case = TRUE)) |
          (WDAY == 7 & grepl('L_',PREV_HORARIO , ignore.case = TRUE)) |
          (WDAY == 6 & grepl('L_',PREV_HORARIO , ignore.case = TRUE) | WDAY == 6 & grepl('L_',NEXT_HORARIO , ignore.case = TRUE))
      )
    )  %>% 
    dplyr::filter(
      (WDAY == 2 & grepl('H',HORARIO , ignore.case = TRUE) & grepl('L_',PREV_HORARIO , ignore.case = TRUE) & grepl('C2D',PREV_PREV_HORARIO , ignore.case = TRUE)) |
        (WDAY == 7 & grepl('H',HORARIO , ignore.case = TRUE) & grepl('L_',NEXT_HORARIO , ignore.case = TRUE) & grepl('C2D',NEXT_NEXT_HORARIO , ignore.case = TRUE)) |
        (WDAY == 6 & grepl('H',HORARIO , ignore.case = TRUE) & grepl('C2D',NEXT_HORARIO , ignore.case = TRUE) & grepl('L_',NEXT_NEXT_HORARIO , ignore.case = TRUE))
    ) %>% 
    dplyr::select(COLABORADOR,DATA,TIPO_TURNO,HORARIO,DIA_TIPO) 
  
  return(sabSeg)
}

selectDFrelax1 <- function(result_df){
  trabDom <- result_df %>%
    dplyr::filter(HORARIO!=0,DIA_TIPO =='domYf') %>%
    dplyr::group_by(DATA) %>%
    dplyr::select(COLABORADOR,DATA,WDAY,HORARIO,DIA_TIPO, TIPO_TURNO) %>% unique() %>%
    dplyr::arrange(COLABORADOR,DATA) %>%
    dplyr::group_by(COLABORADOR) %>%
    dplyr::mutate(PREV_HORARIO = lag(HORARIO),
                  PREV_PREV_HORARIO = lag(HORARIO,2),
                  PREV_PREV_PREV_HORARIO = lag(HORARIO,3),
                  NEXT_HORARIO = lead(HORARIO),
                  NEXT_NEXT_HORARIO = lead(HORARIO,2),
                  NEXT_NEXT_NEXT_HORARIO = lead(HORARIO,3)
    ) %>% ungroup() %>%
    dplyr::filter(
      !(
        (grepl('L_|C|LQ',NEXT_HORARIO , ignore.case = TRUE) &
           grepl('L_|C|LQ',NEXT_NEXT_HORARIO , ignore.case = TRUE)#&
        ) |
          (grepl('L_|C|LQ',PREV_HORARIO , ignore.case = TRUE) &
             grepl('L_|C|LQ',PREV_PREV_HORARIO , ignore.case = TRUE)# &
          ) |
          (difftime(lead(DATA),DATA,units = 'days')==1 & grepl('L_|C|LQ',NEXT_HORARIO , ignore.case = TRUE)
          ) |
          (difftime(DATA,lag(DATA),units = 'days')==1 & grepl('L_|C|LQ',PREV_HORARIO , ignore.case = TRUE)
          )             )
    )
  
  return(trabDom)
}


selectDFrelax2 <- function(result_df){
  trabDom <- result_df %>%
    dplyr::group_by(DATA) %>%
    dplyr::select(COLABORADOR,DATA,WDAY,HORARIO,DIA_TIPO, TIPO_TURNO) %>% unique() %>%
    dplyr::arrange(COLABORADOR,DATA) %>%
    dplyr::group_by(COLABORADOR) %>%
    dplyr::mutate(PREV_HORARIO = lag(HORARIO),
                  NEXT_HORARIO = lead(HORARIO),
    ) %>% ungroup() %>%
    dplyr::filter(HORARIO!=0,DIA_TIPO =='domYf') %>%
    dplyr::filter(
      !(
        (difftime(lead(DATA),DATA,units = 'days')==1 & grepl('L_|C|LQ',NEXT_HORARIO , ignore.case = TRUE)) |
        (difftime(DATA,lag(DATA),units = 'days')==1 & grepl('L_|C|LQ',PREV_HORARIO , ignore.case = TRUE))             
        )
    )
  
  return(trabDom)
}


selectDFrelax2 <- function(result_df){
  trabDom <- result_df %>%
    dplyr::group_by(DATA) %>%
    dplyr::select(COLABORADOR,DATA,WDAY,HORARIO,DIA_TIPO, TIPO_TURNO) %>% unique() %>%
    dplyr::arrange(COLABORADOR,DATA) %>%
    dplyr::group_by(COLABORADOR) %>%
    dplyr::mutate(PREV_HORARIO = lag(HORARIO),
                  NEXT_HORARIO = lead(HORARIO),
    ) %>% ungroup() %>%
    dplyr::filter(HORARIO!=0,DIA_TIPO =='domYf') %>%
    dplyr::filter(
      !(
        (difftime(lead(DATA),DATA,units = 'days')==1 & grepl('L_|C|LQ',NEXT_HORARIO , ignore.case = TRUE)) |
          (difftime(DATA,lag(DATA),units = 'days')==1 & grepl('L_|C|LQ',PREV_HORARIO , ignore.case = TRUE))             
      )
    )
  
  return(trabDom)
}
