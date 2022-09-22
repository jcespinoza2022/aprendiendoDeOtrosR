#Data type considerations for real world datasets

#Load the csv files into dataframes and inspect them

crop_df <- read.csv('https://cf-courses-data.s3.us.cloud-object-storage.appdomain.cloud/IBM-RP0203EN-SkillsNetwork/labs/Final%20Project/Annual_Crop_Data.csv', colClasses=c(YEAR="character"))
fx_df <- read.csv('https://cf-courses-data.s3.us.cloud-object-storage.appdomain.cloud/IBM-RP0203EN-SkillsNetwork/labs/Final%20Project/Daily_FX.csv', colClasses=c(date="character"))

head(crop_df)
head(fx_df)

#Connect to the database

library(RODBC);

dsn_driver <- "{IBM DB2 ODBC Driver}"
dsn_database <- "bludb"            # e.g. "bludb"
dsn_hostname <- "6667d8e9-9d4d-4ccb-ba32-21da3bb5aafc.c1ogj3sd0tgtu0lqde00.databases.appdomain.cloud" # e.g "54a2f15b-5c0f-46df-8954-.databases.appdomain.cloud"
dsn_port <- "30376"   # e.g. "32733" 
dsn_protocol <- "TCPIP"            # i.e. "TCPIP"
dsn_uid <- "gqg40240"        # e.g. "zjh17769"
dsn_pwd <- "cywYWsqdQIpzuZIf"      # e.g. "zcwd4+8gbq9bm5k4"  
dsn_security <- "ssl"

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

# Dump connection info
##############################################################
sql.info <- sqlTypeInfo(conn)
conn.info <- odbcGetInfo(conn)
conn.info["DBMS_Name"]
conn.info["DBMS_Ver"]
conn.info["Driver_ODBC_Ver"]

#Table creation steps:

#Check whether these tables already exist, and drop them if so.

tables <- c("CROP_DATA", "DAILY_FX") 

for (table in tables) {
        # Drop tables if they already exist
        out <- sqlTables(conn, tableType = "TABLE",
                         tableName = table)
        if (nrow(out)>0) {
                err <- sqlDrop(conn, table,
                               errors=FALSE)  
                if (err==-1) {
                        cat("An error has occurred.\n")
                        err.msg <- odbcGetErrMsg(conn)
                        for (error in err.msg) { 
                                cat(error,"\n")
                        }
                } 
                else {
                        cat ("Table: ",table," was dropped\n")
                }
        }
        else {
                cat ("Table: ", table," does not exist\n")
        }
}

#Create "CROP_DATA" table in Db2.

df1 <- sqlQuery(conn, 
                "CREATE TABLE CROP_DATA (
                                      CD_ID INTEGER NOT NULL,
                                      YEAR DATE NOT NULL,
                                      CROP_TYPE VARCHAR(20) NOT NULL,
                                      GEO VARCHAR(20) NOT NULL, 
                                      SEEDED_AREA INTEGER NOT NULL,
                                      HARVESTED_AREA INTEGER NOT NULL,
                                      PRODUCTION INTEGER NOT NULL,
                                      AVG_YIELD INTEGER NOT NULL,
                                      PRIMARY KEY (CD_ID)
                                      )", 
                errors=FALSE
)

if (df1 == -1){
        cat ("An error has occurred.\n")
        msg <- odbcGetErrMsg(conn)
        print (msg)
} else {
        cat ("Table was created successfully.\n")
}

#Create "DAILY_FX" table in Db2.

df3 <- sqlQuery(conn, "CREATE TABLE DAILY_FX (
                                DFX_ID INTEGER NOT NULL,
                                DATE DATE NOT NULL, 
                                FXUSDCAD FLOAT(6),
                                PRIMARY KEY (DFX_ID)
                                )",
                errors=FALSE
)

if (df3 == -1){
        cat ("An error has occurred.\n")
        msg <- odbcGetErrMsg(conn)
        print (msg)
} else {
        cat ("Table was created successfully.\n")
}

#Load the dataframes into the Db2 tables you created.

sqlSave(conn, crop_df, "CROP_DATA", append=TRUE, fast=FALSE, rownames=FALSE, colnames=FALSE, verbose=FALSE)
sqlSave(conn, fx_df, "DAILY_FX", append=TRUE, fast=FALSE, rownames=FALSE, colnames=FALSE, verbose=FALSE)


#Now let's solve some practice problems using SQL commands:

