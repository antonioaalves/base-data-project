selectDayShift <- function(matrizA, matrizB, matriz2, mudaLvizinhos=F,relaxaRegraDom=F,relaxaMin=F,semanasTrabalho, semanaSelecionada, colabSelecionado,matriz2_bk,mudaDvizinhos=F,convenio,matrizXor,maxRelax=F,tipoFolga,tipoFolga2){
  
  res <- data.table()
  
  matrizB$DATA <- as.Date(matrizB$DATA)
  matrizB$TIPO_TURNO = matrizB$TURNO
  matriz2$DATA <- as.Date(matriz2$DATA)
  matriz2_bk$DATA <- as.Date(matriz2_bk$DATA)
  
  
  #0o ATRIBUI DIAS VAZIOS--------------------------
  if (tipoFolga=='VZ') {
    matrizA_aux <- matrizA %>% 
      dplyr::filter(VZ>0)
    
    filtroHorario <- 'H'
    if (nrow(matrizA_aux)>0) {
      res <- selectVZ(matrizA_aux,
                      matrizB,
                      matriz2 %>% 
                        dplyr::filter(COLABORADOR %in% matrizA_aux$MATRICULA),
                      filtroHorario,relaxaMin,matriz2_bk,maxRelax)
      
      if (nrow(res)>0) {
        res$COLUNA <- paste0("VZ")
      }
      return(res)
    }
  }

  
  #1o procura domingo e/ou feriados com L por atribuir--------------------------
  if (tipoFolga=='L_DOM') {
    matrizA_aux <- matrizA %>% 
      dplyr::filter(L_DOM>0)
  
    filtroHorario <- 'H|NLDF'
    if (nrow(matrizA_aux)>0) {
      res <- selectDomFes(matrizA_aux,
                          matrizB,
                          matriz2 %>% 
                            dplyr::filter(COLABORADOR %in% matrizA_aux$MATRICULA),
                          filtroHorario,semanasTrabalho,
                          relaxaRegraDom,relaxaMin,matriz2_bk,mudaDvizinhos,maxRelax, tipoFolga2)
      
      if (nrow(res)>0) {
        res$COLUNA <- paste0("L_DOM")
      }
      
      return(res)
      
    }
  }
  
  #2o FDS de calidad------------------------------------------------------------
  ##filtrar colaboradores com FDS de calidad
  #### 1O AVALIAR OS FDS com 2dias de calidad - - - - - - - - - - - - - - - - - 
  if (tipoFolga=='C2D') {
    matrizA_aux <- matrizA %>% 
      dplyr::filter(C2D>0)
    
    if (nrow(matrizA_aux)>0) {
      filtroHorario <- 'H'
      res <- selectFDScalidad(matrizA_aux,
                              matrizB,
                              matriz2 %>% 
                                dplyr::filter(COLABORADOR %in% matrizA_aux$MATRICULA), 
                              tipo="2D",
                              filtroHorario,relaxaMin,matriz2_bk,convenio,'2025-12-01',maxRelax)
      
      if (nrow(res)>0) {
        res$COLUNA <- paste0("C2D")
      }
      return(res)
    }
  }

  
  #### 2O AVALIAR OS FDS com 3dias de calidad - - - - - - - - - - - - - - - - -
  if (tipoFolga=='C3D') {
    matrizA_aux <- matrizA %>% 
      dplyr::filter(C3D>0)
    
    if (nrow(matrizA_aux)>0) {
      filtroHorario <- 'H'
      res <- selectFDScalidad(matrizA_aux,
                              matrizB, 
                              matriz2 %>% 
                                dplyr::filter(COLABORADOR %in% matrizA_aux$MATRICULA), 
                              tipo="3D",
                              filtroHorario,relaxaMin,matriz2_bk,convenio,'2025-12-01',maxRelax)
      
      if (nrow(res)>0) {
        res$COLUNA <- paste0("C3D")
      }
      return(res)
    }
  }

  
  
  
  #4o procura dias para LD------------------------------------------------------
  if (tipoFolga=='L_D') {
    matrizA_aux <- matrizA %>% 
      dplyr::filter(L_D>0)
    
    if (nrow(matrizA_aux)>0) {
      filtroHorario <- 'H'
      res <- selectLD(matrizA_aux,
                      matrizB, 
                      matriz2 %>% 
                        dplyr::filter(COLABORADOR %in% matrizA_aux$MATRICULA),
                      filtroHorario,
                      semanasTrabalho,
                      semanasTotal, colabTotal,
                      relaxaMin,matriz2_bk,matrizXor,maxRelax)
      
      if (nrow(res)>0) {
        res$COLUNA <- paste0("L_D")
      }
      return(res)
    }
  }

  
  #3o procura Qs --------------------------
  # matrizA_aux <- matrizA %>% 
  #   dplyr::filter(L_QS>0)
  # 
  # if (nrow(matrizA_aux)>0) {
  #   res <- selectQs(matrizA_aux,
  #                   matrizB, 
  #                   matriz2 %>% 
  #                     dplyr::filter(COLABORADOR %in% matrizA_aux$MATRICULA), 
  #                   'H',relaxaMin,matriz2_bk,maxRelax)
  #   
  #   if (nrow(res)>0) {
  #     res$COLUNA <- paste0("L_QS")
  #     return(res)
  #   }
  # }
  # rm(matrizA_aux)
  
  
  #6o procura dias para LQ------------------------------------------------------
  if (tipoFolga=='L_Q') {
    matrizA_aux <- matrizA %>%
      dplyr::filter(L_Q > 0 )
    
    if (nrow(matrizA_aux)>0) {
      filtroHorario <- 'H'
      res <- selectLQ(matrizA_aux,
                      matrizB,
                      matriz2 %>%
                        dplyr::filter(COLABORADOR %in% matrizA_aux$MATRICULA),
                      filtroHorario,relaxaMin,matriz2_bk,maxRelax)
      
      if (nrow(res)>0) {
        res$COLUNA <- paste0("L_Q")
      }
      return(res)
    }
  }
  
  #7o procura dias para L_RES------------------------------------------------------
  if (tipoFolga=='L_RES') {
    matrizA_aux <- matrizA %>%
      dplyr::filter(L_RES > 0 )
    
    if (nrow(matrizA_aux)>0) {
      filtroHorario <- 'H'
      res <- selectL(matrizA_aux,
                     matrizB,
                     matriz2 %>%
                       dplyr::filter(COLABORADOR %in% matrizA_aux$MATRICULA),
                     filtroHorario,
                     semanasTrabalho,semanasTotal, colabTotal,
                     mudaLvizinhos,relaxaMin,matriz2_bk,maxRelax,
                     tipoFolga2)
      
      if (nrow(res)>0) {
        res$COLUNA <- paste0("L_RES")
      }
      return(res)
    }
  }
  
  if (tipoFolga=='L_RES2') {
    matrizA_aux <- matrizA %>%
      dplyr::filter(L_RES2 > 0 )
    
    if (nrow(matrizA_aux)>0) {
      filtroHorario <- 'H'
      res <- selectL(matrizA_aux,
                     matrizB,
                     matriz2 %>%
                       dplyr::filter(COLABORADOR %in% matrizA_aux$MATRICULA),
                     filtroHorario,
                     semanasTrabalho,semanasTotal, colabTotal,
                     mudaLvizinhos,relaxaMin,matriz2_bk,maxRelax,
                     tipoFolga2)
      
      if (nrow(res)>0) {
        res$COLUNA <- paste0("L_RES2")
      }
      return(res)
    }
  }
  
  #5o procura dias para XX(calidad durante a semana)----------------------------
  if (tipoFolga=='CXX') {
    matrizA_aux <- matrizA %>%
      dplyr::filter(CXX > 0 )
    
    if (nrow(matrizA_aux)>0) {
      filtroHorario <- 'NL|H'
      res <- selectCXX(matrizA_aux,
                       matrizB,
                       matriz2 %>%
                         dplyr::filter(COLABORADOR %in% matrizA_aux$MATRICULA),
                       filtroHorario,
                       semanasTrabalho,
                       semanasTotal, colabTotal,
                       relaxaMin,matriz2_bk,maxRelax)
      
      if (nrow(res)>0) {
        res$COLUNA <- paste0("CXX")
      }
      return(res)
    }
  }

  #rm(matrizA_aux)
  
  return(res)
}

