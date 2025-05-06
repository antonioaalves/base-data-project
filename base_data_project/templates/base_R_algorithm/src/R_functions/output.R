### OUTPUT FILE FUNCTIONS ###

# Generate M_out
initializaMatrizOut <- function(M_dia2, M_calendario, dateSeq, lista_datas) {
  # M_dia2 <- df_list_304
  # M_calendario <- matriz_calendario
  # dateSeq <- dateSeq
  # lista_datas <- lista_datas3
  
  feriados_fixos <- c('01-01-2024', '06-01-2024', '01-05-2024', '25-12-2024')
  # retrieve the colabs list to be considered
  colabTotalList <<- M_calendario$MATRICULA
  # initialize an EMPty dataframe to store information
  M_out <<- data.frame(matrix(NA, nrow = length(colabTotalList), ncol = length(dateSeq)+1))
  M_out[, 1] <- colabTotalList
  colnames(M_out) <- c('colab', dateSeq) 
  workingStates <- c('M', 'T')
  
  # cycle through days
  for (date in dateSeq) {
    #print(date)
    dateYMD <- format(as.POSIXct(date, format = "%d-%m-%Y"), '%Y-%m-%d')
    # error correction if the dataframe for that day has not been created
    if ((date %in% feriados_fixos)) {
      M_out[, date] <- 'F'
      next
    }
    # cycle through colabs
    if (is.null(M_dia2[[dateYMD]]) & (dateYMD %in% lista_datas)) {
      for (colab in colabTotalList) {
        M_out[M_out$colab == colab, date] <- M_calendario[M_calendario$MATRICULA == colab, format(as.Date(dateYMD), "%d-%m-%Y")]
      } 
    } else {
      horarios <- findHorSeq(M_dia2[[dateYMD]])
      for (colab in colabTotalList) {
        #print(colab)
        dayType <- M_calendario[M_calendario$MATRICULA == colab, format(as.Date(dateYMD), "%d-%m-%Y")]
        if (dayType %in% workingStates){
          colabHorario <- paste('EMPloyee_', colab, sep = '')
          M_out[M_out$colab == colab, date] <- horarios[[colabHorario]]
        } else {
          M_out[M_out$colab == colab, date] <- M_calendario[M_calendario$MATRICULA == colab, format(as.Date(dateYMD), "%d-%m-%Y")]
        }
      }
    }
  }
  return(M_out)
}

# Old output
saveOutput <- function(pathOS, M_output) {
  ### Save output as a CSV ###
  index <- format(as.POSIXct(Sys.time(), "%d-%m-%Y %H:%M:%OS", tz = 'UTC'), "%d-%m-%Y_%Hh%Mm%OSs")
  fileName <- paste('outputFinal_', index, '.csv', sep = '')
  # correct the filepath
  write.csv(M_output, paste('output//', fileName, sep = ''), row.names=FALSE)
}

# Output excel for the granularity
fillExcelDia <- function(M_out, tEMPlatePath, matriz_info) {
  ### Fill excel tEMPlate with schedules and daysoff ###
  
  # TODO: put the FK_tipo_de_posto in the file name, and in the rest of the written parameters
  
  # Create the list of names to put as the matricula + nome of colabs
  names <- list()
  for (i in 1:length(M_out[, 1])) {
    colabID <- M_out[, 1][i]
    names[i] <- paste(colabID, matriz_info[matriz_info$MATRICULA == colabID, 2], sep = ' - ')
  }
  # print(names)
  # Load the tEMPlate into R
  tEMPlate <- loadWorkbook(tEMPlatePath)
  sheet_name <- "Folha1"
  
  writeData(tEMPlate, sheet_name, unlist(names), startCol = 1, startRow = 9) # fill colab list
  
  for (col in 2:ncol(M_out)) {
    # colx <- col + 4
    writeData(tEMPlate, sheet_name, colnames(M_out)[col], startCol = col, startRow = 6) # fill the date
    writeData(tEMPlate, sheet_name, M_out[, col], startCol = col, startRow = 9) # fill the schedules for each day
    
  }
  # Create a new file name
  index <- format(as.POSIXct(Sys.time(), "%d-%m-%Y %H:%M:%OS", tz = 'UTC'), "%d-%m-%Y_%Hh%Mm%OSs")
  fileName <- paste('output/outputFinal_', index, '.xlsx', sep = '')
  saveWorkbook(tEMPlate, fileName)
  return(TRUE)
}

