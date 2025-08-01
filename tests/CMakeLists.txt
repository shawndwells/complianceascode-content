if(ENABLE_PYTHON_COVERAGE)
    set(PYTEST_COVERAGE_OPTIONS --cov-append --cov-report=xml --cov "${CMAKE_SOURCE_DIR}/ssg")
endif()

macro(ssg_python_unit_tests PYTHON_COMPONENT_ID RELATIVE_PYTHONPATH IGNORE_SUBDIR)
    if(NOT "${IGNORE_SUBDIR}" STREQUAL "")
        set(IGNORE "${CMAKE_SOURCE_DIR}/tests/unit/${PYTHON_COMPONENT_ID}/${IGNORE_SUBDIR}")
        set(TEST_COMMAND "${Python_EXECUTABLE}" -m pytest "--ignore=${IGNORE}" ${PYTEST_COVERAGE_OPTIONS} "${CMAKE_SOURCE_DIR}/tests/unit/${PYTHON_COMPONENT_ID}")
    else()
        set(TEST_COMMAND "${Python_EXECUTABLE}" -m pytest ${PYTEST_COVERAGE_OPTIONS} "${CMAKE_SOURCE_DIR}/tests/unit/${PYTHON_COMPONENT_ID}")
    endif()
    add_test(
        NAME "python-unit-${PYTHON_COMPONENT_ID}"
        COMMAND ${TEST_COMMAND}
    )
    set_tests_properties("python-unit-${PYTHON_COMPONENT_ID}" PROPERTIES ENVIRONMENT
        "PYTHONPATH=${CMAKE_SOURCE_DIR}/${RELATIVE_PYTHONPATH}:$ENV{PYTHONPATH}"
        LABELS quick
    )
endmacro()

if(PY_PYTEST)
    ssg_python_unit_tests("utils" "utils" "oscal/")
    ssg_python_unit_tests("ssg-module" "." "")
    ssg_python_unit_tests("ssg_test_suite" "tests" "")
    if(Python_VERSION_MAJOR GREATER 2 AND Python_VERSION_MINOR GREATER 7 AND PY_TRESTLE AND PY_LXML)
        ssg_python_unit_tests("utils/oscal" "utils/oscal" "")
    endif()
endif()

add_test(
    NAME "max-path-len"
    COMMAND "${Python_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/ensure_paths_are_short.py"
)
set_tests_properties("max-path-len" PROPERTIES LABELS quick)

add_test(
    NAME "test-rule-dir-json"
    COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/utils/rule_dir_json.py" "--root" "${CMAKE_SOURCE_DIR}" "--output" "${CMAKE_SOURCE_DIR}/build/rule_dirs.json"
)
set_tests_properties("test-rule-dir-json" PROPERTIES LABELS quick)
set_tests_properties("test-rule-dir-json" PROPERTIES FIXTURES_SETUP "rule-dir-json")

add_test(
    NAME "stable-profile-ids"
    COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/stable_profile_ids.py" "${CMAKE_BINARY_DIR}"
)
set_tests_properties("stable-profile-ids" PROPERTIES LABELS quick)

add_test(
    NAME "shorthand-to-oval"
    COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/utils/shorthand_to_oval.py" "${CMAKE_CURRENT_SOURCE_DIR}/data/utils/shorthand_oval.xml" "${CMAKE_CURRENT_BINARY_DIR}/oval.xml"
)
set_tests_properties("shorthand-to-oval" PROPERTIES LABELS quick)

add_test(
    NAME "stable-profiles"
    COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/test_profile_stability.py" "${CMAKE_BINARY_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}/data/profile_stability"
)
set_tests_properties("stable-profiles" PROPERTIES LABELS quick)

add_test(
    NAME "stable-products"
    COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/test_product_stability.py" "${CMAKE_BINARY_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}/data/product_stability"
)
set_tests_properties("stable-products" PROPERTIES LABELS quick)

add_test(
    NAME "machine-only-rules"
    COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/test_machine_only_rules.py" --source_dir "${CMAKE_SOURCE_DIR}" --build_dir "${CMAKE_BINARY_DIR}"
)
set_tests_properties("machine-only-rules" PROPERTIES LABELS quick)

if(SSG_BATS_TESTS_ENABLED AND BATS_EXECUTABLE)
    add_test(
        NAME "bash-unit-tests"
        COMMAND "${CMAKE_CURRENT_SOURCE_DIR}/unit/bash/execute_tests.sh" "${Python_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}/unit/bash" "${CMAKE_BINARY_DIR}/tests"
    )
    set_tests_properties("bash-unit-tests" PROPERTIES LABELS quick)
