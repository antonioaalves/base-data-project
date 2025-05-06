sourceFiles <- function(pathOS){
  
  #Global Files-----------------------------------------------------------------------------------------
  source(paste0(pathOS,"/RFiles/dbconn.R"))
  source(paste0(pathOS,"/RFiles/getFuncs.R"))
  source(paste0(pathOS,'/mainFuncs/ponderacoes.R'))
  source(paste0(pathOS,'/mainFuncs/criacaoMatrizes.R'))
  source(paste0(pathOS,'/mainFuncs/criacaoMatrizXOR.R'))
  source(paste0(pathOS,'/mainFuncs/get_related_xor.R'))
  source(paste0(pathOS,'/mainFuncs/selecionaSemana.R'))
  source(paste0(pathOS,'/mainFuncs/selecionaColab.R'))
  source(paste0(pathOS,'/mainFuncs/atribuiDescanso.R'))
  source(paste0(pathOS,'/mainFuncs/atribuiDescanso_filho.R'))
  

}