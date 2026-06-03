add_rules("mode.debug", "mode.release")

-- ============================================================
-- memleak - main executable
-- ============================================================
target("memleak")
    set_kind("binary")
    add_files("memleak.c")
    add_includedirs(".", "$(buildir)")
    add_cxflags("-std=gnu11")

    -- libbpf
    add_links("bpf", "elf", "z")

    -- blazesym: prefer system-installed, fallback to submodule build
    local blazesym_dir = path.join(os.projectdir(), "blazesym")
    if os.isdir(path.join(blazesym_dir, "capi", "include")) then
        -- build from submodule
        add_includedirs(path.join(blazesym_dir, "capi", "include"))
        add_linkdirs(path.join(blazesym_dir, "target", "release"))
        add_links("blazesym_c")
    else
        -- system-installed
        add_includedirs("/usr/local/include")
        add_linkdirs("/usr/local/lib")
        add_links("blazesym_c")
    end
    add_links("pthread", "dl", "m")

    before_build(function (target)
        -- Step 0: generate vmlinux.h if missing
        local vmlinux_h = path.join(os.projectdir(), "vmlinux.h")
        if not os.isfile(vmlinux_h) then
            print("  [VMLINUX] generating vmlinux.h from kernel BTF")
            os.vrunv("bpftool", {"btf", "dump", "file", "/sys/kernel/btf/vmlinux", "format", "c"},
                     {stdout = vmlinux_h})
        end

        -- Step 1: build blazesym if submodule exists and not yet built
        local blazesym_dir = path.join(os.projectdir(), "blazesym")
        local blazesym_so = path.join(blazesym_dir, "target", "release", "libblazesym_c.so")
        local blazesym_a  = path.join(blazesym_dir, "target", "release", "libblazesym_c.a")
        if os.isdir(path.join(blazesym_dir, "capi")) and
           not os.isfile(blazesym_so) and not os.isfile(blazesym_a) then
            print("  [BLAZESYM] building from submodule (one-time, ~90s)")
            os.vrunv("cargo", {"build", "--release", "-p", "blazesym-c"},
                     {curdir = blazesym_dir})
        end

        -- Step 2: compile BPF program
        local bpf_src = "memleak.bpf.c"
        local builddir = target:targetdir()
        local bpf_obj = path.join(builddir, path.basename(bpf_src) .. ".o")
        local skel_h  = path.join(builddir, path.basename(bpf_src) .. ".skel.h")

        print("  [BPF] compiling " .. bpf_src)
        os.vrunv("clang", {
            "-g", "-O2", "-target", "bpf",
            "-D__TARGET_ARCH_x86",
            "-c", bpf_src,
            "-o", bpf_obj
        })

        print("  [SKEL] generating " .. skel_h)
        os.vrunv("bpftool", {"gen", "skeleton", bpf_obj}, {stdout = skel_h})
    end)

-- ============================================================
-- test_memleak - simple memory leak test helper
-- ============================================================
target("test_memleak")
    set_kind("binary")
    add_files("test_memleak.cpp")
    set_languages("c++17")
    add_cxflags("-g", "-no-pie")
