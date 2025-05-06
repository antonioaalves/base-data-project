pad_zeros <- function(x,nr=7) {
  x <- str_pad(x, width = nr, side = "left", pad = "0")
  return(x)
}

IsDate <- function(mydate, date.format = "%d/%m/%Y") {
  tryCatch(!is.na(as.Date(mydate, date.format)),  
           error = function(err) {FALSE})  
}

# df <- matriz2_antes_data
convert_types_in <- function(df){
  
  df <- df %>% 
    dplyr::mutate(
      SCHED_SUBTYPE = case_when(
        TYPE == 'T' & SUBTYPE == 'M' ~ 'M',
        TYPE == 'T' & SUBTYPE == 'T' ~ 'T',
        TYPE == 'T' & SUBTYPE == 'H' ~ 'MoT',
        TYPE == 'T' & SUBTYPE == 'P' ~ 'P',
        TYPE == 'T' & SUBTYPE == 'C' ~ 'MoT',
        TYPE == 'F' & is.na(SUBTYPE) ~ 'L',
        TYPE == 'F' & SUBTYPE == 'D' ~ 'LD',
        TYPE == 'F' & SUBTYPE == 'Q' ~ 'LQ',
        
        TYPE == 'F' & SUBTYPE == 'C' ~ 'C',
        TYPE == 'R' & is.na(SUBTYPE) ~ 'F',
        TYPE == 'N' & is.na(SUBTYPE) ~ '-',
        TYPE == 'T' & SUBTYPE == 'A' ~ 'V'
      ),
      IND ='P'
    ) %>% 
    dplyr::rename(SCHEDULE_DT = SCHEDULE_DAY)
  
  return(df)
}


convert_types_out <- function(df){
  
  df <- df %>% 
    dplyr::mutate(
      SCHED_TYPE = case_when(
        HORARIO == 'M' ~ 'T',
        HORARIO == 'T' ~ 'T',
        HORARIO == 'MoT' ~ 'T',
        HORARIO == 'ToM' ~ 'T',
        HORARIO == 'P' ~ 'T',
        
        HORARIO == 'L' ~ 'F',
        HORARIO == 'LD' ~ 'F',
        HORARIO == 'LQ' ~ 'F',
        HORARIO == 'C' ~ 'F',
        
        HORARIO == 'F' ~ 'R',
        HORARIO == '-' ~ 'N',
        
        HORARIO == 'V' ~ 'T',
        HORARIO == 'A' ~ 'T',
        HORARIO == 'DFS' ~ 'T'
      ),
      SCHED_SUBTYPE = case_when(
        HORARIO == 'M' ~ 'M',
        HORARIO == 'T' ~ 'T',
        HORARIO == 'MoT' ~ 'H',
        HORARIO == 'ToM' ~ 'H',
        HORARIO == 'P' ~ 'P',
        
        HORARIO == 'L' ~ '',
        HORARIO == 'LD' ~ 'D',
        HORARIO == 'LQ' ~ 'Q',
        HORARIO == 'C' ~ 'C',
        
        HORARIO == 'F' ~ '',
        HORARIO == '-' ~ '',
        
        HORARIO == 'V' ~ 'A',
        HORARIO == 'A' ~ 'A',
        HORARIO == 'DFS' ~ 'C'
      )
    ) 
  
  return(df)
}

# df <- df_pre_ger
countSetDaysOff <- function(df){
  df <- df %>% 
    dplyr::mutate(WD = wday(SCHEDULE_DT)) %>% 
    dplyr::arrange(EMPLOYEE_ID, SCHEDULE_DT) %>% 
    dplyr::group_by(EMPLOYEE_ID) %>% 
    dplyr::summarise(DyF_MAX_T_at = sum(WD==1 & SCHED_SUBTYPE=='L'),
                     Q_at = sum(SCHED_SUBTYPE=='LQ'),
                     C2D_at = sum((SCHED_SUBTYPE=='C' & lead(SCHED_SUBTYPE)=='L' & lead(WD)==1) | 
                                 (SCHED_SUBTYPE=='C' & lag(SCHED_SUBTYPE)=='L') & lag(WD)==1),
                     C3D_at = sum( (lag(SCHED_SUBTYPE)=='C' & SCHED_SUBTYPE=='C' & lead(SCHED_SUBTYPE)=='L') |
                                  (lag(SCHED_SUBTYPE,2)=='C' & lag(SCHED_SUBTYPE)=='L' & SCHED_SUBTYPE=='C')),
                     CXX_at = sum((SCHED_SUBTYPE=='C' & WD %in% c(3,4,5)) |
                                    (SCHED_SUBTYPE=='C' & lag(SCHED_SUBTYPE)!='L'& WD %in% c(2)) |
                                    (SCHED_SUBTYPE=='C' & lead(SCHED_SUBTYPE,2)!='L'& WD %in% c(6)) |
                                  (SCHED_SUBTYPE=='C' & lag(SCHED_SUBTYPE)!='L'& WD %in% c(7)) 
                                  ),
                     LQ_at = sum(SCHED_SUBTYPE=='LQ'),
                     LD_at = sum(SCHED_SUBTYPE=='LD'),
                     .groups='drop') %>% data.frame()
  
  return(df)
}



