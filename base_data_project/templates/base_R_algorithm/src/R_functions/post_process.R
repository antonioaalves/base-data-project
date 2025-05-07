# horariosDados<- savehorariosDados
# matriz_colaborador <- matriz_colaborador
# faixas_diarias<- M_dia1_final
# select_day <- select_day
# collaborator_tibbles<- collaborator_tibbles
# class<- class
# matriz_colab_semana <- matriz_colab_semana


resolve_implicacoes <- function(horariosDados, matriz_colaborador, faixas_diarias, select_day,collaborator_tibbles, class,matriz_colab_semana, gran = 15,data_bank){
  log_time <- Sys.time()
  log_file_name <-paste0(pathFicheirosGlobal,'pos_process_log_', info$UNI,'_', posto, '_', timeIndex, '.csv')
  
  
  if (is.null(data_bank)) {return(horariosDados)}
  colab_data_bank <- NULL
  
  # save the index names from collaborator tibbles
  colabTibblesList <- names(collaborator_tibbles)
  
  #Get colab info
  for (i in seq_along(collaborator_tibbles)) {
    table <- collaborator_tibbles[[i]]
    df <- get_slot_parameters(table, colabTibblesList[i])
    colab_data_bank <- rbind(colab_data_bank,df)
  }
  
  if (any(grepl('^ZERO-', names(data_bank)))) {
    new_schedules_results <- try_to_cover_zeros(data_bank, colab_data_bank, horariosDados, faixas_diarias, log_file_name)
    new_schedules <- new_schedules_results[[1]]
    data_bank <-  new_schedules_results[[2]]
    colab_data_bank <-  new_schedules_results[[3]]
  } else {
    return(NULL)
  }
  # if (any(grepl('^EXEC-', names(data_bank)))) {
  #   new_schedules <- try_to_remo_excess(data_bank, colab_data_bank, horariosDados, faixas_diarias)
  # } 
  horariosDados <- new_schedules
  return(list(horariosDados,data_bank))
}

try_to_remo_excess <- function(data_bank, colab_data_bank, horariosDados, faixas_diarias){
  print("Removing excessos")
  zero_keys <- grep('^EXEC-', names(data_bank), value = TRUE)
  X <- 22  
  
  collabs_with_excess_hours <- colab_data_bank[colab_data_bank$SLOTS_MISSING < 0, ]
  new_schedules <- horariosDados
  
  savecollabsfor<- collabs_with_excess_hours
  if(length(zero_keys) >= 1){
    for (key in zero_keys) {
      day <- gsub('^EXEC-', '', key)
      cat("Day:", day, "\n")
      
      schedule_for_zero_day <- horariosDados[[day]]
      faixas_for_day <- faixas_diarias[[day]]
      
      collaborators_for_day <- data_bank[[key]]$collaborators
      
      filtered_collabs <- collabs_with_excess_hours[collabs_with_excess_hours$EMP %in% collaborators_for_day, ]
      
      schedule_for_zero_day$timestamps <- as.POSIXct(schedule_for_zero_day$timestamps)
      
      for (i in 1:nrow(schedule_for_zero_day)) {
        row <- schedule_for_zero_day[i, ]
        if (row$Ideal_por_Cobrir < 0) {
          for (collab in (filtered_collabs)$EMP) {
            faixa_horaria <- faixas_for_day[faixas_for_day$EMP == collab, ]
            if (nrow(faixa_horaria) > 0) {
              faixa_horaria_start <- as.POSIXct(faixa_horaria$hora_in)
              faixa_horaria_end <- as.POSIXct(faixa_horaria$hora_out)
              
              # Check if timestamp falls within the faixa_horaria
              if (row$timestamps >= faixa_horaria_start && row$timestamps <= faixa_horaria_end) {
                colname <- paste0('EMPloyee_',collab)
                schedule_for_zero_day[i, colname] <- as.integer(schedule_for_zero_day[i, colname]) - 1
                schedule_for_zero_day[i, 'Alocado'] <- schedule_for_zero_day[i, 'Alocado'] - 1
                schedule_for_zero_day[i, 'Minimo_Por_cobrir'] <- schedule_for_zero_day[i, 'Minimo_Por_cobrir'] + 1
                schedule_for_zero_day[i, 'Ideal_por_Cobrir'] <- schedule_for_zero_day[i, 'Ideal_por_Cobrir'] + 1
                filtered_collabs[filtered_collabs$EMP == collab, "SLOTS_MISSING"] <- filtered_collabs[filtered_collabs$EMP == collab, "SLOTS_MISSING"] + 1
                collabs_with_excess_hours[collabs_with_excess_hours$EMP == collab, "SLOTS_MISSING"] <- collabs_with_excess_hours[collabs_with_excess_hours$EMP == collab, "SLOTS_MISSING"] + 1
                
                print(paste0("Filled Zero at: ", row$timestamps, " with collaborator ", collab))
              }
            }
          }
        }
      }  
      new_schedules[[day]] <- schedule_for_zero_day 
      
    }
  }
  return(new_schedules)
}

