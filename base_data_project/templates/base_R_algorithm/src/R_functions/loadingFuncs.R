insert_feriados <- function(df_feriados, reshaped_final_3){
  default_names <- paste0("Column", seq_along(reshaped_final_3))
  new_row <- data.frame(matrix('-', nrow = 1, ncol = ncol(reshaped_final_3)))
  
  new_row[1, 1] <- "TIPO_DIA"
  upper_bind <-reshaped_final_3[1,] 
  lower_bind <- reshaped_final_3[-1,]
  colnames(upper_bind) <- default_names
  colnames(lower_bind) <- default_names 
  colnames(new_row) <- default_names
  reshaped_final_3 <-  dplyr::bind_rows(upper_bind, new_row, lower_bind) # reshaped_final[-1,])
  colnames(reshaped_final_3) <- NULL
  
  
  for (k in seq(1,nrow(df_feriados))) {
  
    temp <- df_feriados[k,1]
    data <- substr(temp, 1, 10)
    val <- df_feriados[k,2]
    
    
  
    col_index <- which(apply(reshaped_final_3, 2, function(col) data %in% col))
    #print(paste0('temp: ',temp,' data: ',data,' val: ',val, ' col_index: ',col_index))
    #tryCatch({
    if (val == 2) {
      reshaped_final_3[2,col_index[1]:col_index[2]] <- "F"
      
    }else if (val == 3){
      reshaped_final_3[2,col_index[1]:col_index[2]] <- "F"
      reshaped_final_3[4:nrow(reshaped_final_3),col_index[1]] <- "F"
      reshaped_final_3[4:nrow(reshaped_final_3),col_index[2]] <- "F"
    }
    # },
    #error = function(e){
    # print(data)
    #str(e)
    #next
    #})
  }
  
  
  return(reshaped_final_3)
  
  
}


#this function assings the holidays(V) and absences(A) values to the matrix
insert_holidays_abscences <- function(employees_tot,ausencias_total,reshaped_final_3){
  # employees_tot <- all_colab_pad
  
  for (colab in employees_tot) {
    
    #colab_pad <- sapply(colab, pad_zeros)
    colab_pad <- colab
    #ausencias <- get_ausencias_ferias(pathOS, erro_control = 0, colab_pad)
    ausencias <- subset(ausencias_total, MATRICULA == colab_pad) #temp testing
    #ausencias <- subset(ausencias, DATA_INI >= as.Date("2024-01-01"))
    if (nrow(ausencias) == 0) {
      next
    }
    
    
    row_index <- which(apply(reshaped_final_3, 1, function(row) colab %in% row))
    
    for (k in seq(1,nrow(ausencias))) {
      
      
      temp <- ausencias[k,4]
      data <- substr(temp, 1, 10)
      val <- ausencias[k,6]
      fk_motivo_ausencia <- ausencias[k,7]
      col_index <- which(apply(reshaped_final_3, 2, function(col) data %in% col))
      #tryCatch({
      if (fk_motivo_ausencia == 1) {
        reshaped_final_3[row_index,col_index[1]] <- "V"
        reshaped_final_3[row_index,col_index[2]] <- "V"
      }else{
        reshaped_final_3[row_index,col_index[1]] <- val
        reshaped_final_3[row_index,col_index[2]] <- val
      }
      # },
      #error = function(e){
      # print(data)
      #str(e)
      #next
      #})
    }
    
    
    
  }
  
  
  return(reshaped_final_3)
}

#this function assins 0 after the M shift and before the T shif
#to indicate free afternood of morning as there are two column for each date
#each column is related to the afternoon or morning
create_M0_0T <- function(reshaped_final_3){
  for(i in seq(2, length(reshaped_final_3), by = 2)){ #length(reshaped_final_3)
    #print(reshaped_final_3[,i:(i+1)])
    
    for (j in seq(3,nrow(reshaped_final_3))){
      # print(paste0("Valor de j: ", j))
      #print(reshaped_final_3[j,i:(i+1)])
      
      if (reshaped_final_3[[j,i]] == "M") {
        #reshaped_final_3[[j,i]] <- "M"
        reshaped_final_3[[j,i+1]] <- 0
      }else if(reshaped_final_3[[j,i]] == "T"){
        reshaped_final_3[[j,i]] <- 0
        #reshaped_final_3[[j,i+1]] <- "T"
      }else if(reshaped_final_3[[j,i]] == "T1"){
        reshaped_final_3[[j,i]] <- 0
        #reshaped_final_3[[j,i+1]] <- "T1"
      }else if(reshaped_final_3[[j,i]] == "T2"){
        reshaped_final_3[[j,i]] <- 0
        #reshaped_final_3[[j,i+1]] <- "T2"
      }
      
    }
    
  }
  return(reshaped_final_3)
}