endif()
add_test(
    NAME "macros-oval"
    COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/test_macros_oval.py" "--verbose"
)
set_tests_properties("macros-oval" PROPERTIES LABELS quick)

add_test(
    NAME "fix_rules"
    COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/utils/fix_rules.py" "--dry-run" "--root" "${CMAKE_SOURCE_DIR}" "--json" "${CMAKE_SOURCE_DIR}/build/rule_dirs.json" "test_all"
)
set_tests_properties("fix_rules" PROPERTIES LABELS quick)
set_tests_properties("fix_rules" PROPERTIES DEPENDS "test-rule-dir-json")
set_tests_properties("fix_rules" PROPERTIES FIXTURES_REQUIRED "rule-dir-json")

macro(mypy_test SCRIPT FOLLOW_IMPORTS)
    if(PY_MYPY)
        add_test(
            NAME "test-mypy-${SCRIPT}"
            COMMAND env "${Python_EXECUTABLE}" -m mypy "${CMAKE_SOURCE_DIR}/${SCRIPT}" "--follow-imports=${FOLLOW_IMPORTS}"
        )
        set_tests_properties("test-mypy-${SCRIPT}" PROPERTIES LABELS quick)
        set_tests_properties("test-mypy-${SCRIPT}" PROPERTIES LABELS mypy)
    endif()
endmacro()

mypy_test("utils/import_srg_spreadsheet.py" "skip")
mypy_test("utils/check_eof.py" "normal")
mypy_test("utils/import_disa_stig.py" "skip")
mypy_test("tests/cces-removed.py" "normal")
mypy_test("utils/build_control_from_reference.py" "skip")
mypy_test("tests/rule_removal.py" "skip")

if(Python_VERSION_MAJOR GREATER 2 AND Python_VERSION_MINOR GREATER 7 AND PY_TRESTLE AND PY_LXML)
    mypy_test("utils/oscal/" "skip")
endif()

if(Python_VERSION_MAJOR GREATER 2 AND PY_OPENPYXL AND PY_PANDAS AND SSG_PRODUCT_RHEL9)
    add_test(
        NAME "srg-export-rhel9-xlsx"
        COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/utils/create_srg_export.py" --root "${CMAKE_SOURCE_DIR}" --json "${CMAKE_SOURCE_DIR}/build/rule_dirs.json" --control "${CMAKE_SOURCE_DIR}/controls/srg_gpos.yml" --product rhel9 --out-format "xlsx" --output "${CMAKE_BINARY_DIR}/cac_stig_output.xlsx" --build-config-yaml "${CMAKE_BINARY_DIR}/build_config.yml"
    )
    set_tests_properties("srg-export-rhel9-xlsx" PROPERTIES LABELS quick)
    set_tests_properties("srg-export-rhel9-xlsx" PROPERTIES FIXTURES_SETUP "rhel9-cac-xlsx")
    set_tests_properties("srg-export-rhel9-xlsx" PROPERTIES FIXTURES_REQUIRED "rule-dir-json")
    set_tests_properties("srg-export-rhel9-xlsx" PROPERTIES DEPENDS "test-rule-dir-json")


    add_test(
        NAME "srg-export-rhel9-md"
        COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/utils/create_srg_export.py" --root "${CMAKE_SOURCE_DIR}" --json "${CMAKE_SOURCE_DIR}/build/rule_dirs.json" --control "${CMAKE_SOURCE_DIR}/controls/srg_gpos.yml" --product rhel9 --out-format "md" --output "${CMAKE_BINARY_DIR}/cac_stig_output.md" --build-config-yaml "${CMAKE_BINARY_DIR}/build_config.yml"
    )
    set_tests_properties("srg-export-rhel9-md" PROPERTIES LABELS quick)
    set_tests_properties("srg-export-rhel9-md" PROPERTIES FIXTURES_REQUIRED "rule-dir-json")
    set_tests_properties("srg-export-rhel9-md" PROPERTIES DEPENDS "test-rule-dir-json")


    add_test(
        NAME "srg-export-rhel9-csv"
        COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/utils/create_srg_export.py" --root "${CMAKE_SOURCE_DIR}" --json "${CMAKE_SOURCE_DIR}/build/rule_dirs.json" --control "${CMAKE_SOURCE_DIR}/controls/srg_gpos.yml" --product rhel9 --out-format csv --output "${CMAKE_BINARY_DIR}/cac_stig_output.csv" --build-config-yaml "${CMAKE_BINARY_DIR}/build_config.yml"
    )
    set_tests_properties("srg-export-rhel9-csv" PROPERTIES LABELS quick)
    set_tests_properties("srg-export-rhel9-csv" PROPERTIES FIXTURES_REQUIRED "rule-dir-json")
    set_tests_properties("srg-export-rhel9-csv" PROPERTIES DEPENDS "test-rule-dir-json")

    add_test(
        NAME "srg-export-rhel9-html"
        COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/utils/create_srg_export.py" --root "${CMAKE_SOURCE_DIR}" --json "${CMAKE_SOURCE_DIR}/build/rule_dirs.json" --control "${CMAKE_SOURCE_DIR}/controls/srg_gpos.yml" --product rhel9 --out-format html --output "${CMAKE_BINARY_DIR}/cac_stig_output.html" --build-config-yaml "${CMAKE_BINARY_DIR}/build_config.yml"
    )
    set_tests_properties("srg-export-rhel9-html" PROPERTIES LABELS quick)
    set_tests_properties("srg-export-rhel9-html" PROPERTIES FIXTURES_REQUIRED "rule-dir-json")
    set_tests_properties("srg-export-rhel9-html" PROPERTIES DEPENDS "test-rule-dir-json")


    add_test(
        NAME "srg-diff-rhel9"
        COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/utils/srg_diff.py" --base "${CMAKE_SOURCE_DIR}/tests/data/utils/rhel9_stig_diff_base.xlsx" --target "${CMAKE_BINARY_DIR}/cac_stig_output.xlsx" --product rhel9
    )
    set_tests_properties("srg-diff-rhel9" PROPERTIES LABELS quick)
    set_tests_properties("srg-diff-rhel9" PROPERTIES FIXTURES_REQUIRED "rhel9-cac-xlsx")
    set_tests_properties("srg-diff-rhel9" PROPERTIES DEPENDS "srg-export-rhel9")