try_to_cover_zeros <- function(data_bank, colab_data_bank, horariosDados, faixas_diarias, log_file_name){
  print("Covering zeros")
  zero_keys <- grep('^ZERO-', names(data_bank), value = TRUE)
  collabs_with_excess_hours <- colab_data_bank %>%
    #  filter(SLOTS_MISSING > 0) %>%
    arrange(desc(SLOTS_MISSING))
  
  new_schedules <- horariosDados
  i <- 1
  savecollabsfor<- collabs_with_excess_hours
  for (key in zero_keys) {
    # if (key=="ZERO-2024-12-15") {
    #   print("dia 15")
    #   break
    # }
    day <- gsub('^ZERO-', '', key)
    print(paste0("Iteration: ", i))
    cat("Day:", day, "\n")
    i <- i+1
    schedule_for_zero_day <- horariosDados[[day]]
    schedule_for_zero_day <- trim_schedule(schedule_for_zero_day,day)
    faixas_for_day <- faixas_diarias[[day]] 
    faixas_for_day <- faixas_for_day[faixas_for_day$tipo_hor != 'F',]
    if(nrow(faixas_for_day) == 0) next
    schedule_map <- build_schedule_map(faixas_for_day,schedule_for_zero_day,day,new_schedules)
    collaborators_for_day <- data_bank[[key]]$collaborators
    zero_indices <- str_split(data_bank[[key]]$indices,' ')[[1]]
    filtered_collabs <- collabs_with_excess_hours[collabs_with_excess_hours$EMP %in% collaborators_for_day, ]
    filtered_collabs <- filtered_collabs %>%
      # filter(SLOTS_MISSING > 0) %>%
      arrange(desc(SLOTS_MISSING))
    schedule_for_zero_day$timestamps <- as.POSIXct(schedule_for_zero_day$timestamps)
    new_schedule <- schedule_for_zero_day
    
    for( index in zero_indices){
      print(index)
      collab_to_use <- NULL
      given = FALSE
      goodCollab = FALSE
      # Get the indices 
      if(grepl(":", index)){
        print("interval")
        collapsed_indices <- index
        indices <- as.numeric(unlist(strsplit(collapsed_indices, ":")))
        
        # Create a temporary dictionary
        temp_dict <- list(
          indices = as.numeric(indices[1]:indices[2]),  # Generate the indices
          length = indices[2] - indices[1] + 1  # Calculate the length
        )
      }else{
        print("not an interval")
        temp_dict <- list(
          indices = as.numeric(index[1]), 
          length = 1  
        )
      }
      print(temp_dict)
      
      savetempd <<- temp_dict
      saveMap <<- schedule_map
      # temp_dict_for_collab <- temp_dict
      # # see which collab can fill it 
      # for(collab in filtered_collabs$EMP){
      #   max_work <- get_slot_max(collab, matriz_colaborador)
      #   current_slots <- collab_day_working_slots(collab, day, schedule_for_zero_day)
      #   temp_dict_for_collab <- pad_indices(collab, temp_dict, schedule_for_zero_day)
      #   savepads <<- temp_dict_for_collab
      #   if(all(temp_dict_for_collab$indices %in% schedule_map[[collab]])){
      #       valid <- FALSE
      #       collab_to_use <- collab
      # 
      #       schedule_start <- get_schedule_start(collab, schedule_for_zero_day)
      #       schedule_end <- get_schedule_end(collab, schedule_for_zero_day)
      #       
      #       if(current_slots + temp_dict_for_collab$length <= max_work){
      #         valid <- TRUE
      #       }else{
      #         next
      #       }
      #       if(valid == TRUE){
      #         goodCollab <- TRUE
      #         collab_to_use <- collab
      #         temp_dict <- temp_dict_for_collab
      #         
      #       }
      #     }else{
      #       next
      #     }
      #   }
      
      temp_dict_collab <- list()
      
      
      
      for(collab in filtered_collabs$EMP){
        # print(collab)
        # print(temp_dict)
        max_work <- get_slot_max(collab, matriz_colaborador)
        current_slots <- collab_day_working_slots(collab, day, schedule_for_zero_day)
        if(length(temp_dict$indices)>0){ 
          indices <- temp_dict$indices
          
          if(any(indices %in% schedule_map[[collab]])){
            temp_dict_temp <- pad_indices(collab, temp_dict, schedule_for_zero_day)
            indices <- temp_dict_temp$indices
            print(indices)
            LEFT <- FALSE
            RIGHT <- FALSE
            savepads <<- temp_dict
            
            
            valid <- FALSE
            collab_to_use <- collab
            
            schedule_start <- get_schedule_start(collab, schedule_for_zero_day)
            schedule_end <- get_schedule_end(collab, schedule_for_zero_day)
            indices_match <- which(indices %in% schedule_map[[collab]])
            indices <- indices[indices_match]
            if(indices[1] > schedule_end){
              print("On the right")
              RIGHT <- TRUE
            }else if(indices[length(indices)] < schedule_start){
              print("On the left")
              LEFT <- TRUE
            }
            if(current_slots + length(indices) <= max_work){
              valid <- TRUE
            }else{
              print("Too big we have to shorten")
              diff <- abs(max_work - (current_slots + length(indices)))
              if(LEFT && diff > 0){
                valid <- TRUE
                indices <- indices[-seq_len(diff)]
                
              }else if(RIGHT && diff > 0){
                valid <- TRUE
                indices <- indices[-seq(length(indices) - diff + 1, length(indices))]
              }
            }
            
            if(valid == TRUE){
              goodCollab <- TRUE
              collab_to_use <- c(collab_to_use, collab)
              temp_dict$indices <- temp_dict$indices[!temp_dict$indices %in% indices]
              temp_dict_collab[[collab]] <- list(collab = collab, indices = indices)
              
            }
            
          }else{
            next
          }
        }
      }
      indices_not_covered <- ifelse(length(temp_dict$indices) > 0, temp_dict$indices, 0)
      collab <- collab_to_use
      if (length(temp_dict_collab) > 0) {
        for(collab_case in temp_dict_collab){
          indices <- collab_case$indices
          collab <- collab_case$collab
          
          for(index in indices){
            collab_row <- collabs_with_excess_hours[collabs_with_excess_hours$EMP == collab, ]
            
            slots_missing_value <- collab_row$SLOTS_MISSING
            
            print(paste("Collaborator:", collab, "Index:", index, "SLOTS_MISSING:", slots_missing_value))
            #value to pass to replace function is 1 when giving an index and -1 when removing
            #if future use index list then value is still 1
            new_schedule <- replace_schedule_index(collab, new_schedule,index,1)
            
            stringlog <- (paste0("Filled Zero at: ", schedule_for_zero_day[index,]$timestamps, " with collaborator ", collab, "for day: ", day))
            # write.table(stringlog, log_file_name, append = TRUE, row.names = FALSE, col.names = FALSE)
            colab_data_bank[colab_data_bank$EMP == collab, "SLOTS_MISSING"] <- colab_data_bank[colab_data_bank$EMP == collab, "SLOTS_MISSING"] -1
            filtered_collabs[filtered_collabs$EMP == collab, "SLOTS_MISSING"] <- filtered_collabs[filtered_collabs$EMP == collab, "SLOTS_MISSING"] - 1
            collabs_with_excess_hours[collabs_with_excess_hours$EMP == collab, "SLOTS_MISSING"] <- collabs_with_excess_hours[collabs_with_excess_hours$EMP == collab, "SLOTS_MISSING"] - 1
            given <- TRUE
            #readLines(con = stdin(), n = 1)
          }
        }
      } 
      
      just_in_case <<- data_bank
      ## IMPROVISE IF THERES NO COVERAGE
      testOver <- FALSE
      # if(length(indices_not_covered > 0) & testOver == TRUE){
      #   for(index in indices_not_covered){
      #     print(paste("No Collaborator for ", "Index:", index, ' with excess hours'))
      #     #print("Finding collab that works")
      #     foundCollab <- FALSE
      #     for(collab in faixas_for_day$EMP){
      #       print(index)
      #       
      #       if (index %in% schedule_map[[collab]]) {
      #         foundCollab <- TRUE
      #        # print("Got collab")
      #         collab_row <- colab_data_bank[colab_data_bank$EMP == collab, ]
      #         slots_missing_value <- collab_row$SLOTS_MISSING
      #         print(paste("Collaborator:", collab, "Index:", index, "SLOTS_MISSING:", slots_missing_value))
      #         percentage <- get_hour_percent(collab_row$EMP, collab_row$SLOTS_MISSING)
      #         exec_key <- find_collab_exec(data_bank, collab_row$EMP)
      #         #print(exec_key)
      #         if(length(exec_key) >=1){
      #         schedule_without_excess_result <- remove_target_excess(exec_key, collab, colab_data_bank, data_bank, horariosDados, faixas_diarias, log_file_name)
      #         while(length(schedule_without_excess_result) == 1){
      #           #print("infinte loop")
      #           data_bank[[exec_key]]$collaborators <- data_bank[[exec_key]]$collaborators[data_bank[[exec_key]]$collaborators != collab]
      #           savedogwater <<- schedule_without_excess_result
      #             exec_key <- find_collab_exec(data_bank, collab_row$EMP)
      #            # print(exec_key)
      #             if(is.null(exec_key )){
      #               print("Cannot remove excess for collab")
      #               #readLines(con = stdin(), n = 1)
      #               given = FALSE
      #               break
      #               
      #             }
      #             exec_day <- gsub('^EXEC-', '', exec_key)
      #             schedule_without_excess_result <- remove_target_excess(exec_key, collab, colab_data_bank, data_bank, horariosDados, faixas_diarias, log_file_name)
      #             saveThis <<- schedule_without_excess_result
      #             
      #         }
      #         if(length(schedule_without_excess_result) == 1) next
      #             new_schedule_matrix <- schedule_without_excess_result[[1]]
      # 
      #             excess_indices_removed <- schedule_without_excess_result[[2]] 
      #             data_bank <- remove_index( data_bank, exec_key, excess_indices_removed)
      #             if(collab %in% filtered_collabs$EMP){
      #             colab_data_bank[colab_data_bank$EMP == collab, "SLOTS_MISSING"] <- colab_data_bank[colab_data_bank$EMP == collab, "SLOTS_MISSING"] +excess_indices_removed
      #             filtered_collabs[filtered_collabs$EMP == collab, "SLOTS_MISSING"] <- filtered_collabs[filtered_collabs$EMP == collab, "SLOTS_MISSING"] +excess_indices_removed
      #             collabs_with_excess_hours[collabs_with_excess_hours$EMP == collab, "SLOTS_MISSING"] <- collabs_with_excess_hours[collabs_with_excess_hours$EMP == collab, "SLOTS_MISSING"] +excess_indices_removed
      #             }else{ 
      #               colab_data_bank[colab_data_bank$EMP == collab, "SLOTS_MISSING"] <- colab_data_bank[colab_data_bank$EMP == collab, "SLOTS_MISSING"] +excess_indices_removed
      #               new_row <- colab_data_bank[colab_data_bank$EMP == collab,]
      #               filtered_collabs <- rbind(filtered_collabs, new_row)
      #               collabs_with_excess_hours <- rbind(collabs_with_excess_hours, new_row)
      #               
      #             }
      #             new_schedules[[exec_day]] <- new_schedule_matrix 
      #             new_schedule <- replace_schedule_index(collab, new_schedule,index,1)
      #             print("Covered 0 with removing excess ")
      #             stringlog <- (paste0("Filled Zero at: ", schedule_for_zero_day[index,]$timestamps, " with collaborator ", collab, "for day: ", day))
      #             write.table(stringlog, log_file_name, append = TRUE, row.names = FALSE, col.names = FALSE)
      #             
      #             colab_data_bank[colab_data_bank$EMP == collab, "SLOTS_MISSING"] <- colab_data_bank[colab_data_bank$EMP == collab, "SLOTS_MISSING"] -1
      #             filtered_collabs[filtered_collabs$EMP == collab, "SLOTS_MISSING"] <- filtered_collabs[filtered_collabs$EMP == collab, "SLOTS_MISSING"] - 1
      #             collabs_with_excess_hours[collabs_with_excess_hours$EMP == collab, "SLOTS_MISSING"] <- collabs_with_excess_hours[collabs_with_excess_hours$EMP == collab, "SLOTS_MISSING"] - 1
      #             #readLines(con = stdin(), n = 1)
      #               print("Filled zeros")
      #               new_schedules[[day]] <- new_schedule 
      #               data_bank[[key]] <- NULL 
      #               next
      #             
      #           
      #         
      #         }else{
      #           given = FALSE
      #           next
      #      #     print("Banger")
      #         }
      #       }
      #     #  print(paste0("Given is: ",given))
      #       if(given == TRUE) break
      #     }
      #     
      #     #Partial fit
      #     if(!foundCollab){
      #       stringlog <- (paste0("Didn't fill zero at: ", schedule_for_zero_day[index,]$timestamps,  "for day: ", day))
      #       write.table(stringlog, log_file_name, append = TRUE, row.names = FALSE, col.names = FALSE)
      #     }
      # }
      # }
      print("passed here")
      if(given == TRUE){
        print("Filled zeros")
        new_schedules[[day]] <- new_schedule 
        data_bank[[key]] <- NULL 
        next
      }
    }
    
  }
  
  saveResult <<- collabs_with_excess_hours
  
  collabs_above_max <-  collabs_with_excess_hours  %>%
    filter(abs(SLOTS_MISSING) > abs(DIVERGENCE_LACK)) %>%
    arrange(desc(abs(SLOTS_MISSING)))
  
  for(row in 1:nrow(collabs_above_max)){
    collab_row <- collabs_above_max[row,]
    print(collab_row)
    for(i in 1:abs(collab_row$SLOTS_MISSING)){
      exec_key <- find_collab_exec(data_bank, collab_row$EMP)
      collab <- collab_row$EMP
      if(length(exec_key) >=1){
        exec_day <- gsub('^EXEC-', '', exec_key)
        schedule_without_excess_result <- remove_target_excess(exec_key, collab, collabs_above_max, data_bank, new_schedules, faixas_diarias, log_file_name)
        while(length(schedule_without_excess_result) == 1){
          data_bank[[exec_key]]$collaborators <- data_bank[[exec_key]]$collaborators[data_bank[[exec_key]]$collaborators != collab]
          exec_key <- find_collab_exec(data_bank, collab_row$EMP)
          if(is.null(exec_key )){
            print("Cannot remove excess for collab")
            #readLines(con = stdin(), n = 1)
            given = FALSE
            break
            
          }
          exec_day <- gsub('^EXEC-', '', exec_key)
          schedule_without_excess_result <- remove_target_excess(exec_key, collab, colab_data_bank, data_bank, horariosDados, faixas_diarias, log_file_name)
          
        }
        if(length(schedule_without_excess_result) == 1) next
        new_schedule_matrix <- schedule_without_excess_result[[1]]
        
        excess_indices_removed <- schedule_without_excess_result[[2]] 
        data_bank <- remove_index( data_bank, exec_key, excess_indices_removed)
        data_bank[[exec_key]]$collaborators <- data_bank[[exec_key]]$collaborators[data_bank[[exec_key]]$collaborators != collab]
        if(collab %in% collabs_above_max$EMP){
          collabs_above_max[collabs_above_max$EMP == collab, "SLOTS_MISSING"] <- collabs_above_max[collabs_above_max$EMP == collab, "SLOTS_MISSING"] +length(excess_indices_removed)
          collabs_with_excess_hours[collabs_with_excess_hours$EMP == collab, "SLOTS_MISSING"] <- collabs_with_excess_hours[collabs_with_excess_hours$EMP == collab, "SLOTS_MISSING"] +length(excess_indices_removed)
        }
        new_schedules[[exec_day]] <- new_schedule_matrix 
      }
    }
  }
  
  print(length(data_bank))
  return(list(new_schedules,data_bank, colab_data_bank))
}