###FUNC PARA DIAS VAZIOS------------------------------------------------
selectVZ <- function(matrizA,matrizB, matriz2, filtroHorario,relaxaMin,matriz2_bk,maxRelax){
  
  res <- data.table()
  
  semana1L <- matriz2 %>% 
    dplyr::mutate(WW = isoweek(DATA)) %>% 
    dplyr::group_by(WW,COLABORADOR) %>% 
    dplyr::summarise(nrL = sum(HORARIO=='VZ')/2, .groups='drop') %>% 
    dplyr::filter(nrL<1) %>% 
    dplyr::select(COLABORADOR,WW) %>% unique()
  
  
  trabM2 <- matriz2 %>% 
    merge(semana1L, by = c('COLABORADOR','WW')) %>% 
    dplyr::filter((HORARIO == 'H'),DIA_TIPO !='domYf') 
  
  ##se existirem pessoas a trabalhar, escolher dia das hiposteses
  if (nrow(trabM2)>0) {
    res <- getDayShift(matrizB,trabM2,filtroHorario,relaxaMin,matriz2_bk,maxRelax)
  }
  
  return(res)
  
}


###FUNC PARA DOMINGOS E FESTIVOS------------------------------------------------
selectDomFes <- function(matrizA,matrizB, matriz2, filtroHorario,semanasTrabalho,relaxaRegraDom,relaxaMin,matriz2_bk,mudaDvizinhos,maxRelax,tipoFolga2){

  res <- data.table()

  matriz2_1 <- matriz2
  
  if (!is.null(tipoFolga2) && tipoFolga2=='L_DOM_TARDE') {
    ##extrair domngos e festivos com pessoas a trabalhar
    matriz2 <- matriz2 %>%
      dplyr::filter(DIA_TIPO == 'domYf',TIPO_TURNO!=0, TIPO_TURNO=='T')
  } else{
    matriz2 <- matriz2 %>%
      dplyr::filter(DIA_TIPO == 'domYf',TIPO_TURNO!=0)
  }
  
  matriz2 <- collapseFunc(matriz2)
  
    
  ##extrair domingos e festivos

  if (relaxaRegraDom==F) {
    ##extrair domngos e festivos com pessoas a trabalhar
    trabDom <- matriz2 %>% 
      dplyr::group_by(DATA) %>%
      dplyr::select(COLABORADOR,DATA,WDAY,HORARIO,DIA_TIPO,TIPO_TURNO) %>% unique() %>%
      dplyr::arrange(COLABORADOR,DATA) %>%
      dplyr::group_by(COLABORADOR) %>%
      dplyr::mutate(PREV_HORARIO = lag(HORARIO),
                    NEXT_HORARIO = lead(HORARIO) ) %>% ungroup() %>% 
      dplyr::filter(
        !(#grepl('L_|C|LQ',HORARIO , ignore.case = TRUE) |
            grepl('L_|C|LQ',NEXT_HORARIO , ignore.case = TRUE) |
            grepl('L_|C|LQ',PREV_HORARIO , ignore.case = TRUE)
        ),(HORARIO == 'H'),DIA_TIPO =='domYf') %>%
      dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
    } else{
      ##extrair domngos e festivos com pessoas a trabalhar
  
      if (mudaDvizinhos==1) {
  
        trabDom <- matriz2 %>%
          dplyr::select(COLABORADOR,DATA,WDAY,HORARIO,DIA_TIPO,TIPO_TURNO) %>% unique() %>%
          dplyr::arrange(COLABORADOR,DATA) #%>%
  
        
        indices <- which(rollapply(trabDom$HORARIO %in% c("H","NLDF",'OUT','DFS'), width = min(4,length(trabDom$HORARIO)), FUN = all))
        if(length(indices)>0){
          
          result_df <- lapply(indices, function(i) trabDom %>% data.table %>% slice(i:(i + 3))) %>% bind_rows()
          
          trabDom <- selectDFrelax1(result_df) %>%
            dplyr::filter(#dias>1,
              (HORARIO %in% c('H')),DIA_TIPO =='domYf') %>%
            dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
          
          if (nrow(trabDom)==0) {
            # trabDom <- matriz2 %>%
            #   dplyr::filter(DIA_TIPO == 'domYf', HORARIO %in% c('H','NLDF')) %>%
            #   dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
            trabDom <- selectDFrelax2(matriz2) %>%
              dplyr::filter(#dias>1,
                (HORARIO %in% c('H','NLDF')),DIA_TIPO =='domYf') %>% 
              dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
          }
        } else{
          indices <- which(rollapply(trabDom$HORARIO %in% c("H","NLDF",'OUT','DFS'), width = min(3,length(trabDom$HORARIO)), FUN = all))
          
          if(length(indices)>0){
            result_df <- lapply(indices, function(i) trabDom %>% data.table %>% slice(i:(i + 2))) %>% bind_rows()
            
            trabDom <- selectDFrelax1(result_df) %>%
              dplyr::filter(#dias>1,
                (HORARIO %in% c('H','NLDF')),DIA_TIPO =='domYf') %>%
              dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
            
            datas <- unique(c(trabDom$DATA, trabDom$DATA-1, trabDom$DATA+1))
            trabDom <- selectDFrelax2(matriz2 %>% dplyr::filter(DATA %in% datas)) %>%
              dplyr::filter(#dias>1,
                (HORARIO %in% c('H','NLDF')),DIA_TIPO =='domYf') %>% 
              dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
            
            if (nrow(trabDom)==0) {
              # trabDom <- matriz2 %>%
              #   dplyr::filter(DIA_TIPO == 'domYf', HORARIO %in% c('H','NLDF')) %>%
              #   dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
              trabDom <- selectDFrelax2(matriz2) %>%
                dplyr::filter(#dias>1,
                  (HORARIO %in% c('H','NLDF')),DIA_TIPO =='domYf') %>% 
                dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
            }
          } else{
  
            # trabDom <- selectDFrelax1(matriz2) %>%
            #     dplyr::filter(#dias>1,
            #       (HORARIO %in% c('H','NLDF')),DIA_TIPO =='domYf') %>%
            #     dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
            trabDom <- selectDFrelax2(matriz2) %>%
              dplyr::filter(#dias>1,
                (HORARIO %in% c('H','NLDF')),DIA_TIPO =='domYf') %>% 
              dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
          }
        }
        
        relaxaMin <- T
      } else if (mudaDvizinhos==0) {
        trabDom <- matriz2 %>%
          # dplyr::filter(DATA %in% domEfes$DATA ) %>%
          # dplyr::group_by(DATA) %>%
          dplyr::select(COLABORADOR,DATA,WDAY,HORARIO,DIA_TIPO,TIPO_TURNO) %>% unique() %>%
          dplyr::arrange(COLABORADOR,DATA)
        
        indices <- which(rollapply(trabDom$HORARIO %in% c("H",'OUT','DFS'), width = min(4,length(trabDom$HORARIO)), FUN = all))
        if(length(indices)>0){
          result_df <- lapply(indices, function(i) trabDom %>% data.table %>% slice(i:(i + 3))) %>% bind_rows()
          
          
          trabDom <- selectDFrelax1(result_df) %>%
            dplyr::filter(#dias>1,
              (HORARIO %in% c('H')),DIA_TIPO =='domYf') %>%
            dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
          
          datas <- unique(c(trabDom$DATA, trabDom$DATA-1, trabDom$DATA+1))
          trabDom <- selectDFrelax2(matriz2 %>% dplyr::filter(DATA %in% datas)) %>%
            dplyr::filter(#dias>1,
              (HORARIO %in% c('H','NLDF')),DIA_TIPO =='domYf') %>% 
            dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
          
        } else{
          indices <- which(rollapply(trabDom$HORARIO %in% c("H",'OUT','DFS'), width = min(3,length(trabDom$HORARIO)), FUN = all))
          if(length(indices)>0){
            
            result_df <- lapply(indices, function(i) trabDom %>% data.table %>% slice(i:(i + 2))) %>% bind_rows()
            
            trabDom <- selectDFrelax1(result_df) %>%
              dplyr::filter(#dias>1,
                (HORARIO %in% c('H')),DIA_TIPO =='domYf') %>%
              dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
            
            datas <- unique(c(trabDom$DATA, trabDom$DATA-1, trabDom$DATA+1))
            trabDom <- selectDFrelax2(matriz2 %>% dplyr::filter(DATA %in% datas)) %>%
              dplyr::filter(#dias>1,
                (HORARIO %in% c('H','NLDF')),DIA_TIPO =='domYf') %>% 
              dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
          } else{
  
            trabDom <- selectDFrelax2(matriz2) %>%
              dplyr::filter(#dias>1,
                (HORARIO %in% c('H','NLDF')),DIA_TIPO =='domYf') %>% 
              dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
          }
        }
        
        relaxaMin <- T
      } else if(mudaDvizinhos==2){
        # trabDom <- matriz2 %>%
        #   dplyr::filter(DIA_TIPO == 'domYf', HORARIO %in% c('H','NLDF')) %>%
        #   dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
        trabDom <- selectDFrelax2(matriz2) %>%
          dplyr::filter(#dias>1,
            (HORARIO %in% c('H','NLDF')),DIA_TIPO =='domYf') %>%
          dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
      }
  
    }

  trabDom <- expandFunc(trabDom)
  
  if (matrizA$TIPO_CONTRATO <=3 ) {
    
    trabDom$WW <- isoweek(trabDom$DATA)
    
    semanasTrabalhoLDOM <- trabDom %>% dplyr::select(COLABORADOR,WW) %>% unique() %>% 
      merge(semanasTrabalho, by=c('COLABORADOR','WW')) %>% 
      dplyr::filter(diasH > matrizA$TIPO_CONTRATO)
    
    trabDom <- trabDom %>% 
      dplyr::filter(WW %in% semanasTrabalhoLDOM$WW) %>% 
      dplyr::select(-WW)
  } 

  ##extrair domngos e festivos com pessoas a trabalhar
  trabM2 <- matriz2_1 %>%
    merge(trabDom, by=c('COLABORADOR','DATA','TIPO_TURNO')) %>% 
    dplyr::filter(HORARIO!=0) 

  ##se existirem pessoas a trabalhar, escolher dia das hiposteses
  if (nrow(trabM2)>0) {
    res <- getDayShift(matrizB,trabM2,filtroHorario,relaxaMin,matriz2_bk,maxRelax)
  }

  return(res)

}

