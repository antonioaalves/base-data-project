
criarMatrizXor <- function(matriz2){
  
  matriz2$DATA <- as.Date(matriz2$DATA)
  matriz2$WEEK <- isoweek(matriz2$DATA)
  
  ##extrair festivos fechados
  fesFechados <- matriz2 %>%
    dplyr::filter(HORARIO=='F', COLABORADOR != 'TIPO_DIA') %>%
    dplyr::group_by(DATA) %>%
    dplyr::filter(all(HORARIO == 'F'))
  
  ##extrair semans com domngos e festivos com pessoas a trabalhar
  semanasPossiveis <- matriz2 %>%
    dplyr::group_by(DATA,COLABORADOR) %>%
    dplyr::filter((grepl('H|NL|OUT|DFS',HORARIO , ignore.case = TRUE) & DIA_TIPO=='domYf') ) %>%
    ungroup() %>%
    dplyr::group_by(COLABORADOR,WEEK) %>%
    dplyr::select(COLABORADOR,WEEK) %>% unique() %>% ungroup()

  if (nrow(semanasPossiveis)==0) {
    return(NULL)
  }
  
  
  trabM2 <- matriz2 %>%
    merge(semanasPossiveis, by = c('COLABORADOR','WEEK'))
  
  
  countNLDF_ctl <- trabM2 %>%
    dplyr::arrange(COLABORADOR, DATA, desc(HORARIO)) %>%
    dplyr::group_by(COLABORADOR, DATA) %>%
    dplyr::mutate(dups = row_number()) %>% ungroup() %>% 
    dplyr::filter(dups==1) %>% 
    dplyr::group_by(COLABORADOR,WEEK) %>%
    dplyr::summarise(nldf = sum(grepl('H|NL', HORARIO, ignore.case = TRUE) & DIA_TIPO == 'domYf'),
                     nlOut = sum(HORARIO %in% c('OUT') & DIA_TIPO == 'domYf'),
                     nlDFS = sum(HORARIO %in% c('DFS') & DIA_TIPO == 'domYf'),
                     .groups='drop') %>%
    dplyr::mutate(nldf = nldf + nlOut + nlDFS) %>% select(-nlOut,-nlDFS) %>% 
    dplyr::arrange(WEEK)

  
  #duplicar linhas para cada xor
  ld_dupli <- countNLDF_ctl %>% 
    dplyr::group_by(COLABORADOR,WEEK) %>% 
    slice(rep(1:n(), each = nldf)) %>% 
    ungroup()
  
  
  #criar matriz semana/colab
  matrizXor <- matrix(NA, nrow = nrow(ld_dupli), ncol = 52)
  colnames(matrizXor) <- seq_along(1:52)
  
  #preencher matriz com xor
  for (i in 1:nrow(ld_dupli)) {
    semana <- ld_dupli[i,]$WEEK
    
    matrizXor[i,colnames(matrizXor)==semana] <- ifelse(semana==52,semana,semana+1)
    matrizXor[i,colnames(matrizXor)==semana+1] <- semana
  }
  
  matrizXor[is.na(matrizXor)] <- 0
  
  return(matrizXor)
  
}