#Find the number of rows in each table.

query = "SELECT COUNT(CD_ID) FROM CROP_DATA"
sqlQuery(conn,query)

query = "SELECT COUNT(DFX_ID) FROM DAILY_FX"
sqlQuery(conn,query)

#Query and display the first 6 rows of the crop data.

query <- "SELECT * FROM CROP_DATA LIMIT 6;"
view <- sqlQuery(conn,query)
view

# Notice that we did not just query the entire table and then display first 6 rows of the dataframe. 
# For larger datasets, using a LIMIT statement this way can save a lot of transit time in moving the data.


#List the types of crops in the crop dataset.

query <- "SELECT DISTINCT(CROP_TYPE) FROM CROP_DATA;"
view <- sqlQuery(conn,query)
view

#Query and display the first 6 rows of the crop data for Rye.

query <- "SELECT * FROM CROP_DATA WHERE CROP_TYPE='Rye' LIMIT 6;"
view <- sqlQuery(conn,query)
view

#Which crops have had an average yield greater than or equal to 3000 KG per Hectare?

query <- 
        "SELECT DISTINCT(CROP_TYPE) 
    FROM CROP_DATA 
    WHERE AVG_YIELD > 3000;"
view <- sqlQuery(conn,query)
view

#Find the first and last dates of each table.

query <-
        "SELECT min(DATE) FIRST_DATE, max(DATE) LAST_DATE
    FROM DAILY_FX;
    "
view <- sqlQuery(conn,query)
view

query <-
        "SELECT min(YEAR) FIRST_DATE, max(YEAR) LAST_DATE
    FROM CROP_DATA;
    "
view <- sqlQuery(conn,query)
view

#List the top 10 years of Wheat production in Saskatchewan in terms of harvested area.

query <- 
        "SELECT YEAR(YEAR) AS TOP_10_YRS, GEO, HARVESTED_AREA 
    FROM CROP_DATA 
    WHERE CROP_TYPE='Wheat' AND 
          GEO='Saskatchewan'
    ORDER BY HARVESTED_AREA DESC
    LIMIT 10;"
view <- sqlQuery(conn,query)
view

#How many years did Barley yield at least 2000 KG per Hectare in Canada?

query <- 
        "SELECT COUNT(DISTINCT(YEAR)) AS BLY_YRS_ABOVE_2MTPH
    FROM CROP_DATA 
    WHERE AVG_YIELD > 2000 AND 
          CROP_TYPE='Barley' AND 
          GEO='Canada';"
view <- sqlQuery(conn,query)
view

#How much farm land was seeeded with Barley in Alberta but not harvested each year since the year 2000?

#Create a new 'AS' column called something like 'PCT_UNHARVESTED_AREA'. 

query <- 
        "SELECT YEAR(YEAR) AS YEAR, GEO, CROP_TYPE,
            SEEDED_AREA, HARVESTED_AREA, 
            100*(SEEDED_AREA-HARVESTED_AREA)/SEEDED_AREA AS PCT_UNHARVESTED_AREA
    FROM CROP_DATA
    WHERE YEAR(YEAR) >= 2000 AND
          GEO = 'Alberta' AND
          CROP_TYPE = 'Barley';"

view <- sqlQuery(conn,query)
view

#Over the last 3 calendar years of data, what was the average value of the Canadian dollar relative to the USD?

query <-
        "SELECT MIN(DATE) AS AS_OF_DATE, 
            AVG(FXUSDCAD) AS FX_DAILY_AVG_CAD 
    FROM  DAILY_FX
    WHERE DATE >= (SELECT MAX(DATE) - 3 YEARS FROM DAILY_FX);
    "
view <- sqlQuery(conn,query)
view

#Use an implicit inner join to create a view of the crop data with an FX column included.

#Use the year and month parts of the date columns to align the tables on December of each year.

query <- "SELECT CD_ID, YEAR, CROP_TYPE, GEO, SEEDED_AREA, HARVESTED_AREA, PRODUCTION, AVG_YIELD, FXUSDCAD  
    FROM CROP_DATA, MONTHLY_FX 
    WHERE YEAR(CROP_DATA.YEAR)=YEAR(MONTHLY_FX.DATE) AND MONTH(CROP_DATA.YEAR)=MONTH(MONTHLY_FX.DATE)
    LIMIT 5;"
view <- sqlQuery(conn,query)
view

#That's it!

close(conn)