###FUNC PARA FDS calidad--------------------------------------------------------
# tipo="3D"
# filtroHorario <- 'H'
# dataLimite <- '2025-12-01'
selectFDScalidad <- function(matrizA,matrizB, matriz2, tipo,filtroHorario,relaxaMin,matriz2_bk,convenio,dataLimite,maxRelax){
  
  res <- data.table()
  
  matriz2_1 <- matriz2
  matriz2 <- collapseFunc(matriz2)

  ##tratar FDS calidad de 2dias
  if (tipo=='2D') {
    ##extrair domngos com pessoas em L
    dia2D <- matriz2 %>%
      dplyr::filter(HORARIO =='C2D') %>%
      unique() %>%
      dplyr::select(DATA)
    dia2D$MES <- month(dia2D$DATA)
    if(nrow(dia2D) == 0) {
      # Escolher o primeiro dia para atribuir descanso
      feriasMesPar <- matriz2 %>%
        dplyr::mutate(MES = month(matriz2$DATA)) %>%
        dplyr::filter(HORARIO == "V") %>%
        dplyr::mutate(ParImpar = ifelse(MES %% 2 == 0, "Par", "Impar"))  %>%
        dplyr::group_by(ParImpar) %>%
        dplyr::summarise(countDiasFerias = n()/2) %>%
        dplyr::arrange(desc(countDiasFerias)) %>%
        slice(1)
      if(nrow(feriasMesPar) > 0){
        if(unique(feriasMesPar$ParImpar) == "Par"){
          # se o numero maior de ferias for um mês par , entao selecionar mês impar
          ##extrair domingos fechados e Calidad
          sabSeg <- selectC2D(matriz2 %>% filter(DATA < dataLimite), convenio) %>%
            dplyr::filter(month(DATA) %% 2 != 0)
          
          sabSeg <- expandFunc(sabSeg)
          sabSeg$DATA <- as.character(sabSeg$DATA)
          trabM2 <- matriz2_1 %>% 
            merge(sabSeg, by=c('COLABORADOR','DATA','TIPO_TURNO','HORARIO','DIA_TIPO')) %>% 
            dplyr::filter(HORARIO %in% c('H'), DIA_TIPO!='domYf')
        } else{
          # se o numero maior de ferias for um mês impar , entao selecionar mês par
          sabSeg <- selectC2D(matriz2 %>% filter(DATA < dataLimite), convenio) %>%
            dplyr::filter(month(DATA) %% 2 == 0)
          
          sabSeg <- expandFunc(sabSeg)
          sabSeg$DATA <- as.character(sabSeg$DATA)
          trabM2 <- matriz2_1 %>% 
            merge(sabSeg, by=c('COLABORADOR','DATA','TIPO_TURNO','HORARIO','DIA_TIPO')) %>% 
            dplyr::filter(HORARIO %in% c('H'), DIA_TIPO!='domYf')
          
        }
      } else{
        sabSeg <- selectC2D(matriz2 %>% filter(DATA < dataLimite), convenio)
        
        sabSeg <- expandFunc(sabSeg)
        sabSeg$DATA <- as.character(sabSeg$DATA)
        trabM2 <- matriz2_1 %>% 
          merge(sabSeg, by=c('COLABORADOR','DATA','TIPO_TURNO','HORARIO','DIA_TIPO')) %>% 
          dplyr::filter(HORARIO %in% c('H'), DIA_TIPO!='domYf')
      }
    } else {
      if(all(month(dia2D$DATA) %% 2 == 0)){
        ## Se mês for par
        sabSeg <- selectC2D(matriz2 %>% filter(DATA < dataLimite), convenio) %>% 
          dplyr::filter(month(DATA) %% 2 == 0,!(month(DATA) %in% dia2D$MES), DIA_TIPO!='domYf')
        if(nrow(sabSeg) == 0) {
          sabSeg <- selectC2D(matriz2 %>% filter(DATA < dataLimite), convenio) %>% 
            dplyr::filter(!(month(DATA) %in% dia2D$MES))
        }
        ##extrair domngos e festivos com pessoas a trabalhar
        sabSeg <- expandFunc(sabSeg)
        sabSeg$DATA <- as.character(sabSeg$DATA)
        trabM2 <- matriz2_1 %>% 
          merge(sabSeg, by=c('COLABORADOR','DATA','TIPO_TURNO','HORARIO','DIA_TIPO')) %>% 
          dplyr::filter(HORARIO %in% c('H'), DIA_TIPO!='domYf')
      } else {
        ## Se mês for impar
        sabSeg <- selectC2D(matriz2 %>% filter(DATA < dataLimite), convenio) %>% 
          dplyr::filter(month(DATA) %% 2 != 0,!(month(DATA) %in% dia2D$MES), DIA_TIPO!='domYf')
        if(nrow(sabSeg) == 0) {
          sabSeg <- selectC2D(matriz2%>% filter(DATA < dataLimite), convenio) %>% 
            dplyr::filter(!(month(DATA) %in% dia2D$MES))
        }
        if(nrow(sabSeg) == 0) { ## necessario adicionar por causa do OUT -> pode atribuir em meses que ja tenha
          # ou ? assim ou sobrepoe-se a OUT....
          sabSeg <- selectC2D(matriz2%>% filter(DATA < dataLimite), convenio) 
        }
        ##extrair domngos e festivos com pessoas a trabalhar
        sabSeg <- expandFunc(sabSeg)
        sabSeg$DATA <- as.character(sabSeg$DATA)
        trabM2 <- matriz2_1 %>% 
          merge(sabSeg, by=c('COLABORADOR','DATA','TIPO_TURNO','HORARIO','DIA_TIPO')) %>% 
          dplyr::filter(HORARIO %in% c('H'), DIA_TIPO!='domYf')
      }
    }

    ##se existirem pessoas a trabalhar, escolher dia/turno das hiposteses
    if (nrow(trabM2)>0) {
      res <- getDayShift(matrizB, trabM2,filtroHorario,relaxaMin,matriz2_bk,maxRelax)
    }
    #}
  }
  
  ##tratar FDS calidad de 3dias
  if (tipo=='3D') {
    
    
    mes3D <- matriz2 %>% 
      dplyr::filter(HORARIO =='C3D') %>% 
      unique() %>% 
      dplyr::select(DATA) 
    
    
    mes3D$MES <- month(mes3D$DATA)
    
    if(nrow(mes3D) == 0) {
      ##extrair sabados e segundas com pessoas a trabalhar, ao lado de um domingo com L
      sabSeg <- selectC3D(matriz2)
      
      sabSeg <- expandFunc(sabSeg)
      sabSeg$DATA <- as.character(sabSeg$DATA)
      trabM2 <- matriz2_1 %>% 
        merge(sabSeg, by=c('COLABORADOR','DATA','TIPO_TURNO','HORARIO','DIA_TIPO')) %>% 
        dplyr::filter(HORARIO %in% c('H'), DIA_TIPO!='domYf')
      
      
    } else{
      ##extrair sabados e segundas com pessoas a trabalhar, ao lado de um domingo com L
      
      if(unique(mes3D$MES) == 6) {
        sabSeg <- selectC3D(matriz2) %>% 
          dplyr::filter((month(DATA) < (unique(mes3D$MES) - 5)))
        
        
        
        if(nrow(sabSeg) == 0){
          
          sabSeg <- selectC3D(matriz2)
          
          
          sabSeg$DATA2D <- unique(mes3D$DATA)
          
          sabSeg <- sabSeg %>% 
            dplyr::mutate(diffDays = abs(DATA - DATA2D)) %>% 
            arrange(diffDays) %>% 
            dplyr::filter(diffDays == max(diffDays)) %>% 
            dplyr::select(-c(DATA2D, diffDays))
          
          
        }
        sabSeg <- expandFunc(sabSeg)
        sabSeg$DATA <- as.character(sabSeg$DATA)
        trabM2 <- matriz2_1 %>% 
          merge(sabSeg, by=c('COLABORADOR','DATA','TIPO_TURNO','HORARIO','DIA_TIPO')) %>% 
          dplyr::filter(HORARIO %in% c('H'), DIA_TIPO!='domYf')
        
      } 
      
      else {
        
        sabSeg <- selectC3D(matriz2) %>% 
          dplyr::filter((month(DATA) < (unique(mes3D$MES) - 5)) | (month(DATA) > (unique(mes3D$MES) + 5 )))
        
        
        if(nrow(sabSeg) == 0){
          
          sabSeg <- selectC3D(matriz2)
          
          
          sabSeg$DATA2D <- unique(mes3D$DATA)
          
          sabSeg <- sabSeg %>% 
            dplyr::mutate(diffDays = abs(DATA - DATA2D)) %>% 
            arrange(diffDays) %>% 
            dplyr::filter(diffDays == max(diffDays)) %>% 
            dplyr::select(-c(DATA2D, diffDays))
          
          
        }
        sabSeg <- expandFunc(sabSeg)
        sabSeg$DATA <- as.character(sabSeg$DATA)
        trabM2 <- matriz2_1 %>% 
          merge(sabSeg, by=c('COLABORADOR','DATA','TIPO_TURNO','HORARIO','DIA_TIPO')) %>% 
          dplyr::filter(HORARIO %in% c('H'), DIA_TIPO!='domYf')
        
      } 
      
      
      
      if(nrow(trabM2) == 0){
        
        sabSeg <- selectC3D(matriz2)
        
        sabSeg <- expandFunc(sabSeg)
        sabSeg$DATA <- as.character(sabSeg$DATA)
        trabM2 <- matriz2_1 %>% 
          merge(sabSeg, by=c('COLABORADOR','DATA','TIPO_TURNO','HORARIO','DIA_TIPO')) %>% 
          dplyr::filter(HORARIO %in% c('H'), DIA_TIPO!='domYf')
        
        
      }
      
      
    }
    matriz2 <- matriz2_1
    
    if (nrow(trabM2)>0) {
      trabM2 <- selectBestLD(matriz2,trabM2,semanasTrabalho,semanasTotal,colabTotal,matrizB)
      res <- getDayShift(matrizB, trabM2,filtroHorario,relaxaMin,matriz2_bk,maxRelax)
    }
    
    
  }
  
  
  return(res)
  
  
}



