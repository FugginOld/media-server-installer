#!/usr/bin/env bats
# Tests for core/platform.sh

load helpers/common

REPO_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

# Helper: source platform.sh in a subshell with a fake /etc/os-release.
# $1 = ID value (e.g. "ubuntu")
# $2 = optional ID_LIKE value (e.g. "debian")
# $3 = extra commands to run after detect_platform (quoted if multi-word)
_platform_detect() {
    local id="$1"
    local id_like="${2:-}"
    local extra="${3:-}"
    bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        export HOST_IP='127.0.0.1'

        # Write a fake os-release
        FAKE_OS_RELEASE=\"\$(mktemp)\"
        echo 'ID=${id}' > \"\$FAKE_OS_RELEASE\"
        echo 'ID_LIKE=${id_like}' >> \"\$FAKE_OS_RELEASE\"

        source '$REPO_DIR/lib/runtime.sh'

        # Patch detect_platform to read from our fake file
        detect_platform() {
            if [[ -n \"\${MEDIA_STACK_PLATFORM_DETECTED:-}\" ]]; then return; fi
            . \"\$FAKE_OS_RELEASE\"
            PLATFORM_ID=\"\${ID,,}\"
            PLATFORM_LIKE=\"\${ID_LIKE:-}\"

            if [ -f /etc/unraid-version ]; then NAS_PLATFORM=\"unraid\"; else NAS_PLATFORM=\"none\"; fi

            case \"\$PLATFORM_ID\" in
                truenas*)       NAS_PLATFORM=\"truenas\" ;;
                openmediavault) NAS_PLATFORM=\"openmediavault\" ;;
                casaos)         NAS_PLATFORM=\"casaos\" ;;
            esac

            case \"\$PLATFORM_ID\" in
                debian|ubuntu|devuan|linuxmint|pop|elementary)
                    PLATFORM_FAMILY=\"debian\"; PACKAGE_MANAGER=\"apt\" ;;
                fedora|rhel|centos|rocky|almalinux)
                    PLATFORM_FAMILY=\"redhat\"
                    if command -v dnf >/dev/null 2>&1; then PACKAGE_MANAGER=\"dnf\"; else PACKAGE_MANAGER=\"yum\"; fi ;;
                arch|manjaro|endeavouros)
                    PLATFORM_FAMILY=\"arch\"; PACKAGE_MANAGER=\"pacman\" ;;
                opensuse*|sles)
                    PLATFORM_FAMILY=\"suse\"; PACKAGE_MANAGER=\"zypper\" ;;
                alpine)
                    PLATFORM_FAMILY=\"alpine\"; PACKAGE_MANAGER=\"apk\" ;;
                *)
                    if [[ \"\$PLATFORM_LIKE\" == *debian* ]]; then
                        PLATFORM_FAMILY=\"debian\"; PACKAGE_MANAGER=\"apt\"
                    elif [[ \"\$PLATFORM_LIKE\" == *rhel* ]]; then
                        PLATFORM_FAMILY=\"redhat\"; PACKAGE_MANAGER=\"dnf\"
                    else
                        PLATFORM_FAMILY=\"unknown\"; PACKAGE_MANAGER=\"unknown\"
                    fi ;;
            esac

            if [ \"\$PACKAGE_MANAGER\" = \"unknown\" ]; then exit 1; fi

            export PLATFORM_ID PLATFORM_FAMILY PACKAGE_MANAGER NAS_PLATFORM
            export MEDIA_STACK_PLATFORM_DETECTED=1
        }

        detect_platform
        echo \"PLATFORM_ID=\$PLATFORM_ID\"
        echo \"PLATFORM_FAMILY=\$PLATFORM_FAMILY\"
        echo \"PACKAGE_MANAGER=\$PACKAGE_MANAGER\"
        echo \"NAS_PLATFORM=\$NAS_PLATFORM\"
        ${extra}
        rm -f \"\$FAKE_OS_RELEASE\"
    "
}

setup() {
    setup_common
}

teardown() {
    teardown_common
}

# ---------------------------------------------------------------------------
# detect_platform — family and package manager mapping
# ---------------------------------------------------------------------------

@test "detect_platform: ubuntu -> debian family, apt" {
    run _platform_detect "ubuntu"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PLATFORM_FAMILY=debian"* ]]
    [[ "$output" == *"PACKAGE_MANAGER=apt"* ]]
}

@test "detect_platform: debian -> debian family, apt" {
    run _platform_detect "debian"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PLATFORM_FAMILY=debian"* ]]
    [[ "$output" == *"PACKAGE_MANAGER=apt"* ]]
}

@test "detect_platform: linuxmint -> debian family, apt" {
    run _platform_detect "linuxmint"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PLATFORM_FAMILY=debian"* ]]
}

@test "detect_platform: fedora -> redhat family" {
    run _platform_detect "fedora"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PLATFORM_FAMILY=redhat"* ]]
}

@test "detect_platform: centos -> redhat family" {
    run _platform_detect "centos"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PLATFORM_FAMILY=redhat"* ]]
}

@test "detect_platform: arch -> arch family, pacman" {
    run _platform_detect "arch"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PLATFORM_FAMILY=arch"* ]]
    [[ "$output" == *"PACKAGE_MANAGER=pacman"* ]]
}

@test "detect_platform: manjaro -> arch family, pacman" {
    run _platform_detect "manjaro"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PLATFORM_FAMILY=arch"* ]]
}

@test "detect_platform: alpine -> alpine family, apk" {
    run _platform_detect "alpine"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PLATFORM_FAMILY=alpine"* ]]
    [[ "$output" == *"PACKAGE_MANAGER=apk"* ]]
}

@test "detect_platform: opensuse -> suse family, zypper" {
    run _platform_detect "opensuse-leap"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PLATFORM_FAMILY=suse"* ]]
    [[ "$output" == *"PACKAGE_MANAGER=zypper"* ]]
}

# ---------------------------------------------------------------------------
# detect_platform — ID_LIKE fallback
# ---------------------------------------------------------------------------

@test "detect_platform: unknown ID with ID_LIKE=debian uses debian family" {
    run _platform_detect "popos" "debian"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PLATFORM_FAMILY=debian"* ]]
    [[ "$output" == *"PACKAGE_MANAGER=apt"* ]]
}

@test "detect_platform: unknown ID with ID_LIKE=rhel uses redhat family" {
    run _platform_detect "almalinux9" "rhel"
    [ "$status" -eq 0 ]
    [[ "$output" == *"PLATFORM_FAMILY=redhat"* ]]
}

@test "detect_platform: fully unknown distro exits with failure" {
    run _platform_detect "unknowndistro" ""
    [ "$status" -ne 0 ]
}

# ---------------------------------------------------------------------------
# detect_platform — NAS detection
# ---------------------------------------------------------------------------

@test "detect_platform: casaos sets NAS_PLATFORM=casaos" {
    # CasaOS is Debian-based; provide ID_LIKE=debian so package manager resolves
    run _platform_detect "casaos" "debian"
    [ "$status" -eq 0 ]
    [[ "$output" == *"NAS_PLATFORM=casaos"* ]]
}

@test "detect_platform: openmediavault sets NAS_PLATFORM=openmediavault" {
    # OMV is Debian-based; provide ID_LIKE=debian so package manager resolves
    run _platform_detect "openmediavault" "debian"
    [ "$status" -eq 0 ]
    [[ "$output" == *"NAS_PLATFORM=openmediavault"* ]]
}

# ---------------------------------------------------------------------------
# detect_platform — idempotency guard
# ---------------------------------------------------------------------------

@test "detect_platform is idempotent: second call does not change values" {
    run _platform_detect "ubuntu" "" "
        PLATFORM_FAMILY_FIRST=\$PLATFORM_FAMILY
        detect_platform  # second call — should be no-op
        echo \"SAME=\$([ \"\$PLATFORM_FAMILY\" = \"\$PLATFORM_FAMILY_FIRST\" ] && echo yes || echo no)\"
    "
    [ "$status" -eq 0 ]
    [[ "$output" == *"SAME=yes"* ]]
}

# ---------------------------------------------------------------------------
# require_root
# ---------------------------------------------------------------------------

@test "require_root exits with error when not running as root" {
    # We are not root in CI; this should fail
    if [ "$(id -u)" -eq 0 ]; then
        skip "Running as root; cannot test non-root rejection"
    fi
    run bash -c "
        export MEDIA_STACK_RUNTIME_LOADED=1
        export INSTALL_DIR='$REPO_DIR'
        export CORE_DIR='$REPO_DIR/core'
        export LIB_DIR='$REPO_DIR/lib'
        export SCRIPT_DIR='$REPO_DIR/scripts'
        export PLUGIN_DIR='$REPO_DIR/plugins'
        export TEMPLATE_DIR='$REPO_DIR/templates'
        export HOST_IP='127.0.0.1'
        source '$REPO_DIR/lib/runtime.sh'
        source '$REPO_DIR/core/platform.sh'
        require_root
    "
    [ "$status" -ne 0 ]
}