endif()

file(GLOB RHEL8_DISA_STIG_REF "${SSG_SHARED_REFS}/disa-stig-rhel8-v[0-9]*r[0-9]*-xccdf-manual.xml")

if(Python_VERSION_MAJOR GREATER 2)
add_test(
    NAME "test-compare_ds"
    COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/utils/compare_ds.py" "${CMAKE_SOURCE_DIR}/tests/data/utils/disa-stig-rhel8-v1r6-xccdf-manual.xml" "${RHEL8_DISA_STIG_REF}"
)
set_tests_properties("test-compare_ds" PROPERTIES LABELS quick)
endif()

if(Python_VERSION_MAJOR GREATER 2 AND GIT_EXECUTABLE AND EXISTS "${CMAKE_SOURCE_DIR}/.git")
add_test(
    NAME "test-generate_contributors"
    COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/utils/generate_contributors.py" "--dry-run"
)
set_tests_properties("test-generate_contributors" PROPERTIES LABELS quick)
endif()


if(Python_VERSION_MAJOR GREATER 2 AND SSG_PRODUCT_RHEL8)
add_test(
        NAME "test-create_scap_delta_tailoring"
        COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/utils/create_scap_delta_tailoring.py" --dry-run --root "${CMAKE_SOURCE_DIR}" --json "${CMAKE_BINARY_DIR}/rule_dirs.json" --build-config-yaml "${CMAKE_BINARY_DIR}/build_config.yml" --reference "stigid"  --output "${CMAKE_BINARY_DIR}/rhel8_stig_tailoring.xml" --product rhel8 --manual  "${RHEL8_DISA_STIG_REF}" -B "${CMAKE_BINARY_DIR}"
)
set_tests_properties("test-create_scap_delta_tailoring" PROPERTIES FIXTURES_REQUIRED "rule-dir-json")
set_tests_properties("test-create_scap_delta_tailoring" PROPERTIES DEPENDS "test-rule-dir-json")