###FUNC PARA Q ----------------------------------------------------------------
selectQs <- function(matrizA,matrizB, matriz2, filtroHorario,relaxaMin,matriz2_bk,maxRelax){
  
  res <- data.table()
  
  matriz2_1 <- matriz2
  matriz2 <- collapseFunc(matriz2)
  
  paridadeMes <- matriz2 %>% 
    dplyr::filter(HORARIO =='L_QS') %>% 
    unique() %>% 
    dplyr::select(DATA) 
  
  
  paridadeMes$MES <- month(paridadeMes$DATA)
  
  if(nrow(paridadeMes) == 0) {
    
    ##extrair domingos fechados e Calidad
    semanaQs <- matriz2 %>% 
      dplyr::group_by(COLABORADOR,WW) %>% 
      dplyr::filter(!any(HORARIO=='L_QS')) %>% 
      ungroup() %>% 
      dplyr::filter(HORARIO!=0) %>% 
      dplyr::select(COLABORADOR,DATA,WDAY,HORARIO,DIA_TIPO,TIPO_TURNO) %>% unique() %>% 
      dplyr::arrange(COLABORADOR,DATA) %>% 
      # dplyr::group_by(COLABORADOR) %>% 
      dplyr::mutate(PREV_HORARIO = lag(HORARIO),
                    NEXT_HORARIO = lead(HORARIO) ) %>% 
      dplyr::filter(
        !(
          grepl('L_|C',NEXT_HORARIO , ignore.case = TRUE) |
            grepl('L_|C',PREV_HORARIO , ignore.case = TRUE)
        ),(HORARIO == 'H') & DIA_TIPO!='domYf') %>% 
      dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
    
    
    
    semanaQs <- expandFunc(semanaQs)
    
    ##extrair domngos e festivos com pessoas a trabalhar
    trabM2 <- matriz2_1 %>% 
      merge(semanaQs, by=c('COLABORADOR','DATA','TIPO_TURNO')) %>% 
      dplyr::filter(HORARIO!=0)
    }
  #dplyr::filter(any(HORARIO == 'H'))
  # fdssssa <<- T
  
  else{
    
    if(all(month(paridadeMes$DATA) %% 2 == 0)){
      
      semanaQs <- matriz2 %>% 
        dplyr::group_by(COLABORADOR,WW) %>% 
        dplyr::filter(!any(HORARIO=='L_QS')) %>% 
        ungroup() %>% 
        dplyr::filter(HORARIO!=0) %>% 
        dplyr::select(COLABORADOR,DATA,WDAY,HORARIO,DIA_TIPO,TIPO_TURNO) %>% unique() %>% 
        dplyr::arrange(COLABORADOR,DATA) %>% 
        # dplyr::group_by(COLABORADOR) %>% 
        dplyr::mutate(PREV_HORARIO = lag(HORARIO),
                      NEXT_HORARIO = lead(HORARIO) ) %>% 
        dplyr::filter(
          !(
            grepl('L_|C',NEXT_HORARIO , ignore.case = TRUE) |
              grepl('L_|C',PREV_HORARIO , ignore.case = TRUE)
          ),(HORARIO == 'H') & DIA_TIPO!='domYf',
          month(DATA) %% 2 == 0,
          !(month(DATA) %in% paridadeMes$MES)
          ) %>% 
        dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
      
      
      
      semanaQs <- expandFunc(semanaQs)
      ##extrair domngos e festivos com pessoas a trabalhar
      trabM2 <- matriz2_1 %>% 
        merge(semanaQs, by=c('COLABORADOR','DATA','TIPO_TURNO')) %>% 
        dplyr::filter(HORARIO!=0)
      
    } else {
      
      semanaQs <- matriz2 %>% 
        dplyr::group_by(COLABORADOR,WW) %>% 
        dplyr::filter(!any(HORARIO=='L_QS')) %>% 
        ungroup() %>% 
        dplyr::filter(HORARIO!=0) %>% 
        dplyr::select(COLABORADOR,DATA,WDAY,HORARIO,DIA_TIPO,TIPO_TURNO) %>% unique() %>% 
        dplyr::arrange(COLABORADOR,DATA) %>% 
        # dplyr::group_by(COLABORADOR) %>% 
        dplyr::mutate(PREV_HORARIO = lag(HORARIO),
                      NEXT_HORARIO = lead(HORARIO) ) %>% 
        dplyr::filter(
          !(
            grepl('L_|C',NEXT_HORARIO , ignore.case = TRUE) |
              grepl('L_|C',PREV_HORARIO , ignore.case = TRUE)
          ),(HORARIO == 'H') & DIA_TIPO!='domYf',
          month(DATA) %% 2 != 0,
          !(month(DATA) %in% paridadeMes$MES)
          ) %>% 
        dplyr::select(COLABORADOR,DATA,TIPO_TURNO) 
      
      
      semanaQs <- expandFunc(semanaQs)
      
      ##extrair domngos e festivos com pessoas a trabalhar
      trabM2 <- matriz2_1 %>% 
        merge(semanaQs, by=c('COLABORADOR','DATA','TIPO_TURNO')) %>% 
        dplyr::filter(HORARIO!=0)
      
    }
    
  }
  matriz2 <- matriz2_1
  
  ##se existirem pessoas a trabalhar, escolher dia das hiposteses
  if (nrow(trabM2)>0) {
    trabM2 <- selectBestLD(matriz2,trabM2,semanasTrabalho,semanasTotal,colabTotal,matrizB)
    res <- getDayShift(matrizB,trabM2,filtroHorario,relaxaMin,matriz2_bk,maxRelax)
  }
  
  return(res)
  
}


