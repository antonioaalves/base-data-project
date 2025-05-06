
### TESTES--------------

matrizA <- fread(paste0(pathOS,"/Docs/MA_TRATADA.csv"), encoding = 'UTF-8')
names(matrizA) <- c("UNIDADE","SECAO","POSTO","CONVENIO","NOME","MATRICULA","OUT","TIPO_CONTRATO",
                    "MIN_DIA_TRAB","MAX_DIA_TRAB","TIPO_TURNO","H1","H2","H3","H4","T_TOTAL","L_TOTAL",
                    "DyF_MAX_T","LD","LQ","C","C2D","C3D","CXX","HORAS_DIA","HORAS_SEMANA","HORAS_MENSAL","HORAS_ANO")



matrizA <- read_xlsx(paste0(pathOS,"/Docs/output_M1.xlsx"))
matriz1_og <- fread(paste0(pathOS,"/Docs/output_M1.csv"), encoding = 'UTF-8', header = T)
matriz1_ini <- melt(matriz1_og,id.vars='DIA')

# 
# matrizB <- matriz1_ini %>% 
#   dplyr::filter(DIA %in% c("TIPO_DIA","TURNO","maxTurno","mediaTurno","minTurno","sdTurno"))

matriz1 <- matriz1_ini %>% 
  dplyr::filter(!(DIA %in% c("TURNO","maxTurno","mediaTurno","minTurno","sdTurno")))

# 
# matrizB %>% data.table() %>% 
#   dplyr::group_by(DIA,variable) %>% 
#   dplyr::summarise(value_agg= paste0(value,collapse = ", ")) %>% View()
#   separate(value_agg, into = c("turno1", "turno2"), sep = ",") %>% 
#   reshape2::dcast(variable~DIA, value.var = c("turno1", "turno2")) %>%  View()


matriz1 %>% data.table() %>% 
  dplyr::group_by(DIA,variable) %>% 
  dplyr::summarise(value_agg= paste0(value,collapse = ", ")) %>% 
  separate(value_agg, into = c("turno1", "turno2"), sep = ",") %>% View()



matrizB_ini <- fread(paste0(pathOS,"/Docs/matrizEstimativas.csv"), encoding = 'UTF-8', header = T, sep=";",dec = ",") %>% 
  separate(DATA_TURNO, into = c("DATA", "TURNO"), sep = "_")


matrizB <- matrizB_ini %>% 
  dplyr::group_by(DATA,FK_TIPO_POSTO) %>% 
  dplyr::summarise(mediaTurno=sum(mediaTurno),
                   maxTurno=sum(maxTurno),
                   minTurno=sum(minTurno),
                   sdTurno=sum(sdTurno))

matrizB <- matrizB %>% 
  dplyr::filter(FK_TIPO_POSTO == 153)



matriz1 %>% data.table() %>% 
  dplyr::group_by(DIA,variable) %>% 
  dplyr::summarise(value_agg= paste0(value,collapse = ", ")) %>% View()
# dplyr::mutate(value_agg = ifelse(grepl("M|T", value_agg), 1, value_agg)) %>% 
merge(matrizB)
View()






######--------------
matrizB <- matriz1_ini %>%
  dplyr::filter(DIA %in% c("maxTurno","mediaTurno","minTurno","sdTurno"))

matrizB <- matrizB %>% data.table() %>% 
  dplyr::group_by(DIA,variable) %>% 
  dplyr::summarise(value_agg= sum(as.numeric(value)), .groups='drop') %>% 
  dplyr::mutate(value_agg=as.character(value_agg))


matrizB_d <- matrizB %>% 
  dplyr::arrange(DIA) %>% 
  reshape2::dcast(DIA~variable, value.var = "value_agg") 


matriz1 <- matriz1_ini %>% 
  dplyr::filter(!(DIA %in% c("maxTurno","mediaTurno","minTurno","sdTurno")))

matriz1 %>% data.table() %>% 
  dplyr::group_by(DIA,variable) %>% 
  dplyr::summarise(value_agg= paste0(value,collapse = ", "), .groups='drop') %>% 
  separate(value_agg, into = c("turno1", "turno2"), sep = ",") %>% View()

matriz1 <- matriz1 %>% data.table() %>% 
  dplyr::group_by(DIA,variable) %>% 
  dplyr::summarise(value_agg= paste0(value,collapse = ", "), .groups='drop') %>%
  mutate(value_agg = ifelse(grepl("M|T", value_agg), 1, value_agg))


matriz1_d <- matriz1 %>% 
  dplyr::arrange(DIA) %>% 
  reshape2::dcast(DIA~variable, value.var = "value_agg")


matriz1Final <- matriz1_d %>% 
  dplyr::bind_rows(matrizB_d)
