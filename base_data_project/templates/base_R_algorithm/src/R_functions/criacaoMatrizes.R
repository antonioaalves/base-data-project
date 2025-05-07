criacaoMatrizes <- function(infoGeral, dfDescansos, matrizInicial, fatorPonderacao1, fatorPonderacao2, fatorPonderacao3, 
                            fatorPonderacao4, fatorPonderacao5, fatorPonderacao6, fatorPonderacao7, dfRegras, var_OPC,var_OU,var_OBR){

  
  matrizInicial <- fread(paste0(pathOS,"/Docs/MA_V3.csv"), encoding = 'UTF-8')
  
  

  split_data_frames <- split(matrizInicial, interaction(matrizInicial$UNIDADE, matrizInicial$SECAO, drop = TRUE))
  
  #LEGANES ID==4
  #View(split_data_frames[[4]])
  

  matrizInicial <- split_data_frames[[1]]
  
  # paste0("'",gsub("ESP","",matrizInicial$MATRICULA),sep="',")
  
  matrizInicial %>% 
    dplyr::filter(DIAS_SEMANA_MEDIA > 0) %>% 
    dplyr::select(-c(INI_TURNO_1,FIM_TURNO_1,INI_TURNO_2,FIM_TURNO_2)) %>% 
    dplyr::mutate(
      OUT = NA,
      DyF_TRAB_MAX = as.numeric(ifelse(DyF_TRAB_MAX=='TODOS',63,DyF_TRAB_MAX)),
      TOTAL_DyF = 63,
      LDF = TOTAL_DyF - DyF_TRAB_MAX,
      LD = DyF_TRAB_MAX) %>% 
    dplyr::mutate(L_TOTAL = ifelse(DIAS_SEMANA_MEDIA %in% c(2,3),0,L_TOTAL )) %>% 
    dplyr::select(UNIDADE,SECAO,CONVENIO,MATRICULA,HORAS, CARGA_ANUAL,TIPO_TURNO_1,TIPO_TURNO_2,DIAS_SEMANA_MEDIA,DIAS_VAZIOS,OUT,
                  L_TOTAL, LDF, FDS_QL_2D, FDS_QL_3D, LD, QL_2D, LQ) %>% View()
 
  
  dcast(matrix1, MATRICULA~DATA, value.var = 'TIPO') %>% View()
  
  
  diarizacao <- read_xlsx(paste0(pathOS,"/Docs/FORECAST.xlsx"))
  
  
  
  matrizInicial <- fread(paste0(pathOS,"/Docs/Alcampo MA e M1 Teste.csv"), encoding = 'UTF-8')
  
  
  split_data_frames <- split(matrizInicial, interaction(matrizInicial$UNIDADE, matrizInicial$SECAO, drop = TRUE))
  
  #LEGANES ID==4
  #View(split_data_frames[[4]])
  
  
  matrizInicial <- split_data_frames[[1]]
  
  #CREATE MATRIX 1
  dias <- seq.Date(as.Date('2023-12-18'),as.Date('2025-01-12'), by ='days')
  dias_column <- rep(dias, length(unique(matrizInicial$COLABORADOR)))
  colabs_column <- rep(unique(matrizInicial$COLABORADOR), each=length(dias) )
  
  matrix1 <- data.table(MATRICULA = colabs_column, DATA = dias_column, TIPO='T')
  
  matrix1$WNUM <- week(matrix1$DATA)
  
  
  # dfDescansos <- dfDescansos %>% dplyr::filter(ADJUST_CYCLE_ID== 'D/V')
  
  # infoGeral <- infoGeral %>% dplyr::filter(ADJUST_CYCLE_ID== 'D/V')
  
  feriados <- c(as.Date("2023-12-25 00:00:00"),
                as.Date("2024-01-01 00:00:00"),
                as.Date("2024-01-06 00:00:00"),
                as.Date("2024-03-19 00:00:00"),
                as.Date("2024-04-07 00:00:00"),
                as.Date("2024-04-10 00:00:00"),
                as.Date("2024-04-17 00:00:00"),
                as.Date("2024-05-28 00:00:00"),
                as.Date("2024-06-24 00:00:00"),
                as.Date("2024-08-15 00:00:00"),
                as.Date("2024-10-12 00:00:00"),
                as.Date("2024-11-01 00:00:00"),
                as.Date("2024-12-06 00:00:00"),
                as.Date("2024-12-08 00:00:00"),
                as.Date("2024-12-25 00:00:00"),
                as.Date("2025-01-01 00:00:00"))
  
  infoGeral <- infoGeral %>% 
    dplyr::select(-c(BEGIN_DATE, END_DATE, TOTAL_HOLIDAYS, VACATION_DAYS))
  
  
  # Replace all NA values in those rows with 0 for all columns
  infoGeral[infoGeral$STATUS == "N", ] <- lapply(infoGeral[infoGeral$STATUS == "N", ], function(x) replace(x, is.na(x), 0))
  
  colabsStatusN <- infoGeral %>% dplyr::filter(STATUS == 'N') %>% .$EMPLOYEE_ID
  
  
  infoGeral$TOTAL_AGG_DAY_OFF <- infoGeral$TOTAL_FIRST_DAY_OFF + infoGeral$TOTAL_SECOND_DAY_OFF 
  
  matrizInicial$SCHEDULE_DAY <- as.Date(matrizInicial$SCHEDULE_DAY)
  
  matrizInicial$WD <- lubridate::wday(matrizInicial$SCHEDULE_DAY, label=T, abbr = T)
  
  matrizInicial <- matrizInicial %>% 
    # dplyr::select(-NEW_SCHEDULE_TYPE) %>%
    dplyr::mutate(OLD_SCHEDULE_TYPE=case_when(
      FK_MOTIVO_AUSENCIA==761 ~ 'V', #motivo ferias tst09
      FK_MOTIVO_AUSENCIA==1 ~ 'V', #motivo ferias pruebas
      TRUE ~ OLD_SCHEDULE_TYPE))
  
  matrizInicial <- matrizInicial %>% 
    dplyr::select(-FK_MOTIVO_AUSENCIA) 
  
  ## Verificar descansos já atribuidos
  
  matrizInicial <- matrizInicial %>% 
    dplyr::mutate(OLD_SCHEDULE_TYPE = ifelse((EMPLOYEE_ID %in% colabsStatusN & OLD_SCHEDULE_TYPE == 'F' & WD != dfDescansos$Folga), 'D', OLD_SCHEDULE_TYPE))
  
  matrizInicial <- matrizInicial %>%
    dplyr::mutate(OLD_SCHEDULE_TYPE=case_when(
      SCHEDULE_DAY %in%  feriados ~ 'R',
      TRUE ~ OLD_SCHEDULE_TYPE)) 
  
  matrizInicial <- matrizInicial %>%
    dplyr::arrange(EMPLOYEE_ID, SCHEDULE_DAY) %>% 
    dplyr::group_by(EMPLOYEE_ID) %>% 
    dplyr::mutate(LEAD=lead(OLD_SCHEDULE_TYPE, default='T'), 
                  OLD_SCHEDULE_TYPE=case_when(
                    WD==dfDescansos$D6 & LEAD=='R' & OLD_SCHEDULE_TYPE=='T' ~ 'F',
                    TRUE ~ OLD_SCHEDULE_TYPE)) %>% 
    ungroup()
  
  start_date <- as.Date(min(matrizInicial$SCHEDULE_DAY))
  end_date <- as.Date(max(matrizInicial$SCHEDULE_DAY)) 
  
  dateSequence <- seq(start_date, end_date, by="day")
  employeeID <- unique(matrizInicial$EMPLOYEE_ID)
  
  dateSequence <- crossing(dateSequence, employeeID)
  names(dateSequence) <- c('SCHEDULE_DAY', 'EMPLOYEE_ID')
  
  matrizInicial <- merge(dateSequence, matrizInicial, by=c('SCHEDULE_DAY', 'EMPLOYEE_ID'), all.x=T)
  
  matrizInicial <- matrizInicial %>% 
    dplyr::mutate(PROCESS_ID = process_id,
                  OLD_SCHEDULE_TYPE = ifelse(is.na(OLD_SCHEDULE_TYPE), 'A', OLD_SCHEDULE_TYPE))
  
  matrizInicial <- merge(matrizInicial, infoGeral, by=c('EMPLOYEE_ID', 'PROCESS_ID'))
  
  matrizInicial$WD <- lubridate::wday(matrizInicial$SCHEDULE_DAY, label=T, abbr = T)
  
  
  ##seleciona só F ao sábado
  # matrizInicial <- matrizInicial %>%
  #   dplyr::filter(GROUP_ID=='6536') %>%
  #   dplyr::filter(EMPLOYEE_ID != '8885')
  
  
  
  matrizInicial <- matrizInicial %>% 
    dplyr::select(-c(LEAD, UNIT_ID, SECTION_ID, GROUP_ID))
  
  
  matrizInicial$DATA <- paste0(matrizInicial$SCHEDULE_DAY, '_', matrizInicial$WD)
  
  
  matrizInicial$WEEK_NUMB <- lubridate::isoweek(matrizInicial$SCHEDULE_DAY + 1)
  
  matrizInicial <- matrizInicial %>% 
    dplyr::mutate(WEEK_NUMB=ifelse(SCHEDULE_DAY<'2023-12-31',0,WEEK_NUMB))
  
  matrizInicial <- matrizInicial %>% 
    dplyr::mutate(WEEK_NUMB=ifelse(SCHEDULE_DAY>'2024-12-28',53,WEEK_NUMB))
  
  
  # matrizInicial <- matrizInicial %>% 
  #   dplyr::select(-c(WD))
  
  matrizInicial <- matrizInicial %>% 
    dplyr::select(-c(TOTAL_FIRST_DAY_OFF, TOTAL_SECOND_DAY_OFF, ADJUST_CYCLE_ID))
  
  matrizInicialV <- matrizInicial %>% 
    dplyr::group_by(EMPLOYEE_ID, WEEK_NUMB, OLD_SCHEDULE_TYPE) %>% 
    dplyr::summarise(COUNT=n(),
                     .groups = 'drop') %>% 
    dplyr::filter(OLD_SCHEDULE_TYPE=='V') %>% 
    dplyr::filter(COUNT>0) %>% 
    dplyr::group_by(EMPLOYEE_ID) %>% 
    dplyr::summarise(COUNT=n(),
                     .groups = 'drop')
  
  matrizInicial <- merge(matrizInicial, matrizInicialV, by=c('EMPLOYEE_ID'))
  
  
  matrizInicial <- matrizInicial %>% 
    dplyr::rename(WEEK_COM_FERIAS=COUNT)
  
  #16 feriados -1 ("2023-12-25" semana 0) - 2 ao sabado - 2 (semanas com 2feriados conseccutivos )
  
  matrizInicial <- matrizInicial %>% 
    #dplyr::mutate(DELTA=52-11-WEEK_COM_FERIAS)
    dplyr::mutate(DELTA=53-10-WEEK_COM_FERIAS)
  
  # matrizInicial$D2 <- 0
  # matrizInicial$D3 <- 0
  # matrizInicial$D4 <- 0
  # matrizInicial$D5 <- 0
  # matrizInicial$D6 <- 0
  # matrizInicial$D1 <- 0
  
  
  matrizInicial <- matrizInicial %>% 
    dplyr::mutate(WD_DIN = case_when( 
      matrizInicial$WD == dfDescansos$D2 ~ "D2",
      matrizInicial$WD == dfDescansos$D3 ~ "D3",
      matrizInicial$WD == dfDescansos$D4 ~ "D4",
      matrizInicial$WD == dfDescansos$D5 ~ "D5",
      matrizInicial$WD == dfDescansos$D6 ~ "D6",
      matrizInicial$WD == dfDescansos$D1 ~ "D1"
  ))
  
  matrizInicial$CONT <- 0
  
  matrizInicial <- matrizInicial %>% 
    dplyr::mutate(CONT = case_when( 
      OLD_SCHEDULE_TYPE == 'D' ~ 1, T ~ CONT
    ))
  
  
  matrizInicial <- matrizInicial %>% 
    dplyr::select(-c(PROCESS_ID))
  
  matriz1 <- reshape2::dcast(matrizInicial, 
                             EMPLOYEE_ID +  STATUS + TOTAL_AGG_DAY_OFF + TOTAL_DAYS_OFF + WEEK_COM_FERIAS + DELTA ~ WD_DIN, 
                             value.var = 'CONT', fun.aggregate = sum) 
  
  matriz1 <- matriz1 %>% 
    dplyr::select(-c(`NA`))

  # matrizInicialDs <- reshape2::dcast(matrizInicialDs,
  #                            EMPLOYEE_ID + STATUS + TOTAL_AGG_DAY_OFF + TOTAL_DAYS_OFF + WEEK_COM_FERIAS + DELTA + D2 + D3 + D4 + D5 + D6 + D1 ~ DATA,
  #                            value.var = 'STATUS')
  # 
  # matrizInicialDs <- matrizInicialDs %>% group_by()
  # 
  # matriz1 <- reshape2::dcast(matrizInicial, 
  #                            EMPLOYEE_ID + STATUS + TOTAL_AGG_DAY_OFF + TOTAL_DAYS_OFF + WEEK_COM_FERIAS + DELTA + D2 + D3 + D4 + D5 + D6 + D1 ~ DATA, 
  #                            value.var = 'OLD_SCHEDULE_TYPE') 
  
  #### FILTRAR COLABORADORES COM MAIS DIAS A ATRIBUIR QUE POSSIVEIS
  matriz1 <- matriz1 %>%
    dplyr::filter(TOTAL_DAYS_OFF <= DELTA)
  
  
  matrizInicial <- matrizInicial %>% 
    dplyr::filter(EMPLOYEE_ID %in% matriz1$EMPLOYEE_ID)
  
  #### MATRIZ DESCANSOS E DELTAS POR COLABORADOR
  
  matrizDescansos <- matriz1 %>% 
    dplyr::select(c("EMPLOYEE_ID", "STATUS", "TOTAL_AGG_DAY_OFF", "TOTAL_DAYS_OFF", "WEEK_COM_FERIAS", "DELTA", "D2", "D3", "D4", "D5", "D6", "D1")) 
  
  # write.csv2(matrizDescansos, 'data/matrizDescansos_A.csv', row.names = F)
  
  #### MATRIZ 1 FINAL
  
  matriz1 <- matriz1 %>% 
    dplyr::select(-c("TOTAL_AGG_DAY_OFF", "STATUS", "TOTAL_DAYS_OFF", "WEEK_COM_FERIAS", "DELTA", "D2", "D3", "D4", "D5", "D6", "D1"))
  
  
  # write.csv2(matriz1, 'data/exemplo_matriz1.csv', row.names = F)
  
  #### MATRIZ +H E MEDIAS CORRIGIDAS
  
  Tdia_MB <- matrizInicial %>% 
    dplyr::group_by(SCHEDULE_DAY, OLD_SCHEDULE_TYPE) %>% 
    dplyr::summarise(COUNT=n(),
                     .groups = 'drop') %>% 
    dplyr::filter(OLD_SCHEDULE_TYPE=='T') %>% 
    dplyr::select(-OLD_SCHEDULE_TYPE)
  
  
  Tdia_MB <- merge(matrizInicial, Tdia_MB, by=c('SCHEDULE_DAY'), all.x=T)
  
  
  Tdia_MB <- Tdia_MB %>% 
    dplyr::select(c(SCHEDULE_DAY, COUNT)) %>% 
    distinct() %>% 
    dplyr::mutate(COUNT=ifelse(is.na(COUNT), 0, COUNT))
  
  
  ndiastrabalhados <- nrow(Tdia_MB %>% dplyr::filter(COUNT>0))
  
  totaltrabalhadores <- sum(Tdia_MB$COUNT)
  
  mediaColabDia <- round(totaltrabalhadores/ndiastrabalhados,0)
  
  # fatorPonderacao1 <- 0.25#0.1#0.4 -> inverção 0.4 descansos -> 0.1 Trabalho
  # fatorPonderacao2 <- 0.25#0.2#0.3
  # fatorPonderacao3 <- 0.25#0.3#0.2
  # fatorPonderacao4 <- 0.25#0.4#0.1
  
  # totalMedia4Dias <- mediaColabDia * 4
  # 
  # mediaColabDia1 <- round(totalMedia4Dias * fatorPonderacao1,0)
  # mediaColabDia2 <- round(totalMedia4Dias * fatorPonderacao2,0)
  # mediaColabDia3 <- round(totalMedia4Dias * fatorPonderacao3,0)
  # mediaColabDia4 <- round(totalMedia4Dias * fatorPonderacao4,0)
  # 
  # somaMediaDias <- mediaColabDia1 + mediaColabDia2 + mediaColabDia3 + mediaColabDia4
  # 
  # if (somaMediaDias > totalMedia4Dias) {
  #   
  #   max_variable <- max(mediaColabDia1, mediaColabDia2, mediaColabDia3, mediaColabDia4)
  #   
  #   
  #   if (max_variable == mediaColabDia1) {  
  #     
  #     mediaColabDia1 <- mediaColabDia1 - 1
  #     
  #   } else if (max_variable == mediaColabDia2) {  
  #     
  #     mediaColabDia2 <- mediaColabDia2 - 1
  #     
  #   } else if (max_variable == mediaColabDia3) { 
  #     
  #     mediaColabDia3 <- mediaColabDia3 - 1
  #     
  #   } else {  
  #     
  #     mediaColabDia4 <- mediaColabDia4 - 1
  #     
  #   }
  # 
  # }
  # 
  # 
  # Tdia$WD <- lubridate::wday(Tdia$SCHEDULE_DAY, label=T, abbr = T)
  # 
  # medias <- c(mediaColabDia1, mediaColabDia2, mediaColabDia3, mediaColabDia4)
  # WD <- c('Mon', 'Tue', 'Wed', 'Thu')
  # 
  # dfMedias <- data.frame(WD, medias)
  # 
  # Tdia <- merge(Tdia, dfMedias, by=c('WD'), all.x=T)
  # 
  # Tdia <- Tdia %>% 
  #   dplyr::mutate(medias=ifelse(is.na(medias), mediaColabDia, medias))
  # 
  # 
  # Tdia <- Tdia %>% 
  #   dplyr::mutate(medias=ifelse(WD=='Sat', 0, medias))
  # 
  # Tdia <- Tdia %>% 
  #   dplyr::mutate(medias=ifelse(SCHEDULE_DAY %in% feriados, 0, medias))
  
  # Tdia <- Tdia %>% 
  #   dplyr::rename(`+H`=COUNT,
  #                 MEDIA_CORRIGIDA = medias) %>% 
  #   dplyr::mutate(DIF=`+H`-MEDIA_CORRIGIDA,
  #                 MEDIA = mediaColabDia)
  
  Tdia_MB <- Tdia_MB %>% 
    dplyr::rename(`+H`=COUNT)
  
  Tdia_MB$WEEK_NUMB <- lubridate::isoweek(Tdia_MB$SCHEDULE_DAY + 1)
  
  Tdia_MB <- Tdia_MB %>% 
    dplyr::mutate(WEEK_NUMB=ifelse(SCHEDULE_DAY<'2023-12-31',0,WEEK_NUMB))
  
  Tdia_MB <- Tdia_MB %>% 
    dplyr::mutate(WEEK_NUMB=ifelse(SCHEDULE_DAY>'2024-12-28',53,WEEK_NUMB))
  
  
  
  matrizInicial2 <- merge(matrizInicial, Tdia_MB, by=c('SCHEDULE_DAY', 'WEEK_NUMB'))
  
  #### CONSTRUCAO MATRIZ 2 
  
  matriz2 <- matrizInicial %>% 
    dplyr::select(c(EMPLOYEE_ID, SCHEDULE_DAY, DATA, OLD_SCHEDULE_TYPE, WEEK_NUMB))
  
  
  
  ##Regra 4 - nao pode haver 3 dias seguidos sem T
  if (dfRegras[ID==4]$ACTIVE == 1) {
    # print("regra 4 ativa")
    matriz2 <- matriz2 %>%
      dplyr::arrange(EMPLOYEE_ID, SCHEDULE_DAY) %>%
      dplyr::group_by(EMPLOYEE_ID) %>%
      dplyr::mutate(
        OLD_SCHEDULE_TYPE = case_when(
          wday(SCHEDULE_DAY - 1, label = T)==dfDescansos$D1 & !(lag(OLD_SCHEDULE_TYPE, default = 'T') %in% c('T','ND')) & OLD_SCHEDULE_TYPE=='T' ~ 'ND',
          wday(SCHEDULE_DAY - 1, label = T)==dfDescansos$D5 & !(lag(OLD_SCHEDULE_TYPE, default = 'T') %in% c('T','ND')) & OLD_SCHEDULE_TYPE=='T' ~ 'ND',
          !(lag(OLD_SCHEDULE_TYPE, default = 'T') %in% c('T','ND')) & !(lead(OLD_SCHEDULE_TYPE, default = 'T') %in% c('T','ND')) & OLD_SCHEDULE_TYPE=='T' ~'ND',
          !(lag(OLD_SCHEDULE_TYPE, default = 'T') %in% c('T','ND')) & !(lag(OLD_SCHEDULE_TYPE,2, default = 'T') %in% c('T','ND')) & OLD_SCHEDULE_TYPE=='T' ~ 'ND',
          !(lead(OLD_SCHEDULE_TYPE, default = 'T') %in% c('T','ND')) & !(lead(OLD_SCHEDULE_TYPE,2, default = 'T') %in% c('T','ND')) & OLD_SCHEDULE_TYPE=='T' ~ 'ND',
          T ~ OLD_SCHEDULE_TYPE
        )) %>% ungroup()
  }
  
  matrizIntermedia <- matriz2 %>% 
    dplyr::distinct(EMPLOYEE_ID, WEEK_NUMB) %>% 
    dplyr::arrange(EMPLOYEE_ID, WEEK_NUMB)
  
  matrizIntermedia$WEEK_STATE <- NA
  
  for (i in 1:nrow(matrizIntermedia)) {
    
    #i=1
    
    employee_id <- matrizIntermedia$EMPLOYEE_ID[i] 
    week_numb <- matrizIntermedia$WEEK_NUMB[i] 
    
    matrizSemana <- matriz2 %>% 
      dplyr::filter(EMPLOYEE_ID==employee_id,
                    WEEK_NUMB==week_numb)
    
    if ('V' %in% matrizSemana$OLD_SCHEDULE_TYPE){
      
      matrizIntermedia <- matrizIntermedia %>% 
        dplyr::mutate(WEEK_STATE=ifelse(EMPLOYEE_ID==employee_id & WEEK_NUMB==week_numb, 'V',  WEEK_STATE))
  
      
    } else if ('R' %in% matrizSemana$OLD_SCHEDULE_TYPE){
      
      matrizIntermedia <- matrizIntermedia %>% 
        dplyr::mutate(WEEK_STATE=ifelse(EMPLOYEE_ID==employee_id & WEEK_NUMB==week_numb, 'R',  WEEK_STATE))
  
      
    } else if ('T' %in% matrizSemana$OLD_SCHEDULE_TYPE){
      
      matrizIntermedia <- matrizIntermedia %>% 
        dplyr::mutate(WEEK_STATE=ifelse(EMPLOYEE_ID==employee_id & WEEK_NUMB==week_numb, 'T',  WEEK_STATE))
  
    } else {
      
      matrizIntermedia <- matrizIntermedia %>% 
        dplyr::mutate(WEEK_STATE=ifelse(EMPLOYEE_ID==employee_id & WEEK_NUMB==week_numb, 'A',  WEEK_STATE))
      
    } 
  }
  
  
  matrizIntermediaNova <- data.frame(matrix(ncol = 3, nrow=0))
  
  
  for (colab in unique(matrizIntermedia$EMPLOYEE_ID)) {  
    
    # colab = 8553
     # colab <- 8674
    matrizIntermediaColab <- matrizIntermedia %>% 
      dplyr::filter(EMPLOYEE_ID==colab)
  
    for (i in 1:nrow(matrizIntermediaColab)) {  
      
      # i=53
      
      if (!is.na(matrizIntermediaColab$WEEK_STATE[i+1])) {
      
        if (matrizIntermediaColab$WEEK_STATE[i]=='R' & matrizIntermediaColab$WEEK_STATE[i+1]=='R'){
          
          matrizIntermediaColab$WEEK_STATE[i] <-'RC' 
          matrizIntermediaColab$WEEK_STATE[i+1] <-'RC' 
          
        }
      }
      
      if (!is.na(matrizIntermediaColab$WEEK_STATE[i+2])) {
    
        if (matrizIntermediaColab$WEEK_STATE[i]=='RC' & matrizIntermediaColab$WEEK_STATE[i+1]=='RC' & matrizIntermediaColab$WEEK_STATE[i+2]=='R'){
          
          matrizIntermediaColab$WEEK_STATE[i] <-'T' 
          matrizIntermediaColab$WEEK_STATE[i+1] <-'T' 
          matrizIntermediaColab$WEEK_STATE[i+2] <-'T' 
        }
      }
  }
    matrizIntermediaNova <- rbind(matrizIntermediaNova, matrizIntermediaColab)
  }
  
  
  ## Pontuacao - m3 -----
  
  
  # Heuristica Feriado 50/50 -----
  
  matriz3Pontuacao <- matrizIntermediaNova
  
  matriz3RC <- matriz3Pontuacao %>%
    dplyr::filter(WEEK_STATE == 'RC') %>% 
    dplyr::group_by(WEEK_NUMB, WEEK_STATE) %>% 
    dplyr::summarise(count = n()) %>% 
    dplyr::mutate(nColabs = round(count/2))
  
  matriz3RC <- matriz3RC %>% 
    dplyr::arrange(WEEK_NUMB)
  
  matriz3RC$PAIR_WEEK <- rep(1:(nrow(matriz3RC)/2), each = 2)
  
  matriz3PontuacaoRC <- matriz3Pontuacao  %>% dplyr::filter(WEEK_STATE == 'RC') 
  
  matriz3PontuacaoRC <- merge(matriz3PontuacaoRC, matriz3RC, by=c('WEEK_NUMB', 'WEEK_STATE'))
  
  matriz3PontuacaoRCPair <- matriz3PontuacaoRC %>% 
    dplyr::select(-WEEK_NUMB) %>% 
    dplyr::distinct()
  
  matriz3PontuacaoRCPair <- matriz3PontuacaoRCPair %>% 
    dplyr::group_by(PAIR_WEEK) %>% 
    mutate(EMPLOYEE_ID=sample(EMPLOYEE_ID)) %>%
    dplyr::mutate(id_random = ifelse((row_number() < nColabs), 1, 0))
  
  matriz3PontuacaoRC <- merge(matriz3PontuacaoRC, matriz3PontuacaoRCPair, by=c('PAIR_WEEK', 'WEEK_STATE', 'EMPLOYEE_ID', 'count', 'nColabs'))
  
  matriz3PontuacaoRCNova <- data.frame(matrix(ncol = 7, nrow=0))
  
  for (colab in unique(matriz3PontuacaoRC$EMPLOYEE_ID)) {  
    
    # colab = 8553 
    
    matriz3PontuacaoRCColab <- matriz3PontuacaoRC %>% 
      dplyr::filter(EMPLOYEE_ID==colab)
    
    for (week in unique(matriz3PontuacaoRCColab$PAIR_WEEK)) {  
      
      # week=3
      
      matriz3PontuacaoRCColab2 <- matriz3PontuacaoRCColab %>% 
        dplyr::filter(PAIR_WEEK==week)
      
      if (unique(matriz3PontuacaoRCColab2$id_random)==1) {
        matriz3PontuacaoRCColab2$WEEK_STATE[1] <- 'T'
        matriz3PontuacaoRCColab2$WEEK_STATE[2] <- 'R'
        
      }
      
      if (unique(matriz3PontuacaoRCColab2$id_random)==0) {
        matriz3PontuacaoRCColab2$WEEK_STATE[1] <- 'R'
        matriz3PontuacaoRCColab2$WEEK_STATE[2] <- 'T'
        
      }
      matriz3PontuacaoRCNova <- rbind(matriz3PontuacaoRCNova, matriz3PontuacaoRCColab2)
    }
  }
  
  matriz3PontuacaoRCNova <- matriz3PontuacaoRCNova %>% 
    dplyr::select(c(WEEK_STATE, EMPLOYEE_ID, WEEK_NUMB))
  
  matriz3PontuacaoNRC <- matriz3Pontuacao  %>% 
    dplyr::filter(WEEK_STATE != 'RC')
  
  matrizPontuacao <- rbind(matriz3PontuacaoNRC, matriz3PontuacaoRCNova)
  
  matrizPontuacao$PONTUACAO <- 33
  
  ## Ponderação
  
  matrizPontuacao <- matrizPontuacao %>%
    dplyr::mutate(PONTUACAO = case_when(
      WEEK_STATE == "A"  ~ 0,
      WEEK_STATE == "V"  ~ 0,
      WEEK_STATE == "R"  ~ 0,
      WEEK_STATE == "T"  ~ 1,
      T ~ PONTUACAO
    ))
    
  matrizPontuacao$WEEK_NUMB <- as.numeric(matrizPontuacao$WEEK_NUMB)
  
  matrizPontuacao <- matrizPontuacao %>%  dplyr::arrange(EMPLOYEE_ID, WEEK_NUMB)
  
  matrizPontos<- data.frame(matrix(ncol = 3, nrow=0))
  
  for (colab in unique(matrizPontuacao$EMPLOYEE_ID)) {  
    
    # colab = 8553
    
    matrizPontuacaoColab <- matrizPontuacao %>% 
      dplyr::filter(EMPLOYEE_ID==colab)
    
    for (i in 1:nrow(matrizPontuacaoColab)) {  
  
      
      # i=53
      if (!is.na(matrizPontuacaoColab$PONTUACAO[i+1])) {
        
        if (matrizPontuacaoColab$PONTUACAO[i]== 0 & matrizPontuacaoColab$PONTUACAO[i + 1] == 1){
          
          matrizPontuacaoColab$PONTUACAO[i + 1] <- 3
            
        }
      }
        
      if (length(matrizPontuacaoColab$PONTUACAO[i-1]) > 0) {
          
        if (matrizPontuacaoColab$PONTUACAO[i]== 0 & matrizPontuacaoColab$PONTUACAO[i - 1] == 1){
            
          matrizPontuacaoColab$PONTUACAO[i - 1] <- 3
            
          }
      }
    }
    
    matrizPontos <- rbind(matrizPontos, matrizPontuacaoColab)
  }
  
  matrizPontos <- matrizPontos %>% dplyr::mutate(PONTUACAO=ifelse(EMPLOYEE_ID %in% colabsStatusN, 0, PONTUACAO))
  
  matriz3 <- reshape2::dcast(matrizPontos, EMPLOYEE_ID ~ WEEK_NUMB, value.var = "PONTUACAO")
  
  
  
  ##MUDAR PONTUAÇOES PARA HEURISTICAS
  # matriz3 %>%
  #   dplyr::mutate_at(vars(-EMPLOYEE_ID), ~ case_when(
  #     . == 1 ~ 3,
  #     . == 3 ~ 1,
  #     T ~ .
  #   ))
  # 
  # matriz3 %>%
  #   dplyr::mutate_at(vars(-EMPLOYEE_ID), ~ case_when(
  #     . == 1 ~ 3,
  #     . == 3 ~ 10,
  #     T ~ .
  #   ))
   
  # matrizXor <- createXORmx(matrizIntermediaNova)
  # dfXor <- as.data.frame(matrizXor)
  # dfXor <- as.data.frame(t(apply(dfXor, 1, get_related_xor)))
  # dfXor %>%
  #   dplyr::mutate_at(vars(-EMPLOYEE_ID), ~ case_when(
  #     . == 1 ~ 'OPC',
  #     . == 3 ~ 'OBR',
  #     T ~ as.character(.)
  #   )) %>% View()
  
  # Function to replace consecutive sequences of 1s with 2
  replace_consecutive_ones <- function(row) {
    for (i in 1:(length(row) - 1)) {
      if ((row[i] == 1 && row[i + 1] == 1) | (row[i] == 1 && row[i - 1] == 2)) {
        row[i] <- 2
      }
    }
    return(row)
  }
  
  matriz3 <- as.data.frame(t(apply(matriz3, 1, replace_consecutive_ones)))
  
  Tdia <- atribuiPonderacoes(Tdia_MB, matriz3, feriados, fatorPonderacao1, fatorPonderacao2, fatorPonderacao3, fatorPonderacao4, fatorPonderacao5,
                             fatorPonderacao6, fatorPonderacao7)

  matriz3 <- matriz3 %>%
    dplyr::mutate_at(vars(-EMPLOYEE_ID), ~ case_when(
      . == 1 ~ var_OPC,
      . == 2 ~ var_OU,
      . == 3 ~ var_OBR,
      T ~ .
    ))


# write.csv2(matriz3, 'data/matriz3.csv', row.names = F)


  return(list( matriz2=matriz2, Tdia=Tdia, matriz3=matriz3, matrizDescansos=matrizDescansos))

}