###FUNC PARA LD------------------------------------------------
selectLD <- function(matrizA,matrizB, matriz2,filtroHorario,semanasTrabalho,semanasTotal, colabTotal,relaxaMin,matriz2_bk,matrizXor,maxRelax){
  
  res <- data.table()
  
  #totalizador LD possiveis por semana
  totalXor <- colSums(matrizXor > 0, na.rm = TRUE)
  
  #escolhe semana com mais hipoteses
  maxSemana <- as.numeric(names(totalXor[totalXor==max(totalXor)]))
  #extrai valores da semana escolhida
  vals <- unique(c(matrizXor[, maxSemana]))
  #filtrar valor >0, junta "nome" da semana
  vals <- unique(c(vals[vals>0],maxSemana))
  
  semanaLD <- matriz2 %>%
    dplyr::filter(WW %in% vals)
  
  matriz2_1 <- matriz2
  matriz2 <- collapseFunc(matriz2_1)
  
  diasPossiveis <- matriz2 %>%
    dplyr::filter(HORARIO!=0) %>%
    dplyr::select(COLABORADOR,DATA,WDAY,HORARIO,DIA_TIPO,TIPO_TURNO) %>% unique() %>%
    dplyr::arrange(COLABORADOR,DATA) %>%
    dplyr::group_by(COLABORADOR) %>%
    dplyr::mutate(PREV_HORARIO = lag(HORARIO),
                  NEXT_HORARIO = lead(HORARIO) ) %>%
    dplyr::filter(
      !(#grepl('L_|C',HORARIO , ignore.case = TRUE) |
        grepl('L_|C',NEXT_HORARIO , ignore.case = TRUE) |
          grepl('L_|C',PREV_HORARIO , ignore.case = TRUE)
      ),(HORARIO %in% c('H')), DIA_TIPO!='domYf') %>%
    dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
  
  
  diasPossiveis <- expandFunc(diasPossiveis)
  
  ##extrair domngos e festivos com pessoas a trabalhar
  trabM2 <- semanaLD %>%
    merge(diasPossiveis, by=c('COLABORADOR','DATA','TIPO_TURNO')) %>%
    dplyr::filter(HORARIO!=0)
  
  matriz2 <- matriz2_1
  
  ##se existirem pessoas a trabalhar, escolher dia das hiposteses
  if (nrow(trabM2)>0) {
    ##de todos os dias(semanas disponiveis) escolhe o melhor das estimativas
    # trabM2 <- selectBestLDloop(matriz2,trabM2,semanasTrabalho,semanasTotal,colabTotal)
    
    ##de todos os dias(semanas disponiveis):
    ### 1º escolhe semana com mais dias de trabalho
    ### 2º escolhe o melhor dias das estimativas
    trabM2 <- selectBestLD(matriz2,trabM2,semanasTrabalho,semanasTotal,colabTotal,matrizB)
    
    res <- getDayShift(matrizB,trabM2,filtroHorario,relaxaMin,matriz2_bk,maxRelax)
  }
  
  return(res)
  
}

