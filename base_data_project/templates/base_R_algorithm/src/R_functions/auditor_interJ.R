library(dplyr)
# Checking Interjornadas --------------------------------------------------

#usar o df usado para escrever no ficheiro de integração
#M_WFM

M_WFM <- read.csv("C:/ALCAMPO/algoritmo_GH/output/Integracao_WFM_HUESCA_323_teste.csv", sep = ';')

matriz_festivos <- read.csv("C:/ALCAMPO/algoritmo_GH/data/festivos.csv", sep = ';')
cidade <-  'HUESCA'

auditor_interjornadas <- function(M_WFM, matriz_festivos, cidade = info$UNI, df_erros, regra = "Interjornada"){
  wdList <- list(
    Monday = 'SEG',
    Tuesday = 'TER',
    Wednesday = 'QUA',
    Thursday = 'QUI',
    Friday = 'SEX',
    Saturday = 'SAB',
    Sunday = 'DOM',
    Festivo = 'FER',
    0
  )
  
  interjornadas <- list(
    Monday = 12,
    Tuesday = 12,
    Wednesday = 12,
    Thursday = 12,
    Friday = 12,
    Saturday = 12,
    Sunday = 9,
    Festivo = 9, #????????????????????????????????
    0
  )
  
  current_emps <- unique(M_WFM$EMPLOYEE_ID)
  
 
 
  matriz_festivos_temp <- matriz_festivos
  
  matriz_festivos_temp <- data.frame(lapply(matriz_festivos_temp, function(x) parse_date_time(x, orders = c("d/m/y", "d-m-y"))))

# tornar esta selecao dinamica --------------------------------------------

 
  festivos <- as.POSIXct(matriz_festivos_temp[,cidade], format = "%d/%m/%Y")
  festivos <-format(festivos, "%Y-%m-%d")
  
  
 



  
  df_erros <- data.frame(EMP = character(), DATA = character(), TIPO_ERRO = character() )
  
  for (emp in current_emps) {
    M_WFM_temp <- M_WFM %>%
      dplyr::filter(M_WFM$EMPLOYEE_ID %in% emp)
    
    
  

# falta blindar para escolher a 1ª hora de entrada e a ultima hora --------
# de saida, neste momento está Hardcoded
    
    M_WFM_temp$dateTime_ST1 <- as.POSIXct(paste(M_WFM_temp$SCHEDULE_DT, M_WFM_temp$Start_Time_1), format = "%Y-%m-%d %H:%M")
    M_WFM_temp$dateTime_ET1 <- as.POSIXct(paste(M_WFM_temp$SCHEDULE_DT, M_WFM_temp$End_Time_1), format = "%Y-%m-%d %H:%M")
    M_WFM_temp$dateTime_ST2 <- as.POSIXct(paste(M_WFM_temp$SCHEDULE_DT, M_WFM_temp$Start_Time_2), format = "%Y-%m-%d %H:%M")
    M_WFM_temp$dateTime_ET2 <- as.POSIXct(paste(M_WFM_temp$SCHEDULE_DT, M_WFM_temp$End_Time_2), format = "%Y-%m-%d %H:%M")
    
    
    
    M_WFM_temp <- M_WFM_temp %>%
      
      mutate(descanso_interjonada = pmin(dateTime_ST1, dateTime_ET1, dateTime_ST2, dateTime_ET2, na.rm = TRUE) - lag(pmax(dateTime_ST1, dateTime_ET1, dateTime_ST2, dateTime_ET2, na.rm = TRUE))) %>% 
      mutate(SCHEDULE_DT = as.POSIXct(SCHEDULE_DT, format("%Y-%m-%d"))) %>% 
      mutate(interjornada_legal = interjornadas [weekdays(SCHEDULE_DT)]) %>% 
      mutate(interjornada_legal = ifelse(as.character(M_WFM_temp$SCHEDULE_DT) %in% as.character(festivos), 9, interjornada_legal)) %>% 
      mutate(interjornada_legal = lag(interjornada_legal)) %>% 
      mutate(descanso_interjonada = as.double(descanso_interjonada)) %>% 
      mutate(interjornada_legal = ifelse(row_number() == 1, 9, interjornada_legal)) %>% 
      mutate(interjornada_legal = unlist(interjornada_legal)) %>% 
      mutate(interjornada_legal = as.double(interjornada_legal))
    
    
    teste <- all(M_WFM_temp$descanso_interjonada > M_WFM_temp$interjornada_legal, na.rm=TRUE)
    if (teste) {
      print(paste("Os horarios do colab", emp, "cumprem a lei das interJornadas"))
      
    }else{
      false_rows <- M_WFM_temp %>%
        filter((descanso_interjonada < interjornada_legal) &  (!is.na(descanso_interjonada) & !is.na(interjornada_legal)))
      
      print(paste("Os horarios do colab ", emp, "não cumprem interJornadas nestas datas:"))
      print(false_rows$SCHEDULE_DT)
      
      df_erros <- rbind(df_erros, data.frame(EMP = emp, DATA = false_rows$SCHEDULE_DT, TIPO_ERRO = regra ))
      
    }
    
   
    
    
    
    
    
  }
  
  
  if (nrow(df_erros) == 0) {
    cumpre = TRUE
  } else {
    cumpre = FALSE
  }
  print(cumpre)
  
  
  return(df_erros, cumpre)
}


















# 
# 
# 
# 
# 
# 
# 
# 
# 
# 
# df_granul <- read.csv("C:/Users/miguel.teixeira/Desktop/algoritmosAlocacao deHorarios/ALCAMPO/algoritmo_ 3_vFinal/algoritmo_V2.0/data/output_V27_Granularidade_HORARIOS CORRIGIDOS _V2.csv", sep = ';')
# 
# 
# 
# matriz_base_dados_estatisticas <- read.csv2("data/estatisticas_posto_dia_2.csv", sep=";",
#                                             check.names = FALSE)
# 
# postos_tst <-  unique(matriz_base_dados_estatisticas$FK_TIPO_POSTO)
# postos_tst
# 
# 
# output_32 <- read.csv('data/output_ 32.csv', sep = ';')
# transformed_df <- data.frame(
#   FK_TIPO_POSTO = output_32$FK_TIPO_POSTO,
#   DATA = as.Date(output_32$DATA),
#   HORA_INI = output_32$HORA_INI,
#   MINIMO = output_32$PESSOAS_MIN,
#   IDEAL = output_32$PESSOAS_FINAL
# )
