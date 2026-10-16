# Historical development files

These files are preserved for reference. They are not supported setup, test,
build, or publishing entry points. The entire extra_functions directory is
excluded from source package builds by .Rbuildignore.

| Original location | Preserved file | Why archived |
| --- | --- | --- |
| inst/Build_Package.R | [Build_Package.R](Build_Package.R) | Interactive scratchpad, obsolete APIs, installation and publishing commands |
| test.R | [test.R](test.R) | Exploratory examples superseded by the retained test suite |
| install_statart_deps.R | [install_statart_deps.R](install_statart_deps.R) | Installs dependencies from the earlier, larger package scope |
| TEST_SUMMARY.md | [TEST_SUMMARY.md](TEST_SUMMARY.md) | Historical test inventory and installation blockage |
| CRAN-SUBMISSION | [CRAN-SUBMISSION](CRAN-SUBMISSION) | Version 0.2.0 submission metadata from 2024 |
| cran-comments.md | [cran-comments.md](cran-comments.md) | Earlier release check comments and 33-Imports note |

The six files were moved without modifying their bytes. Do not source the
historical build scratchpad or dependency installer as part of current setup.

Current development and verification instructions are in
[DEVELOPMENT.md](../../DEVELOPMENT.md) and
[CONTRIBUTING.md](../../CONTRIBUTING.md). The supported test workflow is
[verify_package.py](../../.opencode/workflows/verify_package.py);
[run_tests.R](../../run_tests.R) remains a compatible protected-launcher wrapper.
The current issue list is [.opencode/PROBLEMS.md](../../.opencode/PROBLEMS.md).
