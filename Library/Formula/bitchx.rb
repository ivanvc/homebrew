require 'formula'

class Bitchx <Formula
  url 'http://downloads.sourceforge.net/project/bitchx/ircii-pana/ircii-pana-1.1/ircii-pana-1.1-final.tar.gz?use_mirror=superb-sea2'
  version '1.1-final'
  homepage 'http://bitchx.org/'
  md5 '611d2dda222f00c10140236f4c331572'

# depends_on 'cmake'

  def install
    ENV.append "CFLAGS", "-DBIND_8_COMPAT"
    system "./configure", 
           "--prefix=#{prefix}",
           "--without-gtk",
           "--without-ssl",
           "--with-tgetent",
           "--with-plugins"
    
    system "make install"
  end
  
  def patches
    { :p0 => DATA }
  end
end
__END__
--- dll/aim/toc/toc.h.orig	2010-04-08 11:35:43.000000000 -0500
+++ dll/aim/toc/toc.h	2010-04-08 11:36:13.000000000 -0500
@@ -150,9 +150,6 @@
 void parse_toc_buddy_list(char *);
 void translate_toc_error_code(char *c);
 
-extern int toc_fd;
-extern int seqno;
-extern unsigned int peer_ver;
 extern int state;
 /* extern int inpa; */
 
@@ -207,9 +204,7 @@
 void serv_set_away(char *message);
 
 extern int idle_timer;
-extern time_t lastsent;
 extern time_t login_time;
-extern struct timeval lag_tv;
 extern int is_idle;
 extern int lag_ms;
 extern int permdeny;

--- include/irc.h.orig	2010-04-08 11:40:38.000000000 -0500
+++ include/irc.h	2010-04-08 11:41:02.000000000 -0500
@@ -283,7 +283,6 @@
 extern	char	wait_nick[];
 extern	char	whois_nick[];
 extern	char	lame_wait_nick[];
-extern	char	**environ;
 extern	int	cuprent_numeric;
 extern	int	quick_startup;
 extern	char	version[];

--- source/bcompat.c.orig	2010-04-08 11:44:06.000000000 -0500
+++ source/bcompat.c	2010-04-08 11:46:44.000000000 -0500
@@ -1011,40 +1011,6 @@
 #include <stddef.h>
 #include <string.h>

-int   bsd_setenv(const char *name, const char *value, int rewrite);
-
-/*
- * __findenv --
- *	Returns pointer to value associated with name, if any, else NULL.
- *	Sets offset to be the offset of the name/value combination in the
- *	environmental array, for use by setenv(3) and unsetenv(3).
- *	Explicitly removes '=' in argument name.
- *
- *	This routine *should* be a static; don't use it.
- */
-__inline__ static char *__findenv(const char *name, int *offset)
-{
-	extern char **environ;
-	register int len, i;
-	register const char *np;
-	register char **p, *cp;
-
-	if (name == NULL || environ == NULL)
-		return (NULL);
-	for (np = name; *np && *np != '='; ++np)
-		continue;
-	len = np - name;
-	for (p = environ; (cp = *p) != NULL; ++p) {
-		for (np = name, i = len; i && *cp; i--)
-			if (*cp++ != *np++)
-				break;
-		if (i == 0 && *cp++ == '=') {
-			*offset = p - environ;
-			return (cp);
-		}
-	}
-	return (NULL);
-}

 /*
  * getenv --
@@ -1052,9 +1018,7 @@
  */
 char *bsd_getenv(const char *name)
 {
-	int offset;
-
-	return (__findenv(name, &offset));
+  return getenv(name);
 }

 /*
@@ -1064,67 +1028,12 @@
  */
 int bsd_setenv(const char *name, const char *value, int rewrite)
 {
-	extern char **environ;
-	static int alloced;			/* if allocated space before */
-	register char *c;
-	int l_value, offset;
-
-	if (*value == '=')			/* no `=' in value */
-		++value;
-	l_value = strlen(value);
-	if ((c = __findenv(name, &offset))) {	/* find if already exists */
-		if (!rewrite)
-			return (0);
-		if (strlen(c) >= l_value) {	/* old larger; copy over */
-			while ( (*c++ = *value++) );
-			return (0);
-		}
-	} else {					/* create new slot */
-		register int cnt;
-		register char **p;
-
-		for (p = environ, cnt = 0; *p; ++p, ++cnt);
-		if (alloced) {			/* just increase size */
-			environ = (char **)realloc((char *)environ,
-			    (size_t)(sizeof(char *) * (cnt + 2)));
-			if (!environ)
-				return (-1);
-		}
-		else {				/* get new space */
-			alloced = 1;		/* copy old entries into it */
-			p = malloc((size_t)(sizeof(char *) * (cnt + 2)));
-			if (!p)
-				return (-1);
-			memcpy(p, environ, cnt * sizeof(char *));
-			environ = p;
-		}
-		environ[cnt + 1] = NULL;
-		offset = cnt;
-	}
-	for (c = (char *)name; *c && *c != '='; ++c);	/* no `=' in name */
-	if (!(environ[offset] =			/* name + `=' + value */
-	    malloc((size_t)((int)(c - name) + l_value + 2))))
-		return (-1);
-	for (c = environ[offset]; (*c = *name++) && *c != '='; ++c);
-	for (*c++ = '='; (*c++ = *value++); );
-	return (0);
+  return setenv(name, value, rewrite);
 }

 int bsd_putenv(const char *str)
 {
-	char *p, *equal;
-	int rval;
-
-	if ((p = strdup(str)) == NULL)
-		return (-1);
-	if ((equal = strchr(p, '=')) == NULL) {
-		free(p);
-		return (-1);
-	}
-	*equal = '\0';
-	rval = bsd_setenv(p, equal + 1, 1);
-	free(p);
-	return (rval);
+  return putenv(str);
 }

 /*
@@ -1133,14 +1042,7 @@
  */
 void bsd_unsetenv(const char *name)
 {
-	extern char **environ;
-	register char **p;
-	int offset;
-
-	while (__findenv(name, &offset))	/* if set multiple times */
-		for (p = &environ[offset];; ++p)
-			if (!(*p = *(p + 1)))
-				break;
+  return unsetenv(name);
 }
 #endif
 /* --- end of env.c --- */