#this function creates MT or MT1T2 cycles accodring starting in the shift indicated in 
#"semana1" variable in the core_alg_schedules database table
#example MMMMMMM TTTTTTT MMMMMMM   semana1 <- M
#example MMMMMMM T1T1T1T1T1T1T1 T2T2T2T2T2T2T2 semana1 <- M
#example T2T2T2T2T2T2T2 MMMMMMM T1T1T1T1T1T1T1 semana1 <- T2
create_MT_MTT_cycles <- function(df_alg_variables_filtered, reshaped_final_3){
  colnames(reshaped_final_3) <- NULL
  rownames(reshaped_final_3) <- NULL
  df_alg_variables_filtered <- df_alg_variables_filtered %>%
    dplyr::select(EMP,SEQ_TURNO,SEMANA_1)
  
   for (row in seq(1,nrow(df_alg_variables_filtered))){
    emp <- df_alg_variables_filtered[row,1]
  
    seq_turno <- df_alg_variables_filtered[row,2]
   
    ##################################################
    ##################################################
    #this if is for testing purposes!!!!!!!!!!!!!!!!!!
     if(is.na(seq_turno) | is.null(seq_turno)){
      print(paste0("Não há Seq turno definido para o colaborador:    ", emp))
      seq_turno <-"T"
      
    }
    ##################################################
    ##################################################
    ##################################################
    ##################################################
    semana1 <- df_alg_variables_filtered[row,3]
    eachrep <- count_days_in_week(as.character(reshaped_final_3[1,2]))*2
    
    if (seq_turno == "MT" &  semana1 == "T") {
      new_row <- rep(c('T'),eachrep)
      new_row2 <- rep(c('M','T'),ceiling((length(reshaped_final_3)/2/14)),each=14)
      new_row <- c(emp, new_row,new_row2)
      elements_to_drop <- length(new_row)-length(reshaped_final_3)
      new_row <- new_row[1:(length(new_row)-elements_to_drop)]
    }else if (seq_turno == "MT" & semana1 == "M") {
      new_row <- rep(c('M'),eachrep)
      new_row2 <- rep(c('T','M'),ceiling((length(reshaped_final_3)/2/14)),each=14)
      new_row <- c(emp, new_row,new_row2)
      
      elements_to_drop <- length(new_row)-length(reshaped_final_3)
      new_row <- new_row[1:(length(new_row)-elements_to_drop)]
    }else if (seq_turno == "MTT" & semana1 == "M") {
      new_row <- rep(c('M'),eachrep)
      new_row2 <- rep(c('T','T','M'),ceiling((length(reshaped_final_3)/3/14)),each=14)
      new_row <- c(emp, new_row,new_row2)
      elements_to_drop <- length(new_row)-length(reshaped_final_3)
      new_row <- new_row[1:(length(new_row)-elements_to_drop)]
      
    }else if (seq_turno == "MTT" & semana1 == "T1") {
      new_row <- rep(c('T'),eachrep)
      new_row2 <- rep(c('T','M','T'),ceiling((length(reshaped_final_3)/3/14)),each=14)
      new_row <- c(emp, new_row,new_row2)
      elements_to_drop <- length(new_row)-length(reshaped_final_3)
      new_row <- new_row[1:(length(new_row)-elements_to_drop)]
      
    }else if(seq_turno == "MTT" & semana1 == "T2") {
      
      new_row <- rep(c('T'),eachrep)
      new_row2 <- rep(c('M','T','T'),ceiling((length(reshaped_final_3)/3/14)),each=14)
      new_row <- c(emp, new_row,new_row2)
      elements_to_drop <- length(new_row)-length(reshaped_final_3)
      new_row <- new_row[1:(length(new_row)-elements_to_drop)]
    }else{
      new_row <- rep(seq_turno, length(reshaped_final_3))
      new_row <- c(emp, new_row)
      elements_to_drop <- length(new_row)-length(reshaped_final_3)
      new_row <- new_row[1:(length(new_row)-elements_to_drop)]
    }  
    
    reshaped_final_3 <- rbind(reshaped_final_3, new_row)
    
  }
  
  colnames(reshaped_final_3) <- NULL
  rownames(reshaped_final_3) <- NULL
  
  return(reshaped_final_3)
}