build_data_bank <- function(horariosDados,faixas_diarias,days_given){
  data_bank <- NULL
  
  for(day in days_given){
    print(day)
    days_schedule <- horariosDados[[day]]
    faixa_diaria <- faixas_diarias[[day]]
    faixa_diaria <- faixa_diaria[faixa_diaria$tipo_hor != 'F',]
    faixa_diaria <- faixa_diaria[faixa_diaria$day_type != 'P',]
    if(nrow(faixa_diaria) == 0) next
    days_schedule <- trim_schedule(days_schedule, day)
    Theres_flaws <- ifelse(length(which(days_schedule$Minimo > 0  & days_schedule$Alocado == 0)) > 0 , TRUE, FALSE )
    Theres_mins_to_cover <- ifelse(length(which(days_schedule$Minimo_Por_cobrir > 0 )) > 0 , TRUE, FALSE )
    Theres_ideais_to_cover <- ifelse(length(which(days_schedule$Ideal_por_Cobrir > 0 )) > 0 , TRUE, FALSE )
    Theres_excess <- ifelse(length(which(days_schedule$Ideal_por_Cobrir < 0 )) > 0 , TRUE, FALSE )
    schedule_map <- build_schedule_map(faixa_diaria, days_schedule,day,horariosDados)
    
    if(Theres_excess){
      flaws_indices <- which(days_schedule$Ideal_por_Cobrir < 0 )
      entry <- list(
        length = length(flaws_indices),
        indices = unlist(flaws_indices),
        day = day,  
        collaborators = unique(names(schedule_map[sapply(schedule_map, function(x) any(x %in% flaws_indices))]))
      )
      
      title <- paste("EXEC-", day, sep = "")
      
      data_bank[[title]] <- entry
      
    }
    
    if (Theres_flaws) {
      flaws_indices <- which(days_schedule$Minimo > 0 & days_schedule$Alocado == 0 & 
                               rowSums(days_schedule[, -(1:6), drop = FALSE] == 'P', na.rm = TRUE) == 0)
      flat_schedule <- unlist(schedule_map)
      index_counts <- table(flat_schedule)
      
      if (length(flaws_indices) > 0) {
        # Function to collapse consecutive numbers into ranges
        
        # Get collapsed indices
        collapsed_indices <- collapse_ranges(flaws_indices)
        
        entry <- list(
          length = length(flaws_indices),
          indices = collapsed_indices,
          day = day,  
          collaborators = unique(names(schedule_map[sapply(schedule_map, function(x) any(x %in% flaws_indices))]))
        )
        
        title <- paste("ZERO-", day, sep = "")
        data_bank[[title]] <- entry
      }
    }
    
  }
  return(data_bank)
}

