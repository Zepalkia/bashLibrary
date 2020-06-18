source ../bashLibrary.sh

testing_testCase "Changing case" << TEST
assertSuccess string_toUpperCase "Test" res
assertEqual \$res "TEST"
assertSuccess string_toUpperCase abc123+@# res
assertEqual \$res "ABC123+@#"
assertSuccess string_toLowerCase "Test" res
assertEqual \$res "test"
assertSuccess string_toLowerCase "AbC123+@#" res
assertEqual \$res "abc123+@#"
TEST

testing_testCase "Trimming" << TEST
assertSuccess string_trim \" a b c \" all res
assertEqual \$res abc
assertSuccess string_trim \" a b c \" leading res
assertEqual \""\$res\"" \""a b c \""
assertSuccess string_trim \" a b c \" trailing res
assertEqual \""\$res\"" \"" a b c\""
assertSuccess string_trim \"     \" leading res
assertEqual \${#res} 0
assertSuccess string_trim \"     \" all res
assertEqual \${#res} 0
assertSuccess string_trim \"      \" trailing res
assertEqual \${#res} 0
TEST

testing_testCase "Tokenizing" << TEST
assertSuccess string_tokenize \"a:b:c\" \":\" res
assertEqual \${res[0]} a
assertEqual \${res[1]} b
assertEqual \${res[2]} c
assertSuccess string_tokenize \"a:\" \":\" res
assertEqual \${res[0]} a
assertEqual \${#res[1]} 0
assertSuccess string_tokenize \"a::b\" \":\" res
assertEqual \${res[0]} a
assertEqual \${#res[1]} 0
assertEqual \${res[2]} b
TEST

testing_testCase "Substring & CharAt" << TEST
assertSuccess string_substr 0123456789 0 3 res
assertEqual \$res 012
assertSuccess string_substr 0123456789 3 1 res
assertEqual \$res 3
assertSuccess string_substr 0123456789 -1 0 res
assertEqual \${#res} 0
assertSuccess string_substr 0123 0 5 res
assertEqual \$res 0123
assertSuccess string_charAt 0123456789 8 res
assertEqual \$res 8
assertSuccess string_charAt 0123 10 res
assertEqual \${#res} 0
TEST

testing_testCase "Random string" << TEST
assertSuccess string_rand \"[0-9]\" 5 res
assertEqual \${#res} 5
TEST
