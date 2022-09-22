#Load RODBC

library(RODBC);

#Create a database connection

dsn_driver <- "{IBM DB2 ODBC Driver}"
dsn_database <- "bludb"            # e.g. "bludb"
dsn_hostname <- "6667d8e9-9d4d-4ccb-ba32-21da3bb5aafc.c1ogj3sd0tgtu0lqde00.databases.appdomain.cloud" # e.g "54a2f15b-5c0f-46df-8954-.databases.appdomain.cloud"
dsn_port <- "30376"   # e.g. "32733" 
dsn_protocol <- "TCPIP"            # i.e. "TCPIP"
dsn_uid <- "gqg40240"        # e.g. "zjh17769"
dsn_pwd <- "cywYWsqdQIpzuZIf"      # e.g. "zcwd4+8gbq9bm5k4"  
dsn_security <- "ssl"

##Create a connection string and connect to the database

conn_path <- paste("DRIVER=",dsn_driver,
                   ";DATABASE=",dsn_database,
                   ";HOSTNAME=",dsn_hostname,
                   ";PORT=",dsn_port,
                   ";PROTOCOL=",dsn_protocol,
                   ";UID=",dsn_uid,
                   ";PWD=",dsn_pwd,
                   ";SECURITY=",dsn_security,        
                   sep="")
conn <- odbcDriverConnect(conn_path)
conn

#View database and driver information

#sql.info <- sqlTypeInfo(conn)
#conn.info <- odbcGetInfo(conn)
#conn.info["DBMS_Name"]
#conn.info["DBMS_Ver"]
#conn.info["Driver_ODBC_Ver"]


#Create the tables

myschema <- "GQG40240" # e.g. "ZJH17769"
tables <- c("BOARD", "SCHOOL")

for (table in tables){  
        # Drop School table if it already exists
        out <- sqlTables(conn, tableType = "TABLE", schema = myschema, tableName =table)
        if (nrow(out)>0) {
                err <- sqlDrop (conn, paste(myschema,".",table,sep=""), errors=FALSE)  
                if (err==-1){
                        cat("An error has occurred.\n")
                        err.msg <- odbcGetErrMsg(conn)
                        for (error in err.msg) {
                                cat(error,"\n")
                        }
                } else {
                        cat ("Table: ",  myschema,".",table," was dropped\n")
                }
        } else {
                cat ("Table: ",  myschema,".",table," does not exist\n")
        }
}

#Let's create the BOARD table in the database.1

df1 <- sqlQuery(conn, "CREATE TABLE BOARD (
                            B_ID CHAR(6) NOT NULL, 
                            B_NAME VARCHAR(75) NOT NULL, 
                            TYPE VARCHAR(50) NOT NULL, 
                            LANGUAGE VARCHAR(50), 
                            PRIMARY KEY (B_ID))", 
                errors=FALSE)

#Check if successful

if (df1 == -1){
        cat ("An error has occurred.\n")
        msg <- odbcGetErrMsg(conn)
        print (msg)
} else {
        cat ("Table was created successfully.\n")
}

#Now let's create the SCHOOL table.

df2 <- sqlQuery(conn, "CREATE TABLE SCHOOL (
                  B_ID CHAR(6) NOT NULL, 
                  S_ID CHAR(6) NOT NULL, 
                  S_NAME VARCHAR(100), 
                  LEVEL VARCHAR(70), 
                  ENROLLMENT INTEGER WITH DEFAULT 10,
                  PRIMARY KEY (B_ID, S_ID))", errors=FALSE)

#Check if successful

if (df2 == -1){
        cat ("An error has occurred.\n")
        msg <- odbcGetErrMsg(conn)
        print (msg)
} else {
        cat ("Table was created successfully.\n")
}

#Load the data into the database

tab.frame <- sqlTables(conn, schema=myschema)
nrow(tab.frame)
tab.frame$TABLE_NAME

#Print column 4, 6, 7, 18 details for the tables BOARD and SCHOOL

for (table in tables){  
        cat ("\nColumn info for table", table, ":\n")
        col.detail <- sqlColumns(conn, table)
        print(col.detail[c(4,6,7,18)], row.names=FALSE)
}

#Load the data from the board.csv into the BOARD dataframe.

boarddff <- read.csv("https://cf-courses-data.s3.us.cloud-object-storage.appdomain.cloud/IBMDeveloperSkillsNetwork-RP0103EN-SkillsNetwork/data/school.csv", header = FALSE)

#Display initial data from the BOARD dataframe.

head(boarddf)

#Save the dataframe to the database table BOARD.

sqlSave(conn, boarddf, "BOARD", append=TRUE, fast=FALSE, rownames=FALSE, colnames=FALSE, verbose=FALSE)

#Load the data from the school.csv into the SCHOOL dataframe

schooldf <- read.csv("/resources/data/samples/osb/school.csv", header = FALSE)

head(schooldf)

#Change the encoding of the 3rd column character vector from latin1 to ASCII//TRANSLIT

schooldf$V3 <- iconv(schooldf$V3, "latin1", "ASCII//TRANSLIT")

#Save the dataframe to the database table SCHOOL.

sqlSave(conn, schooldf, "SCHOOL", append=TRUE, fast=FALSE, rownames=FALSE, colnames=FALSE, verbose=FALSE)

#Fetch data from the database

boarddb <- sqlFetch(conn, "BOARD")
tail(boarddb)

schooldb <- sqlFetch(conn, "SCHOOL")
tail(schooldb)

#Plot the data (using ggplot2)

library(ggplot2);

elequery <- query <- paste("select s.enrollment as ENROLLMENT 
from school s, board b 
where b.b_name = 'Toronto DSB' and b.b_id=s.b_id 
and s.level = 'Elementary' 
order by enrollment desc")

eledf <- sqlQuery(conn, elequery)
dim(eledf)

qplot(ENROLLMENT, data=eledf, geom="density",  main="TDSB School Size - Elementary")

secquery <- paste("select s.enrollment as ENROLLMENT 
from school s, board b 
where b.b_name = 'Toronto DSB' and b.b_id=s.b_id 
and s.level = 'Secondary' 
order by enrollment desc")

secdf <- sqlQuery(conn, secquery)

qplot(ENROLLMENT, data=secdf, geom="density", main="TDSB School Size - Secondary")

denquery <- paste("select b.b_name, s.s_name, level as LEVEL, enrollment 
 from board b, school s where b.b_id = s.b_id and b.b_name = 'Toronto DSB'")

dendf <- sqlQuery(conn, denquery)

dendf$LEVEL <- as.factor(dendf$LEVEL)
boxplot(ENROLLMENT ~ LEVEL, dendf, names =c("Secondary","Elementary"), main="Toronto DSB")

#Dis-connect

close(conn)