# faixa_diaria <- faixas_for_day
# days_schedule <- schedule_for_zero_day

build_schedule_map <- function(faixa_diaria, days_schedule,day,new_schedules){
  days_schedule <- trim_schedule(days_schedule, day)
  indices_list <- list()
  for (j in 1:nrow(faixa_diaria)) {
    ifelse(faixa_diaria$day_type[j] == 'M', limiter_slot <- get_morning_limiter_slot(faixa_diaria$EMP[j], matriz_colaborador, days_schedule), limiter_slot <- get_tarde_limiter_slot(faixa_diaria$EMP[j], matriz_colaborador, days_schedule))
    emp_indices <- which(days_schedule$timestamps >= faixa_diaria$hora_in[j] & days_schedule$timestamps <= faixa_diaria$hora_out[j])
    ifelse(faixa_diaria$IJ_in[j] == FALSE && faixa_diaria$tipo_hor[j] == 'R',start_index <- max(1, emp_indices[1] - 4),start_index <- emp_indices[1])
    ifelse(faixa_diaria$IJ_out[j] == FALSE && faixa_diaria$tipo_hor[j] == 'R',emp_indices <- c(start_index:(emp_indices[length(emp_indices)] + 4)),emp_indices <-c(start_index:(emp_indices[length(emp_indices)])))
    emp_indices <- emp_indices[emp_indices <= nrow(days_schedule)]
    ifelse(faixa_diaria$day_type[j] == 'M',emp_indices <- emp_indices[emp_indices < limiter_slot],emp_indices <- emp_indices[emp_indices >= limiter_slot] )
    
    #validar interjornada
    selectCCday <- faixa_diaria[j,]
    selectCCday$hora_in <- days_schedule$timestamps[emp_indices[1]]
    selectCCday$hora_out <- days_schedule$timestamps[emp_indices[length(emp_indices)]]
    selectCCday <- checkInterjornadaPostProc(selectCCday, day, interjornadas,new_schedules)
    selectCCday$hora_out <-  selectCCday$hora_out - as.difftime(15, units = "mins")
    emp_indices <- c(which(days_schedule$timestamps == selectCCday$hora_in):which(days_schedule$timestamps == selectCCday$hora_out))
    indices_list[[faixa_diaria$EMP[j]]] <- emp_indices
  }
  return(indices_list)
}