add_test(
        NAME "test-create_scap_delta_tailoring_resolved"
        COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/utils/create_scap_delta_tailoring.py" --dry-run --root "${CMAKE_SOURCE_DIR}" --resolved-rules-dir --build-config-yaml "${CMAKE_BINARY_DIR}/build_config.yml" --reference "stigid"  --output "${CMAKE_BINARY_DIR}/rhel8_stig_tailoring.xml" --product rhel8 --manual  "${RHEL8_DISA_STIG_REF}" -B "${CMAKE_BINARY_DIR}"
)
set_tests_properties("test-create_scap_delta_tailoring_resolved" PROPERTIES FIXTURES_REQUIRED "rule-dir-json")
set_tests_properties("test-create_scap_delta_tailoring_resolved" PROPERTIES DEPENDS "test-rule-dir-json")
endif()


if(Python_VERSION_MAJOR GREATER 2 AND Python_VERSION_MINOR GREATER 6)
    add_test(
        NAME "test-controleval-directory"
        COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/utils/controleval.py" "--controls-dir" "${CMAKE_SOURCE_DIR}/tests/unit/ssg-module/data/controls_dir" "stats" "--level" "high" "--product" "rhel9" "--id" "qrst-levels"
    )
    set_tests_properties("test-controleval-directory" PROPERTIES LABELS quick)

    add_test(
        NAME "test-controleval-onefile"
        COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/utils/controleval.py" "--controls-dir" "${CMAKE_SOURCE_DIR}/tests/unit/ssg-module/data/controls_dir" "stats" "--level" "low" "--product" "rhel8" "--id" "abcd-levels"
    )
    set_tests_properties("test-controleval-onefile" PROPERTIES LABELS quick)

    add_test(
        NAME "test-controleval-json"
        COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/utils/controleval.py" "--controls-dir" "${CMAKE_SOURCE_DIR}/tests/unit/ssg-module/data/controls_dir" "stats" "--level" "medium" "--product" "rhel8" "--id" "qrst-levels" "--output-format" "json"
    )
    set_tests_properties("test-controleval-json" PROPERTIES LABELS quick)

    if(PY_PROMETHEUS_CLIENT)
        add_test(
            NAME "test-controleval-prometheus-metrics"
            COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/utils/controleval_metrics.py" "--controls-dir" "${CMAKE_SOURCE_DIR}/tests/unit/ssg-module/data/controls_dir" "prometheus" "--products" "fedora" "ol9" "rhel8" "rhel9" "rhel10" "sle15"
        )
        set_tests_properties("test-controleval-prometheus-metrics" PROPERTIES LABELS quick)
    endif()
endif()

macro(ssg_refcheck_test PRODUCT PROFILE KEY)
    # If you pass comma separated list as the fourth argument those rules will be excluded from the check.
    set(extra_args ${ARGN})
    list(LENGTH extra_args extra_args_length)
    if(${extra_args_length} EQUAL 1)
        list(GET extra_args 0 excludes)
        add_test(
            NAME "refchecker-${PRODUCT}-${PROFILE}"
            COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/utils/refchecker.py" --json "${CMAKE_SOURCE_DIR}/build/rule_dirs.json" --build-config-yaml "${CMAKE_BINARY_DIR}/build_config.yml" "--exclude" "${excludes}" "${PRODUCT}" "${PROFILE}" "${KEY}"
        )
    else()
        add_test(
        NAME "refchecker-${PRODUCT}-${PROFILE}"
        COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/utils/refchecker.py" --json "${CMAKE_SOURCE_DIR}/build/rule_dirs.json" --build-config-yaml "${CMAKE_BINARY_DIR}/build_config.yml" "${PRODUCT}" "${PROFILE}" "${KEY}"
        )
    endif()
    set_tests_properties("refchecker-${PRODUCT}-${PROFILE}" PROPERTIES FIXTURES_REQUIRED "rule-dir-json")
    set_tests_properties("refchecker-${PRODUCT}-${PROFILE}" PROPERTIES DEPENDS "test-rule-dir-json")
    set_tests_properties("refchecker-${PRODUCT}-${PROFILE}" PROPERTIES LABELS quick)
endmacro()

macro(stig_srg_mapping_test PRODUCT)
    add_test(
        NAME "stig-srg-mapping-${PRODUCT}"
        COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/stig_srg_mapping.py" --prefix "SRG-OS" --build-root "${CMAKE_BINARY_DIR}" --root "${CMAKE_SOURCE_DIR}" ${PRODUCT}
    )
    set_tests_properties("stig-srg-mapping-${PRODUCT}" PROPERTIES LABELS quick)
endmacro()


if(Python_VERSION_MAJOR GREATER 2 AND SSG_PRODUCT_RHEL9)
    stig_srg_mapping_test("rhel9")
endif()

