/*
 * eif_postgresql.h:	Eiffel PostgreSQL stub library
 *
 * Copyright:	(C) 2025 by EiffelStore contributors
 *
 */

#ifndef __eif_postgresql_h__
#define __eif_postgresql_h__
#include <libpq-fe.h>

#include "eif_macros.h"

/* Type macros */
#define EIF_C_UNKNOWN_TYPE		-1
#define EIF_C_NULL_TYPE			0
#define EIF_C_STRING_TYPE		1
#define EIF_C_WSTRING_TYPE		2
#define EIF_C_INTEGER_32_TYPE	3
#define EIF_C_INTEGER_16_TYPE	4
#define EIF_C_INTEGER_64_TYPE	5
#define EIF_C_DATE_TYPE			6
#define EIF_C_TIME_TYPE			7
#define EIF_C_REAL_32_TYPE		8
#define EIF_C_REAL_64_TYPE		9
#define EIF_C_BOOLEAN_TYPE		10
#define EIF_C_CHARACTER_TYPE	11
#define EIF_C_DECIMAL_TYPE		12

/* Public functions */
extern PGconn *eif_pq_connect(const char *user, const char *pass, const char *host, int port, const char *dbname);
extern PGconn *eif_pq_connect_string(const char *conninfo);
extern void eif_pq_disconnect(PGconn *conn);
extern int eif_pq_status(PGconn *conn);

extern PGresult *eif_pq_prepare(PGconn *conn, const char *stmt_name, const char *query, int n_params);
extern PGresult *eif_pq_exec_prepared(PGconn *conn, const char *stmt_name, int n_params, 
	const char * const *param_values, const int *param_lengths, const int *param_formats);
extern PGresult *eif_pq_exec(PGconn *conn, const char *command);
extern void eif_pq_clear(PGresult *res);

extern int eif_pq_result_status(PGresult *res);
extern int eif_pq_cmd_tuples(PGresult *res);
extern int eif_pq_ntuples(PGresult *res);
extern int eif_pq_nfields(PGresult *res);
extern int eif_pq_column_name(PGresult *res, int column_number, char *buffer, int buffer_size);
extern int eif_pq_column_type(PGresult *res, int column_number);
extern int eif_pq_column_data(PGresult *res, int row, int column, char *buffer, int buffer_size);
extern int eif_pq_is_null_data(PGresult *res, int row, int column);
extern int eif_pq_data_length(PGresult *res, int row, int column);

extern long eif_pq_integer_data(PGresult *res, int row, int column);
extern int eif_pq_integer_16_data(PGresult *res, int row, int column);
extern EIF_NATURAL_64 eif_pq_integer_64_data(PGresult *res, int row, int column);
extern float eif_pq_real_data(PGresult *res, int row, int column);
extern double eif_pq_float_data(PGresult *res, int row, int column);

extern char *eif_pq_get_error_message(PGconn *conn);
extern char *eif_pq_get_result_error(PGresult *res);
extern int eif_pq_get_error_code(PGconn *conn);

extern int eif_pq_begin(PGconn *conn);
extern int eif_pq_commit(PGconn *conn);
extern int eif_pq_rollback(PGconn *conn);

#endif /* __eif_postgresql_h__ */
