# read.R
# December 12, 2017
# Steve Smela, Savvysherpa
# Based on code from Bernardo Marquez

###################################################
#  Loads the "read" function into memory          #
###################################################

read <- function(server, database, schema, table, fields, total_rows = "all", show_time = T) {
  "
  Reads a table in a SQL database and puts it in a dataframe.
  
  Parameters:
  
  server: the name of the server where the SQL database is located.
  database: the name of a SQL database.
  schema: the name of a schema in a SQL database.
  table: the name of a table in a SQL database.
  fields: the names of the columns to be retrieved.
  if '*', then all columns will be retrieved.
  total_rows: if a positive integer, then that is the total number of rows to be retrieved.
  if 'all', then all the rows will be retrieved.
  show_time: a boolean to indicate whether or not to display the time it took to read the table.
  The default value is T.
  
  Output: a dataframe that holds the data contained in a table in a SQL database.
  
  Example:
  
  server = 'devsql10'
  database = database1
  schema = 'dbo'
  table = AreaDeprivationIndex_ZIPLevel
  fields = '*'
  total_rows = 'all'
  
  Run a = read(server, database, schema, table, fields, total_rows)
  "
        
        if (show_time)
            t1 <- Sys.time()
        
        channel <- odbcConnect(server)
        fields <- paste(fields, collapse = ", ")
        
        if (total_rows == "all")
            query <- paste0("SELECT ", fields, " FROM ", database, ".", schema, ".",table)
        else
            query <- paste0("SELECT TOP ", as.integer(total_rows), " ", fields, " FROM ", database, ".", schema, ".", table)
        
        output <- sqlQuery(channel, query)
        odbcClose(channel)
        
        if (show_time) {
          
            t2 <- Sys.time()
            
            cat("\n")
            print(t2 - t1)
            cat("\n")
        }
        
        return(output)
}