# rm("colab"                    
#    ,"dfMedias"                   
#    ,"employee_id"             
#    ,"fatorPonderacao1"         
#    ,"fatorPonderacao2"        
#    ,"fatorPonderacao3"         
#    ,"fatorPonderacao4"        
#    ,"feriados"                 
#    ,"i"                        
#    ,"infoGeral"                          
#    ,"matriz3Pontuacao"         
#    ,"matriz3PontuacaoNRC"     
#    ,"matriz3PontuacaoRC"       
#    ,"matriz3PontuacaoRCColab" 
#    ,"matriz3PontuacaoRCColab2" 
#    ,"matriz3PontuacaoRCNova"  
#    ,"matriz3PontuacaoRCPair"   
#    ,"matriz3RC"       
#    ,"matrizInicial"           
#    ,"matrizInicial2"           
#    ,"matrizInicialV"          
#    ,"matrizIntermedia"         
#    ,"matrizIntermediaColab"   
#    ,"matrizIntermediaNova"     
#    ,"matrizPontos"            
#    ,"matrizPontuacao"          
#    ,"matrizPontuacaoColab"    
#    ,"matrizSemana"             
#    ,"mediaColabDia"           
#    ,"mediaColabDia1"           
#    ,"mediaColabDia2"          
#    ,"mediaColabDia3"           
#    ,"mediaColabDia4"          
#    ,"medias"                   
#    ,"ndiastrabalhados"         
#    ,"somaMediaDias"   
#    ,"totalMedia4Dias"         
#    ,"totaltrabalhadores"       
#    ,"WD"                      
#    ,"week"                     
#    ,"week_numb")