count_days_in_week <- function(date) {
  # Ensure the date is a Date object
  date <- as.Date(date)
  
  # If the date is a Sunday, move to the previous Monday
  if (wday(date) == 1) {
    start_of_week <- date - 6
  } else {
    # Otherwise, find the Monday of the given week
    start_of_week <- date - wday(date) + 2
  }
  # Find the Sunday of the given week
  end_of_week <- start_of_week + 6
  
  # Generate a sequence of dates from Monday to Sunday
  week_days <- seq(start_of_week, end_of_week, by = "day")
  
  # Count the number of days
  num_days <- length(week_days[week_days>=date])
  
  return(num_days)
}


# holidays_df <- fer
# contrato <- cc$TIPO_CONTRATO
# Function to count open holidays in a week from Monday to Thursday
count_open_holidays <- function(holidays_df, contrato) {
  # Ensure the DATA column is in Date format
  holidays_df$DATA <- as.Date(holidays_df$DATA)
  
  if (contrato==3) {
    # Filter holidays that are open (TIPO = 2) and fall from Monday to Thursday
    open_holidays <- holidays_df %>%
      dplyr::filter(TIPO == 2) %>%
      dplyr::filter(wday(DATA) %in% 2:5)  # Monday is 2, Tuesday is 3, Wednesday is 4, Thursday is 5
    
    nrDom <- sum(table(sort(week(open_holidays$DATA)))>1)
  }
  
  if (contrato==2) {
    # Filter holidays that are open (TIPO = 2) and fall from Monday to Thursday
    open_holidays <- holidays_df %>%
      dplyr::filter(TIPO == 2) %>%
      dplyr::filter(wday(DATA) %in% 2:6)  # Monday is 2, Tuesday is 3, Wednesday is 4, Thursday is 5
    
    nrDom <- sum(table(sort(isoweek(holidays_df[holidays_df$TIPO==2,]$DATA)))>1)
  }
  
  
  # Count the number of open holidays
  num_open_holidays <- nrow(open_holidays)
  
  return(list(nrDom,num_open_holidays))
}

# # Example usage
# count_open_holidays(fer,3)
# count_open_holidays(fer,2)


collapseFunc <- function(df){
  df <- df %>%
    dplyr::filter(TIPO_TURNO!=0) %>% 
    dplyr::group_by(COLABORADOR,DATA,WDAY,HORARIO,DIA_TIPO) %>%
    dplyr::summarise(TIPO_TURNO = 
                       case_when(
                         length(unique(TIPO_TURNO)) == 1 ~ unique(TIPO_TURNO),
                         TRUE ~ paste(unique(TIPO_TURNO), collapse = "o"),
                       ), .groups='drop'
    ) %>% ungroup()
  return(df)
}

#df <- trabDom
expandFunc <- function(df){
  df <- as.data.table(df)
  # Create a sequence of all dates in the range
  full_date_range <- unique(df$DATA) #seq(min(df$DATA), max(df$DATA), by = "day")
  
  # Expand the data frame to include all dates
  df_expanded <- df %>%
    complete(COLABORADOR, DATA = full_date_range) %>% # Create rows for all dates
    fill(TIPO_TURNO, .direction = "down")            # Fill missing TIPO_TURNO values with the previous one
  
  # Separate the TIPO_TURNO by 'o' and expand into multiple rows
  df_separated <- df_expanded %>%
    separate_rows(TIPO_TURNO, sep = "o") %>% # Separate by 'o' and create new rows
    filter(TIPO_TURNO != "") # Remove empty rows created by separation
  return(df_separated)
}

getInfoRemove <- function(wday_matrix, matricula_list){
  # wday_matrix <- matriz2
  # matricula_list <- matrizA$MATRICULA
  pathOS <- pathFicheirosGlobal
  source(paste0(pathOS,"connection/dbconn.R"))
  
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  query <- 'select EMP, DOFHC, HMINTC from wfm.core_algorithm_variables
where 1=1'
  emp_condition <- paste0("EMP IN ('", paste(matricula_list, collapse = "', '"), "')")
  updated_query <- gsub("1=1", emp_condition, query)
  dfData <- tryCatch({
    
    data.frame(dbGetQuery(wfm_con,updated_query))
    
  }, error = function(e) {
    #escrever para tabela de log erro de coneccao
    err <- as.character(gsub('[\"\']', '', e))
    print("erro")
    #dbDisconnect(connection)
    print(err)
    dbDisconnect(wfm_con)
    data.frame()
  })
  dbDisconnect(wfm_con)
  colabsWithSundays <- dfData %>%  filter(DOFHC > 0)
  if(nrow(colabsWithSundays)>0){
    for(i in 1:nrow(colabsWithSundays)){
      working_row <- colabsWithSundays[i,]
      print(working_row$EMP)
      sundays <- as.integer(working_row$DOFHC)
      print(paste0("Sundays to remove:", sundays))
      wday_matrix2 <- wday_matrix %>% filter(TIPO_TURNO!=0, WDAY == 1, COLABORADOR == working_row$EMP, grepl('L_',HORARIO , ignore.case = TRUE))
      indices <- round(seq(1, nrow(wday_matrix2), length.out = sundays))
      dates_to_change <- wday_matrix2$DATA[indices]
      
      # Update the HORARIO column for these dates for the specific collaborator
      wday_matrix$HORARIO[
        wday_matrix$DATA %in% dates_to_change & 
          wday_matrix$COLABORADOR == working_row$EMP
      ] <- "DFS"      
      # pri
      
    }
  }
  return(wday_matrix)
}