if(Python_VERSION_MAJOR GREATER 2 AND SSG_PRODUCT_RHEL8)
    stig_srg_mapping_test("rhel8")
endif()

macro(ssg_controlrefcheck_test PRODUCT CONTROL KEY)
    if(Python_VERSION_MAJOR GREATER 2)
        add_test(
            NAME "controlrefchecker-${PRODUCT}-${CONTROL}"
            COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/utils/controlrefcheck.py" --json "${CMAKE_SOURCE_DIR}/build/rule_dirs.json" --build-config-yaml "${CMAKE_BINARY_DIR}/build_config.yml" "${PRODUCT}" "${CONTROL}" "${KEY}"
        )
        set_tests_properties("controlrefchecker-${PRODUCT}-${CONTROL}" PROPERTIES FIXTURES_REQUIRED "rule-dir-json")
        set_tests_properties("controlrefchecker-${PRODUCT}-${CONTROL}" PROPERTIES DEPENDS "test-rule-dir-json")
        set_tests_properties("controlrefchecker-${PRODUCT}-${CONTROL}" PROPERTIES LABELS quick)
    endif()
endmacro()

if(SSG_PRODUCT_RHEL8)
    ssg_controlrefcheck_test("rhel8" "cis_rhel8" "cis")
endif()
if(SSG_PRODUCT_RHEL9)
    ssg_controlrefcheck_test("rhel9" "cis_rhel9" "cis")
    ssg_controlrefcheck_test("rhel9" "stig_rhel9" "stigid")
endif()


if(Python_VERSION_MAJOR GREATER 2)
    add_test(
        NAME "test-check-eof"
        COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/utils/check_eof.py" "${CMAKE_SOURCE_DIR}/ssg" "${CMAKE_SOURCE_DIR}/linux_os" "${CMAKE_SOURCE_DIR}/utils" "${CMAKE_SOURCE_DIR}/tests" "${CMAKE_SOURCE_DIR}/products" "${CMAKE_SOURCE_DIR}/shared" "${CMAKE_SOURCE_DIR}/docs" "${CMAKE_SOURCE_DIR}/apple_os" "${CMAKE_SOURCE_DIR}/applications" "${CMAKE_SOURCE_DIR}/build-scripts" "${CMAKE_SOURCE_DIR}/cmake" "${CMAKE_SOURCE_DIR}/Dockerfiles" "${CMAKE_SOURCE_DIR}/tests" "${CMAKE_SOURCE_DIR}/controls" "${CMAKE_SOURCE_DIR}/.github"
    )
endif()

if(PY_CMAKELINT)
    file(GLOB CMAKELINT_FILES "${CMAKE_SOURCE_DIR}/CMakeLists.txt" "${CMAKE_SOURCE_DIR}/tests/CMakeLists.txt" "${CMAKE_SOURCE_DIR}/products/*/CMakeLists.txt" "${CMAKE_SOURCE_DIR}/cmake/*.cmake")
    add_test(
        NAME "test-cmakelint"
        COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "cmakelint" --config "${CMAKE_SOURCE_DIR}/.cmakelintrc" ${CMAKELINT_FILES}
    )
endif()

if(Python_VERSION_MAJOR GREATER 2)
    add_test(
        NAME "install-vm"
        COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/tests/install_vm.py" "--help"
    )
    set_tests_properties("install-vm" PROPERTIES LABELS quick)
endif()

add_test(
    NAME "automatus-sanity"
    COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/tests/automatus.py" "--help"
)
set_tests_properties("automatus-sanity" PROPERTIES LABELS quick)


if(SSG_PRODUCT_RHEL9)
add_test(
    NAME "components"
    COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/test_components.py" --build-dir "${CMAKE_BINARY_DIR}" --source-dir "${CMAKE_SOURCE_DIR}" --product "rhel9"
)
set_tests_properties("components" PROPERTIES LABELS quick)
endif()

macro(cce_avail_check TEST_NAME_SUFFIX PRODUCTS CCE_LIST_PATH)
    if(Python_VERSION_MAJOR GREATER 2)
        add_test(
            NAME "cce_avail_check-${TEST_NAME_SUFFIX}"
            COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/cces-removed.py" --root  "${CMAKE_SOURCE_DIR}" --json "${CMAKE_SOURCE_DIR}/build/rule_dirs.json" --products "${PRODUCTS}" --cce-list "${CCE_LIST_PATH}"
        )
        set_tests_properties("cce_avail_check-${TEST_NAME_SUFFIX}" PROPERTIES FIXTURES_REQUIRED "rule-dir-json")
        set_tests_properties("cce_avail_check-${TEST_NAME_SUFFIX}" PROPERTIES DEPENDS "test-rule-dir-json")
        set_tests_properties("cce_avail_check-${TEST_NAME_SUFFIX}" PROPERTIES LABELS quick)
    endif()
