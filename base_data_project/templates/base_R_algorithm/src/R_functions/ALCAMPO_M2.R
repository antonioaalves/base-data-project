
matrizInicial <- fread(paste0(pathOS,"/Docs/Alcampo MA e M1 Teste.csv"), encoding = 'UTF-8')


split_data_frames <- split(matrizInicial, interaction(matrizInicial$UNIDADE, matrizInicial$SECAO, drop = TRUE))

#LEGANES ID==4
View(split_data_frames[[4]])
M1_TODOS <- data.table()

for (i in 1:length(split_data_frames)) {
  
  matrizInicial <- split_data_frames[[i]]
  
  
  #CREATE MATRIX 1
  dias <- seq.Date(as.Date('2023-12-18'),as.Date('2025-01-12'), by ='days')
  dias_column <- rep(dias, length(unique(matrizInicial$COLABORADOR)))
  colabs_column <- rep(unique(matrizInicial$COLABORADOR), each=length(dias) )
  
  matrix1 <- data.table(COLABORADOR = colabs_column, DATA = dias_column, TIPO='T')
  
  matrix1$WNUM <- week(matrix1$DATA)
  
  dfCiclos <- setCycles(matrizInicial,matrix1) %>% 
    merge(matrizInicial %>% dplyr::select(FK_UNIDADE,UNIDADE,SECAO,COLABORADOR,INI_T1,FIM_T1,INI_T2,FIM_T2), by = "COLABORADOR")
  
  M1_TODOS <- M1_TODOS %>% 
    dplyr::bind_rows(dfCiclos)
}







setCycles <- function(matrizInicial,matrix1){
  dfCiclos <- data.table()
  for (colab in unique(matrizInicial$COLABORADOR)) {
    tt <- matrizInicial %>% 
      dplyr::filter(COLABORADOR == colab)
    
    mm <- matrix1 %>% 
      dplyr::filter(COLABORADOR == colab) %>% 
      dplyr::arrange(DATA) %>% dplyr::select(-TIPO)
    
    ll <- c(tt$s1)
    if (tt$s2!="") ll <- c(ll,tt$s2)
    if (tt$s3!="") ll <- c(ll,tt$s3)
    if (tt$s4!="") ll <- c(ll,tt$s4)
    
    dfAux <- data.table()
    for (i in 1:length(unique(mm$WNUM))) {
      pos <- i%%length(ll)
      
      if (pos==0) {
        print(ll[length(ll)])
        dfAux <- dfAux %>% 
          dplyr::bind_rows(
            data.table(
              WNUM = i,
              TIPO = ll[length(ll)]
            )
          )
      } else{
        print(ll[pos])
        dfAux <- dfAux %>% 
          dplyr::bind_rows(
            data.table(
              WNUM = i,
              TIPO = ll[pos]
            )
          )
      }
      
      
    }
    dfCiclos <- dfCiclos %>% 
      dplyr::bind_rows(merge(mm, dfAux, by = c("WNUM")))
    
    
  }
  
  
  return(dfCiclos)
}


# dfCiclos <- setCycles(matrizInicial,matrix1)

split_M1_TODOS <- split(M1_TODOS, interaction(M1_TODOS$UNIDADE, M1_TODOS$SECAO, drop = TRUE))

View(split_data_frames[[4]])
View(split_M1_TODOS[[4]])
dcast(split_M1_TODOS[[4]], COLABORADOR~DATA, value.var = 'TIPO') %>% View()


diarizacao <- read_xlsx(paste0(pathOS,"/Docs/FORECAST.xlsx"))



# Load required libraries
# library(dplyr)
# library(lubridate)

# Create a list to store the tables
table_list <- list()
matrixTeste <- split_data_frames[[4]]

# Generate data for each day of the year
for(day_of_year in 1:365) {
  # Create a date for the specific day of the year
  date <- make_date(year(Sys.Date()), month = 1, day = 1) + days(day_of_year - 1)
  
  # Create a time sequence from 06:00 to 23:45 in 15-minute increments
  time_intervals <- seq(from = as.POSIXct('2000-01-01 05:00:00',tz='GMT'), 
                        to = as.POSIXct('2000-01-01 23:45:00',tz='GMT'), by = "15 mins")
  
  # Create a matrix with random values (you can replace this with your data)
  data_matrix <-data.table(
    COLABORADOR = matrixTeste$COLABORADOR,
    HORAS = time_intervals
  )
  colnames(data_matrix) <- format(time_intervals, format = "%H:%M:%S")
  
  # Store the matrix in a table
  table_list[[day_of_year]] <- data_matrix
}

# Now table_list is a list of tables, one for each day of the year, with matrices
table_list[[1]]
