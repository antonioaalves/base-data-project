set_ProcessStatus <- function(pathOS, user, process_id, status='P'){
  
  source(paste0(pathOS,"connection/dbconn.R"))
  
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  query <- paste(readLines(paste0(pathOS,"/data/querys/loading/set_process_status.sql")), collapse = " ")

  
  res <- tryCatch({dbSendUpdate(wfm_con,query,
                                user,
                                process_id,
                                status
                                )
    1
  },
  error = function(e) {
    err <<- as.character(gsub('[\"\']', '', e))
    0
  })
  

  dbDisconnect(wfm_con)
  
  
  return(res)
}


set_ProcessErrors <- function(pathOS, user, fk_process, type_error, process_type, error_code, description, employee_id, schedule_day){
  
  source(paste0(pathOS,"connection/dbconn.R"))
  
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  query <- paste(readLines(paste0(pathOS,"/data/querys/loading/set_process_errors.sql")), collapse = " ")
  
  
  res <- tryCatch({dbSendUpdate(wfm_con,query,
                                user,
                                fk_process, 
                                type_error, 
                                process_type, 
                                error_code, 
                                description, 
                                employee_id, 
                                schedule_day
  )
    1
  },
  error = function(e) {
    err <<- as.character(gsub('[\"\']', '', e))
    0
  })
  
  
  dbDisconnect(wfm_con)
  
  
  return(res)
}


set_ProcessParamStatus <- function(pathOS, user, process_id, new_status){
  
  source(paste0(pathOS,"connection/dbconn.R"))
  
  sis <- Sys.info()[[1]]
  confFileName <- paste0(pathOS,'/conf/CONFIGURATIONS.csv')
  wfm_con <- setConnectionWFM(pathOS, sis, confFileName)
  
  query <- paste(readLines(paste0(pathOS,"/data/querys/loading/set_process_parameter_status.sql")), collapse = " ")
  
  
  res <- tryCatch({dbSendUpdate(wfm_con,query,
                                user,
                                process_id,
                                new_status
  )
    1
  },
  error = function(e) {
    err <<- as.character(gsub('[\"\']', '', e))
    0
  })
  
  
  dbDisconnect(wfm_con)
  
  
  return(res)
}
