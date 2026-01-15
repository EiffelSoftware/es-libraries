/*
 * eif_postgresql.c:	Eiffel PostgreSQL stub library
 *
 * Copyright:	(C) 2025 by EiffelStore contributors
 *
 */

#include "eif_config.h"

#ifdef EIF_WINDOWS
#include <winsock2.h>
#endif

/* System Include Files */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Project Include File */
#include "eif_except.h"
#include "eif_postgresql.h"

/*
 * Function:	PGconn *eif_pq_connect(const char *user, const char *pass,
 *					const char *host, int port, const char *dbname)
 * Description:	Connect to the given PostgreSQL server using the provided credentials
 * Arguments:	const char *user:	Username to connect as
 *				const char *pass:	Password for identification
 *				const char *host:	PostgreSQL Server hostname
 *				int port:			Port to connect to PostgreSQL Server
 *				const char *dbname:	Database to be selected
 * Returns:		Pointer to PGconn structure as returned by PQconnectdb(...)
 */
PGconn *eif_pq_connect(const char *user, const char *pass, const char *host, int port, const char *dbname)
{
	char conninfo[512];
	PGconn *conn;
	
	snprintf(conninfo, sizeof(conninfo), 
		"host='%s' port=%d dbname='%s' user='%s' password='%s'",
		host ? host : "localhost", 
		port > 0 ? port : 5432, 
		dbname ? dbname : "",
		user ? user : "",
		pass ? pass : "");
	
	conn = PQconnectdb(conninfo);
	
	return conn;
}

/*
 * Function:	PGconn *eif_pq_connect_string(const char *conninfo)
 * Description:	Connect to PostgreSQL using a connection string
 * Arguments:	const char *conninfo:	PostgreSQL connection string
 *                                      Example: "host=localhost port=5432 dbname=mydb user=myuser password=mypass"
 * Returns:		Pointer to PGconn structure as returned by PQconnectdb(...)
 */
PGconn *eif_pq_connect_string(const char *conninfo)
{
	if (conninfo == NULL || conninfo[0] == '\0')
		return NULL;
	
	return PQconnectdb(conninfo);
}


/*
 * Function:	void eif_pq_disconnect(PGconn *conn)
 * Description:	Disconnect from the given PostgreSQL Server
 * Arguments:	PGconn *conn:	Pointer to PGconn structure
 * Returns:		<none>
 */
void eif_pq_disconnect(PGconn *conn)
{
	PQfinish(conn);
}

/*
 * Function:	int eif_pq_status(PGconn *conn)
 * Description:	Get connection status
 * Arguments:	PGconn *conn:	Pointer to PGconn structure
 * Returns:		CONNECTION_OK if connected, CONNECTION_BAD otherwise
 */
int eif_pq_status(PGconn *conn)
{
	return PQstatus(conn);
}

/*
 * Function:	PGresult *eif_pq_prepare(PGconn *conn, const char *stmt_name,
 *					const char *query, int n_params)
 * Description:	Prepare a SQL statement for execution
 * Arguments:	PGconn *conn:			Connection pointer
 *				const char *stmt_name:	Name for the prepared statement
 *				const char *query:		SQL query with $1, $2, etc. placeholders
 *				int n_params:			Number of parameters
 * Returns:		PGresult pointer
 */
PGresult *eif_pq_prepare(PGconn *conn, const char *stmt_name, const char *query, int n_params)
{
	return PQprepare(conn, stmt_name, query, n_params, NULL);
}

/*
 * Function:	PGresult *eif_pq_exec_prepared(PGconn *conn, const char *stmt_name,
 *					int n_params, const char * const *param_values,
 *					const int *param_lengths, const int *param_formats)
 * Description:	Execute a prepared statement with parameters
 * Arguments:	PGconn *conn:				Connection pointer
 *				const char *stmt_name:		Prepared statement name
 *				int n_params:				Number of parameters
 *				const char * const *param_values: Array of parameter values
 *				const int *param_lengths:	Array of parameter lengths
 *				const int *param_formats:	Array of parameter formats (0=text, 1=binary)
 * Returns:		PGresult pointer
 */
PGresult *eif_pq_exec_prepared(PGconn *conn, const char *stmt_name, int n_params,
	const char * const *param_values, const int *param_lengths, const int *param_formats)
{
	return PQexecPrepared(conn, stmt_name, n_params, param_values, 
		param_lengths, param_formats, 0);
}