# df_daysoff_final <- df_days_off_filtered
assign_days_off <- function(reshaped_final_3,df_daysoff_final){
  
  ###############For testing purposes
  # reshaped_final_3[4,1] <- "4401683"
  ######################################
  
  emps <- unique(df_daysoff_final$EMPLOYEE_ID)
  for (emp in emps) {
    df_daysoff <- df_daysoff_final %>% 
      dplyr::filter(EMPLOYEE_ID == emp)
    #print(emp)
    for (i in seq(nrow(df_daysoff))) {
      date_temp <- df_daysoff[i,2]
      date <- substr(date_temp,1,10)
      val <-  df_daysoff[i,3]
      
      row_index <- which(apply(reshaped_final_3, 1, function(row) emp %in% row))
      col_index <- which(apply(reshaped_final_3, 2, function(col) date %in% col))
      ##########DEBUGGING###############
      # print(paste0("this is row index from reshaped3:   ",row_index))
      # print(paste0("these are col indexes from reshaped3:   ",col_index[1], ", ", col_index[2]))
      # print(paste0("Progress:   ", i, " of ", nrow(df_daysoff)))
      #Sys.sleep(1)
      reshaped_final_3[row_index,col_index[1]] <- val
      reshaped_final_3[row_index,col_index[2]] <- val
      
    }
    
  }
  return(reshaped_final_3)
}

assign_empty_days <-  function(df_tipo_contrato, reshaped_final_3, not_in_pre_ger,df_feriados_filtered){
  weekday_contrato2 <- c('Mon','Tue','Wed','Thu','Fri')
  weekday_contrato3 <- c('Mon','Tue','Wed','Thu')
  # thrusday development ----------------------------------------------------
  
  for (emp in not_in_pre_ger) {
    
    #pay attention to "5006519" not_in_pre_ger[6], and 0375558  [7],
    #emp <- not_in_pre_ger[6]
    tipo_de_contrato <- df_tipo_contrato %>%
      filter(EMP == emp) %>%
      select(TIPO_CONTRATO) %>%
      pull()
    print(paste0("Colab:   ", emp))
    print(paste0("Tipo de Contrato:  ", tipo_de_contrato))
    # Sys.sleep(1)
    row_index <- which(apply(reshaped_final_3, 1, function(row) emp %in% row))
    if (tipo_de_contrato == 6) {
      
      print("Tipo de contrato = 6, do nothing, next loop")
      next
    }
    #print(emp)
    for (i in seq(2,length(reshaped_final_3), by=2)) {
      #print(i)
      date_temp <- reshaped_final_3[1,i]
      date <- substr(date_temp,1,10)
      weekday <- lubridate::wday(date, label = TRUE)
      type_of_day <- as.character(reshaped_final_3[1,i])
      
      type_of_hol <- df_feriados_filtered[df_feriados_filtered$DATA==as.Date(type_of_day),2]
      
      # if(length(type_of_hol) > 0 &&  type_of_hol == 3){
      #   print(type_of_hol)    
      # }
      # to save
      if ( length(type_of_hol)==0 ) {
        type_of_hol <- '-'
        # print(type_of_hol) 
      }
    }  #   val <-  df_daysoff[i,2]
      
      #8.	Consultar o tipo de contrato na tabela MA2, caso seja de 3 dias, 
      #colocar todas as segundas, terça, quartas e quintas que não sejam feriados 
      #como dia vazio (-);
      
      if(length(type_of_hol) > 0 &&  type_of_hol == 3){
        # print((type_of_hol == 3))
        reshaped_final_3[row_index,seq(i, i+1)] <- 'F'
        
      }else if(tipo_de_contrato == 3 & 
         weekday %in% weekday_contrato3 &
         type_of_hol != 2){
        print((tipo_de_contrato == 3 & 
                 weekday %in% weekday_contrato3 &
                 type_of_hol != 2))
        reshaped_final_3[row_index,seq(i, i+1)] <- '-'
        
      }else if (tipo_de_contrato == 2 & 
                weekday %in% weekday_contrato2 &
                type_of_hol != 2) {
        print((tipo_de_contrato == 2 & 
                 weekday %in% weekday_contrato2 &
                 type_of_hol != 2))
        reshaped_final_3[row_index,seq(i, i+1)] <- '-'
      }
    }
    
  
  return(reshaped_final_3)
}


