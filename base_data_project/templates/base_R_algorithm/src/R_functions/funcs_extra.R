#-------------------------------HC---------------------------------------
giveHC <- function(collaborator_tibbles, day_listextra, hcXmes, corretor = 0.1,matriz_base_dados_estatisticas,matriz_necessidades,matriz_cargas, matriz_calendario,posto_atual){
 
  saveCut1 <<- matriz_base_dados_estatisticas #<- saveCut1
  savecut2 <<- matriz_necessidades #<- savecut2
  saveList <<- day_listextra
  day_listextra <- day_listextra[-(1:4), ]
  matriz_base_dados_estatisticas$DATA <- as.character(matriz_base_dados_estatisticas$DATA)
  matriz_base_dados_estatisticas <- matriz_base_dados_estatisticas %>%  dplyr::filter(DATA  %in% day_listextra$date)
  print(matriz_base_dados_estatisticas)
  matriz_necessidades$DATA <- as.character(matriz_necessidades$DATA)
  #matriz_necessidades$DATA <- format(matriz_necessidades$DATA, "%Y-%m-%d")
  
  matriz_necessidades <- matriz_necessidades %>%  dplyr::filter(DATA  %in% day_listextra$date)
  print(matriz_necessidades)
   matriz_base_dados_estatisticas <- matriz_base_dados_estatisticas %>%  dplyr:: filter(FK_TIPO_POSTO == posto_atual) %>% 
    dplyr::group_by(FK_TIPO_POSTO,DATA_TURNO) 
   whythefuck <<- matriz_base_dados_estatisticas
  matriz_necessidades <- matriz_necessidades %>%  dplyr:: filter(FK_TIPO_POSTO == posto_atual)
  day_listextra$total_horasXpessoa <- as.double(day_listextra$total_horasXpessoa)
  day_listextra$total_horasXpessoa <- (day_listextra$total_horasXpessoa/(1-corretor))
  matriz_base_dados_estatisticas$TURNO <- substr(matriz_base_dados_estatisticas$DATA_TURNO, nchar(matriz_base_dados_estatisticas$DATA_TURNO), nchar(matriz_base_dados_estatisticas$DATA_TURNO))
  
  matriz_necessidades$DATA <- as.Date(matriz_necessidades$DATA)
  matriz_base_dados_estatisticas$DATA <- as.Date(matriz_base_dados_estatisticas$DATA)
  merged_data <- merge(matriz_necessidades, matriz_base_dados_estatisticas, by.x = c("DATA"), by.y = c("DATA"))
  
  sum_max_turno_saveNeeds <- matriz_base_dados_estatisticas %>% 
    group_by(DATA) %>%
    summarise(sum_maxTurno = sum(maxTurno))
  saveSum <<- sum_max_turno_saveNeeds

    merged_data <- merge(merged_data, sum_max_turno_saveNeeds, by.x = "DATA", by.y = "DATA")
  merged_data$ratio <- merged_data$maxTurno / merged_data$sum_maxTurno
  
  merged_data$HORAS.PESSOAS <- as.double( merged_data$HORAS.PESSOAS)
  merged_data$ratio <- as.double(merged_data$ratio)
  merged_data$ratio <- ifelse(is.na(merged_data$ratio), 0, merged_data$ratio)
  merged_data$Needs_Per_turno <- round(merged_data$HORAS.PESSOAS * merged_data$ratio)
  merged_data$Horas_Per_turno <- round(merged_data$HORAS * merged_data$ratio)
  
  monthly_dictionary <- vector("list", length = 12)
  saveMergie <<- merged_data
  # Set names for each list element corresponding to months
  names(monthly_dictionary) <- c(
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  )
  # Initialize matriz_dia_colab as an empty data frame
  matriz_dia_colab <- data.frame(DATA = character(),
                                 TURNO = character(),
                                 month = character(),
                                 MATRICULA = character(),
                                 carga_media = numeric(),
                                 hc_ano = numeric(),
                                 carga_max = numeric(),
                                 stringsAsFactors = FALSE)
  
  # Iterate through each unique date and turno
  for (i in 1:nrow(merged_data)) {
    print(paste0("In iteration for HC attribution: ", i))
    
    # Extract the date and turno from merged_data
    date <- as.character(merged_data$DATA[i])
    turno <- merged_data$TURNO[i]
    #date <- format(date, "%Y-%m-%d")
    print(date)
    date_col = matriz_calendario[,c('MATRICULA',date)]
    print(date_col)
    uniques <- unique(date_col[,date])
    turno_uniques <- uniques %in% c('M', 'T')
    how_many_uniques <- sum(unlist(turno_uniques))
    if(how_many_uniques <= 0) how_many_uniques <- 1
    month <- month(date)  # %B gives full month name
    print(date)
    print(month)
    merged_data[i,'Month'] <- month
    
    # Count 'M' or 'T' for each collaborator
    working_collabs <- filter(date_col, !!sym(date) %in% c(turno,'MoT'))
    print("Working collabs is")
    print(working_collabs)# working_collabs_MOT <- filter(date_col, !!sym(date) ==  'MoT')
    total_available_hours <- 0

    
    if(nrow(working_collabs) == 0){
      merged_data$Available_time[i] <- 0
    } else {
      comp <- 0
      for(j in 1:nrow(working_collabs)){
        matricula <- working_collabs[j,'MATRICULA']
        if(working_collabs[j,date] == 'MoT'){
          carga <- collaborator_tibbles[[matricula]][1,"carga_media_fixa"] / how_many_uniques

        }else{
          carga <- collaborator_tibbles[[matricula]][1,"carga_media_fixa"]
          
        }
        cargas_row <- matriz_cargas %>% filter(EMP == matricula)
        if(cargas_row$HORAS_COMPLEMENTARIAS == 'Y'){
          carga_comp_max <- cargas_row$HORAS_COMPLEMENTARIAS_MAX_ANUAL
          carga_max <- cargas_row$HORAS_TRAB_DIA_CARGA_MAX
          
          total_available_hours <- total_available_hours + merged_data$Horas_Per_turno[i]
          
          # Create a new row to append to matriz_dia_colab
          new_row <- data.frame(DATA = date,
                                TURNO = turno,
                                month = month,
                                MATRICULA = matricula,
                                carga_media = find_closest_mod_0.25(carga),
                                hc_ano = carga_comp_max,
                                carga_max = carga_max,
                                hc_dada = 0,
                                stringsAsFactors = FALSE)
          
          new_row$Percentage_hc_dada <-  (new_row$hc_dada/new_row$hc_ano)*100
          # Append the new row to matriz_dia_colab
          matriz_dia_colab <- rbind(matriz_dia_colab, new_row)
        }
      }
      merged_data$Available_time[i] <- total_available_hours
    }
  }
  
   saveMerge <<- merged_data #<- saveMerge
   saveColabss <<- matriz_dia_colab #<- saveColabss

  final_merge <- calculatePercentages(merged_data)
  final_merge <- arrange(final_merge, desc(final_merge$HC_day))
  saveFinal <<- final_merge
  building_matrix <- NULL
  for(i in 1:nrow(final_merge)){
    #print(paste0("Iteration: ",i))
    #row <- final_merge[i,]
   matriz <- calculate_max_hc(matriz_dia_colab,final_merge,i)
   saveBuildingMatrix <<- building_matrix
   building_matrix <- rbind(building_matrix, matriz)
 #  print(nrow(building_matrix))
  }
  saveResult <<- building_matrix #<- saveResult
  # print(diehere)
  # matriz_dia_colab <- addHcToMonth(collaborator_tibbles,matriz_cargas, matriz_calendario, final_merge)
  for (i in 1:nrow(building_matrix)) {
    # Extract collaborator code and date from aveResult
    collaborator <- building_matrix[i, "MATRICULA"]

    date <- building_matrix[i, "DATA"]
    hc_chosen <- building_matrix[i,'hc_chosen']
    #print(paste0("Collaborator: ", collaborator, " has ",hc_chosen, " extra hours for date ", date))
    tibble_index <- which(names(collaborator_tibbles) == as.character(collaborator))
    date_index <- which(collaborator_tibbles[[tibble_index]]$date == date)
    collaborator_tibbles[[tibble_index]][date_index, "HORAS_EXTRA"] <- hc_chosen
    
  }
  return(collaborator_tibbles)
}