# Output excel for the granularity
fillExcelMin <- function(M_dia_final, M_out, dateSeq, times_sequence, tEMPlatePath, matriz_info) {
  ###
  # M_dia_final
  # dateSeq
  # times_sequence: list of time stamps (format = "HH:MM"), only consider between opening and closing times of posto
  # tEMPlate file path
  # matriz_info: ids to names of colabs
  
  ###
  # Erase this, just for QA
  dateSeq <- seq(from = as.POSIXct('01-01-2024', format = "%d-%m-%Y"),
                 to = as.POSIXct('31-01-2024', format = "%d-%m-%Y"),
                 by = "1 day")
  dateSeq <- format(dateSeq, '%d-%m-%Y')
  
  # load tEMPlate and set sheet numb
  
  sheetNumb <- 0
  dayRow <- 3
  colabTotalList <- paste('EMPloyee_', M_out$colab, sep = '')
  lastMonth <- 0
  letters_sequence <- c("A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "AA", "AB", "AC", "AD", "AE",
                        "AF", "AG", "AH", "AI", "AJ", "AK", "AL", "AM", "AN", "AO", "AP", "AQ", "AR", "AS", "AT", "AU", "AV", "AW", "AX", "AY", "AZ", "BA", "BB", "BC", "BD", "BE", "BF", "BG",
                        "BH", "BI", "BJ", "BK", "BL", "BM", "BN", "BO", "BP", "BQ", "BR", "BS", "BT", "BU", "BV", "BW", "BX", "BY", "BZ", "CA", "CB", "CC", "CD", "CE", "CF", "CG", "CH",
                        "CI", "CJ", "CK", "CL", "CM", "CN", "CO", "CP", "CQ", "CR", "CS", "CT", "CU", "CV")
  
  # Create month list in spanish
  monthNames <- c("enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre")
  
  # Create the list of names to put as the 'matricula - nome' of colabs
  names <- data.frame(matrix(NA, nrow = length(M_out[, 1]), ncol = 2))
  colnames(names) <- c('colabID', 'matricula-name')
  for (i in 1:length(M_out[, 1])) {
    colabID <- M_out[, 1][i]
    names[i, 1] <- paste('EMPloyee_', colabID, sep = '')
    names[i, 2] <- paste(colabID, matriz_info[matriz_info$MATRICULA == colabID, 2], sep = ' - ')
  }
  
  # Create new workbook
  wb <- createWorkbook()
  
  # Cycle through year, month and 
  for (date in dateSeq) {
    #print(date)
    # save the number of the current month
    currentMonth <- as.numeric(format(as.POSIXct(date, format = "%d-%m-%Y"), "%m"))
    dateYMD <- format(as.POSIXct(date, format = "%d-%m-%Y"), '%Y-%m-%d')
    
    # Add new sheet and define the rules, and reset counters
    if (currentMonth != lastMonth) {
      addWorksheet(wb, monthNames[currentMonth])
      sheetNumb <- sheetNumb + 1
      lastMonth <- currentMonth
      dayRow <- 3
      setColWidths(wb, sheet = monthNames[currentMonth], cols = 5:(length(times_sequence) + 4), widths = 2.78)
      setColWidths(wb, sheet = monthNames[currentMonth], cols = 4, widths = 45)
    }
    
    # tEMPlate
    borderStyle <- createStyle(border = "TopBottomLeftRight")
    rotationStyle <- createStyle(textRotation = 90)
    
    # Fill the date, alocado, estimativa e min
    writeData(wb, sheetNumb, date, startCol = 4, startRow = dayRow)
    addStyle(wb, sheet = sheetNumb, style = borderStyle, rows = dayRow, cols = 4)
    writeData(wb, sheetNumb, 'Alocado', startCol = 4, startRow = dayRow + 14)
    addStyle(wb, sheet = sheetNumb, style = borderStyle, rows = dayRow + 14, cols = 4)
    writeData(wb, sheetNumb, 'Estimativas', startCol = 4, startRow = dayRow + 15)
    addStyle(wb, sheet = sheetNumb, style = borderStyle, rows = dayRow + 15, cols = 4)
    writeData(wb, sheetNumb, 'Min', startCol = 4, startRow = dayRow + 16)
    addStyle(wb, sheet = sheetNumb, style = borderStyle, rows = dayRow + 16, cols = 4)
    
    # Fill times_sequence and alocado function
    for (col in 1:(length(times_sequence))) {
      writeData(wb, sheetNumb, times_sequence[col], startCol = col + 4, startRow = dayRow)
      addStyle(wb, sheet = sheetNumb, style = rotationStyle, rows = dayRow, cols = col + 4, stack = TRUE)
      addStyle(wb, sheet = sheetNumb, style = borderStyle, rows = dayRow, cols = col + 4, stack = TRUE)
      # addStyle(wb, sheet = sheetNumb, style = alignStyle, rows = dayRow, cols = col + 4)
      writeFormula(wb, sheet = sheetNumb, x = paste0('=SUM(', letters_sequence[col+4], dayRow+1, ':', letters_sequence[col+4], dayRow+11, ')'), startCol = col + 4, startRow = dayRow + 14)
      addStyle(wb, sheet = sheetNumb, style = borderStyle, rows = dayRow + 14, cols = col + 4, stack = TRUE)
    }
    # Fix the height of the row for dayRow
    setRowHeights(wb, sheetNumb, rows = dayRow, height = 35)
    
    if (is.null(M_dia_final[[dateYMD]])) {
      # if it doesn't exist fill with zeros
      M_dia <- data.frame(matrix(0, nrow = length(colabTotalList), ncol = length(times_sequence)))
      estimativas <- rep(0, length(times_sequence))
      minimos <- rep(0, length(times_sequence))
      # writeData(wb, sheetNumb, zero, startCol = 2, startRow = 9)
    } else {
      # Transform M_dia_final, esimativas and minimos #
      estimativas <- M_dia_final[[dateYMD]] %>% select(Ideal)
      minimos <- M_dia_final[[dateYMD]] %>% select(Minimo)
      M_dia <- M_dia_final[[dateYMD]] %>%  
        select(-c(timestamps, Ideal_por_Cobrir,Minimo_Por_cobrir,Alocado,Ideal,Minimo))
      M_dia <- M_dia %>% 
        mutate_all(~ifelse(. == 'P', 0, .)) # remove pis
      M_dia <- M_dia[rownames(M_dia) %in% times_sequence, ]
      estimativas <- estimativas[rownames(estimativas) %in% times_sequence, ]
      minimos <- minimos[rownames(minimos) %in% times_sequence, ]
      colabList <- colnames(M_dia)
      for (colab in colabTotalList) {
        if (!(colab %in% colabList)) {
          M_dia[, colab] <- 0
        } else {
          M_dia[, colab] <- as.numeric(M_dia[, colab])
        }
      }
      M_dia <- (t(M_dia)) # days not in numeric type
      # end transformation #
      
    }
    # Add borders to the table
    # start_row <- dayRow
    # end_row <- length(colabTotalList) + dayRow
    # start_col <- 4
    # end_col <- start_col + length(times_sequence)
    
    # cycle through the time_stamps and fill the schedule for the day
    for (row in 1:(length(colabTotalList))) {
      # Fill the name of the colabs
      writeData(wb, sheetNumb, names[names[, 1] == colabTotalList[row], 2], startCol = 4, startRow = row + dayRow)
      addStyle(wb, sheet = sheetNumb, style = borderStyle, rows = row + dayRow, cols = 4)
      for (col in 1:(length(times_sequence))) {
        value <- M_dia[row, col]
        # Write the value into excel
        colx <- col + 4
        rowx <- row + dayRow
        # write data from M_dia
        writeData(wb, sheetNumb, value, startCol = colx, startRow = rowx)
        addStyle(wb, sheet = sheetNumb, style = borderStyle, rows = rowx, cols = colx)
        if (row == 1) {
          writeData(wb, sheetNumb, estimativas[col], startCol = colx, startRow = dayRow + 15)
          addStyle(wb, sheet = sheetNumb, style = borderStyle, rows = dayRow + 15, cols = colx)
          writeData(wb, sheetNumb, minimos[col], startCol = colx, startRow = dayRow + 16)
          addStyle(wb, sheet = sheetNumb, style = borderStyle, rows = dayRow + 16, cols = colx)
        }
      }
    }
    
    
    
    # Conditional Formatting
    start_row <- dayRow + 1
    end_row <- length(colabTotalList) + dayRow
    start_col <- 5
    end_col <- start_col + length(times_sequence)
    
    # Define styles for the formatting rules
    blueStyle <- createStyle(fontColour = "#72A7FE", bgFill = "#72A7FE")
    whiteStyle <- createStyle(fontColour = "white", bgFill = "white")
    conditionalFormatting(wb, sheet = sheetNumb, rows = start_row:end_row, cols = start_col:end_col,
                          rule = "1", type = "contains", style = blueStyle)
    conditionalFormatting(wb, sheet = sheetNumb, rows = start_row:end_row, cols = start_col:end_col,
                          rule = "0", type = "contains", style = whiteStyle)
    conditionalFormatting(wb, sheet = sheetNumb, rows = start_row:end_row, cols = start_col:end_col,
                          rule = "P", type = "contains", style = whiteStyle)
    
    
    # Increment counters (tirar martelo)
    dayRow <- dayRow + 35
  }
  
  index <- format(as.POSIXct(Sys.time(), "%d-%m-%Y %H:%M:%OS", tz = 'UTC'), "%d-%m-%Y_%Hh%Mm%OSs")
  fileName <- paste('output/outputFinal_diario_', index, '.xlsx', sep = '')
  saveWorkbook(wb, fileName)
  return(TRUE)
}