endmacro()

cce_avail_check("redhat-all" "ocp4,rhel8,rhel9,rhel10" "${CMAKE_SOURCE_DIR}/shared/references/cce-redhat-avail.txt")
cce_avail_check("sle12" "sle12" "${CMAKE_SOURCE_DIR}/shared/references/cce-sle12-avail.txt")
cce_avail_check("sle15" "sle15" "${CMAKE_SOURCE_DIR}/shared/references/cce-sle15-avail.txt")

if(Python_VERSION_MAJOR GREATER 2 AND Python_VERSION_MINOR GREATER 6 AND PY_OPENPYXL)
    add_test(
        NAME "utils-import_disa_stig_sanity"
        COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/utils/import_disa_stig.py" "--help"
        set_tests_properties("utils-import_disa_stig_sanity" PROPERTIES LABELS quick)
    )
endif()


if(Python_VERSION_MAJOR GREATER 2 AND PY_GITHUB)
    add_test(
        NAME "utils-ansible-playbook-to-role-help"
        COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/utils/ansible_playbook_to_role.py" "--help"
    )
    set_tests_properties("utils-ansible-playbook-to-role-help" PROPERTIES LABELS quick)
    if(SSG_PRODUCT_RHEL9)
        file(MAKE_DIRECTORY "${CMAKE_BINARY_DIR}/roles")
        add_test(
            NAME "utils-ansible-playbook-to-role-rhel9"
            COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/utils/ansible_playbook_to_role.py" "--dry-run" "${CMAKE_BINARY_DIR}/roles" "--product" "rhel9" "--build-playbooks-dir" "${CMAKE_BINARY_DIR}/ansible"
        )
    endif()
endif()

if(Python_VERSION_MAJOR GREATER 2 AND Python_VERSION_MINOR GREATER 6)
    add_test(
        NAME "utils-build_control_from_reference_sanity"
        COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/utils/build_control_from_reference.py" "--product" "rhel10" "--reference" "ospp" "--root" "${CMAKE_SOURCE_DIR}" "--output" "${CMAKE_SOURCE_DIR}/build/rhel10_ospp_control.yml" "--json" "${CMAKE_SOURCE_DIR}/build/rule_dirs.json"
    )
    set_tests_properties("utils-build_control_from_reference_sanity" PROPERTIES FIXTURES_REQUIRED "rule-dir-json")
    set_tests_properties("utils-build_control_from_reference_sanity" PROPERTIES DEPENDS "test-rule-dir-json")
endif()

if(Python_VERSION_MAJOR GREATER 2 AND Python_VERSION_MINOR GREATER 9)
    add_test(
        NAME "validate_automatus_metadata"
        COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/validate_automatus_metadata.py" "--root" "${CMAKE_SOURCE_DIR}"
    )
mypy_test("tests/validate_automatus_metadata.py" "normal")
endif()

macro(check_for_rule_removal PRODUCT)
    if(ENABLE_CHECK_RULE_REMOVAL)
        add_test(
            NAME "rule-removal-${PRODUCT}"
            COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_CURRENT_SOURCE_DIR}/rule_removal.py" "--product" "${PRODUCT}" "--old-release-dir" "${OLD_RELEASE_DIR}" "--build-root" "${CMAKE_BINARY_DIR}"
        )
    endif()
endmacro()

if(SSG_PRODUCT_RHEL8)
    check_for_rule_removal("rhel8")
endif()

if(SSG_PRODUCT_RHEL9)
    check_for_rule_removal("rhel9")
endif()

if(SSG_PRODUCT_RHEL10)
    check_for_rule_removal("rhel10")
endif()

if(Python_VERSION_MAJOR GREATER 2 AND Python_VERSION_MINOR GREATER 6 AND PY_OPENPYXL)
add_test(
    NAME "import_srg_spreadsheet-sanity"
    COMMAND env "PYTHONPATH=$ENV{PYTHONPATH}" "${Python_EXECUTABLE}" "${CMAKE_SOURCE_DIR}/utils/import_srg_spreadsheet.py" "-h"
)
endif()