calculate_max_hc <- function(matriz, merge_data, i){
  # i <- 731
  # merge_data <- final_merge
  # matriz <- matriz_dia_colab
  row_to_give <- merge_data[i,]
  date <- row_to_give$DATA
  turno <- row_to_give$TURNO
  # saveMAtriz <<- matriz #<- saveMAtriz
  # saveRowas <<- row_to_give# <- saveRowas
  #date <- format(as.POSIXct(date, format = "%Y-%m-%d"), '%d-%m-%Y') 
  matriz_to_use <- matriz %>%  filter(DATA == date)
  
  data_by_turno <- split(matriz_to_use, matriz_to_use$DATA)
  rows_by_turno <- split(merge_data, merge_data$DATA)
  
  # matriz_to_use <- matriz %>%  filter(DATA == date)
  # matriz_to_use <- matriz_to_use %>%  filter(TURNO == turno)
  building_matrix <- NULL
  #killer <<- data_by_turno
  if(nrow(matriz_to_use )> 0){
    
    for (turno in names(data_by_turno)) {
      subset_data <- data_by_turno[[turno]]
      subset_row <- rows_by_turno[[turno]]
      
      row_given <- Colab_extra_hour(subset_row, subset_data)
     building_matrix <- rbind(building_matrix, row_given)
     iteratable <- subset(matriz_to_use, !(matriz_to_use$DATA == row_given$DATA & 
                                                matriz_to_use$TURNO == row_given$TURNO &
                                                matriz_to_use$MATRICULA == row_given$MATRICULA))
     
    }
  }
 # what_is_this <<- building_matrix
  return(building_matrix)
}

