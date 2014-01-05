;; Use this file with Nu (http://programming.nu) to build a Mac OS X version of the RadForce SDK.

;; source files
(set @m_files     (filelist "^Common/.*.m$"))

(set @cc "clang")

(set SYSTEM ((NSString stringWithShellCommand:"uname") chomp))
(case SYSTEM
      ("Darwin"
               (set @arch (list "x86_64"))
               (set @cflags "-g -fobjc-arc -DDARWIN -DLEVELDB_PLATFORM_POSIX -DOS_MACOSX -I ./Common/RadHTTP -I ./Common/RadCrypto ")
               (set @ldflags "-framework Foundation"))
      (else nil))

;; framework description
(set @framework "RadForce")
(set @framework_identifier "com.radtastical.radforce")
(set @framework_creator_code "????")

(compilation-tasks)
(framework-tasks)

(task "clobber" => "clean" is
      (SH "rm -rf #{@framework_dir}"))

(task "default" => "framework")