count_dates_per_year <- function(start_date_str, end_date_str) {
  # Convert input strings to date format
  start_date <- as.Date(start_date_str)
  end_date <- as.Date(end_date_str)
  
  # Generate sequence of dates
  dates <- seq.Date(start_date, end_date, by = "day")
  
  # Extract the unique years from the date sequence
  years <- unique(format(dates, "%Y"))
  
  # Initialize a list to store the count of dates for each year
  year_counts <- list()
  
  # Loop through the unique years and count the number of dates for each
  for (year in years) {
    year_counts[[year]] <- sum(format(dates, "%Y") == year)
  }
  
  # Display the counts for each year
  print(year_counts)
  
  # Determine which year has the most dates
  year_with_most_dates <- names(which.max(unlist(year_counts)))
  
  # Output the year with the most dates
  print(paste("Year with most dates is:", year_with_most_dates))
  
  return(year_with_most_dates)
}


generate_two_dates <- function(start_date, end_date) {
  # Ensure input dates are Date objects
  start_date <- as.Date(start_date)
  end_date <- as.Date(end_date)
  
  # Create a sequence of months from start to end date
  months_seq <- seq(floor_date(start_date, "month"), ceiling_date(end_date, "month") - days(1), by = "month")
  
  # Initialize a list to store all combinations
  date_combinations <- list()
  
  months_seq <- as.character(months_seq)
  # Iterate through each month in the sequence
  for (month_start in months_seq) {
    first_day <- floor_date(as.Date(month_start), "month")  # First day of the month
    last_day <- ceiling_date(as.Date(month_start), "month") - days(1)  # Last day of the month
    
    # Store the possible combinations (first, last)
    date_combinations <- append(date_combinations, list(c(as.character(first_day), as.character(last_day))))
  }
  
  # Return all combinations
  return(do.call(rbind, date_combinations))
}


# Função para calcular L_RES e L_DOM por semana
calcular_folgas2 <- function(semana_df) {
  # Identificar os dias de trabalho (excluindo domingo)
  dias_trabalho <- semana_df %>% 
    dplyr::filter(WDAY != 1 & HORARIO %in% c("H","OUT"))
  
  L_RES <- 0
  if (nrow(dias_trabalho %>% dplyr::filter(DIA_TIPO == "domYf"))>0 & nrow(dias_trabalho %>% dplyr::filter(WDAY == 7, HORARIO=='H',DIA_TIPO != "domYf"))>0) {
    L_RES <- 1
  }
  
  # Identificar feriados (DIA_TIPO == "domYf" e WDAY != 1)
  feriados <- semana_df %>% dplyr::filter(DIA_TIPO == "domYf" & WDAY != 1 & HORARIO %in% c("H","OUT"))
  
  L_DOM <- 0
  if (nrow(feriados)>0) {
    L_DOM <- nrow(feriados)-1
  }
  
  
  
  
  return(data.frame(L_RES = L_RES, L_DOM = L_DOM))
}


# Função para calcular L_RES e L_DOM por semana
calcular_folgas3 <- function(semana_df) {
  
  #dias trabalho semana
  semanaH <- nrow(semana_df %>% dplyr::filter(HORARIO %in% c("H","OUT","NL3D")))
  if (semanaH <=0) {
    return(data.frame(L_RES = 0, L_DOM = 0))
  }
  # Identificar os dias de trabalho (excluindo domingo)
  dias_trabalho <- semana_df %>% 
    dplyr::filter(WDAY != 1 & HORARIO %in% c("H","OUT","NL3D"))
  
  #dias trabalho sexta e sabado
  diasH <- nrow(dias_trabalho %>% dplyr::filter(DIA_TIPO != "domYf"))
  
  L_RES <- max(min(diasH,semanaH-3),0)
  
  # Identificar feriados (DIA_TIPO == "domYf" e WDAY != 1)
  feriados <- semana_df %>% dplyr::filter(DIA_TIPO == "domYf" & WDAY != 1)
  
  L_DOM <- 0
  if (nrow(feriados)>0) {
    L_DOM <- max(nrow(feriados)-2,0)
  }
  
  return(data.frame(L_RES = L_RES, L_DOM = L_DOM))
}
