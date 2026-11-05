Collection of ROC CMS launcher ready to use.

- Include any-safe.ecf to use any of cgi, fcgi, libfcgi or standalone connector.
- Include standalone-safe.ecf to use standalone connector.
- Include fcgi-safe.ecf to use fcgi connector (FastCGI in pure Eiffel).
- Include libfcgi-safe.ecf to use libfcgi connector.
- Include cgi-safe.ecf to use cgi connector.

In application, the root class need to inherit from ROC_CMS_LAUNCHER with adapted CMS_EXECUTION
descendant.