/*
 * Function:	PGresult *eif_pq_exec(PGconn *conn, const char *command)
 * Description:	Execute a simple SQL command
 * Arguments:	PGconn *conn:			Connection pointer
 *				const char *command:	SQL command to execute
 * Returns:		PGresult pointer
 */
PGresult *eif_pq_exec(PGconn *conn, const char *command)
{
	return PQexec(conn, command);
}

/*
 * Function:	void eif_pq_clear(PGresult *res)
 * Description:	Free result set resources
 * Arguments:	PGresult *res:	Result set pointer
 * Returns:		<none>
 */
void eif_pq_clear(PGresult *res)
{
	PQclear(res);
}

/*
 * Function:	int eif_pq_result_status(PGresult *res)
 * Description:	Get result status
 * Arguments:	PGresult *res:	Result set pointer
 * Returns:		Status code (PGRES_COMMAND_OK, PGRES_TUPLES_OK, etc.)
 */
int eif_pq_result_status(PGresult *res)
{
	if (res == NULL)
		return -1;
	return PQresultStatus(res);
}

/*
 * Function:	int eif_pq_cmd_tuples(PGresult *res)
 * Description:	Get number of rows affected by SQL command
 * Arguments:	PGresult *res:	Result set pointer
 * Returns:		Number of affected rows from INSERT, UPDATE, DELETE, etc.
 *              Returns 0 if the result is from a SELECT or empty query
 */
int eif_pq_cmd_tuples(PGresult *res)
{
	const char *tuples_str;
	
	if (res == NULL)
		return 0;
	
	/* PQcmdTuples returns a string with the number of affected rows */
	tuples_str = PQcmdTuples(res);
	
	if (tuples_str == NULL || tuples_str[0] == '\0')
		return 0;
	
	return atoi(tuples_str);
}


/*
 * Function:	int eif_pq_ntuples(PGresult *res)
 * Description:	Get number of rows in result set
 * Arguments:	PGresult *res:	Result set pointer
 * Returns:		Number of rows
 */
int eif_pq_ntuples(PGresult *res)
{
	if (res == NULL)
		return 0;
	return PQntuples(res);
}

/*
 * Function:	int eif_pq_nfields(PGresult *res)
 * Description:	Get number of columns in result set
 * Arguments:	PGresult *res:	Result set pointer
 * Returns:		Number of columns
 */
int eif_pq_nfields(PGresult *res)
{
	if (res == NULL)
		return 0;
	return PQnfields(res);
}

/*
 * Function:	int eif_pq_column_name(PGresult *res, int column_number,
 *					char *buffer, int buffer_size)
 * Description:	Get column name
 * Arguments:	PGresult *res:		Result set pointer
 *				int column_number:	Column index (0-based)
 *				char *buffer:		Buffer to store column name
 *				int buffer_size:	Size of buffer
 * Returns:		Length of column name
 */
int eif_pq_column_name(PGresult *res, int column_number, char *buffer, int buffer_size)
{
	const char *name;
	size_t len;
	
	if (res == NULL || column_number < 0 || column_number >= PQnfields(res))
		return 0;
	
	name = PQfname(res, column_number);
	len = strlen(name);
	
	if (len < buffer_size) {
		memcpy(buffer, name, len);
		return (int)len;
	} else {
		memcpy(buffer, name, (size_t)(buffer_size - 1));
		return buffer_size - 1;
	}
}

/*
 * Function:	int eif_pq_column_type(PGresult *res, int column_number)
 * Description:	Get Eiffel type code for column
 * Arguments:	PGresult *res:		Result set pointer
 *				int column_number:	Column index (0-based)
 * Returns:		Eiffel type code
 */
