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

    -- blazesym (Rust static lib — force static linking to avoid .so dependency)
    add_includedirs("/tmp/blazesym/capi/include")
    add_linkdirs("/tmp/blazesym/target/release")
    -- -Bstatic tells linker to use .a; -Bdynamic resumes normal dynamic linking after
    add_ldflags("-Wl,-Bstatic", "-lblazesym_c", "-Wl,-Bdynamic")
    add_links("pthread", "dl", "m")

    before_build(function (target)
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