# Generate M_WFM to fill excel for integration in WFM
# M_dia <- M_dia4_final
create_MWFM <- function(M_dia, M_calendario, M_colab, dateSeq) {
  # M_dia <- M_dia4_final
  # M_calendario <- matriz_calendario
  # M_colab <- matriz_colaborador
  logs <- NULL
  feriados_fixos <-  c("2024-01-01","2024-05-01", "2024-12-25", "2024-01-06")#lista_datas3
  # Declare important values
  colabTotalList <- M_calendario$MATRICULA
  # Initialize the empty dataframe
  df <- data.frame(EMPLOYEE_ID = character(),
                   SCHEDULE_DT = character(),
                   SCHED_TYPE = character(),
                   SCHED_SUBTYPE = character(),
                   Start_Time_1 = character(),
                   End_Time_1 = character(),
                   Start_Time_2 = character(),
                   End_Time_2 = character(),
                   stringsAsFactors = FALSE
  )
  i <- 0
  for (date in dateSeq) {
    i <- i + 1
    #print(i)
    dateYMD <- format(as.POSIXct(date#, format = "%d/%m/%Y"
    ), '%Y-%m-%d')
    dateDMY <- format(as.POSIXct(date#, format = "%d/%m/%Y"
    ), '%d-%m-%Y')
    if ((dateYMD %in% feriados_fixos)) {
      # If it is a day that is closed, fill with F's certain columns
      for (colab in colabTotalList) {
        new_row <- data.frame(EMPLOYEE_ID = colab,
                              SCHEDULE_DT = date,
                              SCHED_TYPE = 'F',
                              SCHED_SUBTYPE = 'F',
                              Start_Time_1 = '',
                              End_Time_1 = '',
                              Start_Time_2 = '',
                              End_Time_2 = '',
                              stringsAsFactors = FALSE
        )
        df <- rbind(df, new_row)
      }
    } else {
      #day without working ppl, fill with calendar's type
      if (is.null((M_dia[[dateYMD]]))) {
        for (colab in colabTotalList) {
          M_calendario_row <- M_calendario %>% dplyr::filter(MATRICULA==colab)
          new_row <- data.frame(EMPLOYEE_ID = colab,
                                SCHEDULE_DT = date,
                                SCHED_TYPE = ifelse(M_calendario_row[[dateYMD]]=='V','V','F'),
                                SCHED_SUBTYPE = ifelse(M_calendario_row[[dateYMD]]=='V','Ferias',M_calendario_row[[dateYMD]]),
                                Start_Time_1 = '',
                                End_Time_1 = '',
                                Start_Time_2 = '',
                                End_Time_2 = '',
                                stringsAsFactors = FALSE
          )
          df <- rbind(df, new_row)
        }
      } else{
        # Else retrieve the schedules for the values present in the output for that day
        horarios <- findSeq(M_dia[[dateYMD]])[[1]]
        
        # print(horarios)
        for (colab in colabTotalList) {
          colabHorario <- paste('EMPloyee_', colab, sep = '')
          
          
          # Test if it has horario, if not, it must be a day off so fill the vaues from M_calendario
          if (is.null(horarios[[colabHorario]])) {
            new_row <- data.frame(EMPLOYEE_ID = colab,
                                  SCHEDULE_DT = date,
                                  SCHED_TYPE = ifelse(M_calendario[M_calendario$MATRICULA == colab, dateYMD]=='V','V','F'),
                                  SCHED_SUBTYPE = ifelse(M_calendario[M_calendario$MATRICULA == colab, dateYMD]=='V','Ferias',M_calendario[M_calendario$MATRICULA == colab, dateYMD]),
                                  Start_Time_1 = '',
                                  End_Time_1 = '',
                                  Start_Time_2 = '',
                                  End_Time_2 = '',
                                  stringsAsFactors = FALSE)
          } else {
            # If it has horario it must be a working day, so fill with times 
            if (length(horarios[[colabHorario]]) == 2) {
              new_row <- data.frame(EMPLOYEE_ID = colab,
                                    SCHEDULE_DT = date,
                                    SCHED_TYPE = 'T',
                                    SCHED_SUBTYPE = '',
                                    Start_Time_1 = horarios[[colabHorario]][[1]],
                                    End_Time_1 = horarios[[colabHorario]][[2]],
                                    Start_Time_2 = '',
                                    End_Time_2 = '',
                                    stringsAsFactors = FALSE)
            } else if (length(horarios[[colabHorario]]) == 4) {
              # horario3 <- (horarios[[colabHorario]][[3]])
              
              # # Define the time value
              # time_value <- as.POSIXct(horario3, format="%H:%M")
              # 
              # # Add 5 minutes
              # time_value_plus_5 <- time_value + 5*60  # Adding 5 minutes in seconds
              # Convert back to "HH:MM" format
              # new_time <- format(time_value_plus_5, "%H:%M")
              # print(time_value)
              # print(new_time)
              new_row <- data.frame(EMPLOYEE_ID = colab,
                                    SCHEDULE_DT = date,
                                    SCHED_TYPE = 'T',
                                    SCHED_SUBTYPE = '',
                                    Start_Time_1 = horarios[[colabHorario]][[1]],
                                    End_Time_1 = horarios[[colabHorario]][[2]],
                                    Start_Time_2 = horarios[[colabHorario]][[3]],#new_time,
                                    End_Time_2 = horarios[[colabHorario]][[4]],
                                    stringsAsFactors = FALSE)
            } else {
              logs <<- c(logs,print(paste('Invalid number of horarios. Check findSeq for colab:', colab, 'and date:', dateYMD, sep = ' ')))
              next
            }
          }
          df <- rbind(df, new_row)
        }
      }
      
    }
  }
  # # Transform dates
  # dftesti <<- df
  # df$SCHEDULE_DT <- format(as.Date(df$SCHEDULE_DT, format =extract_date_format(df$SCHEDULE_DT)))
  # # df$SCHEDULE_DT <- as.Date(df$SCHEDULE_DT, '%d/%m/%Y')
  # 
  # infoDescDur <- M_colab[, c('EMP', 'DESC_CONTINUOS_DURACAO')]
  # infoDescDur$DESC_CONTINUOS_DURACAO <- sapply(infoDescDur$DESC_CONTINUOS_DURACAO, convert_to_minuts)

  # df2 <- df %>%
  #   merge(infoDescDur %>%
  #           dplyr::rename(EMPLOYEE_ID=EMP),
  #         by='EMPLOYEE_ID') %>%
  #   dplyr::mutate(INT_DIF = case_when(
  #     Start_Time_2 != "" ~ difftime(as.POSIXct(Start_Time_2,format='%H:%M',tz='GMT'),
  #                                   as.POSIXct(End_Time_1,format='%H:%M',tz='GMT'), units = "mins")
  #   )) %>%
  #   dplyr::mutate(NEW_DIF = ifelse(is.na(INT_DIF) | INT_DIF>=60,0,INT_DIF-DESC_CONTINUOS_DURACAO)#,
  #                 #End_Time_1 = format(as.POSIXct(End_Time_1,format='%H:%M',tz='GMT')+NEW_DIF*60,'%H:%M')
  #   ) %>%  
  #   dplyr::select(-c(DESC_CONTINUOS_DURACAO,INT_DIF,NEW_DIF))
  return(df)
}