find_collab_zero <- function(df_list, collab_id){
  result <- NULL
  zero_list  <- grep('^ZERO-', names(df_list), value = TRUE)
  
  for (key in zero_list) {
    collaborators <- df_list[[key]]$collaborators
    if (collab_id %in% collaborators) {
      result <- key
      break
    }
  }
  return(result)
}

find_collab_exec <- function(df_list, collab_id){
  result <- NULL
  exec_list  <- grep('^EXEC-', names(df_list), value = TRUE)
  
  for (key in exec_list) {
    collaborators <- df_list[[key]]$collaborators
    if (collab_id %in% collaborators) {
      result <- key
      break
    }
  }
  return(result)
}

get_hour_percent <- function(collab_id, slots_missing){
  slots_year <-(sum(collaborator_tibbles[[collab_id]]$hours_given)+ collaborator_tibbles[[collab_id]]$horas_goal[1])*4
  ifelse(slots_missing <= 0, return(0), return(slots_missing/slots_year  * 100))
}

replace_schedule_index <- function(collab, day_schedule,i,value){
  colname <- paste0('EMPloyee_',collab)
  if(value >= 1){value = 1}else if(value <= -1){value = -1}else{return(day_schedule)}
  day_schedule[i, colname] <- as.integer(day_schedule[i, colname]) + value
  day_schedule[i, 'Alocado'] <- day_schedule[i, 'Alocado'] + value
  day_schedule[i, 'Minimo_Por_cobrir'] <- day_schedule[i, 'Minimo_Por_cobrir'] - value
  day_schedule[i, 'Ideal_por_Cobrir'] <- day_schedule[i, 'Ideal_por_Cobrir'] - value
  return(day_schedule)
}

remove_target_excess <- function(exec_key, collab, colab_data_bank, data_bank, horariosDados, faixas_diarias, log_file_name){
  day <- gsub('^EXEC-', '', exec_key)
  print("Removing target exec")
  print(day)
  schedule_for_zero_day <- horariosDados[[day]]
  schedule_for_zero_day <- trim_schedule(schedule_for_zero_day,day)
  faixas_for_day <- faixas_diarias[[day]] 
  faixas_for_day <- faixas_for_day[faixas_for_day$tipo_hor != 'F',]
  if(nrow(faixas_for_day) == 0) reutnr(FALSE)
  schedule_map <- build_schedule_map(faixas_for_day,schedule_for_zero_day,day,horariosDados)
  collab_row <- colab_data_bank[colab_data_bank$EMP == collab, ]
  schedule_map <- schedule_map[collab]
  slots_missing_value <- collab_row$SLOTS_MISSING
  zero_indices <- data_bank[[exec_key]]$indices
  colname <- paste0('EMPloyee_',collab)
  
  index_count <- 0
  
  exec_index_in_schedule <- exec_index_to_remove(schedule_for_zero_day, colname)
  if(is_empty(exec_index_in_schedule)) return(FALSE)
  for(index in exec_index_in_schedule){
    new_Schedule <- replace_schedule_index(collab, schedule_for_zero_day,index,-1)
    stringlog <- (paste0("Removed Excess at: ", schedule_for_zero_day[index,]$timestamps, " with collaborator ", collab, " for day ", day))
    # write.table(stringlog, log_file_name, append = TRUE, row.names = FALSE, col.names = FALSE)
    
    index_count <- index_count + 1
  }
  return_value <- list(new_Schedule, exec_index_in_schedule)
  saveWtf2 <<- return_value
  
  return(return_value)
}