int eif_pq_column_type(PGresult *res, int column_number)
{
	Oid type_oid;
	
	if (res == NULL || column_number < 0 || column_number >= PQnfields(res))
		return EIF_C_UNKNOWN_TYPE;
	
	type_oid = PQftype(res, column_number);
	
	/* Map PostgreSQL OIDs to Eiffel types */
	switch (type_oid) {
		case 16:	/* BOOLOID */
			return EIF_C_BOOLEAN_TYPE;
		case 20:	/* INT8OID (bigint) */
			return EIF_C_INTEGER_64_TYPE;
		case 21:	/* INT2OID (smallint) */
			return EIF_C_INTEGER_16_TYPE;
		case 23:	/* INT4OID (integer) */
			return EIF_C_INTEGER_32_TYPE;
		case 700:	/* FLOAT4OID (real) */
			return EIF_C_REAL_32_TYPE;
		case 701:	/* FLOAT8OID (double precision) */
			return EIF_C_REAL_64_TYPE;
		case 1043:	/* VARCHAROID */
		case 25:	/* TEXTOID */
		case 1042:	/* BPCHAROID (char) */
			return EIF_C_WSTRING_TYPE;
		case 1082:	/* DATEOID */
		case 1083:	/* TIMEOID */
		case 1114:	/* TIMESTAMPOID */
		case 1184:	/* TIMESTAMPTZOID */
			return EIF_C_DATE_TYPE;
		case 1700:	/* NUMERICOID (decimal) */
			return EIF_C_DECIMAL_TYPE;
		case 17:	/* BYTEAOID (binary data) */
			return EIF_C_STRING_TYPE;
		default:
			return EIF_C_WSTRING_TYPE;	/* Default to string */
	}
}

/*
 * Function:	int eif_pq_column_data(PGresult *res, int row, int column,
 *					char *buffer, int buffer_size)
 * Description:	Get field value as string
 * Arguments:	PGresult *res:	Result set pointer
 *				int row:		Row index (0-based)
 *				int column:		Column index (0-based)
 *				char *buffer:	Buffer to store value
 *				int buffer_size: Size of buffer
 * Returns:		Length of data copied
 */
int eif_pq_column_data(PGresult *res, int row, int column, char *buffer, int buffer_size)
{
	const char *value;
	int len;
	
	if (res == NULL || PQgetisnull(res, row, column))
		return 0;
	
	value = PQgetvalue(res, row, column);
	len = PQgetlength(res, row, column);
	
	if (len < buffer_size) {
		memcpy(buffer, value, len);
		return len;
	} else {
		memcpy(buffer, value, buffer_size - 1);
		return buffer_size - 1;
	}
}

/*
 * Function:	int eif_pq_is_null_data(PGresult *res, int row, int column)
 * Description:	Check if field is NULL
 * Arguments:	PGresult *res:	Result set pointer
 *				int row:		Row index (0-based)
 *				int column:		Column index (0-based)
 * Returns:		1 if NULL, 0 otherwise
 */
int eif_pq_is_null_data(PGresult *res, int row, int column)
{
	if (res == NULL)
		return 1;
	return PQgetisnull(res, row, column);
}

/*
 * Function:	int eif_pq_data_length(PGresult *res, int row, int column)
 * Description:	Get field data length
 * Arguments:	PGresult *res:	Result set pointer
 *				int row:		Row index (0-based)
 *				int column:		Column index (0-based)
 * Returns:		Data length in bytes
 */
int eif_pq_data_length(PGresult *res, int row, int column)
{
	if (res == NULL)
		return 0;
	return PQgetlength(res, row, column);
}

/*
 * Function:	long eif_pq_integer_data(PGresult *res, int row, int column)
 * Description:	Get integer value from field
 * Arguments:	PGresult *res:	Result set pointer
 *				int row:		Row index
 *				int column:		Column index
 * Returns:		Integer value
 */
long eif_pq_integer_data(PGresult *res, int row, int column)
{
	const char *value;
	
	if (res == NULL || PQgetisnull(res, row, column))
		return 0;
	
	value = PQgetvalue(res, row, column);
	return atol(value);
}

/*
 * Function:	int eif_pq_integer_16_data(PGresult *res, int row, int column)
 * Description:	Get 16-bit integer value from field
 * Arguments:	PGresult *res:	Result set pointer
 *				int row:		Row index
 *				int column:		Column index
 * Returns:		16-bit integer value
 */
int eif_pq_integer_16_data(PGresult *res, int row, int column)
{
	const char *value;
	
	if (res == NULL || PQgetisnull(res, row, column))
		return 0;
	
	value = PQgetvalue(res, row, column);
	return (int)atoi(value);
}