Colab_extra_hour <- function(row, matriz){
  # row <- row_to_give
  # matriz <- iteratable 
  # Find the row where the value in the column Percentage_hc_dada is minimum
  # min_value_percentage <- min(matriz$Percentage_hc_dada)
  # rows_min <<- matriz %>%  filter(Percentage_hc_dada == min_value_percentage)
  # if(nrow(rows_min) > 1){
  #   max_value_month <- max(rows_min$carga_media)
  #   rows_max <- rows_min %>%  filter(carga_media == max_value_month)
  #   if(nrow(rows_max) > 1){
  #     num_rows <- nrow(rows_max)
  #     
  #     # Generate a random row index
  #     random_row_index <- sample(1:num_rows, 1)
  #     
  #     # Retrieve the random row from the data table
  #     random_row <- rows_max[random_row_index, ] 
  #     row_to_use <- random_row
  #   }else{
  #     row_to_use <- rows_max
  #   }
  # }else{
  #   row_to_use <- rows_min
  # }
  
  # Find the ammount of hours that can be given 
  building_matrix <- NULL
  # whatisMatriz <<- matriz
  # whatisRow <<- row
  for(i in 1:nrow(matriz)){
    row_to_use <- matriz[i,]
    if(row_to_use$hc_ano >= row_to_use$hc_dada){
      if((row_to_use$carga_max - row_to_use$carga_media) < (row_to_use$hc_ano - row_to_use$hc_dada)){
        carga <- row_to_use$carga_max - row_to_use$carga_media
        row_to_use$hc_for_day <- row_to_use$carga_max - row_to_use$carga_media
      }else{
        carga <- row_to_use$hc_ano - row_to_use$hc_dada
        row_to_use$hc_for_day <- row_to_use$hc_ano - row_to_use$hc_dada
      }
    }else{
      row_to_use$hc_for_day <- 0
    }
    building_matrix <- rbind(building_matrix, row_to_use)
  }
  saveMatriz1 <<- building_matrix #<- saveMatriz1
  build_day <- data.frame(
    HORAS_P = numeric(2),
    HORAS_E = numeric(2),
    HORAS_BEST = numeric(2),
    row.names = c("M", "T")
  )
  
  summarized_hc <- aggregate(hc_for_day ~ TURNO, data = building_matrix, sum)
  summarized_he <- aggregate(Available_time ~ TURNO, data = row, sum)

  # Assign summarized values to build_day
  for (i in 1:nrow(summarized_hc)) {
    turno <- summarized_hc[i, "TURNO"]
    hc_for_day_sum <- summarized_hc[i, "hc_for_day"]
    build_day[turno, "HORAS_P"] <- hc_for_day_sum
  }
  
  for (i in 1:nrow(summarized_he)) {
    turno <- summarized_he[i, "TURNO"]
    hc_for_day_sum <- summarized_he[i, "Available_time"]
    build_day[turno, "HORAS_E"] <- hc_for_day_sum
  }
  
  build_day$HORAS_BEST <- pmin(build_day$HORAS_P, build_day$HORAS_E)
  merged_data <- merge(building_matrix, build_day, by.x = "TURNO", by.y = "row.names", all.x = TRUE)
  building_matrix$hc_chosen <- with(merged_data, {
    hc_for_day / HORAS_P * HORAS_BEST
  })
  building_matrix$hc_dada <- with(building_matrix, {
    hc_dada + hc_chosen
  })
  whatTheActualFuck <<- building_matrix
  return(building_matrix)
}