load_pre_ger_scheds <- function(df_pre_ger, employees_tot){
  names(df_pre_ger)[1] <- "EMPLOYEE_ID"
  
  employees_tot_pad <- sapply(employees_tot,pad_zeros)
  #como a query à bd é feita com ..... where FK_EMP in (vetor_de_colabs), a função unique(df_pre_ger$EMPLOYEE_ID) devolve apenas os colabs
  #com horários pregerados do vetor a processar. A função intersect deixa de ser necessária
  
  #emp_pre_ger <- base::intersect(unique(df_pre_ger$EMPLOYEE_ID),employees_tot_pad)#employees_tot %in% unique(df_pre_ger$EMPLOYEE_ID)
  emp_pre_ger <- unique(df_pre_ger$EMPLOYEE_ID)
  
  #do I need it
  employees_pad <- sapply(emp_pre_ger, pad_zeros)
  
  
  
  df_pre_ger_filtered <- df_pre_ger %>%
    dplyr::filter(IND == "P") %>% 
    dplyr::select(-IND)#%>% 
  #dplyr::filter(EMPLOYEE_ID %in% emp_pre_ger) %>% #this as not needed as it's filtered in the query already
  #-START_TIME_1,-START_TIME_2,-END_TIME_1,-END_TIME_2, -SCHED_TYPE, 
  
  reshaped <- df_pre_ger_filtered %>% pivot_wider(names_from = SCHEDULE_DT, values_from = SCHED_SUBTYPE)
  
  column_names <- as.data.frame(t(names(reshaped)), stringsAsFactors = FALSE)
  column_names <- setNames(column_names, names(reshaped))
  reshaped$EMPLOYEE_ID <- as.character(reshaped$EMPLOYEE_ID)
  reshaped_names <- bind_rows (column_names, reshaped)
  reshaped_names[1,1] <- "Dia"
  
  #DUPLICATE EVERY ROW TO GET M/T SHIFTS
  
  reshaped_1st_col <-  reshaped_names[, 1, drop = F]
  reshaped_last_cols <-  reshaped_names[,-1]
  reshaped_last_cols <- cbind(reshaped_last_cols,reshaped_last_cols)
  
  reshaped_last_cols <- reshaped_last_cols[, order(names(reshaped_last_cols))]
  
  
  reshaped_final <- cbind(reshaped_1st_col, reshaped_last_cols)
  rownames(reshaped_final) <- NULL
  colnames(reshaped_final) <- NULL
  
  
  new_row <- ifelse(seq_along(reshaped_final) %% 2 == 1, 'M', 'T')
  new_row <- c("TURNO", new_row)
  elements_to_drop <- length(new_row)-length(reshaped_final)
  new_row <- new_row[1:(length(new_row)-elements_to_drop)]
  
  reshaped_final_1 <-  rbind(reshaped_final[1,], new_row) # reshaped_final[-1,])
  reshaped_final_2 <- reshaped_final[-1,]
  
  default_names <- paste0("Column", seq_along(reshaped_final_1))
  colnames(reshaped_final_1) <- default_names
  colnames(reshaped_final_2) <- default_names
  
  # colnames(reshaped_final_1) <- make.names(names(reshaped_final_1), unique=TRUE)
  # colnames(reshaped_final_2) <- make.names(names(reshaped_final_2), unique=TRUE)
  reshaped_final_3 <- dplyr::bind_rows(reshaped_final_1, reshaped_final_2) 
  colnames(reshaped_final_3) <- NULL
  
  result <-  list(reshaped_final_3, emp_pre_ger)
  return(result)
}