convert_to_minuts <- function(time_str) {
  if (!is.na(time_str) & time_str != "") {
    hm_time <- hm(time_str)  # Convert to hours and minutes format
    as.numeric(hm_time@hour)*60 + as.numeric(hm_time@minute)# Convert to min
  } else {
    return(NA)  # Return NA if input is NA or empty string
  }
}

# Jason's Output
saveOutputJason <- function(fileName, interval_df) {
  if (file.exists(fileName)) {
    write.table(interval_df, fileName, row.names = FALSE, col.names = FALSE, sep = ",", append = TRUE)
  } else {
    write.table(interval_df, fileName, row.names = FALSE, col.names = TRUE, sep = ",")
  }
}

saveOutputValidador <- function(data, postoID, UniNAME) {
  # Create file name
  timeIndex <- format(as.POSIXct(Sys.time(), "%d-%m-%Y %H:%M:%OS", tz = 'UTC'), "%d-%m-%Y_%Hh%Mm%OSs")
  fileName <- paste0(pathFicheirosGlobal, 'output_QA/validador_output_', UniNAME,'_', postoID, '_', timeIndex, '.xlsx')
  
  # Create workbook
  wb <- createWorkbook()
  
  # Create the veral sheets
  addWorksheet(wb, 'Regras nao cumpridas')
  addWorksheet(wb, 'Diario')
  addWorksheet(wb, 'Semanal')
  addWorksheet(wb, 'Anual')
  addWorksheet(wb, 'Mensal')
  
  # Write data in the several sheets
  writeData(wb, 'Regras nao cumpridas', data[[1]], startCol = 1, startRow = 1)
  writeData(wb, 'Diario', data[[2]], startCol = 1, startRow = 1)
  writeData(wb, 'Semanal', data[[4]], startCol = 1, startRow = 1)
  writeData(wb, 'Anual', data[[3]], startCol = 1, startRow = 1)
  writeData(wb, 'Mensal', data[[5]], startCol = 1, startRow = 1)
  
  # Save excel file
  saveWorkbook(wb, fileName)
}

