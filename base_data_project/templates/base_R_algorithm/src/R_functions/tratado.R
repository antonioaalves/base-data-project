# matriz2 %>% 
#   dplyr::group_by(COLABORADOR,WW) %>% 
#   dplyr::summarise(xx = sum(HORARIO %in% c("LD","L_RES","CXX","LQ","L_DOM|L_F","C2D","C3D"))/2) %>% 
#   dplyr::arrange(desc(xx))
# 
# matriz2222 <- matriz2
# 
# 
# matriz2 <- matriz2 %>%  
#   dplyr::select(COLABORADOR, DATA,TIPO_TURNO, HORARIO) %>% 
#   unique() %>% 
#   dplyr::filter(TIPO_TURNO != "0",TIPO_TURNO!="-") %>% 
#   dplyr::mutate(HORARIO = replace(HORARIO, HORARIO %in% c("L_RES","L_DOM|L_F"), "L")) %>% 
#   dplyr::mutate(HORARIO = replace(HORARIO, HORARIO %in% c("NL","NC2","NLDF","NC1"), "H"))# %>% 
#   # dplyr::mutate(HORARIO = replace(HORARIO, HORARIO %in% c("C3D","C2D","CXX"), "C"))
# 
# matriz <- matriz2 %>%
#   dplyr::mutate(HORARIO = case_when(
#     HORARIO == "H" ~ TIPO_TURNO,
#     TRUE ~ HORARIO  # Default case if none of the above conditions are met
#   ))
# 
# matriz2_dcast <- reshape2::dcast(matriz, COLABORADOR ~ DATA+TIPO_TURNO, value.var = "HORARIO", fill = "-")
# 
# write.csv(matriz2_dcast, "M2.csv")
# 
# # View(matriz2 %>% 
# #        dplyr::filter(COLABORADOR != )
# #      )
#####-----------------------------------------------------------------------------------------------------

matriz212 <<- matriz2_bk

matriz <- matriz212 %>%  
  dplyr::select(COLABORADOR, DATA, TIPO_TURNO,HORARIO) %>% 
  unique() %>% 
  dplyr::filter(HORARIO != "0") %>% 
  dplyr::mutate(HORARIO = replace(HORARIO, HORARIO %in% c("L_RES","L_DOM","L_"), "L")) %>% 
  dplyr::mutate(HORARIO = replace(HORARIO, HORARIO %in% c("L_D"), "LD")) %>% 
  dplyr::mutate(HORARIO = replace(HORARIO, HORARIO %in% c("NL","NC2","NLDF","NC1",'OUT',"NL3D"), "H")) %>%
  dplyr::mutate(HORARIO = replace(HORARIO, HORARIO %in% c("C3D","C2D","CXX"), "C")) %>%
  dplyr::mutate(HORARIO = replace(HORARIO, HORARIO %in% c("L_Q"), "LQ")) %>%
  dplyr::mutate(HORARIO = replace(HORARIO, HORARIO %in% c("L_QS"), "Q")) %>%
  dplyr::mutate(HORARIO = replace(HORARIO, HORARIO %in% c("VZ"), "-"))

matriz <- matriz %>% 
  dplyr::filter(TIPO_TURNO != "0")

matriz <- matriz %>%
  dplyr::mutate(HORARIO = case_when(
    HORARIO == "H" ~ TIPO_TURNO,
    TRUE ~ HORARIO  # Default case if none of the above conditions are met
  ))

# write.csv(matriz,"matri2_MT.csv")





matriz_dcast <- matriz %>%
  dplyr::select(COLABORADOR, DATA,HORARIO)
matriz_dcast <- reshape2::dcast(matriz, COLABORADOR ~ DATA, value.var = "HORARIO")


# matriz_dcast$FK_TIPO_POSTO <- FK_POSTO

write.csv2(matriz_dcast, paste0("matriz_18-12-23_",FK_POSTO,".csv"))

# write.csv2(matrizB, "matriB.csv")
#####-----------------------------------------------------------------------------------------------------
# 
# matriz212 <<- matriz2_bk
# 
# matriz <- matriz212 %>%  
#   dplyr::select(COLABORADOR, DATA, TIPO_TURNO,HORARIO) %>% 
#   unique() %>% 
#   dplyr::filter(HORARIO != "0") %>% 
#   dplyr::mutate(HORARIO = replace(HORARIO, HORARIO %in% c("L_RES","L_DOM"), "L")) %>% 
#   dplyr::mutate(HORARIO = replace(HORARIO, HORARIO %in% c("L_D"), "LD")) %>% 
#   dplyr::mutate(HORARIO = replace(HORARIO, HORARIO %in% c("NL","NC2","NLDF","NC1",'OUT'), "H")) %>%
#   # dplyr::mutate(HORARIO = replace(HORARIO, HORARIO %in% c("C3D","C2D"), "LQ")) %>% 
#   dplyr::mutate(HORARIO = replace(HORARIO, HORARIO %in% c("VZ"), "-"))
# 
# matriz <- matriz %>% 
#   dplyr::filter(TIPO_TURNO != "0")
# 
# matriz <- matriz %>%
#   dplyr::mutate(HORARIO = case_when(
#     HORARIO == "H" ~ TIPO_TURNO,
#     TRUE ~ HORARIO  # Default case if none of the above conditions are met
#   ))
# 
# # write.csv(matriz,"matri2_MT.csv")
# 
# custom_concatenate <- function(x) {
#   if (any(grepl("L|C", x, ignore.case = TRUE))) {
#     return(unique(x))
#   } else {
#     return(paste(x, collapse = "o"))
#   }
# }
# 
# # matriz$value <- apply(matriz, 1:2, function(x) custom_concatenate(x))
# matriz$value <- apply(matriz[, "HORARIO", drop = FALSE], MARGIN = 2, FUN = custom_concatenate)
# 
# 
# 
# 
# matriz_dcast <- matriz %>%
#   dplyr::select(COLABORADOR, DATA,HORARIO)
# matriz_dcast <- reshape2::dcast(matriz, COLABORADOR ~ DATA, value.var = "HORARIO",fun.aggregate = custom_concatenate)
# 
# matriz_dcast <- matriz_dcast %>%
#   # dplyr::mutate(across(-1, ~ replace(., "LDoLD","LD")))
#   mutate_at(vars(-1), ~ gsub("LDoLD", "LD", .)) %>% 
#   mutate_at(vars(-1), ~ gsub("CXXoCXX", "CXX", .)) %>% 
#   mutate_at(vars(-1), ~ gsub("LoL", "L", .)) %>% 
#   mutate_at(vars(-1), ~ gsub("C2DoC2D", "C2D", .)) %>% 
#   mutate_at(vars(-1), ~ gsub("C3DoC3D", "C3D", .)) %>% 
#   mutate_at(vars(-1), ~ gsub("LQoLQ", "LQ", .))  
# # matriz_dcast$FK_TIPO_POSTO <- FK_POSTO
# 
# write.csv2(matriz_dcast, paste0("matriz_101223_",FK_POSTO,".csv"))
# 
# # write.csv2(matrizB, "matriB.csv")
