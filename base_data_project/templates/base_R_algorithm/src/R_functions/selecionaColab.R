# matrix <- matrizA_bk_filtered_rest
# matriz_equidade <- matrizEqui_domYfer
get_matricula_coluna <- function(matrix,matriz_equidade, matrizEqui_sab){
  #1º coluna VZ
  #2º coluna L_DOM
  #3º coluna C2D
  #4º coluna C3D
  #5º coluna L_D
  #6º coluna CXX
  #7º coluna L_Q
  #8º coluna L_RES
  # matrix_testing <- matrizA_bk
  # testing <- matriz_equidade %>% dplyr::select(MATRICULA,DyF_atribuir)
  # matrix_testing_merge  <-  matrix_testing %>% merge(testing)
  
  matrix <- matrix %>% 
    merge(matriz_equidade %>% dplyr::select(MATRICULA,DyF_atribuir)) %>% 
    merge(matrizEqui_sab %>% dplyr::select(MATRICULA,Sab_atribuir))
  matricula <- NULL
  coluna <- NULL
  coluna_tardes <- NULL
  if(any(matrix$VZ>0)){
    row_index <- which.max(with(matrix, VZ == max(VZ,na.rm = T) & L_TOTAL == max(L_TOTAL[VZ == max(VZ,na.rm = T)],na.rm = T)))
    matricula <- matrix[row_index,1]
    coluna <- "VZ"
  }else if (any(matrix$DyF_atribuir>0, na.rm = T)) {
    row_index <- which.max(with(matrix,DyF_atribuir == max(DyF_atribuir, na.rm = T) & L_TOTAL == max(L_TOTAL[DyF_atribuir == max(DyF_atribuir,na.rm = T)],na.rm = T)))
    matricula <- matrix[row_index,1]
    coluna <- "L_DOM"
    coluna_tardes <- 'L_DOM_TARDE'
  }else if (any(matrix$L_DOM>0)) {
    row_index <- which.max(with(matrix, L_DOM == max(L_DOM) & L_TOTAL == max(L_TOTAL[L_DOM == max(L_DOM)])))
    matricula <- matrix[row_index,1]
    coluna <- "L_DOM"
  }else if (any(matrix$C2D>0)) {
    row_index <- which.max(with(matrix, C2D == max(C2D) & L_TOTAL == max(L_TOTAL[C2D == max(C2D)])))
    matricula <- matrix[row_index,1]
    coluna <- "C2D"
  }else if (any(matrix$C3D>0)) {
    row_index <- which.max(with(matrix, C3D == max(C3D) & L_TOTAL == max(L_TOTAL[C3D == max(C3D)])))
    matricula <- matrix[row_index,1]
    coluna <- "C3D"
  }else if (any(matrix$L_D>0)) {
    row_index <- which.max(with(matrix, L_D == max(L_D) & L_TOTAL == max(L_TOTAL[L_D == max(L_D)])))
    matricula <- matrix[row_index,1]
    coluna <- "L_D"
  }else if (any(matrix$L_Q>0)) {
    row_index <- which.max(with(matrix, L_Q == max(L_Q) & L_TOTAL == max(L_TOTAL[L_Q == max(L_Q)])))
    matricula <- matrix[row_index,1]
    coluna <- "L_Q"
  }else if (any(matrix$Sab_atribuir>0, na.rm = T)) {
    row_index <- which.max(with(matrix,Sab_atribuir == max(Sab_atribuir, na.rm = T) & L_TOTAL == max(L_TOTAL[Sab_atribuir == max(Sab_atribuir,na.rm = T)],na.rm = T)))
    matricula <- matrix[row_index,1]
    coluna <- "L_RES"
    coluna_tardes <- 'SABADO'
  }else if (any(matrix$L_RES>0)) {
    row_index <- which.max(with(matrix, L_RES == max(L_RES) & L_TOTAL == max(L_TOTAL[L_RES == max(L_RES)])))
    matricula <- matrix[row_index,1]
    coluna <- "L_RES"
  }else if (any(matrix$CXX>0)) {
    row_index <- which.max(with(matrix, CXX == max(CXX) & L_TOTAL == max(L_TOTAL[CXX == max(CXX)])))
    matricula <- matrix[row_index,1]
    coluna <- "CXX"
  }else if (any(matrix$L_RES2>0)) {
    row_index <- which.max(with(matrix, L_RES2 == max(L_RES2) & L_TOTAL == max(L_TOTAL[L_RES2 == max(L_RES2)])))
    matricula <- matrix[row_index,1]
    coluna <- "L_RES2"
  }
  
  result <- list(matricula, coluna,coluna_tardes)
  return(result)
}