trim_schedule <- function(schedule,day){
  opening_timestamps <- getOpening(day)
  closing_timestamps <- getClosing(day)
  
  store_open_hours <- seq.POSIXt(from = opening_timestamps, 
                                 to = closing_timestamps,
                                 by = paste0(gran," min"))
  schedule <- schedule %>%  filter(timestamps %in% store_open_hours)
  return(schedule)
}

exec_index_to_remove <- function(dataframe, colname){
  indices <- which(dataframe[[colname]] == 1)
  indices_exec <- which(dataframe[['Ideal_por_Cobrir']] < 0)
  indices_that_can_be_removed <- intersect(indices_exec, indices)
  
  indices_to_remove <- list()
  
  indices_that_can_be_removed <- sort(indices_that_can_be_removed)
  
  for (n in seq(length(indices_that_can_be_removed), 1)) {
    if (length(indices) - n >= 22) {
      if (any(tail(indices, n) %in% indices_that_can_be_removed)) {
        consecutive <- TRUE
        # Initialize the first index to compare
        
        prev_index <- tail(indices_that_can_be_removed, n)[1]
        if (length(tail(indices_that_can_be_removed, n)) > 1) {
          for (i in 2:n) {
            savethissss <<- tail(indices_that_can_be_removed, n)[i] 
            savethissss2 <<- prev_index
            if (any(tail(indices_that_can_be_removed, n)[i] - prev_index != 1)) {
              print(tail(indices_that_can_be_removed, n)[i])
              consecutive <- FALSE
              break
            }
            prev_index <- tail(indices_that_can_be_removed, i)
          }
        }
        if (consecutive) {
          indices_to_remove <- tail(indices_that_can_be_removed, n)
          break
        } else {
          next
        }
      }
    } else {
      next
    }
  }
  
  return(indices_to_remove)
}

get_slot_parameters <- function(table, collab_id){
  EMP <- table$EMP[1]
  HOURS_MISSING <- table$horas_goal[1]
  SLOTS_MISSING <- HOURS_MISSING*4
  HOURS_YEAR <- (sum(collaborator_tibbles[[collab_id]]$hours_given)+ collaborator_tibbles[[collab_id]]$horas_goal[1])
  SLOTS_YEAR <-HOURS_YEAR*4
  DIVERGENCE_LACK <- SLOTS_YEAR*0.01
  CURRENT_PERCENT <- (SLOTS_MISSING/SLOTS_YEAR) * 100
  df <- data.frame(EMP = EMP,HOURS_MISSING = HOURS_MISSING, SLOTS_MISSING = SLOTS_MISSING,HOURS_YEAR = HOURS_YEAR, SLOTS_YEAR = SLOTS_YEAR, DIVERGENCE_LACK = DIVERGENCE_LACK, CURRENT_PERCENT = CURRENT_PERCENT)
  return(df)
}

collab_day_working_slots <- function(collab, day, schedule_for_zero_day){
  col_name <- paste0("EMPloyee_",collab)
  return(sum(schedule_for_zero_day[[col_name]]))
}

get_slot_max <- function(collab, matriz_colaborador){
  return(matriz_colaborador[matriz_colaborador$EMP == collab,]$HORAS_TRAB_DIA_CARGA_MAX*4)
}

get_schedule_start <- function(collab, schedule_for_zero_day){
  col_name <- paste0("EMPloyee_",collab)
  return(min(which(schedule_for_zero_day[[col_name]] == 1)))
}

get_schedule_end <- function(collab, schedule_for_zero_day){
  col_name <- paste0("EMPloyee_",collab)
  return(max(which(schedule_for_zero_day[[col_name]] == 1)))
}

pad_indices <- function(collab, temp_dict, schedule){
  schedule_end <- get_schedule_end(collab = collab, schedule_for_zero_day = schedule)
  schedule_start <- get_schedule_start(collab = collab, schedule_for_zero_day = schedule)
  if(head(temp_dict$indices,1) > schedule_end){
    diff <- abs(head(temp_dict$indices,1) - schedule_end)
    if(diff > 1){
      new_indices <- (schedule_end+1):tail(temp_dict$indices,1)
      temp_dict$indices <- new_indices
      temp_dict$length <- length(new_indices)
    }
  }else if(tail(temp_dict$indices,1) < schedule_start){
    diff <- abs(tail(temp_dict$indices,1) - schedule_start)
    if(diff > 1){
      new_indices <- head(temp_dict$indices,1):(schedule_start-1)
      temp_dict$indices <- new_indices
      temp_dict$length <- length(new_indices)
    }
  }
  return(temp_dict)
}

remove_index <- function(zero_data, date, index_to_remove) {
  # Split the range to get individual indices
  if(grepl(":", zero_data[[date]]$indices)){
    indices <- unlist(strsplit(zero_data[[date]]$indices, ":"))
    indices <- as.numeric(indices)
  }
  else{
    indices <- as.numeric(zero_data[[date]]$indices)
  }
  # Convert index_to_remove to numeric
  index_to_remove <- as.numeric(index_to_remove)
  
  # Check if the index_to_remove is within the range
  if (index_to_remove %in% indices) {
    # Remove the index
    indices <- indices[indices != index_to_remove]
    
    # Update the indices in the data structure
    zero_data[[date]]$indices <- collapse_ranges(indices)
    zero_data[[date]]$length <- zero_data[[date]]$length -1
  } else {
    print("Index not found in the range.")
  }
  if(length(indices) < 1) zero_data[[date]] <- NULL
  return(zero_data)
}

