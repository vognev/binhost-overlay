# @ECLASS: gobject-introspection.eclass
# @SUPPORTED_EAPIS: 7 8 9
# @BLURB: Helper functions for (cross)building gobject-introspection
# @DESCRIPTION:
# This eclass provides common functions to run gobject-introspection tools in a cross-compilation environment.

case ${EAPI} in
	7|8|9) ;;
	*) die "${ECLASS}: EAPI ${EAPI:-0} not supported" ;;
esac

inherit sysroot

cross_shim_help2man()
{
    mkdir -p "${T}/shims"

    install -m0755 /dev/stdin "${T}/shims/help2man" <<-EOF
        #!/bin/sh

        HELP2MAN=/usr/bin/help2man
        SYSROOT_RUN_PREFIXED=$(sysroot_make_run_prefixed)

        exe=""
        for arg in "\$@"; do
            if [ -x "\${arg}" ]; then
                if [ -z "\${exe}" ]; then
                    exe="\${arg}"
                else
                    echo "bashrc-cross: Found multiple executables." >&2
                    exit 1
                fi
            else
                set -- "\$@" "\${arg}"
            fi
            shift
        done

        if [ -z "\${exe}" ]; then
            exec "\${HELP2MAN}" "\$@"
        fi

        temp_file=\$(mktemp) || exit 1
        trap 'rm -f "\$temp_file"' EXIT

        echo '#!/bin/sh' > "\$temp_file"
        echo "exec \"\${SYSROOT_RUN_PREFIXED}\" \"\${exe}\" \"\\\$@\"" >> "\$temp_file"
        chmod +x "\$temp_file"

        exec "\${HELP2MAN}" "\$@" "\$temp_file"
EOF

    einfo "bashrc-cross: Injected g-ir-scanner wrapper via runtime check"
}
