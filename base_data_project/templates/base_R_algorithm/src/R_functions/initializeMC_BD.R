# library(tidyr)
# pathOS <- fileNameMCALEND
# pathConf <- pathFicheirosGlobal
Initialize_MC <- function(pathConf = pathFicheirosGlobal,pathOS, dateSeq, postoID){
  
  
  source(paste0(pathOS,"connection/dbconn.R"))
  source(paste0(pathOS,"connection/queryCalendario.R"))
  
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathConf, sis, confFileName)
  
  psto <<- as.character(postoID)
  
  
  matriz_calendario_BD <- getCalendarInfo( pathConf, wfm_con, as.character(postoID),dateSeq)
  dbDisconnect(wfm_con)
  
  
  # #########################################################################
  # ###############TEMPORARIO PQ A VPN DA TLANTIC ESTÁ DOWN##################
  # #########################################################################
  # matriz_calendario_BD <- read.table(file = "C:/ALCAMPO/M_Calend_FairyDust/M_CALEND_INSERT_2024-03-18_12-12-31.csv",
  #                                   sep = ",",
  #                                   check.names = FALSE,
  #                                   as.is = TRUE,
  #                                   stringsAsFactors = FALSE,
  #                                   header = TRUE)
  # #########################################################################
  # ###############TEMPORARIO PQ A VPN DA TLANTIC ESTÁ DOWN##################
  # #########################################################################
  
  FK_EMP_plus_FK_POSTO <- matriz_calendario_BD %>% 
    dplyr::select(c('FK_EMP','FK_TIPO_POSTO_ORIGEM')) %>% 
    dplyr::mutate_all(trimws) %>% 
    dplyr::distinct()
  
  colnames(FK_EMP_plus_FK_POSTO) <- c('MATRICULA', 'FK_TIPO_POSTO')

# I'm gonna spill some fairy dust to get the m_colab back to wide format  --------
matriz_calendario_BD_temp <- transform(matriz_calendario_BD, sequence = ave(FK_EMP, FK_EMP, FUN = seq_along))
  
matriz_calendario_back_to_wide <- tidyr::pivot_wider(matriz_calendario_BD_temp, id_cols = FK_EMP,
                                                     names_from = DATA,
                                                     values_from = TIPO_TURNO)



  
# Extract the first column name
first_col_name <- names(matriz_calendario_back_to_wide)[1]

# Extract the rest of the column names and sort them
sorted_col_names <- sort(names(matriz_calendario_back_to_wide)[-1])

# Reorder the column names by putting the first column name at the beginning
new_col_order <- c(first_col_name, sorted_col_names)

# Reorder the columns of the data frame according to the new column order
matriz_calendario_wide_sorted <- matriz_calendario_back_to_wide[new_col_order]
names(matriz_calendario_wide_sorted)[1] <- "MATRICULA"

matriz_calendario_wide_sorted_1 <- merge(matriz_calendario_wide_sorted,FK_EMP_plus_FK_POSTO, by = "MATRICULA")

#matriz_calendario_wide_sorted$FK_TIPO_POSTO <- postoID
matriz_calendario_wide_sorted_1 <- as.data.frame(matriz_calendario_wide_sorted_1)


# current_time <- Sys.time()
# time_string <- format(current_time, "%Y-%m-%d_%H-%M-%S")
# write.csv(matriz_calendario, file =paste0("M_CALEND_AS_IS",time_string,".csv"), row.names = FALSE)
return(matriz_calendario_wide_sorted_1)
}
# MAKE SOME MAGIC TO GET M_CALEND IN LONGWISE FORMAT AGAIN ----------------

  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