collapse_ranges <- function(x) {
  ranges <- split(x, cumsum(c(1, diff(x) != 1)))
  formatted_ranges <- sapply(ranges, function(y) {
    if (length(y) > 1) {
      paste0(y[1], ":", y[length(y)])
    } else {
      as.character(y)
    }
  })
  paste0(formatted_ranges, collapse = " ")
}

get_morning_limiter_slot <- function(collab, matriz_colaborador, schedule){
  return(which(schedule$timestamps == as.POSIXct(paste('2000-01-01',matriz_colaborador[matriz_colaborador$EMP == collab,]$LIMITE_SUPERIOR_MANHA, format = '%H:%M'))))
}

get_tarde_limiter_slot <- function(collab, matriz_colaborador, schedule){
  return(which(schedule$timestamps == as.POSIXct(paste('2000-01-01',matriz_colaborador[matriz_colaborador$EMP == collab,]$LIMITE_INFERIOR_TARDE, format = '%H:%M'))))
}


#---------------------------------- PAUSAS------------------------------------
# list_df <- M_dia4_finalas
resolve_implicacoes_pausas<- function(list_df, matriz_colaborador){
  
  #Cycle through days and give pausas for those days
  for(day in names(list_df)){
    day_df <- list_df[[day]]
    print(paste0("Atribuindo pausas para dia: ", day))
    employeeNames <- matriz_colaborador$EMP
    for(colab in employeeNames){ #:nrow(dfEMPloyee)
      col_name <- paste0("EMPloyee_",colab)
      if(col_name %in% colnames(day_df)){
        col <- day_df %>%  select(timestamps, Alocado,Ideal_por_Cobrir, Minimo_Por_cobrir ,col_name)
        
        # Find the positions of 1s
        ones_position <- which(col[[col_name]] == 1)
        # Calculate the differences between consecutive 1 positions
        gaps <- diff(ones_position) - 1
        # Count the number of zeros between 1s
        zeros_between_ones <- sum(gaps)
        pause_index <- NULL
        if (zeros_between_ones  == 0) {
          pause_index <- atribuirPausas(col,matriz_colaborador,day_df)
          if(!is.null(pause_index)){
            for(index in pause_index){
              day_df[index, col_name] <- 'P' 
              day_df[index, 'Ideal_por_Cobrir'] <- day_df[index, 'Ideal_por_Cobrir'] + 1
              day_df[index, 'Minimo_Por_cobrir'] <- day_df[index, 'Minimo_Por_cobrir'] + 1
              day_df[index, 'Alocado'] <- day_df[index, 'Alocado'] - 1
            }
          }
        } else{
          print("partido --> sem pausa p/ atribuir")
          # gap_positions <- which(gaps > 0)
          # 
          # greatest_seq <- if(length(ones_position[1:gap_positions])>length(ones_position[(gap_positions+1):length(ones_position)])){
          #   ones_position[1:gap_positions]
          # } else{ ones_position[(gap_positions+1):length(ones_position)]}
          # 
          # # Change the alocado column to 0 where indices are greater than max_greatest_seq_index
          # day_df_partido <- col
          # day_df_partido[(max(greatest_seq) + 1):nrow(day_df_partido), col_name] <- 0
          # pause_index2 <- atribuirPausas(day_df_partido,matriz_colaborador,day_df)
        }
        
      }
    }
    list_df[[day]] <- day_df 
    
  }
  return(list_df)
}

gerar_polivalencias <- function(df_list, rules){
  #polivalencias nao veem em codigos
  mapa_postos <- list(
    'INFORMATION' = 160,
    'SED Y GLOBO' = 251,
    0
  )
  order <- c(251,160,21231)
  print(paste0('Posto gerado:', posto))
  posto <- as.character(posto)
  rule <- rules[[posto]]
  if(rule == 'FechoPrematuro'){
    # Initialize an empty list to store new schedules
    new_schedule_to_df <- list()
    
    # Loop through each day in the dataframe list
    for(day in names(df_list)){
      closing_time <- getClosingIdeais(day)
      print(paste0("For day:", day, " it closed at: ",closing_time))
      collab_after_list <- GetCollabAfterHours(df_list[[day]],closing_time )
      print(paste0("For day: ", day, " the collabs working after hours are: ", collab_after_list))
      
      # Check if there are collaborators working after hours
      if(length(collab_after_list) > 0){
        for(collab in collab_after_list){
          collab_leaves <- df_list[[day]][get_schedule_end(collab, df_list[[day]]),]$timestamp
          collab_target_poli <- mapa_postos[[getPolivalenciaDestino(matriz_colaborador, collab)]]
          # Create a new row for each collaborator and add it to the list
          new_row <- data.frame(date = day,
                                collab_id = collab,
                                start_time = closing_time,
                                end_time = collab_leaves,
                                posto_destino = collab_target_poli)
          new_schedule_to_df[[length(new_schedule_to_df) + 1]] <- new_row
        }
      }
    }
    
    # Combine all rows into a single data frame
    new_schedule_df <- do.call(rbind, new_schedule_to_df)
    
    return(new_schedule_df)
  }
}



GetCollabAfterHours <- function(data, closing_time) {
  employee_codes <- character(0)
  employee_columns <- grep("^EMPloyee_", colnames(data), value = TRUE)
  
  for (col in employee_columns) {
    working_indices <- which(data[['timestamps']] > closing_time & data[[col]] > 0)
    if (length(working_indices) > 0) {
      employee_codes <- c(employee_codes, sub("EMPloyee_", "", col))
    }
  }
  
  return(employee_codes)
}

