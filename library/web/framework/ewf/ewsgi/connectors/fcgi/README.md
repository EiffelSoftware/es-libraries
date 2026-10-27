# FastCGI connector (pure Eiffel)

FastCGI connector for EiffelWeb, written in Eiffel on top of EiffelNet.
It replaces the `libfcgi` connector: no C library to build or ship.

- Implements the FastCGI 1.0 Responder role.
- Supports persistent connections (`FCGI_KEEP_CONN`) and `FCGI_GET_VALUES`.
- Processes connections concurrently (thread pool or SCOOP, using the `httpd` library).
- Does not multiplex requests on one connection (`FCGI_MPXS_CONNS=0`), like most FastCGI servers.

## Usage

In the application `.ecf`, replace the `default_libfcgi` (or `default_standalone`) library with:

```xml
<library name="default_fcgi" location="$ISE_LIBRARY\contrib\library\web\framework\ewf\wsf\default\fcgi.ecf"/>
```

The application code (`WSF_DEFAULT_SERVICE [G]` and `WSF_EXECUTION`) does not change.

### Options

Set the options with `set_service_option`, or in an ini file through `WSF_SERVICE_LAUNCHER_OPTIONS_FROM_INI`:

| Option | Default | Description |
|---|---|---|
| `port` | `9000` | TCP port. |
| `server_name` | `127.0.0.1` | Address to bind. Use `0.0.0.0` inside a container. |
| `base` | | Base URL, used to compute `PATH_INFO` when the web server does not send it. |
| `max_concurrent_connections` | `100` | Must be greater than the number of persistent connections the web server keeps open. |
| `keep_alive_timeout` | `75` | Seconds to wait for the next request on a persistent connection. Must be greater than the web server's keepalive timeout. |
| `socket_timeout`, `socket_recv_timeout` | `60` | Socket timeouts, in seconds. |
| `ignore_inherited_socket` | `false` | If true, always listen on the TCP port. |
| `verbose`, `verbose_level` | | Logging. |

## The two modes

1. **Spawned by the web server (Unix):** if stdin (fd 0) is a listening socket,
   the application accepts connections on it. The web server then manages the processes:
   it starts them, restarts them, and changes their number.
   This mode works with Apache `mod_fcgid`, lighttpd and `spawn-fcgi`.
2. **TCP:** otherwise the application listens on `server_name:port`.
   This mode works with nginx and Apache `mod_proxy_fcgi`.
   You start and supervise the process yourself, for example with systemd, Docker or a Windows service.

## Web server configuration

### nginx

```nginx
upstream eiffel_app {
    server 127.0.0.1:9000;
    keepalive 8;                      # keep less than max_concurrent_connections
}
server {
    listen 80;
    location / {
        include fastcgi_params;       # PATH_INFO is computed from REQUEST_URI if missing
        fastcgi_pass eiffel_app;
        fastcgi_keep_conn on;
    }
}
```

If the application is mounted under a prefix, for example `location /app/`, set the `base` option to `/app`.

### Apache with mod_fcgid (Apache starts and manages the processes, Unix)

```apache
LoadModule fcgid_module modules/mod_fcgid.so
<VirtualHost *:80>
    ScriptAlias /app /var/www/app/app.fcgi
    <Directory /var/www/app>
        SetHandler fcgid-script
        Options +ExecCGI
        Require all granted
    </Directory>
    FcgidMaxProcessesPerClass 4
    FcgidIdleTimeout 300
</VirtualHost>
```

`app.fcgi` is the finalized Eiffel executable. Apache passes `SCRIPT_NAME=/app` and `PATH_INFO`.

### Apache with mod_proxy_fcgi (TCP)

```apache
ProxyPass "/app/" "fcgi://127.0.0.1:9000/" enablereuse=on
```

### lighttpd (lighttpd starts the processes)

```lighttpd
server.modules += ( "mod_fastcgi" )
fastcgi.server = ( "/app" => ((
    "socket"    => "/tmp/eiffel-app.sock",
    "bin-path"  => "/var/www/app/app.fcgi",
    "max-procs" => 2,
    "check-local" => "disable"
)))
```

## Limitations

- On Windows, servers that start FastCGI applications (`mod_fcgid`, IIS) pass a named pipe, which is not supported.
  On Windows, use TCP mode.
- Only the Responder role is supported; Authorizer and Filter requests are refused with `FCGI_UNKNOWN_ROLE`.