calculatePercentages <- function(day_listextra, hcXmes = 15000) {
  totalExtraNeeds <- sum(day_listextra$ExtraHours)
  day_listextra <- day_listextra %>%  mutate("ExtraHours" = ifelse(day_listextra$Needs_Per_turno < day_listextra$Available_time, 0, day_listextra$Needs_Per_turno - day_listextra$Available_time))
  totalExtraNeeds <- as.double(sum(day_listextra$ExtraHours))
  # Calculate the minimum between total hours and hc_mes for each month
  monthly_totals <- day_listextra %>%
    group_by(Month) %>%
    summarize(totalExtraNeeds = sum(ExtraHours)) %>%
    mutate(totalHours_Mes = pmin(totalExtraNeeds, hcXmes))
  saveDayy <<- day_listextra
  saveMonthly <<- monthly_totals
  # Join the monthly totals back to the day_listextra
  day_listextra <- day_listextra %>% left_join(monthly_totals, by = "Month")
  
  # Calculate delta for each row
  day_listextra <- day_listextra %>% mutate(Delta = ifelse(ExtraHours != 0, ExtraHours / totalExtraNeeds, 0))
  
  # Calculate HC_day for each row
  day_listextra <- day_listextra %>% mutate(HC_day = totalExtraNeeds * Delta)
  
  return(day_listextra)
}

addHcToMonth <- function(collaborator_tibbles,matriz_cargas, matriz_calendario, merged_data){
  saveTibbie <<- collaborator_tibbles
  saveCargie <<- matriz_cargas
  saveCalie <<- matriz_calendario
  saveMergie <<- merged_data
  
  # for (i in 1:nrow(merged_data)){
  #   date <- merged_data$DATA
  #   turno <- merged_data$TURNO
  #   
  # }
  for( i in 1:nrow(matriz_calendario)){
    employee_id <- matriz_calendario[i, 'MATRICULA'] 
    cargas_row <- matriz_cargas %>% filter(EMP == employee_id)
    carga_comp <- 0
    if(cargas_row$HORAS_COMPLEMENTARIAS == 'Y' & cargas_row$TIPO_DE_TURNO != 'F'){
      carga_comp_max <- cargas_row$HORAS_COMPLEMENTARIAS_MAX_ANUAL
      carga_comp_min <- cargas_row$HORAS_COMPLEMENTARIAS_MIN_ANUAL
    }
    print(employee_id)
  }
}