getPolivalenciaDestino <-function(matriz_colaborador, collab){
  return(matriz_colaborador %>%  filter(EMP == collab) %>%  pull(POLIVALENCIA_1))
}


saveData <- function(path){
  pathOS <- getwd()
  sis <- Sys.info()[[1]]
  queryColaborator <- paste(readLines(paste0(pathOS,"/data/querys/read_colab.sql")))
  
  # Retrieve system information, declare conf filename and set the connection to database
  
  confFileName <- '/conf/CONFIGURATIONS.csv'
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  colabData <- tryCatch({
    data.frame(dbGetQuery(wfm_con,queryColaborator))
  }, error = function(e) {
    #escrever para tabela de log erro de coneccao
    err <- as.character(gsub('[\"\']', '', e))
    print("erro")
    #dbDisconnect(connection)
    print(err)
    data.frame()
  })
  timestamp <- format(Sys.time(), "%Y%m%d%H%M%S")
  csvFileName <- paste0("database_colaborator_", timestamp, ".csv")
  # write.csv(colabData, file = csvFileName, row.names = FALSE)
}


# Gethorario -------------------------------------------------------------------
checkInterjornadaPostProc <- function(horario, date, interjornadas,new_schedules) {
  saveHOR <<- horario #<- saveHOR
  saveDate <<- date #<- saveDate
  saveInter <<- interjornadas #<- saveInter
  emp_id <- horario$EMP
  collumn_name <- paste0("EMPloyee_",emp_id)
  current_day <- ymd(date)
  previous_day <- M_dia1_final[[as.character(current_day - days(1))]] 
  next_day <- M_dia1_final[[as.character(current_day + days(1))]] 
  
  if(!is.null(previous_day)){
    previous_day <- previous_day %>% dplyr::filter(EMP==emp_id, Allocated==T)
    if(nrow(previous_day)>0){
      print(collumn_name)
      interjornada <- interjornadas[weekdays(as.POSIXct(current_day - days(1)))]
      previous_matrix <- new_schedules[[as.character(current_day - days(1))]][,collumn_name]
      leaving_index <- max(which(previous_matrix == '1'))
      leaving_timestamp <- new_schedules[[as.character(current_day - days(1))]][leaving_index,'timestamps']+ as.difftime(15, units = 'mins')
      print("Previous day he left at:")
      print(leaving_timestamp)
      saveLeave <<- leaving_timestamp #<- saveLeave
      
      leaving_timestamp <- as.POSIXct(paste(
        if_else(leaving_timestamp>='2000-01-02',
                current_day,
                current_day - days(1)), 
        ' ', format(leaving_timestamp, '%H:%M:%S'), sep = ''), tz = 'GMT')
      horaINI_prev <- (leaving_timestamp + hours(interjornada))
      horaINI_horario <- as.POSIXct(paste(as.character(if_else(horario$hora_in >= '2000-01-02',current_day+1,current_day)),
                                          ' ',format(horario$hora_in, '%H:%M:%S'), sep = ''), tz = 'GMT')
      print(horaINI_horario)
      print(horaINI_prev)
      if (horaINI_prev > horaINI_horario) {
        horaINI <- horaINI_prev#format(horaINI_prev, '%H:%M')
        horario$hora_in <- if_else(horaINI<as.POSIXct(paste(format(horaINI,'%Y-%m-%d'),format(getOpening(date),"%H:%M:%S")),tz='GMT'),
                                   as.POSIXct(paste('2000-01-02',format(horaINI,'%H:%M:%S')),tz='GMT'),
                                   as.POSIXct(paste('2000-01-01',format(horaINI,'%H:%M:%S')),tz='GMT'))
        print("Changed here to new hour")
        print(horaINI)
        horario$IJ_in <- TRUE
      }
    }
  }
  if(!is.null(next_day)){
    next_day <- next_day %>% dplyr::filter(EMP==emp_id, Allocated==T)
    if(nrow(next_day)>0){
      print(collumn_name)
      interjornada <- interjornadas[weekdays(as.POSIXct(current_day))]
      next_matrix <- new_schedules[[as.character(current_day + days(1))]][,collumn_name]
      entering_index<- min(which(next_matrix == '1'))
      entering_timestamp <- new_schedules[[as.character(current_day + days(1))]][entering_index,'timestamps']
      print("Next day he entered at:")
      print(entering_timestamp)
      saveEnter <<- entering_timestamp
      entering_timestamp <- as.POSIXct(paste(if_else(entering_timestamp>='2000-01-02',current_day + days(2),current_day + days(1)), 
                                             ' ', format(entering_timestamp, '%H:%M:%S'), sep = ''), tz = 'GMT')
      horaOUT_next <- (entering_timestamp - hours(interjornada))
      horaOUT_horario <- as.POSIXct(paste(as.character(if_else(horario$hora_out>='2000-01-02',current_day+1,current_day))
                                          , ' ',format(horario$hora_out,'%H:%M:%S'), sep = ''), tz = 'GMT')
      print(horaOUT_horario)
      print(horaOUT_next)
      # horaOUT <- format((entering_timestamp - hours(interjornada)), '%H:%M')
      if (horaOUT_next < horaOUT_horario ) {
        horaOUT <- horaOUT_next#format(horaOUT_next, '%H:%M')
        horario$hora_out <- if_else(horaOUT<as.POSIXct(paste(format(horaOUT,'%Y-%m-%d'),format(getOpening(date),"%H:%M:%S")),tz='GMT'),
                                    as.POSIXct(paste('2000-01-02',format(horaOUT,'%H:%M:%S')),tz='GMT'),
                                    as.POSIXct(paste('2000-01-01',format(horaOUT,'%H:%M:%S')),tz='GMT'))
        
        print("Changed here to new hour")
        print(horaOUT)
        horario$IJ_out <- TRUE
      }
    }
  }
  
  return(horario)}
