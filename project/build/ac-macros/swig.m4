dnl
dnl Test for swig and the swig languages
dnl
AC_DEFUN([MY_TEST_SWIG], [
  AC_CACHE_VAL(my_cv_swig_vers, [
    my_cv_swig_vers=NONE
    default_search_path="/usr/local/include /usr/include /opt/local/include /opt/local"
    dnl check is the plain-text version of the required version
    check="1.3.33"

    set `perl -e "@v = split('\\.', '$check'); print \"@v\";"`
    check_major=$[1]
    check_minor=$[2]
    check_release=$[3]
    SWIG_OSNAME=`perl -e 'use Config; print $Config{osname};'`

    HAVE_JAVA=0
    HAVE_MCS=0
    HAVE_PERL=0
    HAVE_PHP=0
    HAVE_PYTHON=0
    HAVE_RUBY=0
    JAVA_INCLUDES=
    USE_SWIG_BINDINGS=
    my_have_java=no
    my_have_mcs=no
    my_have_perl=no
    my_have_php=no
    my_have_python=no
    my_have_ruby=no
    my_use_swig_bindings=no

    AC_CHECK_PROG(SWIG, swig, swig, no)
    if test "$SWIG" != "no"; then
      AC_MSG_CHECKING([for swig >= $check])

      dnl Sorry, I never professed to being a perl programmer
      ver=`$SWIG -version | tr "\n" " "`
      ver=`perl -e "@v = split(' ', '$ver');  print \"@v[[2]]\";"`
      set `perl -e "@v = split('\\.' , '$ver'); print \"@v\";"`

      ver_major=$[1]
      ver_minor=$[2]
      ver_release=$[3]

      ok=`expr \
          $ver_major \> $check_major \| \
          $ver_major \= $check_major \& \
          $ver_minor \> $check_minor \| \
          $ver_minor \= $check_minor \& \
          $ver_release \>\= $check_release `                         

      if test "$ok" = "1"; then
        my_cv_swig_vers="$ver"
        AC_MSG_RESULT([$my_cv_swig_vers])

        USE_SWIG_BINDINGS=1
        my_use_swig_bindings=yes

        dnl
        dnl Check to see if we can build for csharp
        dnl
        if test "$my_use_mcs" = "yes"; then
            AC_CHECK_PROG(MCS, mcs, mcs, no)
            AC_CHECK_PROG(GMCS, gmcs, gmcs, no)
            generics=`expr \
                $ver_major \> 1 \| \
                $ver_major \= 1 \& \
                $ver_minor \> 3 \| \
                $ver_minor \= 3 \& \
                $ver_release \>\= 39 `                         

            if test "$generics" = "1"; then
                if test "$GMCS" != "no"; then
                    MCS=GMCS
                fi
            fi
            if test "$MCS" != "no"; then
                HAVE_MCS=1
                my_have_mcs=yes
            fi
        fi

        dnl
        dnl Check to see if we can build for java
        dnl
        if test "$my_use_java" = "yes"; then
            AC_CHECK_PROG(JAVA, java, java, no)
            if test "$JAVA" != "no"; then
                AC_CHECK_PROG(JAVAC, javac, javac, no)
                if test "$JAVAC" != "no"; then
                    AC_CHECK_PROG(JAR, jar, jar, no)
                    if test "$JAR" != "no"; then
                        rm -f JavaHome.java JavaHome.class
                        cat > JavaHome.java <<EOF
                            public class JavaHome
                            {
                                public static void main(String[[]] args)
                                {
                                    System.out.println(System.getProperty("java.home"));
                                }
                            }
EOF
                        if "$JAVAC" JavaHome.java ; then
                            java_home=`java JavaHome`
                        fi
                        rm -f JavaHome.java JavaHome.class

                        if test "$SWIG_OSNAME" = "darwin"; then
                            JAVA_INCLUDES=-I`javaconfig Headers`
                        else
                            JAVA_INCLUDES=
                            AC_ARG_WITH([java-prefix], 
                                AC_HELP_STRING(
                                        [--with-java-prefix=PATH],
                                        [find the Java headers and libraries in `PATH/include` and  `PATH/lib`.
                                        By default, checks in $default_search_path
                                ]),
                                java_prefixes="$withval",
                                java_prefixes="$default_search_path $java_home/include $java_home/../include")
                            for java_prefix in $java_prefixes
                            do
                                jni_h="$java_prefix/jni.h"
                                AC_CHECK_FILE([$jni_h], [my_jni_h=$jni_h])
                                test -n "$my_jni_h" && break
                            done
                            if test -n "$my_jni_h"; then
                                JAVA_INCLUDES="-I$java_prefix -I`dirname $java_prefix/*/jni_md.h`"
                            fi
                        fi
                    fi
                fi
            fi

            if test -n "$JAVA_INCLUDES"; then
                    HAVE_JAVA=1
                    my_have_java=yes
            fi
        fi

        dnl
        dnl Check to see if we should build for perl
        dnl
        if test "$my_use_perl" = "yes"; then
            perl_h=`perl -e 'use Config; print $Config{archlib};'`
            perl_h=$perl_h/CORE/perl.h
            AC_CHECK_FILE([$perl_h], [my_perl_h=$perl_h])
            if test -n "$my_perl_h"; then
                HAVE_PERL=1
                my_have_perl=yes
            fi
        fi

        dnl
        dnl Check to see if we can build for php
        dnl
        if test "$my_use_php" = "yes"; then
            AC_CHECK_PROG(PHP, php, php, no)
            if test "$PHP" != "no"; then
                for php_prefix in $default_search_path
                do
                    php_h="$php_prefix/php/main/php.h"
                    zend_h="$php_prefix/php/Zend/zend.h"
                    AC_CHECK_FILE([$php_h], [my_php_h=$php_h])
                    AC_CHECK_FILE([$zend_h], [my_zend_h=$zend_h])
                    test -n "$my_php_h" && break
                    test -n "$my_zend_h" && break
                done
                if test -n "$my_php_h"; then
                    if test -n "$my_zend_h"; then
                        HAVE_PHP=1
                        my_have_php=yes
                    fi
                fi
            fi
        fi

        dnl
        dnl Check to see if we can build for python
        dnl
        if test "$my_use_python" = "yes"; then
            AC_CHECK_PROG(PYTHON, python, python, no)
            if test "$PYTHON" != "no"; then
                python_version=`python -c "import sys; print sys.version[[:3]]"`
                python_prefix=`python -c "import sys; print sys.prefix"`
                python_h="$python_prefix/include/python$python_version/Python.h"
                AC_CHECK_FILE([$python_h], [my_python_h=$python_h])

                if test -n "$my_python_h"; then
                    HAVE_PYTHON=1
                    my_have_python=yes
                fi
            fi
        fi

        dnl
        dnl Check to see if we can build for ruby
        dnl
        if test "$my_use_ruby" = "yes"; then
            AC_CHECK_PROG(RUBY, ruby, ruby, no)
            if test "$RUBY" != "no"; then
                ruby_prefix=`ruby -e "require 'rbconfig.rb'; include RbConfig; puts \"#{CONFIG[\"topdir\"]}\""`
                ruby_h="$ruby_prefix/ruby.h"
                AC_CHECK_FILE([$ruby_h], [my_ruby_h=$ruby_h])

                if test -n "$my_ruby_h"; then
                    HAVE_RUBY=1
                    my_have_ruby=yes
                fi
            fi
        fi

      else
        AC_MSG_RESULT(FAILED)
        AC_MSG_WARN([$ver is too old. Need version $check or higher.])
      fi
    fi
  ])

  AC_SUBST(USE_SWIG_BINDINGS)
  AC_SUBST(SWIG)
  AC_SUBST(HAVE_JAVA)
  AC_SUBST(JAVA)
  AC_SUBST(JAVAC)
  AC_SUBST(JAR)
  AC_SUBST(JAVA_INCLUDES)
  AC_SUBST(HAVE_MCS)
  AC_SUBST(MCS)
  AC_SUBST(HAVE_PERL)
  AC_SUBST(HAVE_PHP)
  AC_SUBST(PHP)
  AC_SUBST(HAVE_PYTHON)
  AC_SUBST(PYTHON)
  AC_SUBST(HAVE_RUBY)
  AC_SUBST(RUBY)
])