###FUNC PARA CXX --------------------------------------------------------
selectCXX <- function(matrizA,matrizB, matriz2,filtroHorario,semanasTrabalho,
                      semanasTotal, colabTotal,relaxaMin,matriz2_bk,maxRelax){
  
  res <- data.table()
  
  
  ##extrair dias semana com pessoas em LD
  semanaL <- matriz2 %>% 
    dplyr::arrange(COLABORADOR,DATA) %>% 
    unique() 
  
  
  matriz2_1 <- matriz2
  matriz2 <- collapseFunc(matriz2) %>% 
    dplyr::mutate(WW = isoweek(DATA))
  
  if (nrow(semanaL)>0) {
    ###identificar sabados e segundas
    # sabSeg <- sort(c(unique(domL$DATA)-1,unique(domL$DATA),unique(domL$DATA)+1))
    
    ##extrair sabados e segundas com pessoas a trabalhar, ao lado de um domingo com L
    # semanaXX <- matriz2 %>% 
    #   dplyr::mutate(WW = isoweek(DATA)) %>% 
    #   dplyr::group_by(COLABORADOR,WW) %>% 
    #   dplyr::filter(!any(HORARIO=='CXX')) %>% 
    #   ungroup() %>% 
    #   dplyr::filter(HORARIO!=0) %>%
    #   dplyr::select(COLABORADOR,DATA,WDAY,HORARIO,DIA_TIPO,TIPO_TURNO) %>% unique() %>% 
    #   dplyr::group_by(COLABORADOR) %>% 
    #   dplyr::mutate(PREV_HORARIO = lag(HORARIO),
    #                 NEXT_HORARIO = lead(HORARIO) ) %>% 
    #   dplyr::filter(
    #     (grepl(filtroHorario,HORARIO , ignore.case = TRUE) & NEXT_HORARIO=='L_D' & !grepl('L_|C',PREV_HORARIO , ignore.case = TRUE)) |
    #       (grepl(filtroHorario,HORARIO , ignore.case = TRUE) & PREV_HORARIO=='L_D' & !grepl('L_|C',NEXT_HORARIO , ignore.case = TRUE))
    #   ,grepl(filtroHorario,HORARIO , ignore.case = TRUE),DIA_TIPO!='domYf') %>%
    #   dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
    # 
    # 
    # if (nrow(semanaXX)==0) {
      semanaXX <- matriz2 %>% 
        dplyr::group_by(COLABORADOR,WW) %>% 
        dplyr::filter(!any(HORARIO=='CXX')) %>% 
        ungroup() %>% 
        dplyr::filter(HORARIO!=0) %>%
        dplyr::select(COLABORADOR,DATA,WDAY,HORARIO,DIA_TIPO,TIPO_TURNO) %>% unique() %>% 
        dplyr::group_by(COLABORADOR) %>% 
        dplyr::mutate(PREV_HORARIO = lag(HORARIO),
                      NEXT_HORARIO = lead(HORARIO) ) %>% 
        dplyr::filter(
          (grepl(filtroHorario,HORARIO , ignore.case = TRUE) & NEXT_HORARIO  %in% c('L_RES','L_Q','L_D') & !grepl('L_|C',PREV_HORARIO , ignore.case = TRUE)) |
            (grepl(filtroHorario,HORARIO , ignore.case = TRUE) & PREV_HORARIO %in% c('L_RES','L_Q','L_D') & !grepl('L_|C',NEXT_HORARIO , ignore.case = TRUE))
        ,grepl(filtroHorario,HORARIO , ignore.case = TRUE),DIA_TIPO!='domYf') %>%
        dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
    # }
    
    semanaXX <- expandFunc(semanaXX)
    matriz2 <- matriz2_1
    
    trabM2 <- matriz2 %>%
      merge(semanaXX, by=c('COLABORADOR','DATA','TIPO_TURNO')) %>% 
      dplyr::filter(HORARIO!=0)
    
    ##se existirem pessoas a trabalhar, escolher dia/turno das hiposteses
    if (nrow(trabM2)>0) {
      trabM2 <- selectBestLD(matriz2,trabM2,semanasTrabalho,semanasTotal,colabTotal,matrizB)
      res <- getDayShift(matrizB, trabM2,filtroHorario,relaxaMin,matriz2_bk,maxRelax)
    }
  }
  
  return(res)
  
  
}


