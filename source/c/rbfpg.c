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


void RbfPGConnect(const char *conn_string)
{
    conn = PQconnectdb(conn_string);
    status = PQstatus(conn);
    if (status == CONNECTION_BAD) 
        error_msg = PQerrorMessage(conn);
    else
        error_msg = NULL;
}

int RbfGetStatus(char *msg)
{
    msg = error_msg;
    return status;
}

void RbfPGExit()
{
    PQfinish(conn);
}
