sourceFiles <- function(pathOS){
  print(pathOS)
  
  #Global Files-----------------------------------------------------------------------------------------
  # source(paste0(pathOS,'/mainFuncs/atribuiDescanso_filho.R'))
  source(paste0(pathOS,"/mainFuncs/inicializa.R"))
  source(paste0(pathOS,"/mainFuncs/initializeData.R"))
  source(paste0(pathOS,"/mainFuncs/selecionaSemana.R"))
  source(paste0(pathOS,"/mainFuncs/selecionaDiaTurno.R"))
  source(paste0(pathOS,"/mainFuncs/selecionaColab.R"))
  source(paste0(pathOS,"/mainFuncs/atribuiDescanso.R"))
  source(paste0(pathOS,"/mainFuncs/matrizXor.R"))
  #(paste0(pathOS,"/mainFuncs/funcs.R"))
  source(paste0(pathOS,"/mainFuncs/add_OUT.R"))
  source(paste0(pathOS,"mainFuncs/loadingFuncs.R"))
  
  
  
  
  source(paste0(pathOS,"Rfiles/Get_Queries/get_M2_OUT.R"))
  source(paste0(pathOS,"Rfiles/funcs.R"))

  #source(paste0(pathOS,"Rfiles/loadingFuncs.R"))
  source(paste0(pathOS,"Rfiles/getDayAloc.R"))
  
  source(paste0(pathOS,"Rfiles/getCoreSChedule.R"))
  source(paste0(pathOS,"Rfiles/insertHorarios.R"))
  
  #estimativas
  source(paste0(pathOS,"Rfiles/get_needed_files.R"))
  source(paste0(pathOS,"Rfiles/outputTurnos - AUTO.R"))
  
  #matrizes
  source(paste0(pathOS,"/Rfiles/queryFestivos.R"))
  source(paste0(pathOS,"/Rfiles/queryClosedDays.R"))

  
  #--loading
  source(paste0(pathOS,"Rfiles/loading/get_processo.R"))
  source(paste0(pathOS,"Rfiles/loading/get_processoValidEmp.R"))
  
  source(paste0(pathOS,"Rfiles/loading/set_processo.R"))
  
  
  #--parameters
  source(paste0(pathOS,"Rfiles/parameters/get_faixasSec.R"))
  source(paste0(pathOS,"Rfiles/parameters/get_parameters.R"))
  source(paste0(pathOS,"Rfiles/parameters/log_messages.R"))
  print("ALL SCOURCED")
}


# definePostoLoop <- function(getProc){
#   
#   
#   return(postos)
# }