# matriz_equidade <- matrizEqui_domYfer
selectColab <- function(matrizA_bk, matriz_equidade, matrizEqui_sab){
  
  

  
  #filter contrato 2 dias correr
  #filter contrator 3 dias correr
  #filter restantes contratos
  
  #1º coluna VZ
  #2º coluna L_DOM
  #3º coluna C2D
  #4º coluna C3D
  #5º coluna L_D
  #6º coluna CXX
  #7º coluna L_Q
  #8º coluna L_RES
  #em caso de empate desempatar com maior L_TOTAL
  #return da coluna que deu select (não conta coluna de desempate) e da matricula
  matrizA_bk_filtered_2 <- matrizA_bk %>% dplyr::filter(TIPO_CONTRATO == 2)
  matrizA_bk_filtered_3 <- matrizA_bk %>% dplyr::filter(TIPO_CONTRATO == 3)
  matrizA_bk_filtered_rest <- matrizA_bk %>% dplyr::filter(TIPO_CONTRATO > 3)
  
  
  if ((nrow(matrizA_bk_filtered_2)>0) && sum(matrizA_bk_filtered_2$L_TOTAL)>0) {
    matricula_coluna <- get_matricula_coluna_2D3D(matrizA_bk_filtered_2, matriz_equidade)
    
  }else if ((nrow(matrizA_bk_filtered_3)>0) && sum(matrizA_bk_filtered_3$L_TOTAL)>0) {
   matricula_coluna <- get_matricula_coluna_2D3D(matrizA_bk_filtered_3, matriz_equidade)
   
  }else if ((nrow(matrizA_bk_filtered_rest)>0) && sum(matrizA_bk_filtered_rest$L_TOTAL)>0) {
    matricula_coluna <- get_matricula_coluna(matrizA_bk_filtered_rest, matriz_equidade, matrizEqui_sab) 
  }

  ## Caso só existam contratos de 3 dias cheira me que vai dar erro (António)

return(matricula_coluna)
}






get_matricula_coluna_2D3D <- function(matrix,matriz_equidade){
  #1º coluna VZ
  #2º coluna L_DOM
  #3º coluna C2D
  #4º coluna C3D
  #5º coluna L_D
  #6º coluna CXX
  #7º coluna L_Q
  #8º coluna L_RES
  # matrix_testing <- matrizA_bk
  # testing <- matriz_equidade %>% dplyr::select(MATRICULA,DyF_atribuir)
  # matrix_testing_merge  <-  matrix_testing %>% merge(testing)
  
  
  matrix <- matrix %>% 
    merge(matriz_equidade %>% dplyr::select(MATRICULA,DyF_atribuir))
  matricula <- NULL
  coluna <- NULL
  coluna_tardes <- NULL
  if(any(matrix$VZ>0)){
    row_index <- which.max(with(matrix, VZ == max(VZ,na.rm = T) & L_TOTAL == max(L_TOTAL[VZ == max(VZ,na.rm = T)],na.rm = T)))
    matricula <- matrix[row_index,1]
    coluna <- "VZ"
  }else if (any(matrix$L_RES>0)) {
    row_index <- which.max(with(matrix, L_RES == max(L_RES) & L_TOTAL == max(L_TOTAL[L_RES == max(L_RES)])))
    matricula <- matrix[row_index,1]
    coluna <- "L_RES"
  }else if (any(matrix$DyF_atribuir>0, na.rm = T)) {
    row_index <- which.max(with(matrix,DyF_atribuir == max(DyF_atribuir, na.rm = T) & L_TOTAL == max(L_TOTAL[DyF_atribuir == max(DyF_atribuir,na.rm = T)],na.rm = T)))
    matricula <- matrix[row_index,1]
    coluna <- "L_DOM"
    coluna_tardes <- 'L_DOM_TARDE'
  }else if (any(matrix$L_DOM>0)) {
    row_index <- which.max(with(matrix, L_DOM == max(L_DOM) & L_TOTAL == max(L_TOTAL[L_DOM == max(L_DOM)])))
    matricula <- matrix[row_index,1]
    coluna <- "L_DOM"
  }else if (any(matrix$C2D>0)) {
    row_index <- which.max(with(matrix, C2D == max(C2D) & L_TOTAL == max(L_TOTAL[C2D == max(C2D)])))
    matricula <- matrix[row_index,1]
    coluna <- "C2D"
  }else if (any(matrix$C3D>0)) {
    row_index <- which.max(with(matrix, C3D == max(C3D) & L_TOTAL == max(L_TOTAL[C3D == max(C3D)])))
    matricula <- matrix[row_index,1]
    coluna <- "C3D"
  }else if (any(matrix$L_D>0)) {
    row_index <- which.max(with(matrix, L_D == max(L_D) & L_TOTAL == max(L_TOTAL[L_D == max(L_D)])))
    matricula <- matrix[row_index,1]
    coluna <- "L_D"
  }else if (any(matrix$L_Q>0)) {
    row_index <- which.max(with(matrix, L_Q == max(L_Q) & L_TOTAL == max(L_TOTAL[L_Q == max(L_Q)])))
    matricula <- matrix[row_index,1]
    coluna <- "L_Q"
  }else if (any(matrix$CXX>0)) {
    row_index <- which.max(with(matrix, CXX == max(CXX) & L_TOTAL == max(L_TOTAL[CXX == max(CXX)])))
    matricula <- matrix[row_index,1]
    coluna <- "CXX"
  }else if (any(matrix$L_RES2>0)) {
    row_index <- which.max(with(matrix, L_RES2 == max(L_RES2) & L_TOTAL == max(L_TOTAL[L_RES2 == max(L_RES2)])))
    matricula <- matrix[row_index,1]
    coluna <- "L_RES2"
  }
  
  result <- list(matricula, coluna,coluna_tardes)
  return(result)
}