--- source/ctcp.c.orig	2010-04-08 11:49:09.000000000 -0500
+++ source/ctcp.c	2010-04-08 11:49:42.000000000 -0500
@@ -176,7 +176,7 @@
 
 /* CDE do ops and unban logging */
 
-static char	*ctcp_type[] =
+char	*ctcp_type[] =
 {
 	"PRIVMSG",
 	"NOTICE"

--- dll/aim/toc/Makefile.in.orig	2010-04-08 12:07:27.000000000 -0500
+++ dll/aim/toc/Makefile.in	2010-04-08 12:07:59.000000000 -0500
@@ -167,7 +167,7 @@

 libtoc.a: $(LOBJS)
 	ar cru libtoc.a $(LOBJS)
-
+	ranlib libtoc.a
 Makefile: Makefile.in
 	cd $(topdir) \
 	  && ./config.status

--- configure.orig	2010-04-08 12:24:29.000000000 -0500
+++ configure	2010-04-08 12:25:40.000000000 -0500
@@ -12628,6 +12628,9 @@
       BSD/OS-4*)
         SHLIB_LD="$CC -shared"
         ;;
+      Darwin*)
+        SHLIB_LD="$CC -bundle -undefined error"
+        ;;        
       HP-UX-*9* | HP-UX-*10* | HP-UX-*11*)
         SHLIB_CFLAGS="+Z"
         SHLIB_LD="ld"
@@ -13896,6 +13899,9 @@
       BSD/OS-4*)
         SHLIB_LD="$CC -shared"
         ;;
+      Darwin*)
+        SHLIB_LD="$CC -bundle -undefined error"
+        ;;
       HP-UX-*9* | HP-UX-*10* | HP-UX-*11*)
         SHLIB_CFLAGS="+Z"
         SHLIB_LD="ld"

--- include/struct.h.orig	2005-04-03 07:27:25.000000000 -0400
+++ include/struct.h	2005-04-03 07:27:45.000000000 -0400
@@ -1064,7 +1064,6 @@
 	int	delete;
 }	TimerList;
 