/*
 * Function:	EIF_NATURAL_64 eif_pq_integer_64_data(PGresult *res, int row, int column)
 * Description:	Get 64-bit integer value from field
 * Arguments:	PGresult *res:	Result set pointer
 *				int row:		Row index
 *				int column:		Column index
 * Returns:		64-bit integer value
 */
EIF_NATURAL_64 eif_pq_integer_64_data(PGresult *res, int row, int column)
{
	const char *value;
	
	if (res == NULL || PQgetisnull(res, row, column))
		return 0;
	
	value = PQgetvalue(res, row, column);
#ifdef EIF_WINDOWS
	return (EIF_NATURAL_64)_atoi64(value);
#else
	return (EIF_NATURAL_64)strtoll(value, NULL, 10);
#endif
}

/*
 * Function:	float eif_pq_real_data(PGresult *res, int row, int column)
 * Description:	Get float value from field
 * Arguments:	PGresult *res:	Result set pointer
 *				int row:		Row index
 *				int column:		Column index
 * Returns:		Float value
 */
float eif_pq_real_data(PGresult *res, int row, int column)
{
	const char *value;
	
	if (res == NULL || PQgetisnull(res, row, column))
		return 0.0;
	
	value = PQgetvalue(res, row, column);
	return (float)atof(value);
}

/*
 * Function:	double eif_pq_float_data(PGresult *res, int row, int column)
 * Description:	Get double value from field
 * Arguments:	PGresult *res:	Result set pointer
 *				int row:		Row index
 *				int column:		Column index
 * Returns:		Double value
 */
double eif_pq_float_data(PGresult *res, int row, int column)
{
	const char *value;
	
	if (res == NULL || PQgetisnull(res, row, column))
		return 0.0;
	
	value = PQgetvalue(res, row, column);
	return strtod(value, NULL);
}

/*
 * Function:	char *eif_pq_get_error_message(PGconn *conn)
 * Description:	Get connection error message
 * Arguments:	PGconn *conn:	Connection pointer
 * Returns:		Error message string
 */
char *eif_pq_get_error_message(PGconn *conn)
{
	if (conn == NULL)
		return "";
	return PQerrorMessage(conn);
}

/*
 * Function:	char *eif_pq_get_result_error(PGresult *res)
 * Description:	Get result error message
 * Arguments:	PGresult *res:	Result set pointer
 * Returns:		Error message string
 */
char *eif_pq_get_result_error(PGresult *res)
{
	if (res == NULL)
		return "";
	return PQresultErrorMessage(res);
}

/*
 * Function:	int eif_pq_get_error_code(PGconn *conn)
 * Description:	Get error code (for compatibility, PostgreSQL doesn't use numeric codes like MySQL)
 * Arguments:	PGconn *conn:	Connection pointer
 * Returns:		0 if no error, 1 if error
 */
int eif_pq_get_error_code(PGconn *conn)
{
	if (conn == NULL)
		return 1;
	return (PQstatus(conn) == CONNECTION_OK) ? 0 : 1;
}

/*
 * Function:	int eif_pq_begin(PGconn *conn)
 * Description:	Begin transaction
 * Arguments:	PGconn *conn:	Connection pointer
 * Returns:		0 on success, 1 on error
 */
int eif_pq_begin(PGconn *conn)
{
	PGresult *res = PQexec(conn, "BEGIN");
	int status = PQresultStatus(res);
	PQclear(res);
	return (status == PGRES_COMMAND_OK) ? 0 : 1;
}

/*
 * Function:	int eif_pq_commit(PGconn *conn)
 * Description:	Commit transaction
 * Arguments:	PGconn *conn:	Connection pointer
 * Returns:		0 on success, 1 on error
 */
int eif_pq_commit(PGconn *conn)
{
	PGresult *res = PQexec(conn, "COMMIT");
	int status = PQresultStatus(res);
	PQclear(res);
	return (status == PGRES_COMMAND_OK) ? 0 : 1;
}

/*
 * Function:	int eif_pq_rollback(PGconn *conn)
 * Description:	Rollback transaction
 * Arguments:	PGconn *conn:	Connection pointer
 * Returns:		0 on success, 1 on error
 */
int eif_pq_rollback(PGconn *conn)
{
	PGresult *res = PQexec(conn, "ROLLBACK");
	int status = PQresultStatus(res);
	PQclear(res);
	return (status == PGRES_COMMAND_OK) ? 0 : 1;
}