#   #########################################################
#   ############THIS SHOULD NOT BE NEEDED ANYMORE############
#   #########################################################
#   matriz_calendario <-  read.table(pathOS, header = TRUE,
#                                    sep = ';', stringsAsFactors = FALSE, as.is = TRUE,
#                                    check.names = FALSE)
#   #########################################################
#   ############THIS SHOULD NOT BE NEEDED ANYMORE############
#   #########################################################
#   
#   
#   # # Certified lover matrix
#   # if (ncol(matriz_calendario) != length(dateSeq) + 3) {
#   #   #print(paste('Error: CSV provided must have ', length(dateSeq)+3, 'columns. It has ', ncol(matriz_calendario), sep = ''))
#   #   #print(paste('Please verify file named: ', pathOS, sep = ''))
#   # }
#   # 
#   subset_cols <- c("COLABORADOR", dateSeq,'FK_TIPO_POSTO')
#   
#   ##validate the column names date format and force %Y-%m-%d
#   column_names_to_change <- names(matriz_calendario)[3:(ncol(matriz_calendario)-1)]
#   column_names_to_change <- format(as.Date(column_names_to_change, format =extract_date_format(column_names_to_change)))
#   names(matriz_calendario)[3:(ncol(matriz_calendario)-1)] <- column_names_to_change
#   
#   # Subset the matriz_calendario dataframe using the subset_cols
#   matriz_calendario <- matriz_calendario[, subset_cols]
#   # diasConsiderados <- format(as.POSIXct(dateSeq, format = "%d/%m/%Y"), '%Y-%m-%d')
#   # if (any(is.na(diasConsiderados)) == TRUE) {
#   #   diasConsiderados <- dateSeq
#   # }
#   # colnames(matriz_calendario) <- c('COLABORADOR', diasConsiderados, 'FK_TIPO_POSTO')
#   
#   ##para remover TIPO_DIA
#   if ("TIPO_DIA" %in% matriz_calendario$COLABORADOR) {
#     matriz_calendario <- matriz_calendario[-nrow(matriz_calendario), ]
#   }
#   
#   posto_atual <- unique(matriz_calendario[, ncol(matriz_calendario)])
#   posto_atual <- posto_atual[1]
#   #matriz_calendario2 <<- rbind(names(matriz_calendario), matriz_calendario)
#   # print("LEts test")
#   # print(posto_atual)
#   matriz_calendario[,ncol(matriz_calendario)] <- NULL
#   matriz_calendario <- matriz_calendario %>% 
#     mutate(across(everything(), ~ifelse(. == 'FALSE', 'F', .))) %>% 
#     mutate(across(everything(), ~ifelse(. == 'TRUE', 'T', .)))
#   #print("Wasnt here")
#   date_columns <- 2:ncol(matriz_calendario)
#   
#   # Convert date columns to POSIXct format
#   test_row <- as.data.frame(lapply(matriz_calendario[1, date_columns], function(x) as.character(as.POSIXct(x, format = "%d/%m/%Y"))))
#   
#   if (any(is.na(test_row) == FALSE)) {
#     matriz_calendario[1, date_columns] <- lapply(matriz_calendario[1, date_columns], function(x) as.character(as.POSIXct(x, format = "%d/%m/%Y")))
#     colnames(matriz_calendario) <- unlist(matriz_calendario[1, ])
#     
#   }
#   # matriz_calendario <- matriz_calendario[-1,]
#   colnames(matriz_calendario)[colnames(matriz_calendario) == "COLABORADOR"] <- "MATRICULA"
#   matriz_calendario[,ncol(matriz_calendario)+1] <- posto_atual
#   colnames(matriz_calendario)[ncol(matriz_calendario)] <- 'FK_TIPO_POSTO'
#   
#   # if (any(substr(matriz_calendario$MATRICULA, start = 1, stop = 3) == 'ESP')) {
#   #   matriz_calendario$MATRICULA <- substr(matriz_calendario$MATRICULA, start = 4, last)
#   #   print('yas')
#   # }
#   
#   if (postoID != posto_atual) {
#     #print('Last column in CALENDARIO does not contain the same FK_TIPO_POSTO as given before. Please open CALENDARIO file and ensure it is the right one.')
#     return(FALSE)
#   } else {
#     return(matriz_calendario)
#   }
# }