saveOutputValidadorTRADS <- function(data, postoID, UniNAME, collaborator_tibbles, colabList, matriz_calendario, matriz_colaborador) {
  # Create filename with timestamp
  timeIndex <- format(as.POSIXct(Sys.time(), "%d-%m-%Y %H:%M:%OS", tz = 'UTC'), "%d-%m-%Y_%Hh%Mm%OSs")
  fileName <- paste0(pathFicheirosGlobal, 'output_QA/validador_TRADS_', UniNAME,'_', postoID, '_', timeIndex, '.xlsx')
  
  # Create sheet list
  sheetList <- list()
  i <- 0
  
  # Create workbook
  wb <- createWorkbook()
  
  # Create workbook
  addWorksheet(wb, 'Quadro resumo')
  addWorksheet(wb, 'Regras nao cumpridas')
  addWorksheet(wb, 'Integracao')
  addWorksheet(wb, 'Diario')
  addWorksheet(wb, 'Semanal')
  addWorksheet(wb, 'Anual')
  addWorksheet(wb, 'Mensal')
  addWorksheet(wb, 'Matriz_calendario')
  addWorksheet(wb, 'Matriz_colab')
  
  for (colab in colabList) {
    i <- i + 1
    colabname <- paste0('ColabTibles_', colab)
    sheetList[i] <- colabname
    addWorksheet(wb, colabname)
  }
  
  writeData(wb, 'Quadro resumo', data[[6]], startCol = 1, startRow = 1)
  writeData(wb, 'Regras nao cumpridas', data[[1]], startCol = 1, startRow = 1)
  writeData(wb, 'Integracao', M_WFM, startCol = 1, startRow = 1)
  writeData(wb, 'Diario', data[[2]], startCol = 1, startRow = 1)
  writeData(wb, 'Semanal', data[[4]], startCol = 1, startRow = 1)
  writeData(wb, 'Anual', data[[3]], startCol = 1, startRow = 1)
  writeData(wb, 'Mensal', data[[5]], startCol = 1, startRow = 1)
  writeData(wb, 'Matriz_calendario', matriz_calendario, startCol = 1, startRow = 1)
  writeData(wb, 'Matriz_colab', matriz_colaborador, startCol = 1, startRow = 1)
  
  j <- 1
  for (sheet in sheetList) {
    writeData(wb, sheet, collaborator_tibbles[[colabList[j]]], startCol = 1, startRow = 1)
    j <- j + 1
  }
  
  # Save excel file
  saveWorkbook(wb, fileName)
}