###FUNC PARA LQ ----------------------------------------------------------------
selectLQ <- function(matrizA,matrizB, matriz2, filtroHorario,relaxaMin,matriz2_bk,maxRelax){
  
  res <- data.table()
  
  matriz2_1 <- matriz2
  matriz2 <- collapseFunc(matriz2) %>% 
    dplyr::mutate(WW = isoweek(DATA))
  
  ##extrair domingos fechados e Calidad
  semanaLQ <- matriz2 %>% 
    dplyr::group_by(COLABORADOR,WW) %>% 
    dplyr::filter(!any(HORARIO=='L_Q')) %>% 
    ungroup() %>% 
    dplyr::filter(HORARIO!=0) %>% 
    dplyr::select(COLABORADOR,DATA,WDAY,HORARIO,DIA_TIPO,TIPO_TURNO) %>% unique() %>% 
    dplyr::arrange(COLABORADOR,DATA) %>% 
    dplyr::mutate(PREV_HORARIO = lag(HORARIO),
                  NEXT_HORARIO = lead(HORARIO) ) %>% 
    dplyr::filter(
      !(
          grepl('L_|C',NEXT_HORARIO , ignore.case = TRUE) |
          grepl('L_|C',PREV_HORARIO , ignore.case = TRUE)
      ),(HORARIO == 'H') & DIA_TIPO!='domYf') %>% 
    dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
  
  
  semanaLQ <- expandFunc(semanaLQ)
  matriz2 <- matriz2_1
  
  ##extrair domngos e festivos com pessoas a trabalhar
  trabM2 <- matriz2 %>% 
    merge(semanaLQ, by=c('COLABORADOR','DATA','TIPO_TURNO')) %>% 
    dplyr::filter(HORARIO!=0) 
  
  ##se existirem pessoas a trabalhar, escolher dia das hiposteses
  if (nrow(trabM2)>0) {
    trabM2 <- selectBestLD(matriz2,trabM2,semanasTrabalho,semanasTotal,colabTotal,matrizB)
    res <- getDayShift(matrizB,trabM2,filtroHorario,relaxaMin,matriz2_bk,maxRelax)
  }
  
  return(res)
  
}

###FUNC PARA LQ E L_RES----------------------------------------------------------------
selectL <- function(matrizA,matrizB, matriz2, filtroHorario,semanasTrabalho,
                    semanasTotal, colabTotal, mudaLvizinhos,relaxaMin,matriz2_bk,maxRelax, tipoFolga2){
  
  res <- data.table()
  
  
  matriz2_1 <- matriz2
  
  matriz2 <- matriz2 %>%
    dplyr::filter(HORARIO!=0)
  
  matriz2 <- collapseFunc(matriz2)
  
  
  if (!is.null(tipoFolga2) && tipoFolga2=='SABADO') {
    ##extrair domngos e festivos com pessoas a trabalhar
    # matriz2 <- matriz2 %>%
    #   dplyr::filter(HORARIO!=0, WDAY == 7)
    ##extrair domingos fechados e Calidad
    semanaLQ <- matriz2 %>% 
      dplyr::filter(HORARIO!=0) %>% 
      dplyr::select(COLABORADOR,DATA,WDAY,HORARIO,DIA_TIPO,TIPO_TURNO) %>% unique() %>% 
      dplyr::arrange(COLABORADOR,DATA) %>%
      dplyr::mutate(PREV_HORARIO = lag(HORARIO),
                    NEXT_HORARIO = lead(HORARIO) ) %>% ungroup() %>%
      dplyr::filter(
        !(grepl('L_|C',NEXT_HORARIO , ignore.case = TRUE) |
            grepl('L_|C',PREV_HORARIO , ignore.case = TRUE)
        ),(HORARIO %in% c('H')), DIA_TIPO!='domYf') %>% 
      dplyr::filter(HORARIO!=0, WDAY == 7) %>% 
      dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
  } else{
    # matriz2 <- matriz2 %>%
    #   dplyr::filter(HORARIO!=0)
    ##extrair domingos fechados e Calidad
    # semanaLQ <- matriz2 %>% 
    #   dplyr::filter(HORARIO!=0) %>% 
    #   dplyr::select(COLABORADOR,DATA,WDAY,HORARIO,DIA_TIPO,TIPO_TURNO) %>% unique() %>% 
    #   dplyr::arrange(COLABORADOR,DATA) %>%
    #   dplyr::mutate(PREV_HORARIO = lag(HORARIO),
    #                 NEXT_HORARIO = lead(HORARIO) ) %>% ungroup() %>%
    #   dplyr::filter(
    #     !(grepl('L_|C',NEXT_HORARIO , ignore.case = TRUE) |
    #         grepl('L_|C',PREV_HORARIO , ignore.case = TRUE)
    #     ),(HORARIO %in% c('H')), DIA_TIPO!='domYf', WDAY != 7) %>% 
    #   dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
    
    if (matrizA$TIPO_CONTRATO <=3 ) {
      
      semanaLQ <- matriz2 %>% 
        dplyr::filter(HORARIO!=0) %>% 
        dplyr::select(COLABORADOR,DATA,WDAY,HORARIO,DIA_TIPO,TIPO_TURNO) %>% unique() %>% 
        dplyr::arrange(COLABORADOR,DATA) %>%
        dplyr::mutate(PREV_HORARIO = lag(HORARIO),
                      NEXT_HORARIO = lead(HORARIO) ) %>% ungroup() %>%
        dplyr::filter(
          !(grepl('L_|C',NEXT_HORARIO , ignore.case = TRUE) |
              grepl('L_|C',PREV_HORARIO , ignore.case = TRUE)
          ),(HORARIO %in% c('H')), DIA_TIPO!='domYf') %>% 
        dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
    } else {
      semanaLQ <- matriz2 %>% 
        dplyr::filter(HORARIO!=0) %>% 
        dplyr::select(COLABORADOR,DATA,WDAY,HORARIO,DIA_TIPO,TIPO_TURNO) %>% unique() %>% 
        dplyr::arrange(COLABORADOR,DATA) %>%
        dplyr::mutate(PREV_HORARIO = lag(HORARIO),
                      NEXT_HORARIO = lead(HORARIO) ) %>% ungroup() %>%
        dplyr::filter(
          !(grepl('L_|C',NEXT_HORARIO , ignore.case = TRUE) |
              grepl('L_|C',PREV_HORARIO , ignore.case = TRUE)
          ),(HORARIO %in% c('H')), DIA_TIPO!='domYf', WDAY != 7) %>% 
        dplyr::select(COLABORADOR,DATA,TIPO_TURNO)
    }
  }
  
  
   
  # }
  
    semanaLQ <- expandFunc(semanaLQ)
    matriz2 <- matriz2_1
    
  ##extrair domngos e festivos com pessoas a trabalhar
  trabM2 <- matriz2 %>% 
    merge(semanaLQ, by=c('COLABORADOR','DATA','TIPO_TURNO')) %>% 
    dplyr::filter(HORARIO!=0)
  
  ##se existirem pessoas a trabalhar, escolher dia das hiposteses
  if (nrow(trabM2)>0) {
    print("trabM2")
    trabM2 <- selectBestLD(matriz2,trabM2,semanasTrabalho,semanasTotal,colabTotal,matrizB)
    res <- getDayShift(matrizB,trabM2,filtroHorario,relaxaMin,matriz2_bk,maxRelax)
  }
  
  return(res)
  
}




