// U-PLAN-01: the test plan and the tests agree.
//
// - Every test function named test_U_<AREA>_<NN>_... uses an ID that has a row in
//   docs/test-plan.md.
// - Every U- row whose status is not "–" (not automated yet) has at least one test.
#include <unity.h>

#include <filesystem>
#include <fstream>
#include <map>
#include <regex>
#include <set>
#include <sstream>
#include <string>

namespace fs = std::filesystem;

namespace {

fs::path project_dir() { return fs::path(HL_PROJECT_DIR); }   // firmware/, set in platformio.ini

std::string read_file(const fs::path& p) {
    std::ifstream in(p);
    std::stringstream ss;
    ss << in.rdbuf();
    return ss.str();
}

std::string trim(const std::string& s) {
    const auto a = s.find_first_not_of(" \t\r");
    if (a == std::string::npos) return "";
    const auto b = s.find_last_not_of(" \t\r");
    return s.substr(a, b - a + 1);
}

// U- rows of the plan: ID -> status (the last column).
std::map<std::string, std::string> plan_rows() {
    std::map<std::string, std::string> rows;
    std::istringstream in(read_file(project_dir() / ".." / "docs" / "test-plan.md"));
    const std::regex row(R"(^\| (U-[A-Z]+-[0-9]+) \|)");
    std::string line;
    while (std::getline(in, line)) {
        std::smatch m;
        if (!std::regex_search(line, m, row)) continue;
        const auto end = line.find_last_of('|');
        const auto start = line.find_last_of('|', end - 1);
        rows[m[1]] = trim(line.substr(start + 1, end - start - 1));
    }
    return rows;
}

// IDs used by test function names under firmware/test.
std::set<std::string> test_ids() {
    std::set<std::string> ids;
    const std::regex fn(R"(\bvoid\s+test_(U_[A-Z]+_[0-9]+)_\w*\s*\()");
    for (const auto& e : fs::recursive_directory_iterator(project_dir() / "test")) {
        if (!e.is_regular_file() || e.path().extension() != ".cpp") continue;
        const std::string src = read_file(e.path());
        for (std::sregex_iterator it(src.begin(), src.end(), fn), end; it != end; ++it) {
            std::string id = (*it)[1];
            for (char& c : id) if (c == '_') c = '-';
            ids.insert(id);
        }
    }
    return ids;
}

bool not_automated_yet(const std::string& status) { return status == "–" || status == "-"; }

}  // namespace

void setUp() {}
void tearDown() {}

void test_U_PLAN_01_plan_and_tests_agree() {
    const auto rows = plan_rows();
    const auto ids = test_ids();
    TEST_ASSERT_TRUE_MESSAGE(rows.size() > 20, "could not read the U- rows of docs/test-plan.md");
    TEST_ASSERT_TRUE_MESSAGE(ids.count("U-PLAN-01") == 1, "the test scan found no tests");

    std::string problems;
    for (const auto& id : ids)
        if (!rows.count(id)) problems += "\n  test uses " + id + ", which has no row in the plan";
    for (const auto& [id, status] : rows)
        if (!not_automated_yet(status) && !ids.count(id))
            problems += "\n  plan row " + id + " says \"" + status + "\" but no test has its ID";
    TEST_ASSERT_TRUE_MESSAGE(problems.empty(), problems.c_str());
}

int main() {
    UNITY_BEGIN();
    RUN_TEST(test_U_PLAN_01_plan_and_tests_agree);
    return UNITY_END();
}