-extern TimerList *PendingTimers;
 typedef struct nicktab_stru
 {
 	struct nicktab_stru *next;

--- dll/Makefile.in.orig	2010-04-08 13:15:09.000000000 -0500
+++ dll/Makefile.in	2010-04-08 13:16:11.000000000 -0500
@@ -160,9 +160,9 @@
 
 ## Makefile starts here.
 
-ALL_PLUGINS = abot acro aim amp arcfour autocycle blowfish cavlink cdrom encrypt europa fserv hint identd nap nicklist pkga possum qbx qmail scan wavplay xmms
+ALL_PLUGINS = abot acro aim amp arcfour autocycle blowfish cavlink cdrom encrypt fserv hint identd nap nicklist pkga possum qbx qmail scan wavplay xmms
 
-#PLUGINS = abot acro aim arcfour autocycle blowfish cavlink encrypt europa fserv hint identd nap pkga possum qbx qmail scan wavplay
+#PLUGINS = abot acro aim arcfour autocycle blowfish cavlink encrypt fserv hint identd nap pkga possum qbx qmail scan wavplay
 PLUGINS = @PLUGINS@
 
 .c.o:

--- source/compat.c.orig	2010-04-08 11:44:06.000000000 -0500
+++ source/compat.c	2010-04-08 11:46:44.000000000 -0500
@@ -1011,40 +1011,6 @@
 #include <stddef.h>
 #include <string.h>

-int   bsd_setenv(const char *name, const char *value, int rewrite);
-
-/*
- * __findenv --
- *	Returns pointer to value associated with name, if any, else NULL.
- *	Sets offset to be the offset of the name/value combination in the
- *	environmental array, for use by setenv(3) and unsetenv(3).
- *	Explicitly removes '=' in argument name.
- *
- *	This routine *should* be a static; don't use it.
- */
-__inline__ static char *__findenv(const char *name, int *offset)
-{
-	extern char **environ;
-	register int len, i;
-	register const char *np;
-	register char **p, *cp;
-
-	if (name == NULL || environ == NULL)
-		return (NULL);
-	for (np = name; *np && *np != '='; ++np)
-		continue;
-	len = np - name;
-	for (p = environ; (cp = *p) != NULL; ++p) {
-		for (np = name, i = len; i && *cp; i--)
-			if (*cp++ != *np++)
-				break;
-		if (i == 0 && *cp++ == '=') {
-			*offset = p - environ;
-			return (cp);
-		}
-	}
-	return (NULL);
-}

 /*
  * getenv --
@@ -1052,9 +1018,7 @@
  */
 char *bsd_getenv(const char *name)
 {
-	int offset;
-
-	return (__findenv(name, &offset));
+  return getenv(name);
 }

 /*
@@ -1064,67 +1028,12 @@
  */
 int bsd_setenv(const char *name, const char *value, int rewrite)
 {
-	extern char **environ;
-	static int alloced;			/* if allocated space before */
-	register char *c;
-	int l_value, offset;
-
-	if (*value == '=')			/* no `=' in value */
-		++value;
-	l_value = strlen(value);
-	if ((c = __findenv(name, &offset))) {	/* find if already exists */
-		if (!rewrite)
-			return (0);
-		if (strlen(c) >= l_value) {	/* old larger; copy over */
-			while ( (*c++ = *value++) );
-			return (0);
-		}
-	} else {					/* create new slot */
-		register int cnt;
-		register char **p;
-
-		for (p = environ, cnt = 0; *p; ++p, ++cnt);
-		if (alloced) {			/* just increase size */
-			environ = (char **)realloc((char *)environ,
-			    (size_t)(sizeof(char *) * (cnt + 2)));
-			if (!environ)
-				return (-1);
-		}
-		else {				/* get new space */
-			alloced = 1;		/* copy old entries into it */
-			p = malloc((size_t)(sizeof(char *) * (cnt + 2)));
-			if (!p)
-				return (-1);
-			memcpy(p, environ, cnt * sizeof(char *));
-			environ = p;
-		}
-		environ[cnt + 1] = NULL;
-		offset = cnt;
-	}
-	for (c = (char *)name; *c && *c != '='; ++c);	/* no `=' in name */
-	if (!(environ[offset] =			/* name + `=' + value */
-	    malloc((size_t)((int)(c - name) + l_value + 2))))
-		return (-1);
-	for (c = environ[offset]; (*c = *name++) && *c != '='; ++c);
-	for (*c++ = '='; (*c++ = *value++); );
-	return (0);
+  return setenv(name, value, rewrite);
 }

 int bsd_putenv(const char *str)
 {
-	char *p, *equal;
-	int rval;
-
-	if ((p = strdup(str)) == NULL)
-		return (-1);
-	if ((equal = strchr(p, '=')) == NULL) {
-		free(p);
-		return (-1);
-	}
-	*equal = '\0';
-	rval = bsd_setenv(p, equal + 1, 1);
-	free(p);
-	return (rval);
+  return putenv(str);
 }

 /*
@@ -1133,14 +1042,7 @@
  */
 void bsd_unsetenv(const char *name)
 {
-	extern char **environ;
-	register char **p;
-	int offset;
-
-	while (__findenv(name, &offset))	/* if set multiple times */
-		for (p = &environ[offset];; ++p)
-			if (!(*p = *(p + 1)))
-				break;
+  return unsetenv(name);
 }
 #endif
 /* --- end of env.c --- */