###FUNC GLOBAL GET DIA/TRUNO--------------------------------------------------------
getDayShift <- function(matrizB,trabM2, filtroHorario,relaxaMin=F,matriz2_bk, maxRelax=F){
  res <- data.table()
  # fds11 <<- matrizB
  # fds22 <<- trabM2
  ###filtrar dias escolhidos na matrizB
  
  if (relaxaMin==F) {
    ##filtra dias/turno com pessoas a trabalhar > minTurno
    trabMB <- matrizB %>%
      merge(trabM2 %>% dplyr::select(DATA,TIPO_TURNO),
            by = c("DATA","TIPO_TURNO")) %>% 
      # dplyr::mutate(minTurno=`+H`) %>%
      dplyr::filter(`+H` > minTurno) %>% dplyr::filter(`+H` > 1)
  } else{
    if (maxRelax==F) {
      ##filtra dias/turno com pessoas a trabalhar > 1
      trabMB <- matrizB %>%
        merge(trabM2 %>% dplyr::select(DATA,TIPO_TURNO),
              by = c("DATA","TIPO_TURNO")) %>%
        # dplyr::mutate(minTurno=`+H`) %>%
        dplyr::filter(`+H` > 1)
      # 
      if (nrow(trabMB)==0) {
        ##filtra dias com pessoas a trabalhar > 1
        trabMB <- matrizB %>%
          merge(trabM2 %>% dplyr::select(DATA) %>% unique(),
                by = c("DATA")) %>%
          dplyr::group_by(DATA) %>% 
          dplyr::mutate(H = sum(`+H`)) %>% ungroup() %>% 
          dplyr::filter( H > 1) %>% 
          merge(trabM2 %>% dplyr::select(DATA,TIPO_TURNO),
                by = c("DATA","TIPO_TURNO"))
      }
    } else{
      # print(porqueeeeeeeeeeeeeeeeeeeeeeeeeeee)
      ##filtra dias com pessoas a trabalhar > 0
      trabMB <- matrizB %>%
        merge(trabM2 %>% dplyr::select(DATA) %>% unique(),
              by = c("DATA")) %>%
        dplyr::group_by(DATA) %>% 
        dplyr::mutate(H = sum(`+H`)) %>% ungroup() %>% 
        dplyr::filter( H > 0) %>% 
        merge(trabM2 %>% dplyr::select(DATA,TIPO_TURNO),
              by = c("DATA","TIPO_TURNO"))
    }
    
  }
  
  
  if (nrow(trabMB)>0) {
    print("trabM")
    ###extrair dias com maior diff (mB)
    trabMB <- trabMB %>%
      dplyr::filter(diff == max(diff))

    res <- trabM2 %>%
      merge(trabMB %>% dplyr::select(DATA,TIPO_TURNO),
            by = c("DATA","TIPO_TURNO")) %>%
      #dplyr::filter(HORARIO == 'H') %>%
      dplyr::filter(grepl(filtroHorario,HORARIO , ignore.case = TRUE)) %>%
      dplyr::rename(TURNO = TIPO_TURNO) %>%
      dplyr::select(DATA,TURNO,COLABORADOR) %>% unique()
    
    ###extrair dias com minimo obj (mB)
    if (nrow(res)>1) {
      # print("trabMB")
      # trabMB <- trabMB %>%
      #   dplyr::filter(pessObj == min(pessObj))
      # 
      # res <- trabM2 %>%
      #   merge(trabMB %>% dplyr::select(DATA,TIPO_TURNO),
      #         by = c("DATA","TIPO_TURNO")) %>%
      #   # dplyr::filter(HORARIO == 'H') %>%
      #   dplyr::filter(grepl(filtroHorario,HORARIO , ignore.case = TRUE)) %>%
      #   dplyr::rename(TURNO = TIPO_TURNO) %>%
      #   dplyr::select(DATA,TURNO,COLABORADOR) %>% unique()
      
      print("trabB2")
      
      diasMinL <- matriz2_bk %>% dplyr::filter(COLABORADOR != 'TIPO_DIA') %>% 
        merge(trabMB %>% dplyr::select(DATA) %>% unique(),
              by = c("DATA")) %>%
        dplyr::group_by(DATA) %>% 
        dplyr::mutate(L_count = sum(grepl('L_|V|C',HORARIO))) %>% ungroup() %>% 
        dplyr::filter(L_count == min(L_count, na.rm = T)) %>% 
        merge(trabM2 %>% dplyr::select(DATA,TIPO_TURNO),
              by = c("DATA","TIPO_TURNO")) %>% 
        dplyr::filter(COLABORADOR %in% unique(trabM2$COLABORADOR))
      
      res <- matriz2_bk %>%
        merge(diasMinL %>% dplyr::select(DATA,TIPO_TURNO,COLABORADOR),
              by = c("DATA","TIPO_TURNO","COLABORADOR")) %>%
        # dplyr::filter(HORARIO == 'H') %>%
        dplyr::filter(grepl(filtroHorario,HORARIO , ignore.case = TRUE)) %>%
        dplyr::rename(TURNO = TIPO_TURNO) %>%
        dplyr::select(DATA,TURNO,COLABORADOR) %>% unique()
      
      ###extrair dias/turno com minimo desc_atribuido (m2)
      if (nrow(res)>1) {#if (nrow(trabMB)>1) {
        # print("trabB2")
        # 
        # diasMinL <- matriz2_bk %>% dplyr::filter(COLABORADOR != 'TIPO_DIA') %>% 
        #   merge(trabMB %>% dplyr::select(DATA) %>% unique(),
        #         by = c("DATA")) %>%
        #   dplyr::group_by(DATA) %>% 
        #   dplyr::mutate(L_count = sum(grepl('L_|V|C',HORARIO))) %>% ungroup() %>% 
        #   dplyr::filter(L_count == min(L_count, na.rm = T)) %>% 
        #   merge(trabM2 %>% dplyr::select(DATA,TIPO_TURNO),
        #         by = c("DATA","TIPO_TURNO")) %>% 
        #   dplyr::filter(COLABORADOR %in% unique(trabM2$COLABORADOR))
        # 
        # res <- matriz2_bk %>%
        #   merge(diasMinL %>% dplyr::select(DATA,TIPO_TURNO,COLABORADOR),
        #         by = c("DATA","TIPO_TURNO","COLABORADOR")) %>%
        #   # dplyr::filter(HORARIO == 'H') %>%
        #   dplyr::filter(grepl(filtroHorario,HORARIO , ignore.case = TRUE)) %>%
        #   dplyr::rename(TURNO = TIPO_TURNO) %>%
        #   dplyr::select(DATA,TURNO,COLABORADOR) %>% unique()
        print("trabMB")
        trabMB <- trabMB %>%
          merge(diasMinL, by=c('DATA','TIPO_TURNO')) %>% 
          dplyr::filter(pessObj == min(pessObj))
        
        res <- trabM2 %>%
          merge(trabMB %>% dplyr::select(DATA,TIPO_TURNO),
                by = c("DATA","TIPO_TURNO")) %>%
          # dplyr::filter(HORARIO == 'H') %>%
          dplyr::filter(grepl(filtroHorario,HORARIO , ignore.case = TRUE)) %>%
          dplyr::rename(TURNO = TIPO_TURNO) %>%
          dplyr::select(DATA,TURNO,COLABORADOR) %>% unique()
        
        #EXTRAIR A SORTE
        if (nrow(res)>1) {#if (nrow(diasMinL)>1) {
          #escolher turno a sorte
          print("diasMinL")
          res <- res %>%
            slice(sample(1:nrow(res),1)) 
        }
      }
      
    }
    
  }
  return(res)
}
