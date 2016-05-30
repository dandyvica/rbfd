#include <stdio.h>
#include <stdlib.h>

#include <libpq-fe.h>

// compile with
// gcc -c rbfpg.c -I/usr/include/postgresql
//
// and create lib with
// ar rcs ../../lib/librbfpg.a rbfpg.o

// PG connection handle 
PGconn *conn;

// PG error code for any API
int status;

// PG error msg
char *error_msg;

// PG result returned by PG APIs
PGresult *res;

// connect to the PosrgreSQL db
void rbfPGConnect(const char *conn_string)
{
    conn = PQconnectdb(conn_string);
    status = PQstatus(conn);
    if (status != CONNECTION_OK) 
    {
        error_msg = PQerrorMessage(conn);
        printf("%s", error_msg);
    }
    else
        error_msg = NULL;
}

// exec statement
int rbfPGExecStmt(const char *stmt)
{
    res = PQexec(conn, stmt);

    // test result
    status = PQresultStatus(res);
    if (status != PGRES_COMMAND_OK) 
    {
        error_msg = PQerrorMessage(conn);
    }
    return status;
}

// prepare statement
int rbfPGPrepare(const char *stmt, unsigned long nbCols)
{
    res = PQprepare(conn, "INSERT", stmt, (int)nbCols, NULL);
    printf("==========> %s, stmt=<%s>\n ", PQerrorMessage(conn), stmt);
}

// get the current sequence value
char *rbfPGGetSeq()
{
    PGresult *res = PQexec(conn, "SELECT LASTVAL()");    

    if (PQresultStatus(res) != PGRES_TUPLES_OK) {

        printf("No data retrieved\n");        
        PQclear(res);
    }    

    return PQgetvalue(res, 0, 0);
}

// return SQL error code and error message
int rbfPGGetStatus()
{
    return status;
}

// get error message fro PG
char *rbfPGGetErrorMsg()
{
    return error_msg;
}

// exit gracefully
void rbfPGExit()
{
    if (res) PQclear(res);
    PQfinish(conn);
}
